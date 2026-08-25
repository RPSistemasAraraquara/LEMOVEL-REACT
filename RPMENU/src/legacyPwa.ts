type BeforeInstallPromptEvent = Event & {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: string; platform: string }>;
};

declare const __APP_BUILD_ID__: string;

const DISMISS_KEY = "pwaInstallDismissed";

let initialized = false;
let deferredPrompt: BeforeInstallPromptEvent | null = null;

function currentBuildId(): string {
  return typeof __APP_BUILD_ID__ === "string" && __APP_BUILD_ID__.trim() ? __APP_BUILD_ID__ : "dev";
}

function buildAssetUrl(path: string): string {
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  const url = new URL(normalizedPath, window.location.origin);
  url.searchParams.set("v", currentBuildId());
  return url.toString();
}

function pwaBannerWasDismissed(): boolean {
  const value = localStorage.getItem(DISMISS_KEY);
  if (!value) return false;
  if (value === "installed") return true;

  const hideForDays = 3;
  const difference = Date.now() - Number.parseInt(value, 10);
  return difference < hideForDays * 24 * 60 * 60 * 1000;
}

function ensureSlideAnimation(): void {
  if (document.getElementById("rpfood-pwa-style")) return;

  const style = document.createElement("style");
  style.id = "rpfood-pwa-style";
  style.textContent =
    "@keyframes pwaSlideUp{from{transform:translateY(100px);opacity:0}to{transform:translateY(0);opacity:1}}";
  document.head.appendChild(style);
}

function removeBanner(id: string): void {
  document.getElementById(id)?.remove();
}

function injectDynamicManifest(): void {
  if (document.getElementById("rpfood-dynamic-manifest")) return;
  const link = document.createElement("link");
  link.id = "rpfood-dynamic-manifest";
  link.rel = "manifest";
  link.href = buildAssetUrl("/manifest.json");
  document.head.appendChild(link);
}

function registerServiceWorker(): void {
  if (!("serviceWorker" in navigator)) return;

  window.addEventListener("load", () => {
    const serviceWorkerUrl = buildAssetUrl("/sw.js");

    navigator.serviceWorker
      .register(serviceWorkerUrl, {
        scope: "/",
        updateViaCache: "none",
      })
      .then((registration) => {
        void registration.update();
      })
      .catch((error: unknown) => {
        console.log("SW registration failed: ", error);
      });
  });
}

function buildBannerShell(id: string): HTMLDivElement {
  ensureSlideAnimation();
  removeBanner(id);

  const banner = document.createElement("div");
  banner.id = id;
  banner.style.cssText =
    "position:fixed;bottom:70px;left:10px;right:10px;background:#F2994A;color:#fff;padding:14px 16px;border-radius:14px;display:flex;align-items:center;justify-content:space-between;gap:10px;z-index:99999;box-shadow:0 4px 20px rgba(0,0,0,.25);font-family:sans-serif;animation:pwaSlideUp .4s ease;";
  return banner;
}

function showInstallBanner(): void {
  if (pwaBannerWasDismissed()) return;

  const banner = buildBannerShell("pwaInstallBanner");
  banner.innerHTML =
    '<div style="display:flex;align-items:center;gap:12px;flex:1;min-width:0;">' +
    `<img src="${buildAssetUrl("/images/rpfood/logo/mobile500.png")}" style="width:44px;height:44px;border-radius:10px;flex-shrink:0;">` +
    '<div style="min-width:0;"><strong style="display:block;font-size:15px;">RP Food</strong>' +
    '<span style="font-size:13px;opacity:.85;">Adicione ao seu celular</span></div>' +
    "</div>" +
    '<div style="display:flex;gap:8px;flex-shrink:0;">' +
    '<button id="pwaInstallBtn" style="background:#fff;color:#F2994A;border:none;padding:8px 18px;border-radius:20px;font-weight:700;font-size:14px;cursor:pointer;">Instalar</button>' +
    '<button id="pwaDismissBtn" style="background:transparent;color:#fff;border:1.5px solid rgba(255,255,255,.6);padding:8px 14px;border-radius:20px;font-size:13px;cursor:pointer;">Agora não</button>' +
    "</div>";

  document.body.appendChild(banner);

  document.getElementById("pwaInstallBtn")?.addEventListener("click", () => {
    banner.remove();
    if (!deferredPrompt) return;

    void deferredPrompt.prompt();
    void deferredPrompt.userChoice.then(() => {
      deferredPrompt = null;
    });
  });

  document.getElementById("pwaDismissBtn")?.addEventListener("click", () => {
    banner.remove();
    localStorage.setItem(DISMISS_KEY, Date.now().toString());
  });
}

function showIosInstructions(isSafari: boolean): void {
  removeBanner("pwaInstallBannerIOS");

  const banner = buildBannerShell("pwaInstallBannerIOS");
  banner.style.cssText += "flex-direction:column;align-items:stretch;bottom:70px;";

  if (isSafari) {
    banner.innerHTML =
      '<div style="display:flex;align-items:center;gap:12px;flex:1;min-width:0;">' +
      `<img src="${buildAssetUrl("/images/rpfood/logo/mobile500.png")}" style="width:44px;height:44px;border-radius:10px;flex-shrink:0;">` +
      '<div style="min-width:0;"><strong style="display:block;font-size:15px;">RP Food</strong>' +
      '<span style="font-size:13px;opacity:.85;">Instale no iPhone usando o Safari</span></div>' +
      "</div>" +
      '<div style="margin-top:12px;background:rgba(255,255,255,.15);border-radius:12px;padding:12px;font-size:13px;line-height:1.6;">' +
      'Para instalar no iPhone, é necessário abrir este site pelo navegador <strong>Safari</strong>.<br><br>' +
      '<strong>1.</strong> Toque em <strong>Compartilhar</strong><br>' +
      '<strong>2.</strong> Toque em <strong>Adicionar à Tela de Início</strong><br>' +
      '<strong>3.</strong> Toque em <strong>Adicionar</strong>' +
      "</div>" +
      '<div style="display:flex;gap:8px;justify-content:flex-end;margin-top:12px;">' +
      '<button id="iosDismissBtn" style="background:transparent;color:#fff;border:1.5px solid rgba(255,255,255,.6);padding:8px 14px;border-radius:20px;font-size:13px;cursor:pointer;">Agora não</button>' +
      '<button id="iosUnderstoodBtn" style="background:#fff;color:#F2994A;border:none;padding:8px 18px;border-radius:20px;font-weight:700;font-size:14px;cursor:pointer;">Entendi</button>' +
      "</div>";
  } else {
    banner.innerHTML =
      '<div style="display:flex;align-items:center;gap:12px;flex:1;min-width:0;">' +
      `<img src="${buildAssetUrl("/images/rpfood/logo/mobile500.png")}" style="width:44px;height:44px;border-radius:10px;flex-shrink:0;">` +
      '<div style="min-width:0;"><strong style="display:block;font-size:15px;">RP Food</strong>' +
      '<span style="font-size:13px;opacity:.85;">Use o Safari para instalar</span></div>' +
      "</div>" +
      '<div style="margin-top:12px;background:rgba(255,255,255,.15);border-radius:12px;padding:12px;font-size:13px;line-height:1.6;">' +
      'No iPhone, a instalacao do aplicativo precisa ser feita pelo <strong>Safari</strong>. Abra este site no Safari e toque em <strong>Adicionar à Tela de Início</strong>.' +
      "</div>" +
      '<div style="display:flex;gap:8px;justify-content:flex-end;margin-top:12px;">' +
      '<button id="iosDismissBtn" style="background:transparent;color:#fff;border:1.5px solid rgba(255,255,255,.6);padding:8px 14px;border-radius:20px;font-size:13px;cursor:pointer;">Agora não</button>' +
      '<button id="iosUnderstoodBtn" style="background:#fff;color:#F2994A;border:none;padding:8px 18px;border-radius:20px;font-weight:700;font-size:14px;cursor:pointer;">Entendi</button>' +
      "</div>";
  }

  document.body.appendChild(banner);

  document.getElementById("iosDismissBtn")?.addEventListener("click", () => {
    banner.remove();
    localStorage.setItem(DISMISS_KEY, Date.now().toString());
  });

  document.getElementById("iosUnderstoodBtn")?.addEventListener("click", () => {
    banner.remove();
  });
}

function setupInstallPrompt(): void {
  window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault();
    deferredPrompt = event as BeforeInstallPromptEvent;
    showInstallBanner();
  });

  window.addEventListener("appinstalled", () => {
    removeBanner("pwaInstallBanner");
    localStorage.setItem(DISMISS_KEY, "installed");
  });
}

function showIosBanner(): void {
  const isIos =
    /iPad|iPhone|iPod/.test(navigator.userAgent) ||
    (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
  const isSafari =
    /Safari/.test(navigator.userAgent) && !/CriOS|FxiOS|OPiOS|EdgiOS|Chrome/.test(navigator.userAgent);
  const isStandalone =
    (window.navigator as Navigator & { standalone?: boolean }).standalone === true ||
    window.matchMedia("(display-mode: standalone)").matches;

  if (!isIos || isStandalone || pwaBannerWasDismissed()) return;

  window.setTimeout(() => {
    const banner = buildBannerShell("pwaInstallBannerIOS");
    banner.innerHTML =
      '<div style="display:flex;align-items:center;gap:12px;flex:1;min-width:0;">' +
      `<img src="${buildAssetUrl("/images/rpfood/logo/mobile500.png")}" style="width:44px;height:44px;border-radius:10px;flex-shrink:0;">` +
      '<div style="min-width:0;"><strong style="display:block;font-size:15px;">RP Food</strong>' +
      `<span style="font-size:13px;opacity:.85;">${isSafari ? "Instale no iPhone pelo Safari" : "Abra no Safari para instalar no iPhone"}</span></div>` +
      "</div>" +
      '<div style="display:flex;gap:8px;flex-shrink:0;">' +
      '<button id="iosInstallBtn" style="background:#fff;color:#F2994A;border:none;padding:8px 18px;border-radius:20px;font-weight:700;font-size:14px;cursor:pointer;">Instalar</button>' +
      '<button id="iosDismissBtn" style="background:transparent;color:#fff;border:1.5px solid rgba(255,255,255,.6);padding:8px 14px;border-radius:20px;font-size:13px;cursor:pointer;">Agora não</button>' +
      "</div>";

    document.body.appendChild(banner);

    document.getElementById("iosInstallBtn")?.addEventListener("click", () => {
      banner.remove();
      showIosInstructions(isSafari);
    });

    document.getElementById("iosDismissBtn")?.addEventListener("click", () => {
      banner.remove();
      localStorage.setItem(DISMISS_KEY, Date.now().toString());
    });
  }, 1200);
}

export function initLegacyPwa(): void {
  if (initialized || typeof window === "undefined") return;
  initialized = true;

  injectDynamicManifest();
  registerServiceWorker();
  setupInstallPrompt();
  showIosBanner();
}

const STANDALONE_SEEN_KEY = "rpfood.standaloneLaunched";

function isStandaloneMode(): boolean {
  if (typeof window === "undefined") return false;

  return (
    (window.navigator as Navigator & { standalone?: boolean }).standalone === true ||
    window.matchMedia("(display-mode: standalone)").matches
  );
}

export function initStandaloneLaunchScreen(): () => void {
  if (typeof document === "undefined" || !isStandaloneMode()) {
    return () => undefined;
  }

  document.body.classList.add("rpfood-standalone-mode");

  if (document.getElementById("rpfood-standalone-launch")) {
    return () => undefined;
  }

  const firstStandaloneOpen = localStorage.getItem(STANDALONE_SEEN_KEY) !== "1";
  localStorage.setItem(STANDALONE_SEEN_KEY, "1");

  document.body.classList.add("rpfood-standalone-open");

  const particles = Array.from({ length: 10 }, (_, index) => {
    const left = 8 + ((index * 9) % 84);
    const top = 10 + ((index * 17) % 72);
    const size = 4 + (index % 3);
    const delay = (index * 0.18).toFixed(2);
    const duration = (2.8 + (index % 4) * 0.45).toFixed(2);

    return `<span class="rpfood-standalone-launch__particle" style="left:${left}%;top:${top}%;width:${size}px;height:${size}px;animation-delay:${delay}s;animation-duration:${duration}s"></span>`;
  }).join("");

  const overlay = document.createElement("div");
  overlay.id = "rpfood-standalone-launch";
  overlay.className = "rpfood-standalone-launch";
  overlay.innerHTML =
    '<div class="rpfood-standalone-launch__particles" aria-hidden="true">' +
    particles +
    "</div>" +
    '<div class="rpfood-standalone-launch__backdrop" aria-hidden="true"></div>' +
    '<div class="rpfood-standalone-launch__content" role="status" aria-live="polite" aria-label="Carregando RP Food">' +
    '<div class="rpfood-standalone-launch__card">' +
    '<div class="rpfood-standalone-launch__brand">' +
    '<img class="rpfood-standalone-launch__logo" src="/images/rpfood/logo/mobile500.png" alt="RP Food">' +
    '<div class="rpfood-standalone-launch__brand-copy">' +
    '<strong class="rpfood-standalone-launch__title">Preparando seu pedido</strong>' +
    "</div>" +
    "</div>" +
    '<div class="rpfood-standalone-launch__progress" aria-hidden="true"><span></span></div>' +
    '<span class="rpfood-standalone-launch__subtitle">Carregando catálogo, atendimento e pagamentos...</span>' +
    "</div>" +
    "</div>";

  document.body.appendChild(overlay);

  requestAnimationFrame(() => {
    overlay.classList.add("is-visible");
  });

  const startedAt = Date.now();
  const progressBar = overlay.querySelector<HTMLSpanElement>(".rpfood-standalone-launch__progress span");
  const minimumVisible = firstStandaloneOpen ? 900 : 320;
  let progressFrame = 0;
  let closed = false;

  const updateProgress = () => {
    if (!progressBar || closed) {
      return;
    }

    const elapsed = Date.now() - startedAt;
    const eased = Math.min(0.94, Math.max(0.08, elapsed / minimumVisible));
    progressBar.style.transform = `scaleX(${eased})`;
    progressFrame = window.requestAnimationFrame(updateProgress);
  };

  progressFrame = window.requestAnimationFrame(updateProgress);

  return () => {
    if (closed) return;
    closed = true;

    if (progressFrame) {
      window.cancelAnimationFrame(progressFrame);
    }

    if (progressBar) {
      progressBar.style.transform = "scaleX(1)";
    }

    const remaining = Math.max(minimumVisible - (Date.now() - startedAt), 0);

    window.setTimeout(() => {
      overlay.classList.remove("is-visible");
      window.setTimeout(() => {
        overlay.remove();
        document.body.classList.remove("rpfood-standalone-open");
      }, 220);
    }, remaining);
  };
}

import { lazy, Suspense, useEffect, useMemo, useRef, useState } from "react";
import type { MouseEvent as ReactMouseEvent, PointerEvent as ReactPointerEvent, WheelEvent as ReactWheelEvent } from "react";
import {
  apiConfig,
  buscarEnderecoPorCep,
  confirmarPagamentoPix,
  consultarPagamentoPix,
  criarPedido,
  definirEnderecoPadraoCliente,
  fetchAdminDashboard,
  fetchBairros,
  fetchCatalogo,
  fetchEnderecosCliente,
  fetchFormasPagamento,
  fetchProdutos,
  fetchUltimoPedidoCliente,
  fetchProdutoFracoes,
  fetchPedidosCliente,
  fetchProdutoDetalhe,
  fetchProdutoOpcionais,
  fetchProdutosPorCategoria,
  fetchSobre,
  fetchEnderecoCliente,
  iniciarPagamentoPix,
  esqueciMinhaSenhaCliente,
  loginAdmin,
  loginCliente,
  logoutAdmin,
  repetirPedido,
  salvarCliente,
  salvarEnderecoCliente,
} from "./api";
import { PedidoFinalizarView } from "./PedidoFinalizarView";
import { PedidoItemView } from "./PedidoItemView";
import { PedidoAcompanhamentoView } from "./PedidoAcompanhamentoView";
import { PedidoPagamentoView } from "./PedidoPagamentoView";
import { ClienteLoginView } from "./ClienteLoginView";
import { ClienteCadastroView } from "./ClienteCadastroView";
import { EsqueciMinhaSenhaView } from "./EsqueciMinhaSenhaView";
import { ClienteDadosView } from "./ClienteDadosView";
import { ClienteEnderecoView } from "./ClienteEnderecoView";
import { VendaHistoricoView } from "./VendaHistoricoView";
import { SobreView } from "./SobreView";
import { ProdutosPorCategoriaView } from "./ProdutosPorCategoriaView";
import { ProdutosTodasCategoriasView } from "./ProdutosTodasCategoriasView";
import { BuscarEnderecoView } from "./BuscarEnderecoView";
import { NovoEnderecoView } from "./NovoEnderecoView";
import { Erro404View } from "./Erro404View";
// Telas administrativas em chunk separado: o cliente final nunca as abre e nao
// precisa baixar esse codigo junto com o cardapio.
const AdminLoginView = lazy(() => import("./AdminLoginView").then((m) => ({ default: m.AdminLoginView })));
const AdminDashboardView = lazy(() => import("./AdminDashboardView").then((m) => ({ default: m.AdminDashboardView })));
const AdminIndex2View = lazy(() => import("./AdminIndex2View").then((m) => ({ default: m.AdminIndex2View })));
import { showLegacyConfirm, showLegacyError, showLegacyHtmlConfirm, showLegacyValidation, showLegacyWarning } from "./legacySwal";
import {
  categoryWithoutLimit,
  countSelectedFractions,
  defaultProductSize,
  maxExtraFractions,
  normalizeMaxFractionParts,
  optionPriceBySize,
  productPriceBySize,
  productSupportsSize,
  remapProductSize,
  usesCategoryRule,
} from "./pedidoItemRules";
import { clickableCardProps } from "./clickableCard";
import { RailSlider } from "./RailSlider";
import {
  createHorizontalDragState,
  finishHorizontalDrag,
  shouldStartPointerDrag,
  resolveHorizontalDragIntent,
  type HorizontalDragState,
} from "./createHorizontalDragScrollHandlers";
import { SmartImage } from "./SmartImage";
import { getProgressiveImageProps } from "./imageLoading";
import type {
  AdminDashboard,
  AdminSession,
  Bairro,
  Catalogo,
  Cliente,
  Endereco,
  FormaPagamento,
  Opcional,
  PagamentoPix,
  PedidoPayload,
  PedidoRecuperado,
  Produto,
  ProdutoOpcional,
  SobreLoja,
  VendaAcompanhamento,
  VendaHistorico,
} from "./types";

type CheckoutForm = {
  nome: string;
  email: string;
  telefone: string;
  cep: string;
  endereco: string;
  numero: string;
  complemento: string;
  pontoReferencia: string;
  bairroId: number;
  tipoEntrega: "D" | "R";
  formaPagamentoId: number;
  valorAReceber: string;
  observacao: string;
};

type AddressForm = {
  idEndereco: number;
  cep: string;
  endereco: string;
  numero: string;
  complemento: string;
  pontoReferencia: string;
  bairroId: number;
  bairro: string;
  taxaEntrega: number;
};

type CadastroForm = {
  nome: string;
  celular: string;
  telefone: string;
  cep: string;
  endereco: string;
  numero: string;
  complemento: string;
  pontoReferencia: string;
  bairroId: number;
  bairro: string;
  taxaEntrega: number;
};

type PerfilForm = {
  nome: string;
  email: string;
  senha: string;
  celular: string;
  telefone: string;
};

type Draft = {
  quantidade: number;
  tamanho: string;
  observacao: string;
  opcionais: Record<number, number>;
  fracoes: Record<number, number>;
};

type CartItem = {
  id: string;
  produto: Produto;
  quantidade: number;
  tamanho: string;
  observacao: string;
  opcionais: Array<{ quantidade: number; unitPrice: number; opcional: Opcional }>;
  fracoes: Array<{ quantidade: number; produto: Produto }>;
  valorUnitario: number;
  valorTotal: number;
};

type RepeatPriceChange = {
  description: string;
  sizeLabel: string;
  quantity: number;
  previousUnitPrice: number;
  currentUnitPrice: number;
  previousTotal: number;
  currentTotal: number;
};

type RepeatSizeIssue = {
  description: string;
  previousSize: string;
};

type RepeatFractionIssue = {
  description: string;
  previousParts: number;
};

type PaymentSession = {
  pedido: PedidoPayload;
  pagamento: PagamentoPix;
};

type TableAccess = {
  mesa: string;
};

type AppScreen =
  | "home"
  | "login"
  | "register"
  | "forgot-password"
  | "profile"
  | "addresses"
  | "new-address"
  | "history"
  | "about"
  | "products-all"
  | "products-category"
  | "admin-login"
  | "admin-index"
  | "admin-index2"
  | "not-found";

type InitialRoute =
  | AppScreen
  | "item"
  | "checkout"
  | "checkout-address-selector"
  | "tracking"
  | "payment";

type AuthTarget = "home" | "checkout" | "tracking" | "profile" | "addresses" | "history";

const money = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });
const appVersion = "1.0.0";
const catalogOnlyMode = true;
const catalogOnlyVisibleRoutes = new Set<InitialRoute>([
  "home",
  "about",
  "products-all",
  "products-category",
  "admin-login",
  "admin-index",
  "admin-index2",
  "not-found",
]);
const keys = {
  companyId: "rpmenu.site.companyId",
  cart: "rpmenu.site.cart",
  customer: "rpmenu.site.customer",
  checkout: "rpmenu.site.checkout",
  phone: "rpmenu_telefone",
  adminSession: "rpmenu.site.adminSession",
  tableAccess: "rpmenu.site.tableAccess",
};

function resolveCurrentLegacyRoute(): string {
  if (typeof window === "undefined") return "home";

  const fromHash = window.location.hash.replace(/^#\/?/, "").trim().toLowerCase();
  if (fromHash) {
    return fromHash;
  }

  const segments = window.location.pathname
    .split("/")
    .filter(Boolean)
    .map((segment) => decodeURIComponent(segment));
  const loweredSegments = segments.map((segment) => segment.toLowerCase());
  const dllIndex = loweredSegments.findIndex((segment) => segment === "rpfood.dll" || segment === "rpmenu.dll");
  const relevantSegments = dllIndex >= 0 ? segments.slice(dllIndex + 1) : segments;
  const routeSegments = relevantSegments.length > 0 ? relevantSegments : segments;
  const lastSegment = routeSegments[routeSegments.length - 1]?.trim().toLowerCase() ?? "";
  const previousSegment = routeSegments[routeSegments.length - 2]?.trim().toLowerCase() ?? "";

  if (previousSegment === "admin" && lastSegment) {
    return `admin/${lastSegment}`;
  }

  return lastSegment;
}

function scrollViewportToTop() {
  window.scrollTo({ top: 0, left: 0, behavior: "auto" });
  document.documentElement.scrollTop = 0;
  document.body.scrollTop = 0;
}

function resetViewportToTopOnNextFrame() {
  scrollViewportToTop();
  const frame = window.requestAnimationFrame(() => scrollViewportToTop());
  return () => window.cancelAnimationFrame(frame);
}

function mapInitialRouteToScreen(route: InitialRoute): AppScreen {
  switch (route) {
    case "home":
    case "login":
    case "register":
    case "forgot-password":
    case "profile":
    case "addresses":
    case "new-address":
    case "history":
    case "about":
    case "products-all":
    case "products-category":
    case "admin-login":
    case "admin-index":
    case "admin-index2":
    case "not-found":
      return route;
    default:
      return "home";
  }
}

function resolveInitialScreen(loggedCustomer: boolean): InitialRoute {
  const route = resolveCurrentLegacyRoute();

  switch (route) {
    case "":
    case "index.html":
      return "home";
    case "login.html":
      return "login";
    case "cliente-cadastro.html":
      return "register";
    case "esqueci-minha-senha.html":
      return "forgot-password";
    case "cliente-dados.html":
      return loggedCustomer ? "profile" : "login";
    case "cliente-endereco.html":
      return loggedCustomer ? "addresses" : "login";
    case "novo-endereco.html":
      return loggedCustomer ? "new-address" : "login";
    case "venda-historico":
    case "venda-historico.html":
    case "venda-historico-cliente.html":
      return loggedCustomer ? "history" : "login";
    case "pedido-item.html":
      return "item";
    case "pedido-finalizar.html":
      return "checkout";
    case "cliente.endereco.html":
      return "checkout-address-selector";
    case "pedido-acompanhamento.html":
      return "tracking";
    case "pedido-pagamento.html":
      return "payment";
    case "sobre.html":
      return "about";
    case "produto-por-categoria.html":
      return "products-category";
    case "produtostodascategoria.html":
      return "products-all";
    case "admin/login.html":
      return "admin-login";
    case "admin/index.html":
      return "admin-index";
    case "admin/index2.html":
      return "admin-index2";
    case "erro-404.html":
      return "not-found";
    case "erro-500.html":
      return "not-found";
    default:
      return route.endsWith(".html") ? "not-found" : "home";
  }
}

function resolveVisibleRoute(
  screen: AppScreen,
  hasActiveProduct: boolean,
  hasPaymentSession: boolean,
  hasTrackedOrder: boolean,
  hasCheckoutAddressSelector: boolean,
  hasCheckout: boolean,
): string {
  if (hasActiveProduct) return "pedido-item.html";
  if (hasPaymentSession) return "pedido-pagamento.html";
  if (hasCheckoutAddressSelector) return "cliente.endereco.html";
  if (hasCheckout) return "pedido-finalizar.html";
  if (hasTrackedOrder) return "pedido-acompanhamento.html";

  switch (screen) {
    case "home":
      return "index.html";
    case "login":
      return "login.html";
    case "register":
      return "cliente-cadastro.html";
    case "forgot-password":
      return "esqueci-minha-senha.html";
    case "profile":
      return "cliente-dados.html";
    case "addresses":
      return "cliente-endereco.html";
    case "new-address":
      return "novo-endereco.html";
    case "history":
      return "venda-historico.html";
    case "about":
      return "sobre.html";
    case "products-all":
      return "produtostodascategoria.html";
    case "products-category":
      return "produto-por-categoria.html";
    case "admin-login":
      return "admin/login.html";
    case "admin-index":
      return "admin/index.html";
    case "admin-index2":
      return "admin/index2.html";
    case "not-found":
      return "erro-404.html";
    default:
      return "index.html";
  }
}

function syncLegacyRoute(route: string) {
  if (typeof window === "undefined") return;

  const normalizedRoute = route.replace(/^\/+/, "");
  const currentRoute = resolveCurrentLegacyRoute();
  if (currentRoute === normalizedRoute) {
    return;
  }

  const pathname = window.location.pathname;
  const loweredPath = pathname.toLowerCase();
  const markers = ["/rpmenu.dll/", "/rpfood.dll/"];
  const marker = markers.find((item) => loweredPath.includes(item));
  const markerIndex = marker ? loweredPath.indexOf(marker) : -1;
  const targetPath =
    marker && markerIndex >= 0
      ? `${pathname.slice(0, markerIndex + marker.length)}${normalizedRoute}`
      : `/${normalizedRoute}`;

  window.history.replaceState(window.history.state, "", targetPath);
}

function normalizeSearchText(value: string): string {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
}

function isCustomerNotFoundError(error: Error): boolean {
  const normalizedMessage = normalizeSearchText(error.message || "");
  return (
    normalizedMessage === "not found" ||
    normalizedMessage.includes("not found") ||
    normalizedMessage.includes("nao encontrado") ||
    normalizedMessage.includes("nao localizada") ||
    normalizedMessage.includes("nao localizado") ||
    normalizedMessage.includes("cliente nao") ||
    normalizedMessage.includes("cadastro nao")
  );
}

const emptyDraft = (): Draft => ({
  quantidade: 1,
  tamanho: "",
  observacao: "",
  opcionais: {},
  fracoes: {},
});

const emptyAddressForm = (): AddressForm => ({
  idEndereco: 0,
  cep: "",
  endereco: "",
  numero: "",
  complemento: "",
  pontoReferencia: "",
  bairroId: 0,
  bairro: "",
  taxaEntrega: 0,
});

const emptyCadastroForm = (): CadastroForm => ({
  nome: "",
  celular: "",
  telefone: "",
  cep: "",
  endereco: "",
  numero: "",
  complemento: "",
  pontoReferencia: "",
  bairroId: 0,
  bairro: "",
  taxaEntrega: 0,
});

const emptyPerfilForm = (): PerfilForm => ({
  nome: "",
  email: "",
  senha: "",
  celular: "",
  telefone: "",
});

function loadStored<T>(key: string, fallback: T): T {
  const saved = localStorage.getItem(key);
  if (!saved) return fallback;
  try {
    return JSON.parse(saved) as T;
  } catch {
    return fallback;
  }
}

function roundCurrency(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function resolveTipoEntrega(tipoEntrega: "D" | "R", allowPickup: boolean): "D" | "R" {
  return allowPickup && tipoEntrega === "R" ? "R" : "D";
}

function isPixPayment(payment?: FormaPagamento | null): boolean {
  return Boolean(payment?.pagamentoOnline || payment?.utilizaPix);
}

function fallbackPixEmail(companyId: number, customer?: Cliente | null, phone = ""): string {
  const key = digitsOnly(phone || customer?.celular || customer?.telefone || "") || String(customer?.idCliente || "cliente");
  return `pix-${companyId}-${key}@rpfood.com.br`;
}

function isApprovedPaymentStatus(status: string): boolean {
  const normalized = normalizeSearchText(status);
  return normalized === "approved" || normalized === "aprovado" || normalized === "paid" || normalized === "pago";
}

function wait(ms: number): Promise<void> {
  return new Promise((resolve) => window.setTimeout(resolve, ms));
}

function formatMoney(value: number): string {
  return money.format(roundCurrency(value));
}

function digitsOnly(value: string): string {
  return value.replace(/\D/g, "");
}

function loadSessionStored<T>(key: string, fallback: T): T {
  if (typeof window === "undefined") {
    return fallback;
  }

  const saved = window.sessionStorage.getItem(key);
  if (!saved) {
    return fallback;
  }

  try {
    return JSON.parse(saved) as T;
  } catch {
    return fallback;
  }
}

function persistSessionStored<T>(key: string, value: T | null) {
  if (typeof window === "undefined") {
    return;
  }

  if (value === null) {
    window.sessionStorage.removeItem(key);
    return;
  }

  window.sessionStorage.setItem(key, JSON.stringify(value));
}

function firstUrlParam(params: URLSearchParams, ...names: string[]) {
  for (const name of names) {
    const value = params.get(name);
    if (value?.trim()) {
      return value.trim();
    }
  }

  return "";
}

function extractMesaFromQRCode(value: string) {
  const trimmed = value.trim();
  if (!trimmed) {
    return "";
  }

  try {
    const url = new URL(trimmed, typeof window === "undefined" ? "http://localhost" : window.location.origin);
    const mesa = firstUrlParam(url.searchParams, "mesa", "table", "m");
    if (mesa) {
      return digitsOnly(mesa) || mesa;
    }
  } catch {
    // Entrada manual pode ser somente o numero da mesa.
  }

  const queryMatch = trimmed.match(/(?:^|[?&;])(mesa|table|m)=([^&#;]+)/i);
  if (queryMatch?.[2]) {
    const decoded = decodeURIComponent(queryMatch[2].replace(/\+/g, " ")).trim();
    return digitsOnly(decoded) || decoded;
  }

  return digitsOnly(trimmed);
}

function resolveInitialTableAccess(): TableAccess | null {
  if (typeof window === "undefined") {
    return null;
  }

  const mesaFromUrl = extractMesaFromQRCode(firstUrlParam(new URLSearchParams(window.location.search), "mesa", "table", "m"));
  if (mesaFromUrl) {
    return { mesa: mesaFromUrl };
  }

  return loadSessionStored<TableAccess | null>(keys.tableAccess, null);
}

function isProtectedAdminScreen(screen: AppScreen) {
  return screen === "admin-login" || screen === "admin-index" || screen === "admin-index2";
}

function parseCurrencyInput(value: string): number {
  const normalized = value.trim().replace(/\./g, "").replace(",", ".");
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? roundCurrency(parsed) : 0;
}

function formatCurrencyInput(value: number): string {
  if (value <= 0) return "";
  return roundCurrency(value).toLocaleString("pt-BR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

function formatOrderDate(value: string): string {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  return parsed.toLocaleDateString("pt-BR");
}

function truncateText(value: string, maxLength: number): string {
  const normalized = value.trim();
  if (normalized.length <= maxLength) {
    return normalized;
  }

  return `${normalized.slice(0, maxLength)}...`;
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function reprice(item: CartItem): CartItem {
  const extras = roundCurrency(
    item.opcionais.reduce((sum, option) => roundCurrency(sum + roundCurrency(option.quantidade * option.unitPrice)), 0),
  );

  return {
    ...item,
    valorUnitario: roundCurrency(item.valorUnitario),
    opcionais: item.opcionais.map((option) => ({ ...option, unitPrice: roundCurrency(option.unitPrice) })),
    valorTotal: roundCurrency(roundCurrency(item.valorUnitario + extras) * item.quantidade),
  };
}

function normalizeCartItem(item: CartItem): CartItem {
  return reprice({
    ...item,
    fracoes: item.fracoes ?? [],
    valorUnitario: roundCurrency(item.valorUnitario),
    valorTotal: roundCurrency(item.valorTotal),
    opcionais: item.opcionais.map((option) => ({
      ...option,
      unitPrice: roundCurrency(option.unitPrice),
    })),
  });
}

function App() {
  const [companyId] = useState<number>(() => loadStored<number>(keys.companyId, apiConfig.defaultEmpresaId));
  const [catalog, setCatalog] = useState<Catalogo | null>(null);
  const [payments, setPayments] = useState<FormaPagamento[]>([]);
  const [neighborhoods, setNeighborhoods] = useState<Bairro[]>([]);
  const [selectedCategoryId, setSelectedCategoryId] = useState<number | null>(null);
  const [productsByCategory, setProductsByCategory] = useState<Record<number, Produto[]>>({});
  const [activeProduct, setActiveProduct] = useState<Produto | null>(null);
  const [activeOptions, setActiveOptions] = useState<ProdutoOpcional[]>([]);
  const [activeFractions, setActiveFractions] = useState<Produto[]>([]);
  const optionCatalogRef = useRef<Record<number, Opcional>>({});
  const fractionCatalogRef = useRef<Record<number, Produto>>({});
  const [draft, setDraft] = useState<Draft>(() => emptyDraft());
  // draft.fracoes so enxerga o valor novo no render seguinte. Dois toques no mesmo
  // instante liam a mesma selecao antiga, os dois passavam pela checagem de limite
  // e o item estourava o maximo de sabores. Este ref e atualizado na hora do clique.
  const fracoesRef = useRef<Record<number, number>>(draft.fracoes);
  useEffect(() => {
    fracoesRef.current = draft.fracoes;
  }, [draft.fracoes]);
  const [editingCartItemId, setEditingCartItemId] = useState<string | null>(null);
  const [cart, setCart] = useState<CartItem[]>(() =>
    catalogOnlyMode ? [] : loadStored<CartItem[]>(keys.cart, []).map((item) => normalizeCartItem(item)),
  );
  const [customer, setCustomer] = useState<Cliente | null>(() => loadStored<Cliente | null>(keys.customer, null));
  const initialTableAccessRef = useRef<TableAccess | null>(resolveInitialTableAccess());
  const [tableAccess, setTableAccess] = useState<TableAccess | null>(() => initialTableAccessRef.current);
  const [tableInput, setTableInput] = useState(() => initialTableAccessRef.current?.mesa ?? "");
  const initialRouteRef = useRef<InitialRoute>(resolveInitialScreen(Boolean(customer?.idCliente)));
  const initialRouteHandledRef = useRef(false);
  const initialScreenRef = useRef<AppScreen>(mapInitialRouteToScreen(initialRouteRef.current));
  const [screen, setScreen] = useState<AppScreen>(() =>
    initialScreenRef.current === "login" && initialTableAccessRef.current ? "home" : initialScreenRef.current,
  );
  const [authTarget, setAuthTarget] = useState<AuthTarget>("home");
  const [loginPhone, setLoginPhone] = useState<string>(() => localStorage.getItem(keys.phone) ?? "");
  const [forgotEmail, setForgotEmail] = useState("");
  const [cadastro, setCadastro] = useState<CadastroForm>(() => emptyCadastroForm());
  const [perfil, setPerfil] = useState<PerfilForm>(() => emptyPerfilForm());
  const [addressEditor, setAddressEditor] = useState<AddressForm>(() => emptyAddressForm());
  const [editingAddress, setEditingAddress] = useState(false);
  const [aboutData, setAboutData] = useState<SobreLoja | null>(null);
  const [loadingAbout, setLoadingAbout] = useState(false);
  const [browseMode, setBrowseMode] = useState<"all" | "category">("all");
  const [browseTitle, setBrowseTitle] = useState("Todos os produtos");
  const [browseCategoryId, setBrowseCategoryId] = useState<number | null>(null);
  const [browseFilter, setBrowseFilter] = useState("");
  const [browseProducts, setBrowseProducts] = useState<Produto[]>([]);
  const [loadingBrowseProducts, setLoadingBrowseProducts] = useState(false);
  const [history, setHistory] = useState<VendaHistorico[]>([]);
  const [showCheckout, setShowCheckout] = useState(false);
  const [showCheckoutAddressSelector, setShowCheckoutAddressSelector] = useState(false);
  const [showHistoryPanel, setShowHistoryPanel] = useState(false);
  const [showCartPanel, setShowCartPanel] = useState(false);
  const [cartFeedback, setCartFeedback] = useState<{ id: number; text: string } | null>(null);
  const [trackedOrder, setTrackedOrder] = useState<VendaAcompanhamento | null>(null);
  const [showNewAddressForm, setShowNewAddressForm] = useState(false);
  const [selectedAddressId, setSelectedAddressId] = useState(0);
  const [newAddress, setNewAddress] = useState<AddressForm>(() => emptyAddressForm());
  const [showTrocoModal, setShowTrocoModal] = useState(false);
  const [paymentSession, setPaymentSession] = useState<PaymentSession | null>(null);
  const [checkout, setCheckout] = useState<CheckoutForm>(() =>
    loadStored<CheckoutForm>(keys.checkout, {
      nome: "",
      email: "",
      telefone: "",
      cep: "",
      endereco: "",
      numero: "",
      complemento: "",
      pontoReferencia: "",
      bairroId: 0,
      tipoEntrega: "D",
      formaPagamentoId: 0,
      valorAReceber: "",
      observacao: "",
    }),
  );
  const [loading, setLoading] = useState(true);
  const [loadingProduct, setLoadingProduct] = useState(false);
  const [savingCheckout, setSavingCheckout] = useState(false);
  const [loadingPayment, setLoadingPayment] = useState(false);
  const [loadingTracking, setLoadingTracking] = useState(false);
  const [confirmingPayment, setConfirmingPayment] = useState(false);
  const confirmingPaymentRef = useRef(false);
  const [paymentConfirmationBlocked, setPaymentConfirmationBlocked] = useState(false);
  const [repeatingSaleId, setRepeatingSaleId] = useState<number | null>(null);
  const [savingOrder, setSavingOrder] = useState(false);
  const [adminLogin, setAdminLogin] = useState("1");
  const [adminPassword, setAdminPassword] = useState("");
  const [adminSession, setAdminSession] = useState<AdminSession | null>(() =>
    loadStored<AdminSession | null>(keys.adminSession, null),
  );
  const [adminDashboard, setAdminDashboard] = useState<AdminDashboard | null>(null);
  const [loadingAdmin, setLoadingAdmin] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const trackingStatusRef = useRef<string | null>(null);
  const trackingAudioRef = useRef<HTMLAudioElement | null>(null);
  const featuredRailRef = useRef<HTMLDivElement | null>(null);
  const featuredRailDragState = useRef<HorizontalDragState>(createHorizontalDragState());
  const categoriesRailRef = useRef<HTMLDivElement | null>(null);
  const categoriesRailDragState = useRef<HorizontalDragState>(createHorizontalDragState());

  const handleHorizontalRailWheel = (event: ReactWheelEvent<HTMLDivElement>) => {
    const el = event.currentTarget;
    const maxScrollLeft = el.scrollWidth - el.clientWidth;
    if (maxScrollLeft <= 0) {
      return;
    }

    let horizontalDelta = 0;
    if (Math.abs(event.deltaX) > 0) {
      horizontalDelta = event.deltaX;
    } else if (event.shiftKey && Math.abs(event.deltaY) > 0) {
      horizontalDelta = event.deltaY;
    }

    if (Math.abs(horizontalDelta) < 1) {
      return;
    }

    const nextScrollLeft = Math.max(0, Math.min(maxScrollLeft, el.scrollLeft + horizontalDelta));
    if (nextScrollLeft === el.scrollLeft) {
      return;
    }

    el.scrollLeft = nextScrollLeft;
    event.preventDefault();
  };

  const featuredRailPointerDown = (event: ReactPointerEvent<HTMLDivElement>) => {
    if (!shouldStartPointerDrag(event.pointerType, event.button)) {
      return;
    }

    const el = featuredRailRef.current ?? event.currentTarget;
    featuredRailDragState.current.active = true;
    featuredRailDragState.current.moved = false;
    featuredRailDragState.current.suppressClicksUntil = 0;
    featuredRailDragState.current.pointerId = event.pointerId;
    featuredRailDragState.current.startX = event.clientX;
    featuredRailDragState.current.startY = event.clientY;
    featuredRailDragState.current.startScrollLeft = el.scrollLeft;
  };

  const featuredRailPointerMove = (event: ReactPointerEvent<HTMLDivElement>) => {
    const state = featuredRailDragState.current;
    if (!state.active) {
      return;
    }

    const el = featuredRailRef.current ?? event.currentTarget;
    const deltaX = event.clientX - state.startX;
    const deltaY = event.clientY - state.startY;

    if (!state.moved) {
      const intent = resolveHorizontalDragIntent(deltaX, deltaY);

      if (intent === "vertical") {
        state.active = false;
        state.pointerId = null;
        return;
      }

      if (intent === "none") {
        return;
      }

      if ("setPointerCapture" in el && state.pointerId !== null) {
        try {
          el.setPointerCapture(state.pointerId);
        } catch {
          // Ignore capture failures and keep the fallback drag working.
        }
      }

      state.moved = true;
    }

    el.scrollLeft = state.startScrollLeft - deltaX;
    event.preventDefault();
  };

  const featuredRailPointerUp = (event: ReactPointerEvent<HTMLDivElement>) => {
    finishHorizontalDrag(featuredRailRef.current ?? event.currentTarget, featuredRailDragState.current);
  };

  const featuredRailPointerCancel = (event: ReactPointerEvent<HTMLDivElement>) => {
    finishHorizontalDrag(featuredRailRef.current ?? event.currentTarget, featuredRailDragState.current);
  };

  const featuredRailClickCapture = (event: ReactMouseEvent<HTMLDivElement>) => {
    if (Date.now() < featuredRailDragState.current.suppressClicksUntil) {
      event.preventDefault();
      event.stopPropagation();
    }
  };

  const categoriesRailPointerDown = (event: ReactPointerEvent<HTMLDivElement>) => {
    if (!shouldStartPointerDrag(event.pointerType, event.button)) {
      return;
    }

    const el = categoriesRailRef.current ?? event.currentTarget;
    categoriesRailDragState.current.active = true;
    categoriesRailDragState.current.moved = false;
    categoriesRailDragState.current.suppressClicksUntil = 0;
    categoriesRailDragState.current.pointerId = event.pointerId;
    categoriesRailDragState.current.startX = event.clientX;
    categoriesRailDragState.current.startY = event.clientY;
    categoriesRailDragState.current.startScrollLeft = el.scrollLeft;
  };

  const categoriesRailPointerMove = (event: ReactPointerEvent<HTMLDivElement>) => {
    const state = categoriesRailDragState.current;
    if (!state.active) {
      return;
    }

    const el = categoriesRailRef.current ?? event.currentTarget;
    const deltaX = event.clientX - state.startX;
    const deltaY = event.clientY - state.startY;

    if (!state.moved) {
      const intent = resolveHorizontalDragIntent(deltaX, deltaY);

      if (intent === "vertical") {
        state.active = false;
        state.pointerId = null;
        return;
      }

      if (intent === "none") {
        return;
      }

      if ("setPointerCapture" in el && state.pointerId !== null) {
        try {
          el.setPointerCapture(state.pointerId);
        } catch {
          // Ignore capture failures and keep the fallback drag working.
        }
      }

      state.moved = true;
    }

    el.scrollLeft = state.startScrollLeft - deltaX;
    event.preventDefault();
  };

  const categoriesRailPointerUp = (event: ReactPointerEvent<HTMLDivElement>) => {
    finishHorizontalDrag(categoriesRailRef.current ?? event.currentTarget, categoriesRailDragState.current);
  };

  const categoriesRailPointerCancel = (event: ReactPointerEvent<HTMLDivElement>) => {
    finishHorizontalDrag(categoriesRailRef.current ?? event.currentTarget, categoriesRailDragState.current);
  };

  const categoriesRailClickCapture = (event: ReactMouseEvent<HTMLDivElement>) => {
    if (Date.now() < categoriesRailDragState.current.suppressClicksUntil) {
      event.preventDefault();
      event.stopPropagation();
    }
  };

  async function showRequiredFieldAlert(messageText: string, fieldId?: string, title = "Quase lá") {
    setError("");
    await showLegacyValidation(title, messageText);

    if (!fieldId || typeof document === "undefined") {
      return;
    }

    window.setTimeout(() => {
      const field = document.getElementById(fieldId) as HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement | null;
      if (!field) {
        return;
      }

      field.scrollIntoView({ behavior: "smooth", block: "center" });
      field.focus();
    }, 120);
  }

  useEffect(() => localStorage.setItem(keys.companyId, JSON.stringify(companyId)), [companyId]);
  useEffect(() => {
    if (catalogOnlyMode) {
      localStorage.removeItem(keys.cart);
      if (cart.length) {
        setCart([]);
      }
      return;
    }

    localStorage.setItem(keys.cart, JSON.stringify(cart));
  }, [cart]);
  useEffect(() => localStorage.setItem(keys.customer, JSON.stringify(customer)), [customer]);
  useEffect(() => localStorage.setItem(keys.checkout, JSON.stringify(checkout)), [checkout]);
  useEffect(() => {
    localStorage.removeItem("rpmenu.site.adminAuth");
  }, []);
  useEffect(() => {
    if (adminSession) {
      localStorage.setItem(keys.adminSession, JSON.stringify(adminSession));
    } else {
      localStorage.removeItem(keys.adminSession);
    }
  }, [adminSession]);
  useEffect(() => persistSessionStored(keys.tableAccess, tableAccess), [tableAccess]);
  useEffect(() => {
    if (customer?.celular || customer?.telefone) {
      setLoginPhone(customer.celular || customer.telefone);
    }
  }, [customer?.celular, customer?.telefone]);

  useEffect(() => {
    let cancelled = false;
    async function loadStore() {
      setLoading(true);
      try {
        const [catalogData, paymentData, neighborhoodData] = await Promise.all([
          fetchCatalogo(companyId),
          fetchFormasPagamento(companyId),
          fetchBairros(companyId),
        ]);
        if (cancelled) return;
        setCatalog(catalogData);
        setPayments(paymentData);
        setNeighborhoods(neighborhoodData);
        setSelectedCategoryId(null);
        const storeAllowsPickup = catalogData.configuracao.permiteRetiradaNoLocal === true;
        setCheckout((current) => ({
          ...current,
          tipoEntrega: resolveTipoEntrega(current.tipoEntrega, storeAllowsPickup),
          formaPagamentoId: current.formaPagamentoId || paymentData[0]?.id || 0,
        }));
      } catch (loadError) {
        if (!cancelled) setError(loadError instanceof Error ? loadError.message : "Erro ao carregar a loja.");
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    void loadStore();
    return () => {
      cancelled = true;
    };
  }, [companyId]);

  useEffect(() => {
    if (aboutData) {
      return;
    }

    let cancelled = false;

    async function loadAboutPreview() {
      try {
        const data = await fetchSobre(companyId);
        if (!cancelled) {
          setAboutData(data);
        }
      } catch {
        // Keep home resilient even if "sobre" fails.
      }
    }

    void loadAboutPreview();
    return () => {
      cancelled = true;
    };
  }, [aboutData, companyId]);

  useEffect(() => {
    if (catalog?.configuracao.permiteRetiradaNoLocal !== false || checkout.tipoEntrega !== "R") {
      return;
    }

    setCheckout((current) => ({
      ...current,
      tipoEntrega: "D",
    }));
  }, [catalog?.configuracao.permiteRetiradaNoLocal, checkout.tipoEntrega]);

  useEffect(() => {
    const categoryId = selectedCategoryId;
    if (!categoryId || productsByCategory[categoryId]) return;
    const safeCategoryId: number = categoryId;
    let cancelled = false;
    async function loadProducts() {
      try {
        const items = await fetchProdutosPorCategoria(companyId, safeCategoryId);
        if (!cancelled) setProductsByCategory((current) => ({ ...current, [safeCategoryId]: items }));
      } catch (loadError) {
        if (!cancelled) setError(loadError instanceof Error ? loadError.message : "Erro ao carregar produtos.");
      }
    }
    void loadProducts();
    return () => {
      cancelled = true;
    };
  }, [companyId, productsByCategory, selectedCategoryId]);

  useEffect(() => {
    const categoryIds = catalog?.categorias.map((category) => category.codigo) ?? [];
    if (!categoryIds.length) {
      return;
    }

    const allCategoriesLoaded = categoryIds.every((categoryId) => categoryId in productsByCategory);
    if (allCategoriesLoaded) {
      return;
    }

    let cancelled = false;

    async function preloadCategoryProducts() {
      try {
        const items = await fetchProdutos(companyId);
        if (cancelled) {
          return;
        }

        const groupedItems = categoryIds.reduce<Record<number, Produto[]>>((accumulator, categoryId) => {
          accumulator[categoryId] = [];
          return accumulator;
        }, {});

        items.forEach((item) => {
          if (item.idGrupo in groupedItems) {
            groupedItems[item.idGrupo].push(item);
          }
        });

        setProductsByCategory((current) => {
          const nextState = { ...current };
          categoryIds.forEach((categoryId) => {
            if (!(categoryId in nextState)) {
              nextState[categoryId] = groupedItems[categoryId] ?? [];
            }
          });
          return nextState;
        });
      } catch {
        // The per-category loader still works if this background preload fails.
      }
    }

    void preloadCategoryProducts();

    return () => {
      cancelled = true;
    };
  }, [catalog, companyId, productsByCategory]);

  useEffect(() => {
    const customerId = customer?.idCliente;
    if (!customerId) {
      setHistory([]);
      setShowHistoryPanel(false);
      setTrackedOrder(null);
      return;
    }
    const safeCustomerId: number = customerId;
    let cancelled = false;
    async function loadHistory() {
      try {
        const orders = await fetchPedidosCliente(companyId, safeCustomerId);
        if (!cancelled) setHistory(orders);
      } catch {
        if (!cancelled) setHistory([]);
      }
    }
    void loadHistory();
    return () => {
      cancelled = true;
    };
  }, [companyId, customer?.idCliente]);

  useEffect(() => {
    if (!customer || !history.length) {
      setShowHistoryPanel(false);
    }
  }, [customer, history.length]);

  useEffect(() => {
    if (loading || initialRouteHandledRef.current) {
      return;
    }

    const initialRoute = initialRouteRef.current;
    initialRouteHandledRef.current = true;

    if (catalogOnlyMode && !catalogOnlyVisibleRoutes.has(initialRoute)) {
      openHomeScreen();
      return;
    }

    switch (initialRoute) {
      case "login":
        if (tableAccess) {
          openHomeScreen();
        }
        return;
      case "about":
        void openAboutScreen();
        return;
      case "products-all":
        openProductsScreen();
        return;
      case "products-category":
        if (catalog?.categorias.length) {
          openCategoryProductsScreen(catalog.categorias[0].codigo);
        } else {
          openProductsScreen();
        }
        return;
      case "profile":
        if (customer?.idCliente) {
          openProfileScreen(customer);
        } else {
          openLogin("profile");
        }
        return;
      case "addresses":
        if (customer?.idCliente) {
          void openAddressesScreen(customer);
        } else {
          openLogin("addresses");
        }
        return;
      case "new-address":
        if (customer?.idCliente) {
          startNewAddressEditor();
        } else {
          openLogin("addresses");
        }
        return;
      case "history":
        if (customer?.idCliente) {
          openHistoryScreen();
        } else {
          openLogin("history");
        }
        return;
      case "item":
        if (cart.length > 0) {
          editCartItem(cart[0]);
        } else {
          openHomeScreen();
        }
        return;
      case "checkout":
        if (customer?.idCliente) {
          openCheckout(customer);
        } else {
          openLogin("checkout");
        }
        return;
      case "checkout-address-selector":
        if (customer?.idCliente) {
          openCheckout(customer);
          setShowCheckoutAddressSelector(true);
        } else {
          openLogin("checkout");
        }
        return;
      case "tracking":
        if (customer?.idCliente) {
          void openOrderTracking(customer).catch((trackingError) => {
            setError(trackingError instanceof Error ? trackingError.message : "Erro ao abrir acompanhamento.");
          });
        } else {
          openLogin("tracking");
        }
        return;
      case "payment":
        if (paymentSession) {
          return;
        }

        if (customer?.idCliente && cart.length > 0) {
          openCheckout(customer);
          setError("Fluxo de pagamento precisa ser iniciado novamente.");
        } else {
          openLogin("checkout");
        }
        return;
      case "admin-login":
        setScreen("admin-login");
        setError("");
        return;
      case "admin-index":
        setScreen("admin-index");
        setError("");
        return;
      case "admin-index2":
        setScreen("admin-index2");
        setError("");
        return;
      default:
        return;
    }
  // Rota inicial deve ser consumida uma unica vez, depois que catalogo/cliente
  // estiverem disponiveis, sem reexecutar ao recriar handlers de navegacao.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [cart, catalog, customer, loading, paymentSession, tableAccess]);

  useEffect(() => {
    document.body.classList.toggle("rpfood-item-open", Boolean(activeProduct));
    return () => {
      document.body.classList.remove("rpfood-item-open");
    };
  }, [activeProduct]);

  useEffect(() => {
    if (!activeProduct) {
      return;
    }

    return resetViewportToTopOnNextFrame();
  }, [activeProduct]);

  useEffect(() => {
    document.body.classList.toggle("rpfood-checkout-open", showCheckout);
    return () => {
      document.body.classList.remove("rpfood-checkout-open");
    };
  }, [showCheckout]);

  useEffect(() => {
    if (screen !== "products-all" && screen !== "products-category") {
      return;
    }

    let cancelled = false;
    // Sem debounce cada tecla digitada na busca virava uma chamada a API, e as
    // respostas podiam chegar fora de ordem. Troca de categoria/tela nao espera.
    const delay = browseFilter.trim() ? 350 : 0;

    async function loadBrowseProducts() {
      setLoadingBrowseProducts(true);
      try {
        // Com termo digitado a busca vira global: quem procura "pepperoni" dentro de
        // HAMBURGUER espera achar a pizza, e nao uma tela vazia. Sem termo, a
        // categoria selecionada continua mandando na listagem.
        const searching = browseFilter.trim().length > 0;
        const products =
          !searching && browseMode === "category" && browseCategoryId
            ? await fetchProdutosPorCategoria(companyId, browseCategoryId, browseFilter)
            : await fetchProdutos(companyId, browseFilter);

        if (!cancelled) {
          setBrowseProducts(products);
        }
      } catch (browseError) {
        if (!cancelled) {
          setError(browseError instanceof Error ? browseError.message : "Erro ao carregar produtos.");
          setBrowseProducts([]);
        }
      } finally {
        if (!cancelled) {
          setLoadingBrowseProducts(false);
        }
      }
    }

    const timer = window.setTimeout(() => void loadBrowseProducts(), delay);

    return () => {
      cancelled = true;
      window.clearTimeout(timer);
    };
  }, [browseCategoryId, browseFilter, browseMode, companyId, screen]);

  useEffect(() => {
    const adminToken = adminSession?.token ?? "";
    if ((screen !== "admin-index" && screen !== "admin-index2") || !adminToken) {
      return;
    }

    let cancelled = false;

    async function loadAdminDashboard() {
      setLoadingAdmin(true);
      try {
        const dashboard = await fetchAdminDashboard(companyId, adminToken);
        if (!cancelled) {
          setAdminDashboard(dashboard);
          setError("");
        }
      } catch (adminError) {
        if (!cancelled) {
          setAdminSession(null);
          setAdminDashboard(null);
          setError(adminError instanceof Error ? adminError.message : "Erro ao carregar painel administrativo.");
        }
      } finally {
        if (!cancelled) {
          setLoadingAdmin(false);
        }
      }
    }

    void loadAdminDashboard();

    return () => {
      cancelled = true;
    };
  }, [adminSession?.token, companyId, screen]);

  useEffect(() => {
    if (!trackedOrder) {
      trackingStatusRef.current = null;
      return;
    }

    if ("Notification" in window && Notification.permission === "default") {
      void Notification.requestPermission();
    }
  }, [trackedOrder]);

  useEffect(() => {
    if (!trackedOrder || !trackedOrder.listaStatus.length) {
      return;
    }

    const latestStatus = trackedOrder.listaStatus[trackedOrder.listaStatus.length - 1];
    const currentStatus = latestStatus.situacao || trackedOrder.situacaoDescription;
    if (!currentStatus) {
      return;
    }

    if (trackingStatusRef.current === null) {
      trackingStatusRef.current = currentStatus;
      return;
    }

    if (trackingStatusRef.current === currentStatus) {
      return;
    }

    trackingStatusRef.current = currentStatus;
    const description = latestStatus.situacaoDescricao || trackedOrder.situacaoDescription || "Pedido atualizado";

    try {
      if (!trackingAudioRef.current) {
        trackingAudioRef.current = new Audio("/vendor/dotted-map/sounds/bong.mp3");
      }
      trackingAudioRef.current.currentTime = 0;
      void trackingAudioRef.current.play();
    } catch {
      // Ignore browser audio restrictions.
    }

    if ("Notification" in window && Notification.permission === "granted") {
      try {
        const notification = new Notification("RPMENU - Pedido Atualizado", {
          body: description,
          icon: "/images/rpfood/logo/mobile500.png",
          tag: "rpfood-status-pedido",
        });
        window.setTimeout(() => notification.close(), 8000);
      } catch {
        // Ignore notification failures and keep the in-app feedback.
      }
    }

    setMessage(`Status do pedido atualizado: ${description}.`);
  }, [trackedOrder]);

  useEffect(() => {
    if (!trackedOrder || !customer?.idCliente) {
      return;
    }

    let cancelled = false;
    const timer = window.setTimeout(async () => {
      setLoadingTracking(true);
      try {
        const latestOrder = await fetchUltimoPedidoCliente(companyId, customer.idCliente);
        if (!cancelled && latestOrder) {
          setTrackedOrder(latestOrder);
        }
      } catch (trackingError) {
        if (!cancelled) {
          setError(trackingError instanceof Error ? trackingError.message : "Erro ao atualizar acompanhamento.");
        }
      } finally {
        if (!cancelled) {
          setLoadingTracking(false);
        }
      }
    }, 15000);

    return () => {
      cancelled = true;
      window.clearTimeout(timer);
    };
  }, [companyId, customer?.idCliente, trackedOrder]);

  useEffect(() => {
    syncLegacyRoute(
      resolveVisibleRoute(
        screen,
        Boolean(activeProduct),
        Boolean(paymentSession),
        Boolean(trackedOrder),
        showCheckoutAddressSelector,
        showCheckout,
      ),
    );
  }, [activeProduct, paymentSession, screen, showCheckout, showCheckoutAddressSelector, trackedOrder]);

  useEffect(() => {
    if (!paymentSession || confirmingPaymentRef.current || paymentConfirmationBlocked) {
      return;
    }

    const currentPaymentSession = paymentSession;
    if (isApprovedPaymentStatus(currentPaymentSession.pagamento.status)) {
      let cancelled = false;

      async function confirmPayment() {
        confirmingPaymentRef.current = true;
        setConfirmingPayment(true);
        setMessage("");
        setError("");

        async function openApprovedTracking(response?: { idVenda?: number }) {
          setCart([]);
          resetCheckoutAfterOrder(currentPaymentSession.pedido.cliente);
          await openOrderTracking(currentPaymentSession.pedido.cliente, { attempts: 5, delayMs: 1000 });
          if (!cancelled) {
            setMessage(
              response?.idVenda
                ? `Pedido #${response.idVenda} criado com sucesso.`
                : "Pagamento aprovado. Acompanhe seu pedido.",
            );
          }
        }

        try {
          const response = await confirmarPagamentoPix(companyId, {
            pedido: currentPaymentSession.pedido,
            idPix: currentPaymentSession.pagamento.idPix,
            qrCodeUrl: currentPaymentSession.pagamento.qrCodeUrl,
            statusPagamento: currentPaymentSession.pagamento.status,
            valorPagamento: currentPaymentSession.pagamento.valorTotal,
          });
          if (cancelled) return;
          await openApprovedTracking(response);
        } catch (confirmError) {
          if (cancelled) return;

          const confirmMessage = confirmError instanceof Error ? confirmError.message : "Erro ao confirmar pagamento.";
          try {
            await openApprovedTracking();
          } catch {
            if (cancelled) return;
            setPaymentConfirmationBlocked(true);
            setError(confirmMessage);
          }
        } finally {
          confirmingPaymentRef.current = false;
          setConfirmingPayment(false);
        }
      }

      void confirmPayment();
      return () => {
        cancelled = true;
      };
    }

    let cancelled = false;
    const timer = window.setTimeout(async () => {
      setLoadingPayment(true);
      try {
        const status = await consultarPagamentoPix(companyId, {
          clienteNome: currentPaymentSession.pedido.cliente.nome,
          clienteEmail: currentPaymentSession.pedido.cliente.email,
          idPix: currentPaymentSession.pagamento.idPix,
          valorPedido: currentPaymentSession.pagamento.valorTotal,
        });
        if (!cancelled) {
          setPaymentSession((current) =>
            current
              ? {
                  ...current,
                  pagamento: {
                    ...current.pagamento,
                    status: status.status || current.pagamento.status,
                  },
                }
              : current,
          );
        }
      } catch (paymentError) {
        if (!cancelled) {
          setError(paymentError instanceof Error ? paymentError.message : "Erro ao consultar pagamento.");
        }
      } finally {
        if (!cancelled) {
          setLoadingPayment(false);
        }
      }
    }, 5000);

    return () => {
      cancelled = true;
      window.clearTimeout(timer);
    };
  // Polling do Pix depende do snapshot da sessao; handlers internos nao devem
  // reiniciar a consulta enquanto o status do pagamento esta sendo aguardado.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [companyId, paymentConfirmationBlocked, paymentSession]);

  useEffect(() => {
    if (!cartFeedback) {
      return;
    }

    const timer = window.setTimeout(() => setCartFeedback(null), 2600);
    return () => window.clearTimeout(timer);
  }, [cartFeedback]);

  const selectedPayment = payments.find((item) => item.id === checkout.formaPagamentoId) ?? payments[0];
  const selectedNeighborhood =
    neighborhoods.find((item) => item.idBairro === checkout.bairroId) ?? null;
  const allowPickup = catalog?.configuracao.permiteRetiradaNoLocal ?? false;
  const tipoEntregaPedido = resolveTipoEntrega(checkout.tipoEntrega, allowPickup);
  const deliveryFee = tipoEntregaPedido === "D" ? roundCurrency(selectedNeighborhood?.taxa ?? 0) : 0;
  const total = roundCurrency(cart.reduce((sum, item) => roundCurrency(sum + item.valorTotal), 0) + deliveryFee);
  const cartItemsCount = cart.reduce((sum, item) => sum + item.quantidade, 0);
  // Memoizado porque e passado para a listagem: recriar o objeto a cada render
  // invalidaria o memo dos cards de produto.
  const cartQuantityByProduct = useMemo(
    () =>
      cart.reduce<Record<number, number>>((result, item) => {
        result[item.produto.codigo] = (result[item.produto.codigo] ?? 0) + item.quantidade;
        return result;
      }, {}),
    [cart],
  );
  const hasRepeatBanner = Boolean(customer && history.length);
  const selectedAddress =
    customer?.enderecos.find((item) => item.idEndereco === selectedAddressId) ??
    customer?.enderecos.find((item) => item.enderecoPadrao) ??
    customer?.enderecos[0] ??
    null;
  const valorAReceber = parseCurrencyInput(checkout.valorAReceber);
  const valorPago = selectedPayment?.permiteTroco && valorAReceber > 0 ? roundCurrency(valorAReceber) : total;
  const valorTroco = valorAReceber > total ? roundCurrency(valorAReceber - total) : 0;
  const pedidoMinimo = catalog?.configuracao.pedidoMinimo ?? 0;
  const maxFractionParts = normalizeMaxFractionParts(catalog?.empresa.quantidadeMaximaFracaoProdutos);
  const maxExtraFlavors = maxExtraFractions(maxFractionParts);
  const subtotalSemEntrega = total - deliveryFee;
  const allHomeProducts = useMemo(
    () => Array.from(new Map(Object.values(productsByCategory).flat().map((item) => [item.codigo, item])).values()),
    [productsByCategory],
  );
  const featuredProducts = catalog?.destaques?.length ? catalog.destaques : allHomeProducts.slice(0, 20);
  const loggedCustomer = Boolean(customer?.idCliente);
  const adminQtdeVendas = adminDashboard?.qtdeVendas ?? "0";
  const adminValorVendas = adminDashboard?.valorVendas ?? "0,00";
  const adminTaxaEntrega = adminDashboard?.taxaEntrega ?? "0,00";
  const adminSincronizacao = adminDashboard?.sincronizacao ?? "";
  const adminTopBairros = adminDashboard?.topBairros ?? [];
  const adminTopClientes = adminDashboard?.topClientes ?? [];
  const adminTopProdutos = adminDashboard?.topProdutos ?? [];

  function shouldUseIntegratedPix(payment?: FormaPagamento | null): boolean {
    return Boolean((catalog?.configuracao.integracaoMercadoPago ?? false) && isPixPayment(payment));
  }

  function defaultPaymentId(): number {
    return payments[0]?.id ?? 0;
  }

  function defaultCustomerAddress(cliente?: Cliente | null): Endereco | null {
    if (!cliente) return null;
    return cliente.enderecos.find((item) => item.enderecoPadrao) ?? cliente.enderecos[0] ?? null;
  }

  function updateCheckout<K extends keyof CheckoutForm>(field: K, value: CheckoutForm[K]) {
    setCheckout((current) => ({ ...current, [field]: value }));
  }

  function updateNewAddress<K extends keyof AddressForm>(field: K, value: AddressForm[K]) {
    setNewAddress((current) => {
      const next = { ...current, [field]: value };
      if (field === "bairroId") {
        const bairro = neighborhoods.find((item) => item.idBairro === Number(value));
        next.bairro = bairro?.descricao ?? "";
        next.taxaEntrega = bairro?.taxa ?? 0;
      }
      return next;
    });
  }

  function updateCadastro<K extends keyof CadastroForm>(field: K, value: CadastroForm[K]) {
    setCadastro((current) => {
      const next = { ...current, [field]: value };
      if (field === "bairroId") {
        const bairro = neighborhoods.find((item) => item.idBairro === Number(value));
        next.bairro = bairro?.descricao ?? "";
        next.taxaEntrega = bairro?.taxa ?? 0;
      }
      return next;
    });
  }

  function updatePerfil<K extends keyof PerfilForm>(field: K, value: PerfilForm[K]) {
    setPerfil((current) => ({ ...current, [field]: value }));
  }

  function updateAddressEditor<K extends keyof AddressForm>(field: K, value: AddressForm[K]) {
    setAddressEditor((current) => {
      const next = { ...current, [field]: value };
      if (field === "bairroId") {
        const bairro = neighborhoods.find((item) => item.idBairro === Number(value));
        next.bairro = bairro?.descricao ?? "";
        next.taxaEntrega = bairro?.taxa ?? 0;
      }
      return next;
    });
  }

  function syncCustomer(cliente: Cliente) {
    setCustomer(cliente);
    setLoginPhone(cliente.celular || cliente.telefone);
    const address = defaultCustomerAddress(cliente);
    setSelectedAddressId(address?.idEndereco ?? 0);
    setCheckout((current) => ({
      ...current,
      nome: cliente.nome,
      email: cliente.email,
      telefone: cliente.celular || cliente.telefone,
      cep: address?.cep ?? current.cep,
      endereco: address?.endereco ?? current.endereco,
      numero: address?.numero ?? current.numero,
      complemento: address?.complemento ?? current.complemento,
      pontoReferencia: address?.pontoReferencia ?? current.pontoReferencia,
      bairroId: address?.idBairro ?? current.bairroId,
    }));
  }

  function resetCheckoutAfterOrder(cliente?: Cliente | null) {
    const nextCustomer = cliente ?? customer;
    const address = defaultCustomerAddress(nextCustomer);

    if (nextCustomer) {
      setCustomer(nextCustomer);
    }

    clearTrackedOrderState();
    setSelectedAddressId(address?.idEndereco ?? 0);
    setPaymentSession(null);
    setPaymentConfirmationBlocked(false);
    setShowCheckout(false);
    setShowCheckoutAddressSelector(false);
    setShowNewAddressForm(false);
    setShowTrocoModal(false);
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setNewAddress(emptyAddressForm());
    setCheckout((current) => ({
      ...current,
      nome: nextCustomer?.nome ?? current.nome,
      email: nextCustomer?.email ?? current.email,
      telefone: nextCustomer ? nextCustomer.celular || nextCustomer.telefone : current.telefone,
      cep: address?.cep ?? "",
      endereco: address?.endereco ?? "",
      numero: address?.numero ?? "",
      complemento: address?.complemento ?? "",
      pontoReferencia: address?.pontoReferencia ?? "",
      bairroId: address?.idBairro ?? 0,
      tipoEntrega: "D",
      formaPagamentoId: defaultPaymentId() || current.formaPagamentoId,
      valorAReceber: "",
      observacao: "",
    }));
  }

  function clearTransientNavigationState() {
    setActiveProduct(null);
    setActiveOptions([]);
    setActiveFractions([]);
    optionCatalogRef.current = {};
    fractionCatalogRef.current = {};
    setDraft(emptyDraft());
    setEditingCartItemId(null);
    setPaymentSession(null);
    setPaymentConfirmationBlocked(false);
    setTrackedOrder(null);
    trackingStatusRef.current = null;
    setShowCheckout(false);
    setShowCheckoutAddressSelector(false);
    setShowNewAddressForm(false);
    setShowTrocoModal(false);
  }

  function rememberPhone(phone: string) {
    localStorage.setItem(keys.phone, digitsOnly(phone));
  }

  function hydrateProfileForm(cliente: Cliente) {
    setPerfil({
      nome: cliente.nome,
      email: cliente.email,
      senha: cliente.senha,
      celular: cliente.celular,
      telefone: cliente.telefone,
    });
  }

  function hydrateCadastroFromLookup(address: Endereco) {
    setCadastro((current) => ({
      ...current,
      cep: address.cep || current.cep,
      endereco: address.endereco,
      bairroId: address.idBairro,
      bairro: address.bairro,
      taxaEntrega: address.taxaEntrega || address.taxa || current.taxaEntrega,
    }));
  }

  function hydrateAddressEditor(address: Endereco) {
    setAddressEditor({
      idEndereco: address.idEndereco,
      cep: address.cep,
      endereco: address.endereco,
      numero: address.numero,
      complemento: address.complemento,
      pontoReferencia: address.pontoReferencia,
      bairroId: address.idBairro,
      bairro: address.bairro,
      taxaEntrega: address.taxaEntrega || address.taxa,
    });
  }

  function openLogin(target: AuthTarget = "home") {
    clearTransientNavigationState();
    setAuthTarget(target);
    setLoginPhone(customer?.celular || customer?.telefone || localStorage.getItem(keys.phone) || "");
    setScreen("login");
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setError("");
    setMessage("");
  }

  function openForgotPasswordScreen() {
    clearTransientNavigationState();
    setForgotEmail(customer?.email ?? "");
    setScreen("forgot-password");
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setError("");
    setMessage("");
  }

  function openHomeScreen() {
    clearTransientNavigationState();
    setSelectedCategoryId(null);
    setScreen("home");
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setError("");
    setMessage("");
  }

  async function handleTableAccessSubmit() {
    const mesa = extractMesaFromQRCode(tableInput);
    if (!mesa || Number(mesa) <= 0) {
      await showLegacyValidation("Mesa nao identificada", "Leia o QR Code da mesa ou informe o numero da mesa.");
      return;
    }

    setTableAccess({ mesa });
    setTableInput(mesa);
    setScreen("home");
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setError("");
    setMessage("");
  }

  function openAdminLoginScreen() {
    clearTransientNavigationState();
    setScreen("admin-login");
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setError("");
    setMessage("");
  }

  function openAdminDashboard(screenTarget: "admin-index" | "admin-index2" = "admin-index") {
    clearTransientNavigationState();
    setScreen(screenTarget);
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setError("");
    setMessage("");
  }

  function openProfileScreen(cliente?: Cliente | null) {
    const targetCustomer = cliente ?? customer;
    if (!targetCustomer?.idCliente) {
      openLogin("profile");
      return;
    }

    clearTransientNavigationState();
    hydrateProfileForm(targetCustomer);
    setScreen("profile");
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setError("");
    setMessage("");
  }

  async function openAddressesScreen(cliente?: Cliente | null) {
    const targetCustomer = cliente ?? customer;
    if (!targetCustomer?.idCliente) {
      openLogin("addresses");
      return;
    }

    clearTransientNavigationState();
    setEditingAddress(false);
    setAddressEditor(emptyAddressForm());
    setScreen("addresses");
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setError("");
    setMessage("");
    setSavingCheckout(true);
    try {
      const enderecos = await fetchEnderecosCliente(companyId, targetCustomer.idCliente);
      const updatedCustomer = { ...targetCustomer, enderecos };
      syncCustomer(updatedCustomer);
    } catch (addressError) {
      setError(addressError instanceof Error ? addressError.message : "Erro ao carregar enderecos.");
    } finally {
      setSavingCheckout(false);
    }
  }

  function openHistoryScreen() {
    if (!customer?.idCliente) {
      openLogin("history");
      return;
    }

    clearTransientNavigationState();
    setScreen("history");
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setError("");
    setMessage("");
  }

  async function openAboutScreen() {
    clearTransientNavigationState();
    setScreen("about");
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setError("");

    if (aboutData) {
      return;
    }

    setLoadingAbout(true);
    try {
      const data = await fetchSobre(companyId);
      setAboutData(data);
    } catch (aboutError) {
      setError(aboutError instanceof Error ? aboutError.message : "Erro ao carregar dados da loja.");
    } finally {
      setLoadingAbout(false);
    }
  }

  function openProductsScreen() {
    clearTransientNavigationState();
    setBrowseMode("all");
    setBrowseTitle("Todos os produtos");
    setBrowseCategoryId(catalog?.categorias[0]?.codigo ?? null);
    setBrowseFilter("");
    setBrowseProducts([]);
    setScreen("products-all");
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setError("");
    setMessage("");
  }

  function openCategoryProductsScreen(categoryId: number) {
    clearTransientNavigationState();
    const category = catalog?.categorias.find((item) => item.codigo === categoryId);
    setBrowseMode("category");
    setBrowseTitle(category?.descricao || "Produtos");
    setBrowseCategoryId(categoryId);
    setBrowseFilter("");
    setBrowseProducts([]);
    setScreen("products-category");
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setError("");
    setMessage("");
  }

  async function handleAuthenticatedNavigation(target: AuthTarget, cliente: Cliente) {
    switch (target) {
      case "checkout":
        openHomeScreen();
        openCheckout(cliente);
        break;
      case "tracking":
        openHomeScreen();
        await openOrderTracking(cliente);
        break;
      case "profile":
        openProfileScreen(cliente);
        break;
      case "addresses":
        await openAddressesScreen(cliente);
        break;
      case "history":
        openHistoryScreen();
        break;
      default:
        openHomeScreen();
        break;
    }
  }

  async function openOrderTracking(cliente?: Cliente | null, options?: { attempts?: number; delayMs?: number }) {
    const trackingCustomer = cliente ?? customer;
    if (!trackingCustomer?.idCliente) {
      throw new Error("Cliente nao identificado para acompanhar o pedido.");
    }

    const attempts = Math.max(1, options?.attempts ?? 1);
    const delayMs = Math.max(0, options?.delayMs ?? 0);
    let lastError: unknown = null;
    setLoadingTracking(true);
    try {
      for (let attempt = 1; attempt <= attempts; attempt += 1) {
        try {
          const latestOrder = await fetchUltimoPedidoCliente(companyId, trackingCustomer.idCliente);
          if (!latestOrder) {
            throw new Error("Nenhum pedido encontrado para acompanhamento.");
          }

          clearTransientNavigationState();
          setTrackedOrder(latestOrder);
          setShowCartPanel(false);
          setError("");
          return;
        } catch (trackingError) {
          lastError = trackingError;
          if (attempt < attempts && delayMs > 0) {
            await wait(delayMs);
          }
        }
      }

      throw lastError instanceof Error ? lastError : new Error("Nenhum pedido encontrado para acompanhamento.");
    } finally {
      setLoadingTracking(false);
    }
  }

  function closeOrderTracking() {
    setTrackedOrder(null);
    trackingStatusRef.current = null;
    setError("");
  }

  function clearTrackedOrderState() {
    setTrackedOrder(null);
    trackingStatusRef.current = null;
  }

  function hydrateCheckoutFromAddress(address?: Endereco | null) {
    if (!address) return;

    setSelectedAddressId(address.idEndereco);
    setCheckout((current) => ({
      ...current,
      cep: address.cep,
      endereco: address.endereco,
      numero: address.numero,
      complemento: address.complemento,
      pontoReferencia: address.pontoReferencia,
      bairroId: address.idBairro,
    }));
  }

  function openCheckout(cliente?: Cliente | null) {
    if (catalogOnlyMode) {
      openHomeScreen();
      return;
    }

    const targetCustomer = cliente ?? customer;
    const nextTipoEntrega = resolveTipoEntrega(checkout.tipoEntrega, allowPickup);
    setError("");
    setMessage("");
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setShowCheckoutAddressSelector(false);

    if (!targetCustomer?.idCliente) {
      openLogin("checkout");
      return;
    }

    clearTrackedOrderState();

    if (nextTipoEntrega === "D") {
      hydrateCheckoutFromAddress(
        selectedAddress ??
          targetCustomer.enderecos.find((item) => item.enderecoPadrao) ??
          targetCustomer.enderecos[0] ??
          null,
      );
    }

    setCheckout((current) => ({
      ...current,
      nome: targetCustomer.nome,
      email: targetCustomer.email,
      telefone: targetCustomer.celular || targetCustomer.telefone,
      tipoEntrega: nextTipoEntrega,
      formaPagamentoId: current.formaPagamentoId || payments[0]?.id || 0,
    }));
    clearTransientNavigationState();
    setShowCheckout(true);
    setScreen("home");
  }

  function closeCheckout() {
    setShowCheckout(false);
    setShowCheckoutAddressSelector(false);
    setShowNewAddressForm(false);
    setShowTrocoModal(false);
    setNewAddress(emptyAddressForm());
    setError("");
  }

  function closeHistoryPanel() {
    setShowHistoryPanel(false);
  }

  function toggleCartPanel() {
    if (catalogOnlyMode) {
      return;
    }

    if (!cart.length) {
      return;
    }

    setShowHistoryPanel(false);
    setShowCartPanel((current) => !current);
  }

  function openCartPanel() {
    if (!cart.length) {
      return;
    }

    setCartFeedback(null);
    setShowHistoryPanel(false);
    setShowCartPanel(true);
  }

  function closeCartPanel() {
    setShowCartPanel(false);
  }

  async function handleLookupCep() {
    const cep = digitsOnly(newAddress.cep);
    if (cep.length < 8) return;

    setSavingCheckout(true);
    try {
      const endereco = await buscarEnderecoPorCep(companyId, cep);
      setNewAddress((current) => ({
        ...current,
        idEndereco: current.idEndereco,
        cep: endereco.cep || cep,
        endereco: endereco.endereco,
        bairroId: endereco.idBairro,
        bairro: endereco.bairro,
        taxaEntrega: endereco.taxaEntrega || endereco.taxa,
      }));
      setError("");
    } catch (lookupError) {
      setNewAddress((current) => ({
        ...current,
        cep: "",
        endereco: "",
        bairroId: 0,
        bairro: "",
        taxaEntrega: 0,
      }));
      setError(
        lookupError instanceof Error
          ? lookupError.message
          : "CEP nao existe ou nao esta na nossa area de cobertura!",
      );
    } finally {
      setSavingCheckout(false);
    }
  }

  async function handleLookupCadastroCep() {
    const cep = digitsOnly(cadastro.cep);
    if (cep.length < 8) return;

    setSavingCheckout(true);
    try {
      const endereco = await buscarEnderecoPorCep(companyId, cep);
      hydrateCadastroFromLookup(endereco);
      setError("");
    } catch (lookupError) {
      setError(
        lookupError instanceof Error
          ? lookupError.message
          : "CEP nao existe ou nao esta na nossa area de cobertura!",
      );
    } finally {
      setSavingCheckout(false);
    }
  }

  async function handleLookupAddressEditorCep() {
    const cep = digitsOnly(addressEditor.cep);
    if (cep.length < 8) return;

    setSavingCheckout(true);
    try {
      const endereco = await buscarEnderecoPorCep(companyId, cep);
      setAddressEditor((current) => ({
        ...current,
        cep: endereco.cep || cep,
        endereco: endereco.endereco,
        bairroId: endereco.idBairro,
        bairro: endereco.bairro,
        taxaEntrega: endereco.taxaEntrega || endereco.taxa,
      }));
      setError("");
    } catch (lookupError) {
      setError(
        lookupError instanceof Error
          ? lookupError.message
          : "CEP nao existe ou nao esta na nossa area de cobertura!",
      );
    } finally {
      setSavingCheckout(false);
    }
  }

  function openNewAddressForm() {
    setShowNewAddressForm(true);
    setNewAddress(emptyAddressForm());
    setError("");
  }

  function closeNewAddressForm() {
    setShowNewAddressForm(false);
    setNewAddress(emptyAddressForm());
    setError("");
  }

  async function handleSelectAddress(addressId: number) {
    if (!customer) {
      setError("Faca o login do cliente para selecionar o endereco.");
      return;
    }

    setSavingCheckout(true);
    setMessage("");
    setError("");

    try {
      const savedCustomer = await definirEnderecoPadraoCliente(companyId, customer.idCliente, addressId);
      syncCustomer(savedCustomer);
      hydrateCheckoutFromAddress(
        savedCustomer.enderecos.find((address) => address.enderecoPadrao) ?? savedCustomer.enderecos[0] ?? null,
      );
      setMessage("Endereco de entrega atualizado.");
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : "Erro ao atualizar endereco.");
    } finally {
      setSavingCheckout(false);
    }
  }

  async function handleSaveNewAddress() {
    if (!customer?.idCliente) {
      setError("Faca o login do cliente antes de cadastrar endereco.");
      return;
    }

    if (!newAddress.endereco.trim()) {
      await showRequiredFieldAlert(
        catalog?.configuracao.utilizaCEP
          ? "Informe um CEP valido para carregar o endereco corretamente."
          : "Preencha o endereco para continuar.",
        catalog?.configuracao.utilizaCEP ? "novo-endereco-cep" : "novo-endereco-logradouro",
      );
      return;
    }

    if (!newAddress.numero.trim()) {
      await showRequiredFieldAlert("Preencha o numero do endereco para continuar.", "novo-endereco-numero");
      return;
    }

    if (!newAddress.bairroId) {
      await showRequiredFieldAlert(
        catalog?.configuracao.utilizaCEP
          ? "Informe um CEP valido para localizar o bairro."
          : "Selecione o bairro para continuar.",
        catalog?.configuracao.utilizaCEP ? "novo-endereco-cep" : "novo-endereco-bairro",
      );
      return;
    }

    setSavingCheckout(true);
    setMessage("");
    setError("");

    try {
      const address: Endereco = {
        idEndereco: 0,
        idCliente: customer.idCliente,
        idEmpresa: companyId,
        cep: newAddress.cep,
        endereco: newAddress.endereco,
        idBairro: newAddress.bairroId,
        bairro: newAddress.bairro,
        taxaEntrega: newAddress.taxaEntrega,
        numero: newAddress.numero,
        complemento: newAddress.complemento,
        pontoReferencia: newAddress.pontoReferencia,
        idCidade: 0,
        UF: "",
        enderecoPadrao: true,
        taxa: newAddress.taxaEntrega,
      };

      const savedCustomer = await salvarEnderecoCliente(companyId, customer.idCliente, address);
      syncCustomer(savedCustomer);
      hydrateCheckoutFromAddress(
        savedCustomer.enderecos.find((item) => item.enderecoPadrao) ?? savedCustomer.enderecos[0] ?? null,
      );
      closeNewAddressForm();
      setMessage("Endereco cadastrado com sucesso!");
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : "Erro ao cadastrar endereco.");
    } finally {
      setSavingCheckout(false);
    }
  }

  function startNewAddressEditor() {
    setEditingAddress(true);
    setAddressEditor(emptyAddressForm());
    setScreen("new-address");
    setShowHistoryPanel(false);
    setShowCartPanel(false);
    setError("");
    setMessage("");
  }

  function openCheckoutAddressSelector() {
    setShowCheckoutAddressSelector(true);
    setError("");
    setMessage("");
  }

  function closeCheckoutAddressSelector() {
    setShowCheckoutAddressSelector(false);
    setError("");
  }

  async function startEditAddress(addressId: number) {
    if (!customer?.idCliente) {
      openLogin("addresses");
      return;
    }

    setSavingCheckout(true);
    try {
      const endereco = await fetchEnderecoCliente(companyId, customer.idCliente, addressId);
      hydrateAddressEditor(endereco);
      setEditingAddress(true);
      setScreen("new-address");
      setShowHistoryPanel(false);
      setShowCartPanel(false);
      setError("");
      setMessage("");
    } catch (addressError) {
      setError(addressError instanceof Error ? addressError.message : "Erro ao carregar endereco.");
    } finally {
      setSavingCheckout(false);
    }
  }

  function cancelAddressEditor() {
    setEditingAddress(false);
    setAddressEditor(emptyAddressForm());
    openHomeScreen();
  }

  async function handleSaveAddressEditor() {
    if (!customer?.idCliente) {
      openLogin("addresses");
      return;
    }

    if (catalog?.configuracao.utilizaCEP && !digitsOnly(addressEditor.cep)) {
      await showRequiredFieldAlert("Informe um CEP valido para localizar seu endereco.", "cliente-endereco-cep");
      return;
    }

    if (!addressEditor.endereco.trim()) {
      await showRequiredFieldAlert(
        catalog?.configuracao.utilizaCEP
          ? "Confira o CEP para carregar o endereco corretamente."
          : "Preencha o endereco para continuar.",
        catalog?.configuracao.utilizaCEP ? "cliente-endereco-cep" : "cliente-endereco-logradouro",
      );
      return;
    }

    if (!addressEditor.numero.trim()) {
      await showRequiredFieldAlert("Preencha o numero do endereco para continuar.", "cliente-endereco-numero");
      return;
    }

    if (!addressEditor.bairroId) {
      await showRequiredFieldAlert(
        catalog?.configuracao.utilizaCEP
          ? "Informe um CEP valido para localizar o bairro."
          : "Selecione o bairro para continuar.",
        catalog?.configuracao.utilizaCEP ? "cliente-endereco-cep" : "cliente-endereco-bairro",
      );
      return;
    }

    setSavingCheckout(true);
    try {
      const savedCustomer = await salvarEnderecoCliente(companyId, customer.idCliente, {
        idEndereco: addressEditor.idEndereco,
        idCliente: customer.idCliente,
        idEmpresa: companyId,
        cep: addressEditor.cep,
        endereco: addressEditor.endereco,
        enderecoCompleto: "",
        idBairro: addressEditor.bairroId,
        bairro: addressEditor.bairro,
        taxaEntrega: addressEditor.taxaEntrega,
        numero: addressEditor.numero,
        complemento: addressEditor.complemento,
        pontoReferencia: addressEditor.pontoReferencia,
        idCidade: 0,
        UF: "",
        enderecoPadrao: false,
        taxa: addressEditor.taxaEntrega,
      });
      syncCustomer(savedCustomer);
      setEditingAddress(false);
      setAddressEditor(emptyAddressForm());
      openHomeScreen();
      setMessage("Endereco gravado com sucesso!");
    } catch (addressError) {
      setError(addressError instanceof Error ? addressError.message : "Erro ao cadastrar endereco.");
    } finally {
      setSavingCheckout(false);
    }
  }

  async function handleSelectDefaultAddress(addressId: number) {
    if (!customer?.idCliente) {
      openLogin("addresses");
      return;
    }

    setSavingCheckout(true);
    try {
      const savedCustomer = await definirEnderecoPadraoCliente(companyId, customer.idCliente, addressId);
      syncCustomer(savedCustomer);
      setMessage("Endereco padrao atualizado.");
    } catch (addressError) {
      setError(addressError instanceof Error ? addressError.message : "Erro ao selecionar endereco.");
    } finally {
      setSavingCheckout(false);
    }
  }

  async function handleLoginSubmit() {
    if (!digitsOnly(loginPhone)) {
      await showRequiredFieldAlert(
        "Digite seu telefone com DDD para localizar seu cadastro.",
        "login-phone",
        "Telefone obrigatorio",
      );
      return;
    }

    setSavingCheckout(true);
    setError("");
    setMessage("");
    try {
      const loggedCustomer = await loginCliente(companyId, digitsOnly(loginPhone));
      rememberPhone(loginPhone);
      syncCustomer(loggedCustomer);
      await handleAuthenticatedNavigation(authTarget, loggedCustomer);
    } catch (loginError) {
      if (loginError instanceof Error && isCustomerNotFoundError(loginError)) {
        const shouldRegister = await showLegacyConfirm("Uaiiii", "Cadastro nao encontrado, Bora cadastrar?");
        if (shouldRegister) {
          const phoneDigits = digitsOnly(loginPhone);
          setCadastro({
            ...emptyCadastroForm(),
            celular: phoneDigits,
          });
          setScreen("register");
          setError("");
          setMessage("");
        }
        return;
      }

      setError(loginError instanceof Error ? loginError.message : "Erro ao efetuar login.");
    } finally {
      setSavingCheckout(false);
    }
  }

  async function handleForgotPasswordSubmit() {
    const email = forgotEmail.trim();

    if (!email) {
      await showRequiredFieldAlert(
        "Informe o email cadastrado para recuperar o acesso.",
        "forgot-email",
        "Email obrigatorio",
      );
      return;
    }

    setSavingCheckout(true);
    setError("");
    setMessage("");

    try {
      await esqueciMinhaSenhaCliente(companyId, email);
      setMessage("Solicitacao enviada. Confira as instrucoes no email informado.");
    } catch (forgotError) {
      setError(forgotError instanceof Error ? forgotError.message : "Erro ao recuperar senha.");
    } finally {
      setSavingCheckout(false);
    }
  }

  async function handleAdminLoginSubmit() {
    if (!adminLogin.trim()) {
      await showRequiredFieldAlert(
        "Informe o login administrativo para continuar.",
        "admin-login",
        "Login obrigatorio",
      );
      return;
    }

    if (!adminPassword.trim()) {
      await showRequiredFieldAlert(
        "Digite a senha administrativa para continuar.",
        "admin-password",
        "Senha obrigatoria",
      );
      return;
    }

    setSavingCheckout(true);
    setError("");
    setMessage("");
    try {
      const session = await loginAdmin(companyId, adminLogin.trim(), adminPassword);
      setAdminSession(session);
      setAdminPassword("");
      setAdminDashboard(await fetchAdminDashboard(companyId, session.token));
      openAdminDashboard("admin-index");
    } catch (adminError) {
      setAdminSession(null);
      setAdminDashboard(null);
      setError(adminError instanceof Error ? adminError.message : "Erro ao efetuar login administrativo.");
    } finally {
      setSavingCheckout(false);
    }
  }

  async function handleAdminLogout() {
    if (adminSession?.token) {
      try {
        await logoutAdmin(companyId, adminSession.token);
      } catch {
        // Ignore logout API failure and continue cleaning local session.
      }
    }

    setAdminSession(null);
    setAdminDashboard(null);
    setAdminLogin("1");
    setAdminPassword("");
    openAdminLoginScreen();
  }

  async function handleSaveCadastro() {
    if (!cadastro.nome.trim()) {
      await showRequiredFieldAlert("Preencha seu nome para continuar o cadastro.", "cadastro-nome", "Nome obrigatorio");
      return;
    }

    if (!digitsOnly(cadastro.celular)) {
      await showRequiredFieldAlert(
        "Digite seu celular com DDD para continuar o cadastro.",
        "cadastro-celular",
        "Celular obrigatorio",
      );
      return;
    }

    if (catalog?.configuracao.utilizaCEP && !digitsOnly(cadastro.cep)) {
      await showRequiredFieldAlert("Informe um CEP valido para localizar seu endereco.", "cadastro-cep", "CEP obrigatorio");
      return;
    }

    if (!cadastro.endereco.trim()) {
      await showRequiredFieldAlert(
        catalog?.configuracao.utilizaCEP
          ? "Confira o CEP para carregar o endereco corretamente."
          : "Preencha o endereco para continuar o cadastro.",
        catalog?.configuracao.utilizaCEP ? "cadastro-cep" : "cadastro-endereco",
      );
      return;
    }

    if (!cadastro.numero.trim()) {
      await showRequiredFieldAlert("Preencha o numero do endereco para continuar.", "cadastro-numero");
      return;
    }

    if (!cadastro.bairroId) {
      await showRequiredFieldAlert(
        catalog?.configuracao.utilizaCEP
          ? "Informe um CEP valido para localizar o bairro."
          : "Selecione o bairro para continuar o cadastro.",
        catalog?.configuracao.utilizaCEP ? "cadastro-cep" : "cadastro-bairro",
      );
      return;
    }

    setSavingCheckout(true);
    setError("");
    setMessage("");
    try {
      const savedCustomer = await salvarCliente(companyId, {
        idCliente: 0,
        idEmpresa: companyId,
        nome: cadastro.nome,
        email: "",
        senha: "",
        celular: digitsOnly(cadastro.celular),
        telefone: digitsOnly(cadastro.telefone),
        enderecos: [
          {
            idEndereco: 0,
            idCliente: 0,
            idEmpresa: companyId,
            cep: cadastro.cep,
            endereco: cadastro.endereco,
            enderecoCompleto: "",
            idBairro: cadastro.bairroId,
            bairro: cadastro.bairro,
            taxaEntrega: cadastro.taxaEntrega,
            numero: cadastro.numero,
            complemento: cadastro.complemento,
            pontoReferencia: cadastro.pontoReferencia,
            idCidade: 0,
            UF: "",
            enderecoPadrao: true,
            taxa: cadastro.taxaEntrega,
          },
        ],
      });
      rememberPhone(savedCustomer.celular || savedCustomer.telefone);
      syncCustomer(savedCustomer);
      setCadastro(emptyCadastroForm());
      setScreen("home");
      setMessage("Cadastro realizado com sucesso!");
    } catch (registerError) {
      setError(registerError instanceof Error ? registerError.message : "Erro ao cadastrar cliente.");
    } finally {
      setSavingCheckout(false);
    }
  }

  async function handleSaveProfile() {
    if (!perfil.nome.trim()) {
      await showRequiredFieldAlert("Preencha seu nome para salvar o perfil.", "perfil-nome", "Nome obrigatorio");
      return;
    }

    if (!digitsOnly(perfil.celular)) {
      await showRequiredFieldAlert(
        "Digite seu celular com DDD para salvar o perfil.",
        "perfil-celular",
        "Celular obrigatorio",
      );
      return;
    }

    if (!customer?.idCliente) {
      openLogin("profile");
      return;
    }

    setSavingCheckout(true);
    setError("");
    setMessage("");
    try {
      const savedCustomer = await salvarCliente(companyId, {
        ...customer,
        nome: perfil.nome,
        email: perfil.email.trim() ? perfil.email.trim().toLowerCase() : customer.email,
        senha: perfil.senha.trim() ? perfil.senha : customer.senha,
        celular: digitsOnly(perfil.celular),
        telefone: digitsOnly(perfil.telefone),
      });
      syncCustomer(savedCustomer);
      hydrateProfileForm(savedCustomer);
      setScreen("home");
      setMessage("Dados atualizados com sucesso!");
    } catch (profileError) {
      setError(profileError instanceof Error ? profileError.message : "Erro de cadastro.");
    } finally {
      setSavingCheckout(false);
    }
  }

  function handleSelectTipoEntrega(tipoEntrega: "D" | "R") {
    const nextTipoEntrega = resolveTipoEntrega(tipoEntrega, allowPickup);

    updateCheckout("tipoEntrega", nextTipoEntrega);
    if (nextTipoEntrega === "D") {
      hydrateCheckoutFromAddress(
        selectedAddress ??
          customer?.enderecos.find((item) => item.enderecoPadrao) ??
          customer?.enderecos[0] ??
          null,
      );
    } else {
      setShowNewAddressForm(false);
      setNewAddress(emptyAddressForm());
    }
    setError("");
  }

  function handleChangePayment(paymentId: number) {
    const payment = payments.find((item) => item.id === paymentId);
    if (!payment) return;

    if (pedidoMinimo > 0 && subtotalSemEntrega < pedidoMinimo) {
      setError(`Pedido minimo nao atingido. Valor minimo: ${formatMoney(pedidoMinimo)}`);
      return;
    }

    if (catalog && !catalog.aberta) {
      setError("ixee estamos fechado agora...");
      return;
    }

    setCheckout((current) => ({
      ...current,
      formaPagamentoId: paymentId,
      valorAReceber: "",
    }));
    setShowTrocoModal(payment.permiteTroco && !isPixPayment(payment));
    setError("");
  }

  function handleObservationChange(value: string) {
    updateCheckout("observacao", value.slice(0, 100));
  }

  function handleConfirmTroco() {
    const value = parseCurrencyInput(checkout.valorAReceber);
    if (value < total) {
      setError("Valor menor que o total do pedido.");
      return;
    }

    setShowTrocoModal(false);
    setError("");
  }

  function handleCancelTroco() {
    setShowTrocoModal(false);
    updateCheckout("valorAReceber", "");
    setError("");
  }

  function closeProductDetail() {
    setActiveProduct(null);
    setActiveOptions([]);
    setActiveFractions([]);
    optionCatalogRef.current = {};
    fractionCatalogRef.current = {};
    setDraft(emptyDraft());
    setEditingCartItemId(null);
    setError("");
  }

  function discardProductDetail() {
    if (editingCartItemId) {
      setCart((current) => current.filter((item) => item.id !== editingCartItemId));
    }
    closeProductDetail();
  }

  function totalSelectedOptions(): number {
    return Object.values(draft.opcionais).reduce((sum, quantity) => sum + quantity, 0);
  }

  function totalGroupOptions(groupId: number): number {
    return activeOptions
      .filter((item) => item.groupId === groupId)
      .reduce((sum, item) => sum + (draft.opcionais[item.codigoOpcional] ?? 0), 0);
  }

  function calculateItemUnitPrice(product: Produto, size: string, fractions: Array<{ quantidade: number; produto: Produto }>): number {
    let totalPrice = roundCurrency(productPriceBySize(product, size));

    for (const fraction of fractions) {
      const fractionPrice = roundCurrency(productPriceBySize(fraction.produto, size));
      totalPrice += fractionPrice;
    }

    return roundCurrency(totalPrice / (fractions.length + 1));
  }

  function productIsUnavailableForRepeat(product: Produto): boolean {
    return product.idSituacao === 3 || product.situacao.trim() === "3";
  }

  function resolveRecoveredItemSize(product: Produto, size: string, previousProduct?: Produto): string {
    // Produto que nao e vendido por tamanho nunca carrega tamanho, mesmo que a venda
    // antiga tenha gravado um valor padrao ("M") no banco.
    if (!productSupportsSize(product)) {
      return "";
    }

    return size.trim() ? remapProductSize(product, size, previousProduct) : size;
  }

  async function fetchCurrentRepeatProduct(
    product: Produto,
    cache: Map<number, Promise<Produto>>,
  ): Promise<Produto> {
    const cached = cache.get(product.codigo);
    if (cached) {
      return cached;
    }

    const request = fetchProdutoDetalhe(companyId, product.codigo).catch(() => product);
    cache.set(product.codigo, request);
    return request;
  }

  function buildRecoveredCartItem(
    item: PedidoRecuperado["itens"][number],
    index: number,
    currentProduct: Produto,
    currentFractions: Array<{ quantidade: number; produto: Produto }>,
    resolvedSize = resolveRecoveredItemSize(currentProduct, item.tamanho, item.produto),
  ): CartItem {
    const effectiveSize = productSupportsSize(currentProduct) ? resolvedSize || item.tamanho : "";

    return reprice({
      id: `repeat-${item.produto.codigo}-${index}-${Date.now()}`,
      produto: currentProduct,
      quantidade: item.quantidade,
      tamanho: effectiveSize,
      observacao: item.observacao,
      opcionais: item.opcionais.map((option) => ({
        quantidade: option.quantidade,
        unitPrice: roundCurrency(optionPriceBySize(option.opcional, effectiveSize)),
        opcional: option.opcional,
      })),
      fracoes: currentFractions,
      valorUnitario: calculateItemUnitPrice(currentProduct, effectiveSize, currentFractions),
      valorTotal: item.valorTotalProduto,
    });
  }

  async function analyzeRecoveredOrder(
    pedido: PedidoRecuperado,
    sourceSale?: VendaHistorico | null,
  ): Promise<{
    nextCart: CartItem[];
    unavailableProducts: string[];
    sizeIssues: RepeatSizeIssue[];
    fractionIssues: RepeatFractionIssue[];
    priceChanges: RepeatPriceChange[];
  }> {
    const productCache = new Map<number, Promise<Produto>>();
    const unavailableProducts = new Set<string>();
    const sizeIssues: RepeatSizeIssue[] = [];
    const fractionIssues: RepeatFractionIssue[] = [];
    const priceChanges: RepeatPriceChange[] = [];

    const nextCart = await Promise.all(pedido.itens.map(async (item, index) => {
      const currentProduct = await fetchCurrentRepeatProduct(item.produto, productCache);
      const sourceSaleItem = sourceSale?.itens[index];
      if (productIsUnavailableForRepeat(currentProduct)) {
        unavailableProducts.add(currentProduct.descricao || item.produto.descricao);
      }

      const resolvedSize = resolveRecoveredItemSize(currentProduct, item.tamanho, item.produto);
      if (productSupportsSize(currentProduct) && item.tamanho.trim() && !resolvedSize) {
        sizeIssues.push({
          description: currentProduct.descricao || item.produto.descricao,
          previousSize: item.tamanho,
        });
      }

      const currentFractions = await Promise.all(item.fracoes.map(async (fraction) => {
        const currentFractionProduct = await fetchCurrentRepeatProduct(fraction.produto, productCache);
        if (productIsUnavailableForRepeat(currentFractionProduct)) {
          unavailableProducts.add(currentFractionProduct.descricao || fraction.produto.descricao);
        }
        return {
          quantidade: fraction.quantidade,
          produto: currentFractionProduct,
        };
      }));

      const previousParts = currentFractions.reduce((sum, fraction) => sum + fraction.quantidade, 0) + 1;
      if (currentFractions.length > 0 && previousParts > maxFractionParts) {
        fractionIssues.push({
          description: currentProduct.descricao || item.produto.descricao,
          previousParts,
        });
      }

      const nextItem = buildRecoveredCartItem(item, index, currentProduct, currentFractions, resolvedSize);
      const previousUnitPrice = roundCurrency(
        sourceSaleItem?.valorUnitario ||
          item.valorUnitario ||
          (sourceSaleItem?.quantidade ? sourceSaleItem.valorTotalProduto / sourceSaleItem.quantidade : 0),
      );
      const currentUnitPrice = roundCurrency(nextItem.valorUnitario);
      const previousTotal = roundCurrency(sourceSaleItem?.valorTotalProduto ?? item.valorTotalProduto);
      const currentTotal = roundCurrency(nextItem.valorTotal);

      if (previousUnitPrice !== currentUnitPrice || previousTotal !== currentTotal) {
        priceChanges.push({
          description: sourceSaleItem?.produto.descricao || currentProduct.descricao || item.produto.descricao,
          sizeLabel: nextItem.tamanho,
          quantity: item.quantidade,
          previousUnitPrice,
          currentUnitPrice,
          previousTotal,
          currentTotal,
        });
      }

      return nextItem;
    }));

    return {
      nextCart,
      unavailableProducts: [...unavailableProducts],
      sizeIssues,
      fractionIssues,
      priceChanges,
    };
  }

  function buildRepeatPriceChangeHtml(priceChanges: RepeatPriceChange[]): string {
    const items = priceChanges
      .slice(0, 6)
      .map(
        (change) => `
          <li>
            <strong>${escapeHtml(change.description)}</strong>
            ${change.sizeLabel ? `<span> - tamanho ${escapeHtml(change.sizeLabel)}</span>` : ""}
            <div>Valor da unidade: ${escapeHtml(formatMoney(change.previousUnitPrice))} para ${escapeHtml(formatMoney(change.currentUnitPrice))}</div>
            ${change.quantity > 1 ? `<div>Total (${change.quantity}x): ${escapeHtml(formatMoney(change.previousTotal))} para ${escapeHtml(formatMoney(change.currentTotal))}</div>` : ""}
          </li>
        `,
      )
      .join("");

    const remaining = priceChanges.length - 6;

    return `
      <div style="text-align:left">
        <p style="margin:0 0 10px">Encontramos item(ns) com preco atualizado desde o pedido anterior.</p>
        <ul style="margin:0;padding-left:18px">${items}</ul>
        ${remaining > 0 ? `<p style="margin:10px 0 0">E mais ${remaining} item(ns) com valor atualizado.</p>` : ""}
        <p style="margin:12px 0 0">Se continuar, a nova sacola sera montada com os valores atuais.</p>
      </div>
    `;
  }

  function optionQuantityTotal(item: CartItem): number {
    return item.opcionais.reduce((sum, option) => sum + option.quantidade, 0);
  }

  function optionGroupTotal(
    item: CartItem,
    definitions: ProdutoOpcional[],
    groupId: number,
  ): number {
    return item.opcionais.reduce((sum, option) => {
      const definition = definitions.find((entry) => entry.codigoOpcional === option.opcional.codigo);
      if (definition?.groupId === groupId) {
        return sum + option.quantidade;
      }
      return sum;
    }, 0);
  }

  function editCartItem(item: CartItem) {
    setLoadingProduct(true);
    setError("");
    void (async () => {
      try {
        const { resolvedSize } = await loadProductComposer(item.produto.codigo, item.tamanho, item.produto);
        optionCatalogRef.current = item.opcionais.reduce<Record<number, Opcional>>((result, option) => {
          result[option.opcional.codigo] = option.opcional;
          return result;
        }, { ...optionCatalogRef.current });
        fractionCatalogRef.current = item.fracoes.reduce<Record<number, Produto>>((result, fraction) => {
          result[fraction.produto.codigo] = fraction.produto;
          return result;
        }, { ...fractionCatalogRef.current });
        setEditingCartItemId(item.id);
        setDraft({
          quantidade: item.quantidade,
          tamanho: resolvedSize,
          observacao: item.observacao,
          opcionais: item.opcionais.reduce<Record<number, number>>((result, option) => {
            result[option.opcional.codigo] = option.quantidade;
            return result;
          }, {}),
          fracoes: item.fracoes.reduce<Record<number, number>>((result, fraction) => {
            result[fraction.produto.codigo] = fraction.quantidade;
            return result;
          }, {}),
        });
      } catch (loadError) {
        setError(loadError instanceof Error ? loadError.message : "Erro ao abrir item.");
      } finally {
        setLoadingProduct(false);
      }
    })();
  }

  async function handleRemoveCartItem(item: CartItem) {
    const confirmed = await showLegacyConfirm(
      "Remover item?",
      `Deseja tirar ${item.produto.descricao} da sacola?`,
    );

    if (!confirmed) {
      return;
    }

    setCart((current) => {
      const next = current.filter((entry) => entry.id !== item.id);
      if (!next.length) {
        setShowCartPanel(false);
      }
      return next;
    });
    setCartFeedback(null);
    setError("");
  }

  async function handleClearCart() {
    if (!cart.length) {
      return;
    }

    const confirmed = await showLegacyConfirm(
      "Esvaziar a sacola?",
      "Tem certeza que deseja retirar todos os produtos da sacola?",
    );

    if (!confirmed) {
      return;
    }

    setCart([]);
    setShowCartPanel(false);
    setCartFeedback(null);
    setError("");
    setMessage("Sacola esvaziada.");
  }

  async function handleChangeCartOption(itemId: string, optionCode: number, delta: number) {
    const item = cart.find((entry) => entry.id === itemId);
    if (!item) {
      return;
    }

    try {
      const definitions = await fetchProdutoOpcionais(companyId, item.produto.codigo, item.tamanho);
      const definition = definitions.find((entry) => entry.codigoOpcional === optionCode);
      const currentOption = item.opcionais.find((entry) => entry.opcional.codigo === optionCode);

      if (!definition || !currentOption) {
        return;
      }

      if (delta < 0) {
        if (
          catalog?.configuracao.utilizaControleOpcionais &&
          !usesCategoryRule(definitions) &&
          item.produto.opcionalMinimo > 0 &&
          optionQuantityTotal(item) - 1 < item.produto.opcionalMinimo
        ) {
          setError("");
          await showLegacyWarning("Obrigatorio", `Este item exige no minimo ${item.produto.opcionalMinimo} opcionais.`);
          return;
        }

        if (
          !categoryWithoutLimit(definition) &&
          definition.groupId > 0 &&
          definition.opcionalMinimo > 0 &&
          optionGroupTotal(item, definitions, definition.groupId) - 1 < definition.opcionalMinimo
        ) {
          setError("");
          await showLegacyWarning("Obrigatorio", `Selecione no minimo ${definition.opcionalMinimo} em ${definition.groupDescription}.`);
          return;
        }
      } else {
        if (
          catalog?.configuracao.utilizaControleOpcionais &&
          !usesCategoryRule(definitions) &&
          item.produto.opcionalMaximo > 0 &&
          optionQuantityTotal(item) + 1 > item.produto.opcionalMaximo
        ) {
          setError("");
          await showLegacyError("Erro", "Quantidade de opcional excedido.");
          return;
        }

        if (
          !categoryWithoutLimit(definition) &&
          definition.groupId > 0 &&
          definition.opcionalMaximo > 0 &&
          optionGroupTotal(item, definitions, definition.groupId) + 1 > definition.opcionalMaximo
        ) {
          setError("");
          await showLegacyError("Erro", `Limite maximo de ${definition.opcionalMaximo} atingido para ${definition.groupDescription}.`);
          return;
        }
      }

      setCart((current) =>
        current
          .map((entry) => {
            if (entry.id !== itemId) {
              return entry;
            }

            const nextOptions = entry.opcionais
              .map((option) => {
                if (option.opcional.codigo !== optionCode) {
                  return option;
                }
                return { ...option, quantidade: option.quantidade + delta };
              })
              .filter((option) => option.quantidade > 0);

            return reprice({ ...entry, opcionais: nextOptions });
          })
          .filter(Boolean),
      );
      setError("");
    } catch (optionError) {
      setError(optionError instanceof Error ? optionError.message : "Erro ao alterar opcional.");
    }
  }

  function handleChangeCartItemQuantity(itemId: string, delta: number) {
    setCart((current) =>
      current
        .map((entry) => {
          if (entry.id !== itemId) {
            return entry;
          }
          return reprice({ ...entry, quantidade: entry.quantidade + delta });
        })
        .filter((entry) => entry.quantidade > 0),
    );
    setError("");
  }

  async function loadProductComposer(productId: number, nextSize?: string, previousProduct?: Produto) {
    const detail = activeProduct?.codigo === productId ? activeProduct : await fetchProdutoDetalhe(companyId, productId);
    const remappedSize = nextSize ? remapProductSize(detail, nextSize, previousProduct) : "";
    const resolvedSize = nextSize ? remappedSize || defaultProductSize(detail) : defaultProductSize(detail);
    const [options, fractions] = await Promise.all([
      fetchProdutoOpcionais(companyId, productId, resolvedSize),
      detail.permiteFrac ? fetchProdutoFracoes(companyId, productId, resolvedSize) : Promise.resolve([]),
    ]);

    optionCatalogRef.current = options.reduce<Record<number, Opcional>>((result, option) => {
      result[option.codigoOpcional] = option.opcional;
      return result;
    }, { ...optionCatalogRef.current });
    fractionCatalogRef.current = fractions.reduce<Record<number, Produto>>((result, item) => {
      result[item.codigo] = item;
      return result;
    }, { ...fractionCatalogRef.current, [detail.codigo]: detail });

    setActiveProduct(detail);
    setActiveOptions(options);
    setActiveFractions(fractions.filter((item) => item.codigo !== detail.codigo));
    return { detail, resolvedSize };
  }

  async function chooseProduct(product: Produto) {
    setLoadingProduct(true);
    setError("");
    try {
      clearTrackedOrderState();
      optionCatalogRef.current = {};
      fractionCatalogRef.current = { [product.codigo]: product };
      const { resolvedSize } = await loadProductComposer(product.codigo);
      setEditingCartItemId(null);
      setDraft({
        ...emptyDraft(),
        tamanho: resolvedSize,
      });
    } catch (loadError) {
      const message = loadError instanceof Error ? loadError.message : "Erro ao abrir produto.";
      await showLegacyError("Erro", message);
    } finally {
      setLoadingProduct(false);
    }
  }

  async function handleSelectItemSize(nextSize: string) {
    if (!activeProduct) return;

    setLoadingProduct(true);
    setError("");
    try {
      const { resolvedSize } = await loadProductComposer(activeProduct.codigo, nextSize);
      setDraft((current) => ({
        ...current,
        tamanho: resolvedSize,
      }));
    } catch (loadError) {
      const message = loadError instanceof Error ? loadError.message : "Erro ao trocar tamanho.";
      await showLegacyWarning("Atencao", message);
    } finally {
      setLoadingProduct(false);
    }
  }

  function handleChangeOptional(option: ProdutoOpcional, delta: number) {
    if (!activeProduct) return;

    const currentQuantity = draft.opcionais[option.codigoOpcional] ?? 0;
    if (delta < 0) {
      setError("");
      setDraft((current) => ({
        ...current,
        opcionais: {
          ...current.opcionais,
          [option.codigoOpcional]: Math.max(0, currentQuantity - 1),
        },
      }));
      return;
    }

    if (catalog?.configuracao.utilizaControleOpcionais && !usesCategoryRule(activeOptions) && activeProduct.opcionalMaximo > 0) {
      if (totalSelectedOptions() + 1 > activeProduct.opcionalMaximo) {
        void showLegacyError("Erro", "Quantidade de opcional excedido.");
        return;
      }
    }

    if (!categoryWithoutLimit(option) && option.groupId > 0 && option.opcionalMaximo > 0) {
      if (totalGroupOptions(option.groupId) >= option.opcionalMaximo) {
        void showLegacyError("Erro", `Limite maximo de ${option.opcionalMaximo} atingido para ${option.groupDescription}.`);
        return;
      }
    }

    setError("");
    setDraft((current) => ({
      ...current,
      opcionais: {
        ...current.opcionais,
        [option.codigoOpcional]: currentQuantity + 1,
      },
    }));
  }

  function handleChangeFraction(product: Produto, delta: number) {
    // Sempre pelo ref, nunca por draft.fracoes: e o unico jeito de dois toques no
    // mesmo instante enxergarem a selecao que o toque anterior acabou de fazer.
    const fracoesAtuais = fracoesRef.current;
    const currentQuantity = fracoesAtuais[product.codigo] ?? 0;

    if (delta < 0) {
      setError("");
      fracoesRef.current = { ...fracoesAtuais, [product.codigo]: 0 };
      setDraft((current) => ({
        ...current,
        fracoes: {
          ...current.fracoes,
          [product.codigo]: 0,
        },
      }));
      return;
    }

    // Sabor ja marcado: o proprio contador mostra o 1, nao precisa avisar nada.
    if (currentQuantity >= 1) {
      return;
    }

    // No limite, o cliente precisa saber por que nao consegue adicionar. Travar
    // em silencio parecia tela quebrada. Mesmo padrao usado nos opcionais.
    if (countSelectedFractions(fracoesAtuais) >= maxExtraFlavors) {
      void showLegacyWarning(
        "Atencao",
        `Este item aceita no maximo ${maxFractionParts} sabores, e o proprio produto ja conta como 1. Remova um sabor para escolher outro.`,
      );
      return;
    }

    setError("");
    fracoesRef.current = { ...fracoesAtuais, [product.codigo]: 1 };
    setDraft((current) => ({
      ...current,
      fracoes: {
        ...current.fracoes,
        [product.codigo]: 1,
      },
    }));
  }

  function addToCart() {
    if (!activeProduct) return;

    if (catalogOnlyMode) {
      void showLegacyValidation("Cardapio online", "Este cardapio e somente para consulta.");
      return;
    }

    if (catalog?.configuracao.utilizaControleOpcionais && !usesCategoryRule(activeOptions) && activeProduct.opcionalMinimo > 0) {
      if (totalSelectedOptions() < activeProduct.opcionalMinimo) {
        void showLegacyWarning("Atencao", `A quantidade minima a ser preenchido e: ${activeProduct.opcionalMinimo} Opcionais.`);
        return;
      }
    }

    const validatedGroups = new Set<number>();
    for (const option of activeOptions) {
      if (categoryWithoutLimit(option) || option.groupId <= 0 || option.opcionalMinimo <= 0 || validatedGroups.has(option.groupId)) {
        continue;
      }

      validatedGroups.add(option.groupId);
      if (totalGroupOptions(option.groupId) < option.opcionalMinimo) {
        void showLegacyWarning("Obrigatorio", `Selecione no minimo ${option.opcionalMinimo} em ${option.groupDescription}.`);
        return;
      }
    }

    const selectedOptions = Object.entries(draft.opcionais)
      .map(([code, quantity]) => ({
        code: Number(code),
        quantidade: quantity,
        opcional: optionCatalogRef.current[Number(code)],
      }))
      .filter((item) => item.quantidade > 0 && item.opcional)
      .map((item) => ({
        quantidade: item.quantidade,
        unitPrice: roundCurrency(optionPriceBySize(item.opcional, draft.tamanho)),
        opcional: item.opcional,
      }));

    const selectedFractions = Object.entries(draft.fracoes)
      .map(([code, quantity]) => ({
        code: Number(code),
        quantidade: quantity,
        produto: fractionCatalogRef.current[Number(code)],
      }))
      .filter((item) => item.quantidade > 0 && item.produto)
      .map((item) => ({
        quantidade: item.quantidade,
        produto: item.produto,
      }));

    const next = reprice({
      id: editingCartItemId ?? `${activeProduct.codigo}-${Date.now()}`,
      produto: activeProduct,
      quantidade: draft.quantidade,
      tamanho: draft.tamanho,
      observacao: draft.observacao,
      opcionais: selectedOptions,
      fracoes: selectedFractions,
      valorUnitario: calculateItemUnitPrice(activeProduct, draft.tamanho, selectedFractions),
      valorTotal: 0,
    });

    const wasEditing = Boolean(editingCartItemId);

    setError("");
    clearTrackedOrderState();
    setCart((current) =>
      wasEditing
        ? current.map((item) => (item.id === editingCartItemId ? next : item))
        : [...current, next],
    );
    setMessage("");
    setCartFeedback(null);
    closeProductDetail();
    if (screen === "products-category" || screen === "products-all") {
      void window.requestAnimationFrame(() => {
        resetViewportToTopOnNextFrame();
      });
    }
  }

  function buildAddress(resolvedTipoEntrega: "D" | "R" = tipoEntregaPedido): Endereco {
    const defaultAddress = customer?.enderecos.find((item) => item.enderecoPadrao) ?? customer?.enderecos[0];
    const companyAddress = catalog?.empresa.endereco;
    if (resolvedTipoEntrega === "R") {
      return {
        idEndereco: selectedAddress?.idEndereco ?? defaultAddress?.idEndereco ?? 0,
        idCliente: customer?.idCliente ?? 0,
        idEmpresa: companyId,
        cep: selectedAddress?.cep || defaultAddress?.cep || companyAddress?.cep || "",
        endereco: selectedAddress?.endereco || defaultAddress?.endereco || companyAddress?.endereco || "",
        idBairro: selectedAddress?.idBairro || defaultAddress?.idBairro || companyAddress?.idBairro || 0,
        bairro: selectedAddress?.bairro || defaultAddress?.bairro || companyAddress?.bairro || "",
        taxaEntrega: 0,
        numero: selectedAddress?.numero || defaultAddress?.numero || companyAddress?.numero || "",
        complemento: selectedAddress?.complemento || defaultAddress?.complemento || companyAddress?.complemento || "",
        pontoReferencia: selectedAddress?.pontoReferencia || defaultAddress?.pontoReferencia || "",
        idCidade: selectedAddress?.idCidade || defaultAddress?.idCidade || companyAddress?.idCidade || 0,
        UF: selectedAddress?.UF || defaultAddress?.UF || companyAddress?.UF || "",
        enderecoPadrao: selectedAddress?.enderecoPadrao ?? defaultAddress?.enderecoPadrao ?? false,
        taxa: 0,
      };
    }

    return {
      idEndereco: selectedAddress?.idEndereco ?? defaultAddress?.idEndereco ?? 0,
      idCliente: customer?.idCliente ?? 0,
      idEmpresa: companyId,
      cep: checkout.cep,
      endereco: checkout.endereco,
      idBairro: selectedNeighborhood?.idBairro ?? 0,
      bairro: selectedNeighborhood?.descricao ?? "",
      taxaEntrega: deliveryFee,
      numero: checkout.numero,
      complemento: checkout.complemento,
      pontoReferencia: checkout.pontoReferencia,
      idCidade: selectedAddress?.idCidade || defaultAddress?.idCidade || companyAddress?.idCidade || 0,
      UF: selectedAddress?.UF || defaultAddress?.UF || companyAddress?.UF || "",
      enderecoPadrao: true,
      taxa: deliveryFee,
    };
  }

  function isStoreClosedError(message: string): boolean {
    const normalized = message.toLowerCase();
    return normalized.includes("fechado agora") || normalized.includes("fora do horario de funcionamento");
  }

  async function handleClosedStoreDuringFinalize() {
    await showLegacyWarning("Atencao", "ixee estamos fechado agora...");
    setCart([]);
    setActiveProduct(null);
    setEditingCartItemId(null);
    setDraft(emptyDraft());
    resetCheckoutAfterOrder(customer);
    openLogin("home");
  }

  async function prepareOrderPayload(
    payment: FormaPagamento,
    options?: { skipStoreOpenCheck?: boolean },
  ): Promise<PedidoPayload> {
    const resolvedTipoEntrega = resolveTipoEntrega(
      checkout.tipoEntrega,
      catalog?.configuracao.permiteRetiradaNoLocal === true,
    );

    if (!cart.length) throw new Error("Adicione ao menos um item ao carrinho.");
    if (!customer?.idCliente) throw new Error("Faca o login do cliente antes de finalizar.");
    if (!checkout.nome.trim()) throw new Error("Informe o nome do cliente.");
    if (!digitsOnly(checkout.telefone)) throw new Error("Informe o telefone com DDD.");
    const integratedPixPayment = shouldUseIntegratedPix(payment);
    if (payment.pagamentoOnline && !integratedPixPayment && !checkout.email.trim()) {
      throw new Error("Informe o email do cliente para gerar o PIX.");
    }
    if (!payment) throw new Error("Selecione a forma de pagamento.");
    if (pedidoMinimo > 0 && subtotalSemEntrega < pedidoMinimo) {
      throw new Error(`Pedido minimo nao atingido. Valor minimo: ${formatMoney(pedidoMinimo)}`);
    }
    if (catalog && !catalog.aberta && !options?.skipStoreOpenCheck) throw new Error("ixee estamos fechado agora...");
    if (payment.permiteTroco && valorAReceber > 0 && valorAReceber < total) {
      throw new Error("Valor menor que o total do pedido.");
    }

    const address = buildAddress(resolvedTipoEntrega);
    if (resolvedTipoEntrega === "D" && (!address.endereco || !address.numero || !address.idBairro)) {
      throw new Error("Preencha endereco, numero e bairro antes de finalizar.");
    }

    const addressesToPersist =
      resolvedTipoEntrega === "D"
        ? customer?.enderecos.length
          ? customer.enderecos
          : [address]
        : customer?.enderecos ?? [];

    const customerEmail = checkout.email.trim() || customer.email.trim();
    const pixEmail = integratedPixPayment ? customerEmail || fallbackPixEmail(companyId, customer, checkout.telefone) : customerEmail;
    const savedCustomer = await salvarCliente(companyId, {
      idCliente: customer.idCliente,
      idEmpresa: companyId,
      nome: checkout.nome,
      email: customerEmail,
      senha: customer?.senha ?? "",
      celular: digitsOnly(customer?.celular || checkout.telefone),
      telefone: digitsOnly(customer?.telefone || ""),
      enderecos: addressesToPersist,
    });

    syncCustomer(savedCustomer);
    const payloadCustomer = integratedPixPayment && !savedCustomer.email.trim()
      ? { ...savedCustomer, email: pixEmail }
      : savedCustomer;

    const productCache = new Map<number, Promise<Produto>>();
    const normalizedItems = await Promise.all(
      cart.map(async (item) => {
        const cachedProduct = productCache.get(item.produto.codigo);
        const currentProductPromise =
          cachedProduct ?? fetchProdutoDetalhe(companyId, item.produto.codigo).catch(() => item.produto);
        productCache.set(item.produto.codigo, currentProductPromise);
        const currentProduct = await currentProductPromise;

        const supportsSize = productSupportsSize(currentProduct);
        const normalizedSize = supportsSize && item.tamanho.trim()
          ? remapProductSize(currentProduct, item.tamanho, item.produto)
          : "";

        if (supportsSize && item.tamanho.trim() && !normalizedSize) {
          throw new Error(`O tamanho selecionado para ${item.produto.descricao} nao esta mais disponivel.`);
        }

        const normalizedFractions = await Promise.all(
          item.fracoes.map(async (fraction) => {
            const cachedFraction = productCache.get(fraction.produto.codigo);
            const currentFractionPromise =
              cachedFraction ?? fetchProdutoDetalhe(companyId, fraction.produto.codigo).catch(() => fraction.produto);
            productCache.set(fraction.produto.codigo, currentFractionPromise);

            return {
              quantidade: fraction.quantidade,
              produto: await currentFractionPromise,
            };
          }),
        );

        return {
          ...item,
          produto: currentProduct,
          tamanho: normalizedSize,
          fracoes: normalizedFractions,
        };
      }),
    );

    return {
      cliente: payloadCustomer,
      endereco: address,
      formaPagamento: payment,
      itens: normalizedItems.map((item) => ({
        quantidade: item.quantidade,
        tamanho: item.tamanho,
        observacao: item.observacao,
        produto: item.produto,
        opcionais: item.opcionais.map((option) => ({
          quantidade: option.quantidade,
          opcional: option.opcional,
        })),
        fracoes: item.fracoes.map((fraction) => ({
          quantidade: fraction.quantidade,
          produto: fraction.produto,
        })),
      })),
      observacao: checkout.observacao,
      tipoEntrega: resolvedTipoEntrega,
      valorAReceber: payment.permiteTroco ? valorAReceber : 0,
    };
  }

  function applyRecoveredOrder(pedido: PedidoRecuperado, nextCart: CartItem[], options?: { priceWasUpdated?: boolean }) {
    const nextTipoEntrega = resolveTipoEntrega(pedido.tipoEntrega === "R" ? "R" : "D", allowPickup);
    const nextAddressId =
      pedido.endereco.idEndereco ||
      pedido.cliente.enderecos.find((item) => item.enderecoPadrao)?.idEndereco ||
      pedido.cliente.enderecos[0]?.idEndereco ||
      0;

    syncCustomer(pedido.cliente);
    clearTrackedOrderState();
    setSelectedAddressId(nextAddressId);
    setCart(nextCart);
    setPaymentSession(null);
    setPaymentConfirmationBlocked(false);
    setShowCheckout(false);
    setShowCheckoutAddressSelector(false);
    setShowNewAddressForm(false);
    setShowTrocoModal(false);
    setShowHistoryPanel(false);
    setScreen("home");
    // Abre a sacola para o cliente conferir, editar ou excluir os itens resgatados
    // antes de confirmar o pedido.
    setShowCartPanel(nextCart.length > 0);
    setCheckout((current) => ({
      ...current,
      nome: pedido.cliente.nome,
      email: pedido.cliente.email,
      telefone: pedido.cliente.celular || pedido.cliente.telefone,
      cep: pedido.endereco.cep || current.cep,
      endereco: pedido.endereco.endereco || current.endereco,
      numero: pedido.endereco.numero || current.numero,
      complemento: pedido.endereco.complemento || current.complemento,
      pontoReferencia: pedido.endereco.pontoReferencia || current.pontoReferencia,
      bairroId: pedido.endereco.idBairro || current.bairroId,
      tipoEntrega: nextTipoEntrega,
      formaPagamentoId: pedido.formaPagamento.id || current.formaPagamentoId || payments[0]?.id || 0,
      valorAReceber: formatCurrencyInput(pedido.valorAReceber),
      observacao: pedido.observacao,
    }));
    setError("");
    setMessage(
      options?.priceWasUpdated
        ? "Pedido carregado com valores atualizados. Confira, edite ou exclua itens antes de finalizar."
        : "Pedido carregado novamente. Confira, edite ou exclua itens antes de finalizar.",
    );
  }

  async function handleRepeatOrder(saleId: number, sourceSale?: VendaHistorico | null) {
    if (catalogOnlyMode) {
      await showLegacyValidation("Cardapio online", "Este cardapio e somente para consulta.");
      return;
    }

    if (!customer?.idCliente) {
      await showLegacyWarning("Atencao", "Faca o login do cliente antes de repetir o pedido.");
      return;
    }

    const confirmed = await showLegacyConfirm("Pedir novamente?", "Confirma repetir esse pedido?");
    if (!confirmed) {
      return;
    }

    setRepeatingSaleId(saleId);
    setMessage("");
    setError("");

    try {
      const pedido = await repetirPedido(companyId, customer.idCliente, saleId, customer);
      const repeatAnalysis = await analyzeRecoveredOrder(pedido, sourceSale);

      if (repeatAnalysis.unavailableProducts.length) {
        await showLegacyWarning(
          "Pedido indisponivel",
          `Nao sera permitido repetir esse pedido, pois os seguintes produto(s) estao em falta: ${repeatAnalysis.unavailableProducts.join(", ")}.`,
        );
        return;
      }

      if (repeatAnalysis.fractionIssues.length) {
        await showLegacyWarning(
          "Combinacao indisponivel",
          `Nao sera permitido repetir esse pedido, pois a loja agora aceita no maximo ${maxFractionParts} sabores por item: ${repeatAnalysis.fractionIssues
            .map((issue) => `${issue.description} (${issue.previousParts} sabores)`)
            .join(", ")}.`,
        );
        return;
      }

      if (repeatAnalysis.sizeIssues.length) {
        await showLegacyWarning(
          repeatAnalysis.sizeIssues.length === 1 ? "Tamanho alterado" : "Tamanhos alterados",
          `Nao sera permitido repetir esse pedido, pois o(s) tamanho(s) anterior(es) nao esta(ao) mais disponivel(is): ${repeatAnalysis.sizeIssues
            .map((issue) => `${issue.description} (${issue.previousSize})`)
            .join(", ")}.`,
        );
        return;
      }

      if (repeatAnalysis.priceChanges.length) {
        const confirmedPriceUpdate = await showLegacyHtmlConfirm(
          repeatAnalysis.priceChanges.length === 1 ? "Produto com preco atualizado" : "Produtos com preco atualizado",
          buildRepeatPriceChangeHtml(repeatAnalysis.priceChanges),
        );

        if (!confirmedPriceUpdate) {
          return;
        }
      }

      applyRecoveredOrder(pedido, repeatAnalysis.nextCart, { priceWasUpdated: repeatAnalysis.priceChanges.length > 0 });
    } catch (repeatError) {
      setError(repeatError instanceof Error ? repeatError.message : "Erro ao copiar dados do pedido.");
    } finally {
      setRepeatingSaleId(null);
    }
  }

  async function startPixPayment(payment: FormaPagamento) {
    setSavingOrder(true);
    setPaymentConfirmationBlocked(false);
    setMessage("");
    setError("");
    try {
      const pedido = await prepareOrderPayload(payment, { skipStoreOpenCheck: true });
      const pagamento = await iniciarPagamentoPix(companyId, pedido);
      setPaymentSession({ pedido, pagamento });
      setShowTrocoModal(false);
      setShowCheckout(false);
    } catch (paymentError) {
      const message = paymentError instanceof Error ? paymentError.message : "Erro ao iniciar pagamento.";
      setError(message);
      if (
        message.startsWith("Informe ") ||
        message.startsWith("Preencha ") ||
        message.startsWith("Selecione ")
      ) {
        await showLegacyValidation("Falta um detalhe no pedido", message);
      } else {
        await showLegacyError("Erro ao iniciar PIX", message);
      }
    } finally {
      setSavingOrder(false);
    }
  }

  function closePayment() {
    setPaymentSession(null);
    setPaymentConfirmationBlocked(false);
    setShowCheckoutAddressSelector(false);
    setShowCheckout(true);
    setError("");
  }

  async function handleFinalizeOrder() {
    setSavingOrder(true);
    setMessage("");
    setError("");
    try {
      if (!selectedPayment) throw new Error("Selecione a forma de pagamento.");

      if (shouldUseIntegratedPix(selectedPayment)) {
        setSavingOrder(false);
        await startPixPayment(selectedPayment);
        return;
      }

      if (catalog && !catalog.aberta) {
        await handleClosedStoreDuringFinalize();
        return;
      }

      const payload = await prepareOrderPayload(selectedPayment);
      const response = await criarPedido(companyId, payload);
      setCart([]);
      resetCheckoutAfterOrder(payload.cliente);
      await openOrderTracking(payload.cliente);
      setMessage(`Pedido #${response.idVenda} criado com sucesso.`);
    } catch (orderError) {
      const message = orderError instanceof Error ? orderError.message : "Erro ao finalizar o pedido.";
      if (isStoreClosedError(message) && !shouldUseIntegratedPix(selectedPayment)) {
        await handleClosedStoreDuringFinalize();
        return;
      }

      if (
        message.startsWith("Informe ") ||
        message.startsWith("Preencha ") ||
        message.startsWith("Selecione ")
      ) {
        setError("");
        await showLegacyValidation("Falta um detalhe no pedido", message);
        return;
      }

      setError(message);
    } finally {
      setSavingOrder(false);
    }
  }

  async function handlePedidoNavigation() {
    setMessage("");
    setError("");

    if (catalogOnlyMode) {
      await showLegacyValidation("Cardapio online", "Este cardapio e somente para consulta.");
      return;
    }

    if (cart.length) {
      openCheckout();
      return;
    }

    openHomeScreen();
    await showLegacyWarning("Sacola vazia", "Adicione itens na sacola antes de seguir para o fechamento do pedido.");
  }

  async function handleTrackingNavigation() {
    setMessage("");
    setError("");

    if (!customer?.idCliente) {
      openLogin("tracking");
      return;
    }

    try {
      await openOrderTracking(customer);
    } catch (trackingError) {
      setError(trackingError instanceof Error ? trackingError.message : "Erro ao abrir acompanhamento do pedido.");
    }
  }

  function renderTableAccessGate() {
    const companyName = catalog?.empresa.nome || "Cardapio digital";
    const loadingStatus = loading ? "Sincronizando cardapio..." : "A mesa sera vinculada a esta sessao do cardapio.";

    return (
      <main className="rpmenu-qr-shell">
        <section className="rpmenu-qr-card">
          <div className="rpmenu-qr-card__brand">
            <div className="rpmenu-qr-card__mark">RP</div>
            <div>
              <strong>RP MENU</strong>
              <span>{companyName}</span>
            </div>
          </div>

          <div className="rpmenu-qr-card__content">
            <div className="rpmenu-qr-card__copy">
              <span className="rpmenu-qr-card__eyebrow">Acesso da mesa</span>
              <h1>Leia o QR Code da mesa</h1>
              <p>Abra o cardapio pelo QR Code impresso na mesa. Se necessario, informe o numero manualmente.</p>
            </div>

            <form
              className="rpmenu-qr-form"
              onSubmit={(event) => {
                event.preventDefault();
                void handleTableAccessSubmit();
              }}
            >
              <label htmlFor="rpmenu-table-input">Mesa</label>
              <div className="rpmenu-qr-form__row">
                <input
                  id="rpmenu-table-input"
                  inputMode="numeric"
                  placeholder="Ex.: 1 ou link do QR Code"
                  value={tableInput}
                  onChange={(event) => setTableInput(event.target.value)}
                />
                <button type="submit">Abrir cardapio</button>
              </div>
              <small>{loadingStatus}</small>
            </form>
          </div>
        </section>

        <footer className="rpmenu-qr-footer">RPMENU {appVersion}</footer>
      </main>
    );
  }

  function renderCartChrome() {
    if (catalogOnlyMode) {
      return null;
    }

    return (
      <>
        {cartFeedback ? (
          <div key={cartFeedback.id} className="rpfood-cart-toast" role="status" aria-live="polite">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <polyline points="20 6 9 17 4 12" />
            </svg>
            <span className="rpfood-cart-toast__text">{cartFeedback.text}</span>
            <button type="button" className="rpfood-cart-toast__action" onClick={openCartPanel}>
              Ver sacola
            </button>
          </div>
        ) : null}

        <button
          id="barVerSacola"
          type="button"
          onClick={toggleCartPanel}
          style={{
            position: "fixed",
            bottom: "calc(var(--rpfood-bottom-nav-total-height) + 4px)",
            left: 0,
            right: 0,
            zIndex: 1050,
            background: "linear-gradient(90deg,#1B4F72 0%,#2e86c1 100%)",
            color: "#fff",
            padding: "8px 12px",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            boxShadow: "0 -2px 10px rgba(0,0,0,0.15)",
            gap: 6,
            border: "none",
          }}
        >
          <span
            id="barNomeCliente"
            style={{
              fontWeight: 600,
              fontSize: "0.8rem",
              whiteSpace: "nowrap",
              overflow: "hidden",
              textOverflow: "ellipsis",
              maxWidth: "35%",
              display: "flex",
              alignItems: "center",
              gap: 4,
              minWidth: 0,
            }}
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}>
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
              <circle cx="12" cy="7" r="4" />
            </svg>
            {customer?.nome || ""}
          </span>
          <div style={{ display: "flex", alignItems: "center", gap: 4, flexShrink: 0 }}>
            <svg height="20" width="20" viewBox="0 -31 512.00026 512" fill="#fff" style={{ flexShrink: 0 }}>
              <path d="m164.960938 300.003906h.023437c.019531 0 .039063-.003906.058594-.003906h271.957031c6.695312 0 12.582031-4.441406 14.421875-10.878906l60-210c1.292969-4.527344.386719-9.394532-2.445313-13.152344-2.835937-3.757812-7.269531-5.96875-11.976562-5.96875h-366.632812l-10.722657-48.253906c-1.527343-6.863282-7.613281-11.746094-14.644531-11.746094h-90c-8.285156 0-15 6.714844-15 15s6.714844 15 15 15h77.96875c1.898438 8.550781 51.3125 230.917969 54.15625 243.710938-15.941406 6.929687-27.125 22.824218-27.125 41.289062 0 24.8125 20.1875 45 45 45h272c8.285156 0 15-6.714844 15-15s-6.714844-15-15-15h-272c-8.269531 0-15-6.730469-15-15 0-8.257812 6.707031-14.976562 14.960938-14.996094zm312.152343-210.003906-51.429687 180h-248.652344l-40-180zm0 0" />
              <path d="m150 405c0 24.8125 20.1875 45 45 45s45-20.1875 45-45-20.1875-45-45-45-45 20.1875-45 45zm45-15c8.269531 0 15 6.730469 15 15s-6.730469 15-15 15-15-6.730469-15-15 6.730469-15 15-15zm0 0" />
              <path d="m362 405c0 24.8125 20.1875 45 45 45s45-20.1875 45-45-20.1875-45-45-45-45 20.1875-45 45zm45-15c8.269531 0 15 6.730469 15 15s-6.730469 15-15 15-15-6.730469-15-15 6.730469-15 15-15zm0 0" />
            </svg>
            <span style={{ fontWeight: 700, fontSize: "0.85rem" }}>Sacola</span>
            <span
              id="badgeQtdSacola"
              className={`badge bg-danger rounded-circle${cartFeedback ? " rpfood-cart-badge--pulse" : ""}`}
              style={{ fontSize: "0.7rem" }}
            >
              {cartItemsCount}
            </span>
            <span id="barSacolaValor" style={{ fontWeight: 800, fontSize: "0.95rem" }}>
              {formatMoney(total)}
            </span>
          </div>
        </button>

        {showCartPanel ? (
          <>
            <div id="painelSacola" className="rpfood-cart-panel">
              <div id="painelSacolaCabecalho" className="rpfood-cart-panel__header">
                <h5 style={{ margin: 0, fontWeight: 700, color: "#1B4F72" }}>Itens do Pedido</h5>
                <button type="button" onClick={closeCartPanel} style={{ background: "none", border: "none", fontSize: "1.6rem", lineHeight: 1, color: "#999", padding: "0 4px" }}>
                  &times;
                </button>
              </div>
              <div id="painelSacolaConteudo" className="rpfood-cart-panel__body">
                <div id="div_itens_do_pedido">
                  {!cart.length ? <p style={{ color: "#999", textAlign: "center", padding: "20px 0" }}>Nenhum item no pedido</p> : null}
                  {cart.length ? (
                    <p className="rpfood-cart-panel__hint">
                      Confira os itens abaixo. Voce pode ajustar a quantidade, tocar em <strong>Editar</strong> ou{" "}
                      <strong>Excluir</strong> antes de finalizar.
                    </p>
                  ) : null}
                  {cart.map((item, index) => (
                    <div key={item.id}>
                      <div className="rpfood-item-separator" style={{ marginTop: index === 0 ? 0 : 12 }}>
                        <span>Item {index + 1}</span>
                        <hr />
                      </div>
                      <div className="row">
                        <div className="col-sm-12 col-xl-12 col-lg-12 col-xxl-6 col-md-6">
                          <div className="order-check d-flex align-items-center my-3">
                            <div className="dlab-media">
                              <SmartImage
                                src={item.produto.imageUrl}
                                placeholderSrc={item.produto.thumbnailUrl ?? item.produto.imageUrl}
                                alt={item.produto.descricao}
                                width={72}
                                height={72}
                                wrapperClassName="rpfood-cart-panel__media-image"
                                loading="lazy"
                              />
                            </div>
                            <div className="dlab-info">
                              <div className="d-flex align-items-center justify-content-between">
                                <h5 className="dlab-title text-wrap text-orange">
                                  {item.produto.descricao} {item.tamanho ? `[Tamanho: ${item.tamanho} ]` : ""}
                                </h5>
                                <div className="d-flex align-content-end justify-content-end">
                                  <h5 className="dlab-title text-wrap text-orange">{formatMoney(item.valorUnitario)}</h5>
                                </div>
                              </div>
                              <div className="d-flex align-items-center justify-content-between">
                                <div className="quntity">
                                  <button data-decrease onClick={() => handleChangeCartItemQuantity(item.id, -1)}>
                                    -
                                  </button>
                                  <input data-value type="text" value={item.quantidade} readOnly />
                                  <button data-increase onClick={() => handleChangeCartItemQuantity(item.id, 1)}>
                                    +
                                  </button>
                                </div>
                                {formatMoney(item.valorTotal)}
                              </div>
                              <div className="d-flex align-items-center justify-content-between">
                                <span>{item.observacao}</span>
                                <div className="rpfood-cart-item-actions">
                                  <button
                                    type="button"
                                    onClick={() => editCartItem(item)}
                                    className="rpfood-cart-item-actions__edit"
                                  >
                                    Editar
                                  </button>
                                  <button
                                    type="button"
                                    onClick={() => void handleRemoveCartItem(item)}
                                    className="rpfood-cart-item-actions__remove"
                                    aria-label={`Remover ${item.produto.descricao} da sacola`}
                                  >
                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" aria-hidden="true">
                                      <line x1="18" y1="6" x2="6" y2="18" />
                                      <line x1="6" y1="6" x2="18" y2="18" />
                                    </svg>
                                    Excluir
                                  </button>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>

                      {item.fracoes.map((fraction) => (
                        <div key={`${item.id}-fracao-${fraction.produto.codigo}`} className="order-check d-flex align-items-center my-3">
                          <div className="dlab-media">
                            <SmartImage
                              src={fraction.produto.imageUrl}
                              placeholderSrc={fraction.produto.thumbnailUrl ?? fraction.produto.imageUrl}
                              alt={fraction.produto.descricao}
                              width={72}
                              height={72}
                              wrapperClassName="rpfood-cart-panel__media-image"
                              loading="lazy"
                            />
                          </div>
                          <div className="dlab-info">
                            <div className="d-flex align-items-center justify-content-between">
                              <h5 className="dlab-title text-wrap text-orange">(+sabor) {fraction.produto.descricao}</h5>
                            </div>
                          </div>
                        </div>
                      ))}

                      {item.opcionais.map((option) => (
                        <div key={`${item.id}-opcional-${option.opcional.codigo}`} className="order-check d-flex align-items-stretch my-3">
                          <div className="dlab-info">
                            <div className="d-flex align-items-stretch justify-content-between">
                              <h6 className="dlab-title text-wrap text-orange">(UP).. {option.opcional.descricao}</h6>
                              <h6 className="dlab-title text-wrap text-orange">{formatMoney(option.quantidade * option.unitPrice)}</h6>
                            </div>
                            <div className="d-flex align-items-center justify-content-between">
                              <span className="text-wrap text-orange">
                                {option.quantidade}x {formatMoney(option.unitPrice)}
                              </span>
                              <div className="quntity">
                                <button data-decrease onClick={() => void handleChangeCartOption(item.id, option.opcional.codigo, -1)}>
                                  -
                                </button>
                                <input data-value type="text" value={option.quantidade} readOnly />
                                <button data-increase onClick={() => void handleChangeCartOption(item.id, option.opcional.codigo, 1)}>
                                  +
                                </button>
                              </div>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  ))}
                </div>
              </div>
              <div id="painelSacolaRodape" className="rpfood-cart-panel__footer">
                <button type="button" onClick={() => openCheckout()} style={{ width: "100%", padding: 14, background: "#1B4F72", color: "#fff", border: "none", borderRadius: 10, fontWeight: 700, fontSize: "1rem" }}>
                  Finalizar Pedido
                </button>
                <button
                  type="button"
                  id="btnEsvaziarSacola"
                  className="rpfood-cart-clear"
                  onClick={() => void handleClearCart()}
                  disabled={!cart.length}
                >
                  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                    <polyline points="3 6 5 6 21 6" />
                    <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
                    <path d="M10 11v6M14 11v6" />
                    <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" />
                  </svg>
                  Esvaziar toda a sacola
                </button>
              </div>
            </div>
            <div
              id="painelSacolaOverlay"
              onClick={closeCartPanel}
              style={{ display: "block", position: "fixed", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(0,0,0,0.4)", zIndex: 1048 }}
            />
          </>
        ) : null}
      </>
    );
  }

  function renderBottomNavigation(onHomeClick?: () => void) {
    return (
      <nav
        id="bottomNavBar"
        className="rpfood-bottom-nav"
        style={{
          position: "fixed",
          bottom: 0,
          left: 0,
          right: 0,
          zIndex: 1051,
          background: "#fff",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: 2,
          height: "var(--rpfood-bottom-nav-total-height)",
          boxShadow: "0 -2px 10px rgba(0,0,0,0.1)",
          borderTop: "1px solid #eee",
          padding:
            "0 calc(env(safe-area-inset-right, 0px) + 4px) calc(env(safe-area-inset-bottom, 0px) + 4px) calc(env(safe-area-inset-left, 0px) + 4px)",
        }}
      >
        <span className="rpfood-bottom-nav-version" aria-label="Versao do sistema">
          v{appVersion}
        </span>
        <button type="button" className="rpfood-nav-button" onClick={onHomeClick ?? (() => window.scrollTo({ top: 0, behavior: "smooth" }))}>
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#1B4F72" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
            <polyline points="9 22 9 12 15 12 15 22" />
          </svg>
          <span>Home</span>
        </button>

        {!catalogOnlyMode ? (
          <button type="button" className="rpfood-nav-button" onClick={() => void handlePedidoNavigation()} style={{ position: "relative" }}>
            <svg height="20" width="20" viewBox="0 -31 512.00026 512" fill="#1B4F72">
              <path d="m164.960938 300.003906h.023437c.019531 0 .039063-.003906.058594-.003906h271.957031c6.695312 0 12.582031-4.441406 14.421875-10.878906l60-210c1.292969-4.527344.386719-9.394532-2.445313-13.152344-2.835937-3.757812-7.269531-5.96875-11.976562-5.96875h-366.632812l-10.722657-48.253906c-1.527343-6.863282-7.613281-11.746094-14.644531-11.746094h-90c-8.285156 0-15 6.714844-15 15s6.714844 15 15 15h77.96875c1.898438 8.550781 51.3125 230.917969 54.15625 243.710938-15.941406 6.929687-27.125 22.824218-27.125 41.289062 0 24.8125 20.1875 45 45 45h272c8.285156 0 15-6.714844 15-15s-6.714844-15-15-15h-272c-8.269531 0-15-6.730469-15-15 0-8.257812 6.707031-14.976562 14.960938-14.996094zm312.152343-210.003906-51.429687 180h-248.652344l-40-180zm0 0" />
              <path d="m150 405c0 24.8125 20.1875 45 45 45s45-20.1875 45-45-20.1875-45-45-45-45 20.1875-45 45zm45-15c8.269531 0 15 6.730469 15 15s-6.730469 15-15 15-15-6.730469-15-15 6.730469-15 15-15zm0 0" />
              <path d="m362 405c0 24.8125 20.1875 45 45 45s45-20.1875 45-45-20.1875-45-45-45-45 20.1875-45 45zm45-15c8.269531 0 15 6.730469 15 15s-6.730469 15-15 15-15-6.730469-15-15 6.730469-15 15-15zm0 0" />
            </svg>
            <span id="badgeQtdNav" className={`badge bg-danger rounded-circle${cartFeedback ? " rpfood-cart-badge--pulse" : ""}`} style={{ position: "absolute", top: 0, right: "calc(50% - 18px)", fontSize: "0.55rem", minWidth: 14, height: 14, display: "flex", alignItems: "center", justifyContent: "center" }}>
              {cartItemsCount}
            </span>
            <span>Pedido</span>
          </button>
        ) : null}

        {!catalogOnlyMode ? (
          <button type="button" id="btnNavPerfil" className="rpfood-nav-button" onClick={() => openProfileScreen()}>
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#1B4F72" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
              <circle cx="12" cy="7" r="4" />
            </svg>
            <span>Perfil</span>
          </button>
        ) : null}

        {!catalogOnlyMode && loggedCustomer ? (
          <button type="button" id="btnNavEnderecos" className="rpfood-nav-button" onClick={() => void openAddressesScreen()}>
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#1B4F72" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
              <circle cx="12" cy="10" r="3" />
            </svg>
            <span>Endereços</span>
          </button>
        ) : null}

        {!catalogOnlyMode && loggedCustomer ? (
          <button type="button" id="btnNavAcompanhamento" className="rpfood-nav-button rpfood-nav-button--small" onClick={() => void handleTrackingNavigation()}>
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#1B4F72" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M9 11l3 3L22 4" />
              <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
            </svg>
            <span>Acompanhar</span>
          </button>
        ) : null}

        <button type="button" className="rpfood-nav-button" onClick={() => void openAboutScreen()}>
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#1B4F72" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="12" cy="12" r="10" />
            <line x1="12" y1="16" x2="12" y2="12" />
            <line x1="12" y1="8" x2="12.01" y2="8" />
          </svg>
          <span>Sobre</span>
        </button>
      </nav>
    );
  }

  if (!isProtectedAdminScreen(screen) && !tableAccess) {
    return renderTableAccessGate();
  }

  if (activeProduct) {
    const selectedFractions = activeFractions
      .filter((item) => (draft.fracoes[item.codigo] ?? 0) > 0)
      .map((item) => ({
        quantidade: draft.fracoes[item.codigo] ?? 0,
        produto: item,
      }));

    return (
      <div id="main-wrapper" className="show dlab-overflow">
      <div
        className="content-body"
        style={{ paddingBottom: 280, marginLeft: 0, paddingTop: 0, marginTop: 0 }}
      >
          <div
            className="container"
            style={{ maxWidth: "100%", paddingLeft: 10, paddingRight: 10, paddingTop: 0, marginTop: 0 }}
          >
            <PedidoItemView
              config={catalog?.configuracao ?? null}
              draft={draft}
              fractionProducts={activeFractions}
              loading={loadingProduct}
              maxFractionParts={maxFractionParts}
              onChangeFraction={handleChangeFraction}
              onChangeObservation={(value) => setDraft((current) => ({ ...current, observacao: value }))}
              onChangeOptional={handleChangeOptional}
              onChangeQuantity={(quantity) =>
                setDraft((current) => ({ ...current, quantidade: Math.max(1, quantity) }))
              }
              onClose={discardProductDetail}
              onConfirm={addToCart}
              onSelectSize={(size) => void handleSelectItemSize(size)}
              priceLabel={formatMoney(calculateItemUnitPrice(activeProduct, draft.tamanho, selectedFractions))}
              product={activeProduct}
              productOptions={activeOptions}
              readOnly={catalogOnlyMode}
            />
          </div>
        </div>
        {renderCartChrome()}
        {renderBottomNavigation(closeProductDetail)}
      </div>
    );
  }

  if (paymentSession) {
    return (
      <>
        <PedidoPagamentoView
          error={error}
          formatMoney={formatMoney}
          loading={loadingPayment || confirmingPayment}
          message={message}
          onBack={closePayment}
          payment={paymentSession.pagamento}
        />
        {renderBottomNavigation(openHomeScreen)}
      </>
    );
  }

  if (showCheckoutAddressSelector) {
    return (
      <BuscarEnderecoView
        addresses={customer?.enderecos ?? []}
        error={error}
        loading={savingCheckout}
        message={message}
        onBack={closeCheckoutAddressSelector}
        selectedAddressId={selectedAddressId}
        onSelect={(addressId) => {
          void (async () => {
            await handleSelectAddress(addressId);
            setShowCheckoutAddressSelector(false);
          })();
        }}
      />
    );
  }

  if (showCheckout) {
    return (
      <>
        <PedidoFinalizarView
          allowPickup={allowPickup}
          cart={cart}
          checkout={{ ...checkout, tipoEntrega: tipoEntregaPedido }}
          company={catalog?.empresa ?? null}
          usesCep={catalog?.configuracao.utilizaCEP ?? true}
          neighborhoods={neighborhoods}
          customerAddresses={customer?.enderecos ?? []}
          deliveryFee={deliveryFee}
          error={error}
          formatMoney={formatMoney}
          loading={loading}
          message={message}
          newAddress={newAddress}
          onBack={closeCheckout}
          onCancelTroco={handleCancelTroco}
          onChangeObservation={handleObservationChange}
          onChangePayment={handleChangePayment}
          onChangeTrocoValue={(value) => updateCheckout("valorAReceber", value)}
          onCloseNewAddress={closeNewAddressForm}
          onConfirm={() => void handleFinalizeOrder()}
          onConfirmTroco={handleConfirmTroco}
          onLookupCep={() => void handleLookupCep()}
          onOpenAddressSelector={openCheckoutAddressSelector}
          onOpenNewAddress={openNewAddressForm}
          onSaveNewAddress={() => void handleSaveNewAddress()}
          onSelectAddress={(addressId) => void handleSelectAddress(addressId)}
          onSelectTipoEntrega={handleSelectTipoEntrega}
          onUpdateNewAddress={updateNewAddress}
          payments={payments}
          saving={savingOrder || savingCheckout}
          selectedAddress={selectedAddress}
          selectedAddressId={selectedAddressId}
          selectedPayment={selectedPayment}
          showNewAddressForm={showNewAddressForm}
          showTrocoModal={showTrocoModal}
          total={total}
          valorPago={valorPago}
          valorTroco={valorTroco}
        />
        {renderBottomNavigation(openHomeScreen)}
      </>
    );
  }

  if (trackedOrder) {
    return (
      <>
        <PedidoAcompanhamentoView
          error={error}
          formatMoney={formatMoney}
          loading={loadingTracking}
          message={message}
          onBack={closeOrderTracking}
          order={trackedOrder}
        />
        {renderBottomNavigation(openHomeScreen)}
      </>
    );
  }

  if (screen === "login") {
    return (
      <ClienteLoginView
        error={error}
        loading={savingCheckout}
        message={message}
        phone={loginPhone}
        onBack={openHomeScreen}
        onChangePhone={setLoginPhone}
        onOpenRegister={() => {
          setCadastro(emptyCadastroForm());
          setScreen("register");
          setError("");
          setMessage("");
        }}
        onOpenForgotPassword={openForgotPasswordScreen}
        onSubmit={() => void handleLoginSubmit()}
      />
    );
  }

  if (screen === "forgot-password") {
    return (
      <EsqueciMinhaSenhaView
        email={forgotEmail}
        error={error}
        loading={savingCheckout}
        message={message}
        onBack={() => setScreen("login")}
        onChangeEmail={setForgotEmail}
        onSubmit={() => void handleForgotPasswordSubmit()}
      />
    );
  }

  if (screen === "register") {
    return (
      <ClienteCadastroView
        bairros={neighborhoods}
        error={error}
        form={cadastro}
        loading={savingCheckout}
        message={message}
        usesCep={catalog?.configuracao.utilizaCEP ?? true}
        onBack={() => setScreen("login")}
        onLookupCep={() => void handleLookupCadastroCep()}
        onOpenLogin={() => setScreen("login")}
        onSave={() => void handleSaveCadastro()}
        onUpdate={updateCadastro}
      />
    );
  }

  if (screen === "profile") {
    return (
      <ClienteDadosView
        error={error}
        form={perfil}
        loading={savingCheckout}
        message={message}
        onBack={openHomeScreen}
        onSave={() => void handleSaveProfile()}
        onUpdate={updatePerfil}
      />
    );
  }

  if (screen === "new-address") {
    return (
      <NovoEnderecoView
        bairros={neighborhoods}
        error={error}
        form={addressEditor}
        loading={savingCheckout}
        message={message}
        usesCep={catalog?.configuracao.utilizaCEP ?? true}
        onBack={cancelAddressEditor}
        onLookupCep={() => void handleLookupAddressEditorCep()}
        onSave={() => void handleSaveAddressEditor()}
        onUpdate={updateAddressEditor}
      />
    );
  }

  if (screen === "addresses") {
    return (
      <ClienteEnderecoView
        addresses={customer?.enderecos ?? []}
        bairros={neighborhoods}
        editing={editingAddress}
        error={error}
        form={addressEditor}
        loading={savingCheckout}
        message={message}
        usesCep={catalog?.configuracao.utilizaCEP ?? true}
        onBack={openHomeScreen}
        onCancelEdit={cancelAddressEditor}
        onLookupCep={() => void handleLookupAddressEditorCep()}
        onSave={() => void handleSaveAddressEditor()}
        onSelectDefault={(addressId) => void handleSelectDefaultAddress(addressId)}
        onStartCreate={startNewAddressEditor}
        onStartEdit={(addressId) => void startEditAddress(addressId)}
        onUpdate={updateAddressEditor}
      />
    );
  }

  if (screen === "history") {
    return (
      <VendaHistoricoView
        error={error}
        formatMoney={formatMoney}
        history={history}
        loading={loading}
        message={message}
        onBack={openHomeScreen}
        onRepeat={(sale) => void handleRepeatOrder(sale.id, sale)}
        repeatingSaleId={repeatingSaleId}
      />
    );
  }

  if (screen === "about") {
    return (
      <SobreView
        data={aboutData}
        error={error}
        loading={loadingAbout}
        message={message}
        onBack={openHomeScreen}
      />
    );
  }

  if (screen === "products-all") {
    return (
      <>
        <ProdutosTodasCategoriasView
          cartQuantityByProduct={cartQuantityByProduct}
          categories={catalog?.categorias ?? []}
          error={error}
          filter={browseFilter}
          loading={loadingBrowseProducts}
          products={browseProducts}
          selectedCategoryId={browseCategoryId}
          title={browseTitle}
          onBack={openHomeScreen}
          onChangeFilter={setBrowseFilter}
          onSelectCategory={(categoryId) => openCategoryProductsScreen(categoryId)}
          onSelectProduct={(product) => void chooseProduct(product)}
        />
        {renderCartChrome()}
        {renderBottomNavigation(openHomeScreen)}
      </>
    );
  }

  if (screen === "products-category") {
    return (
      <>
        <ProdutosPorCategoriaView
          cartQuantityByProduct={cartQuantityByProduct}
          categories={catalog?.categorias ?? []}
          error={error}
          filter={browseFilter}
          loading={loadingBrowseProducts}
          products={browseProducts}
          selectedCategoryId={browseCategoryId}
          title={browseTitle}
          onBack={openHomeScreen}
          onChangeFilter={setBrowseFilter}
          onSelectCategory={(categoryId) => openCategoryProductsScreen(categoryId)}
          onSelectProduct={(product) => void chooseProduct(product)}
        />
        {renderCartChrome()}
        {renderBottomNavigation(openHomeScreen)}
      </>
    );
  }

  if (screen === "admin-login" || screen === "admin-index" || screen === "admin-index2") {
    const adminLoginScreen = (
      <AdminLoginView
        error={error}
        loading={savingCheckout}
        login={adminLogin}
        message={message}
        onBack={openHomeScreen}
        onChangeLogin={setAdminLogin}
        onChangePassword={setAdminPassword}
        onSubmit={() => void handleAdminLoginSubmit()}
        password={adminPassword}
      />
    );

    let adminScreen = adminLoginScreen;

    if (screen === "admin-index" && adminSession?.token) {
      adminScreen = (
        <AdminDashboardView
          bairros={adminTopBairros}
          clientes={adminTopClientes}
          onLogout={() => void handleAdminLogout()}
          produtos={adminTopProdutos}
          qtdeVendas={loadingAdmin ? "..." : adminQtdeVendas}
          sincronizacao={loadingAdmin ? "Carregando..." : adminSincronizacao}
          taxaEntrega={loadingAdmin ? "0,00" : adminTaxaEntrega}
          valorVendas={loadingAdmin ? "0,00" : adminValorVendas}
        />
      );
    }

    if (screen === "admin-index2" && adminSession?.token) {
      adminScreen = <AdminIndex2View onBack={() => openAdminDashboard("admin-index")} />;
    }

    return <Suspense fallback={<div className="rpfood-lazy-fallback">Carregando painel...</div>}>{adminScreen}</Suspense>;
  }

  if (screen === "not-found") {
    return <Erro404View message={error} onBack={openHomeScreen} />;
  }

  return (
    <div id="main-wrapper" className="show dlab-overflow">
      <div
        className="content-body"
        style={{ paddingBottom: 130, marginLeft: 0, paddingTop: 0, marginTop: 0 }}
      >
        <div
          className="container"
          style={{ maxWidth: "100%", paddingLeft: 10, paddingRight: 10, paddingTop: 0, marginTop: 0 }}
        >
          <div className="rpfood-home-page rpmenu-legacy-home">
            <header className="rpmenu-legacy-topbar" id="divNomeEmpresa">
              <div className="rpmenu-legacy-brand" aria-label="RP MENU">
                <span className="rpmenu-legacy-brand__mark" aria-hidden="true">RP</span>
                <span className="rpmenu-legacy-brand__copy">
                  <strong>RP MENU</strong>
                  <small>{catalog?.empresa.nome || "Cardapio online"}</small>
                </span>
              </div>

              <div className="rpmenu-legacy-topbar__actions">
                <button
                  type="button"
                  className="rpmenu-legacy-icon-button"
                  onClick={() => void openAboutScreen()}
                  aria-label="Abrir dados da loja"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                    <circle cx="12" cy="12" r="10" />
                    <line x1="12" y1="16" x2="12" y2="12" />
                    <line x1="12" y1="8" x2="12.01" y2="8" />
                  </svg>
                  <span>Sobre</span>
                </button>

                {!catalogOnlyMode ? (
                  <button
                    type="button"
                    className="rpmenu-legacy-cart-button"
                    onClick={toggleCartPanel}
                    aria-label="Abrir pedido"
                  >
                    <svg height="21" width="21" viewBox="0 -31 512.00026 512" fill="currentColor" aria-hidden="true">
                      <path d="m164.960938 300.003906h.023437c.019531 0 .039063-.003906.058594-.003906h271.957031c6.695312 0 12.582031-4.441406 14.421875-10.878906l60-210c1.292969-4.527344.386719-9.394532-2.445313-13.152344-2.835937-3.757812-7.269531-5.96875-11.976562-5.96875h-366.632812l-10.722657-48.253906c-1.527343-6.863282-7.613281-11.746094-14.644531-11.746094h-90c-8.285156 0-15 6.714844-15 15s6.714844 15 15 15h77.96875c1.898438 8.550781 51.3125 230.917969 54.15625 243.710938-15.941406 6.929687-27.125 22.824218-27.125 41.289062 0 24.8125 20.1875 45 45 45h272c8.285156 0 15-6.714844 15-15s-6.714844-15-15-15h-272c-8.269531 0-15-6.730469-15-15 0-8.257812 6.707031-14.976562 14.960938-14.996094zm312.152343-210.003906-51.429687 180h-248.652344l-40-180zm0 0" />
                      <path d="m150 405c0 24.8125 20.1875 45 45 45s45-20.1875 45-45-20.1875-45-45-45-45 20.1875-45 45zm45-15c8.269531 0 15 6.730469 15 15s-6.730469 15-15 15-15-6.730469-15-15 6.730469-15 15-15zm0 0" />
                      <path d="m362 405c0 24.8125 20.1875 45 45 45s45-20.1875 45-45-20.1875-45-45-45-45 20.1875-45 45zm45-15c8.269531 0 15 6.730469 15 15s-6.730469 15-15 15-15-6.730469-15-15 6.730469-15 15-15zm0 0" />
                    </svg>
                    <span>Pedido</span>
                    <strong>{cartItemsCount}</strong>
                  </button>
                ) : null}
              </div>
            </header>

            {(message || error || loading) && (
              <div className="rpfood-home-feedback rpmenu-legacy-feedback">
                {loading ? <div className="rpfood-home-feedback__ok">Carregando cardapio...</div> : null}
                {message ? <div className="rpfood-home-feedback__ok">{message}</div> : null}
                {error ? <div className="rpfood-home-feedback__error">{error}</div> : null}
              </div>
            )}

            <section className="rpmenu-legacy-section">
              <div className="rpmenu-legacy-section__head">
                <div>
                  <span>Aqui ta on</span>
                  <h2>Destaques da casa</h2>
                </div>
              </div>

              <RailSlider label="Destaques" railRef={featuredRailRef}>
                <div
                  ref={featuredRailRef}
                  className="swiper-wrapper rpfood-scroll-row rpmenu-legacy-featured-row"
                  id="listadestaques"
                  onPointerDown={featuredRailPointerDown}
                  onPointerMove={featuredRailPointerMove}
                  onPointerUp={featuredRailPointerUp}
                  onPointerCancel={featuredRailPointerCancel}
                  onWheel={handleHorizontalRailWheel}
                  onClickCapture={featuredRailClickCapture}
                >
                  {featuredProducts.slice(0, 20).map((product, index) => (
                    <div
                      key={`destaque-${product.codigo}`}
                      className="swiper-slide rpmenu-legacy-featured-slide"
                      {...clickableCardProps(() => void chooseProduct(product), `Abrir ${product.descricao}`)}
                    >
                      <article className="rpmenu-legacy-featured-card">
                        <div className="rpmenu-legacy-featured-card__media">
                          <SmartImage
                            fluid
                            src={product.imageUrl}
                            placeholderSrc={product.thumbnailUrl ?? product.imageUrl}
                            alt={product.descricao}
                            width={220}
                            height={154}
                            {...getProgressiveImageProps(index, 2)}
                          />
                          {product.imageUrl ? <span className="rpmenu-legacy-featured-card__badge">Ta on</span> : null}
                        </div>
                        <div className="rpmenu-legacy-featured-card__body">
                          <h3>{truncateText(product.descricao, 36)}</h3>
                          <strong>{formatMoney(productPriceBySize(product, defaultProductSize(product)))}</strong>
                        </div>
                      </article>
                    </div>
                  ))}
                </div>
              </RailSlider>
            </section>

            <section className="rpmenu-legacy-section">
              <div className="rpmenu-legacy-section__head">
                <div>
                  <span>Categorias</span>
                  <h2>Escolha por tipo</h2>
                </div>
                <button type="button" onClick={openProductsScreen}>Ver todas</button>
              </div>

              <RailSlider label="Categorias" railRef={categoriesRailRef}>
                <div
                  ref={categoriesRailRef}
                  className="swiper-wrapper rpfood-scroll-row rpmenu-legacy-category-row"
                  id="listaCategorias"
                  onPointerDown={categoriesRailPointerDown}
                  onPointerMove={categoriesRailPointerMove}
                  onPointerUp={categoriesRailPointerUp}
                  onPointerCancel={categoriesRailPointerCancel}
                  onWheel={handleHorizontalRailWheel}
                  onClickCapture={categoriesRailClickCapture}
                >
                  {catalog?.categorias.map((category, index) => (
                    <div
                      key={`categoria-card-${category.codigo}`}
                      className="swiper-slide rpmenu-legacy-category-slide"
                      {...clickableCardProps(
                        () => openCategoryProductsScreen(category.codigo),
                        `Abrir categoria ${category.descricao}`,
                      )}
                    >
                      <article className="rpmenu-legacy-category-card">
                        <div className="rpmenu-legacy-category-card__media">
                          <SmartImage
                            fluid
                            src={category.imageUrl}
                            placeholderSrc={category.thumbnailUrl ?? category.imageUrl}
                            alt={category.descricao}
                            width={132}
                            height={108}
                            {...getProgressiveImageProps(index, 3)}
                          />
                        </div>
                        <h3>{truncateText(category.descricao, 24)}</h3>
                      </article>
                    </div>
                  ))}
                </div>
              </RailSlider>
            </section>

            <section id="categorias_produtos" className="rpmenu-legacy-section rpmenu-legacy-products-section">
              <div className="rpmenu-legacy-section__head">
                <div>
                  <span>Cardapio</span>
                  <h2>Produtos</h2>
                </div>
              </div>

              <div className="rpmenu-legacy-product-grid" id="pills-grid" role="list">
                {allHomeProducts.length ? (
                  allHomeProducts.map((product, productIndex) => (
                    <article
                      key={`home-produto-${product.codigo}`}
                      className="rpmenu-legacy-product-card"
                      {...clickableCardProps(() => void chooseProduct(product), `Abrir ${product.descricao}`)}
                    >
                      <div className="rpmenu-legacy-product-card__media">
                        <SmartImage
                          fluid
                          src={product.imageUrl}
                          placeholderSrc={product.thumbnailUrl ?? product.imageUrl}
                          alt={product.descricao}
                          width={192}
                          height={126}
                          {...getProgressiveImageProps(productIndex, 6)}
                        />
                      </div>
                      <div className="rpmenu-legacy-product-card__body">
                        <h3>{product.descricao}</h3>
                        {product.observacao.trim() ? <p>{truncateText(product.observacao, 72)}</p> : null}
                      </div>
                      <div className="rpmenu-legacy-product-card__footer">
                        <strong>{formatMoney(productPriceBySize(product, defaultProductSize(product)))}</strong>
                        <span>Ver detalhes</span>
                      </div>
                    </article>
                  ))
                ) : (
                  <div className="rpmenu-legacy-empty">
                    {loading ? "Carregando produtos..." : "Nenhum produto disponivel para venda."}
                  </div>
                )}
              </div>
            </section>

          </div>

        </div>
      </div>

      {renderCartChrome()}

      {hasRepeatBanner ? (
        <>
          <div
            id="painelUltimosPedidos"
            style={{
              display: showHistoryPanel ? "block" : "none",
              position: "fixed",
              bottom: 120,
              left: 0,
              right: 0,
              zIndex: 1049,
              background: "#fff",
              maxHeight: "60vh",
              overflowY: "auto",
              borderRadius: "16px 16px 0 0",
              boxShadow: "0 -4px 20px rgba(0,0,0,0.2)",
              padding: 16,
            }}
          >
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
              <h5 style={{ margin: 0, fontWeight: 700, color: "#1B4F72" }}>Ultimos Pedidos</h5>
              <button
                type="button"
                onClick={closeHistoryPanel}
                style={{ background: "none", border: "none", fontSize: "1.3rem", cursor: "pointer", color: "#999" }}
              >
                &times;
              </button>
            </div>
            <div id="div_ultimos_pedidos">
              {!history.length ? <p style={{ color: "#999", textAlign: "center", padding: "20px 0" }}>Nenhum pedido encontrado</p> : null}
              {history.map((sale) => (
                <div key={sale.id} style={{ border: "1px solid #eee", borderRadius: 10, padding: 12, marginBottom: 10 }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
                    <div>
                      <strong style={{ fontSize: "0.95rem", color: "#1B4F72" }}>Pedido #{sale.id}</strong>
                      <br />
                      <span style={{ fontSize: "0.8rem", color: "#888" }}>{formatOrderDate(sale.data)}</span>
                    </div>
                    <strong style={{ color: "#1B4F72", fontSize: "1.05rem" }}>{formatMoney(sale.valorTotal)}</strong>
                  </div>
                  {sale.itens.map((item) => (
                    <div
                      key={`${sale.id}-${item.numeroItem}`}
                      style={{ display: "flex", justifyContent: "space-between", padding: "2px 0", fontSize: "0.85rem", color: "#555" }}
                    >
                      <span>
                        {item.produto.descricao} x
                        {item.quantidade.toLocaleString("pt-BR", {
                          minimumFractionDigits: 0,
                          maximumFractionDigits: 0,
                        })}
                      </span>
                      <span>{formatMoney(item.valorTotalProduto)}</span>
                    </div>
                  ))}
                  <button
                    type="button"
                    onClick={(event) => {
                      event.stopPropagation();
                      void handleRepeatOrder(sale.id, sale);
                    }}
                    disabled={repeatingSaleId === sale.id}
                    style={{
                      width: "100%",
                      marginTop: 8,
                      padding: 10,
                      background: "#1B4F72",
                      color: "#fff",
                      border: "none",
                      borderRadius: 8,
                      fontWeight: 600,
                      fontSize: "0.9rem",
                      cursor: "pointer",
                    }}
                  >
                    Quero de novo
                  </button>
                </div>
              ))}
            </div>
          </div>
          <div
            id="painelUltimosPedidosOverlay"
            onClick={closeHistoryPanel}
            style={{
              display: showHistoryPanel ? "block" : "none",
              position: "fixed",
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              background: "rgba(0,0,0,0.4)",
              zIndex: 1048,
            }}
          />
        </>
      ) : null}

      {renderBottomNavigation()}
    </div>
  );
}

export default App;

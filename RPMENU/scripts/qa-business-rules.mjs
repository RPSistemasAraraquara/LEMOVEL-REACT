import fs from "node:fs/promises";
import path from "node:path";
import { chromium } from "playwright";

const baseUrl = "http://127.0.0.1:4173";
const apiBase = `${baseUrl}/rpfood/v1`;
const reportDir = path.resolve("test-results", "business-rules-qa");
const reportFile = path.resolve("test-results", "QA_REGRAS_RPMENU.md");
const transparentPng = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO2p6Y0AAAAASUVORK5CYII=",
  "base64",
);

const company = {
  idEmpresa: 1,
  nome: "RPMENU",
  razaoSocial: "RPMENU LTDA",
  cnpj: "00000000000199",
  email: "qa@local.test",
  fone1: "(85) 99999-9999",
  endereco: {
    idEndereco: 0,
    idCliente: 0,
    idEmpresa: 1,
    cep: "",
    endereco: "Rua QA",
    enderecoCompleto: "Rua QA - N 100",
    idBairro: 1,
    bairro: "CENTRO",
    taxaEntrega: 8,
    numero: "100",
    complemento: "",
    pontoReferencia: "",
    idCidade: 1,
    UF: "CE",
    enderecoPadrao: false,
    taxa: 8,
  },
};

const category = {
  codigo: 1,
  descricao: "01-PIZZAS",
  imageUrl: `${apiBase}/empresa/1/categoria/1/imagem`,
};

const payment = {
  id: 1,
  descricao: "DINHEIRO",
  permiteTroco: true,
  pagamentoOnline: false,
  pix: false,
};

function productTemplate(overrides = {}) {
  return {
    codigo: 101,
    idEmpresa: 1,
    idGrupo: 1,
    descricao: "PIZZA QA",
    observacao: "Produto QA com opcionais",
    valFinal: 35,
    destaqueWeb: true,
    vendaPorTamanho: true,
    permiteFrac: true,
    valorTamanhoP: 30,
    valorTamanhoM: 40,
    valorTamanhoG: 0,
    valorTamanhoGG: 0,
    valorTamanhoExtra: 0,
    tamanhoP: "P",
    tamanhoM: "M",
    tamanhoG: "",
    tamanhoGG: "",
    tamanhoExtra: "",
    tamanhoPadrao: "P",
    opcionalMinimo: 0,
    opcionalMaximo: 0,
    restringirVenda: false,
    imageUrl: `${apiBase}/empresa/1/produto/101/imagem`,
    ...overrides,
  };
}

function fractionTemplate(code, descricao, overrides = {}) {
  return {
    codigo: code,
    idEmpresa: 1,
    idGrupo: 1,
    descricao,
    observacao: "",
    valFinal: 34,
    destaqueWeb: false,
    vendaPorTamanho: true,
    permiteFrac: true,
    valorTamanhoP: 34,
    valorTamanhoM: 44,
    valorTamanhoG: 0,
    valorTamanhoGG: 0,
    valorTamanhoExtra: 0,
    tamanhoP: "P",
    tamanhoM: "M",
    tamanhoG: "",
    tamanhoGG: "",
    tamanhoExtra: "",
    tamanhoPadrao: "P",
    opcionalMinimo: 0,
    opcionalMaximo: 0,
    restringirVenda: false,
    imageUrl: `${apiBase}/empresa/1/produto/${code}/imagem`,
    ...overrides,
  };
}

function optionEntity(code, descricao, overrides = {}) {
  return {
    codigo: code,
    descricao,
    valor: 5,
    valorTamanhoP: 5,
    valorTamanhoM: 7,
    valorTamanhoG: 0,
    valorTamanhoGG: 0,
    valorTamanhoExtra: 0,
    tamanhoP: "P",
    tamanhoM: "M",
    tamanhoG: "",
    tamanhoGG: "",
    tamanhoExtra: "",
    ...overrides,
  };
}

function optionRelation(code, descricao, overrides = {}) {
  const {
    groupId = 0,
    groupDescription = "",
    opcionalMinimo = 0,
    opcionalMaximo = 0,
    opcional: opcionalOverrides = {},
    ...rest
  } = overrides;

  return {
    codigoOpcional: code,
    IdGuarnicao: groupId,
    Guarnicao:
      groupId > 0
        ? {
            Id: groupId,
            Descricao: groupDescription,
            OpcionalMinimo: opcionalMinimo,
            OpcionalMaximo: opcionalMaximo,
          }
        : null,
    opcional: optionEntity(code, descricao, opcionalOverrides),
    ...rest,
  };
}

function emptyCustomer(overrides = {}) {
  return {
    idCliente: 9001,
    idEmpresa: 1,
    nome: "QA Cliente",
    email: "qa@local.test",
    senha: "",
    celular: "85999999999",
    telefone: "",
    enderecos: [],
    ...overrides,
  };
}

function catalogPayload(configOverrides = {}, products = []) {
  return {
    empresa: company,
    configuracao: {
      utilizaCEP: false,
      pedidoMinimo: 0,
      permiteRetiradaNoLocal: true,
      tempoRetirada: "65 min",
      tempoEntrega: "90 min",
      utilizacontroleopcionais: true,
      integracaoMercadoPago: true,
      ...configOverrides,
    },
    aberta: true,
    categorias: [category],
    destaques: products,
    formasPagamento: [payment],
  };
}

function json(status, value) {
  return {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
    body: Buffer.from(JSON.stringify(value)),
  };
}

function image() {
  return {
    status: 200,
    headers: { "Content-Type": "image/png" },
    body: transparentPng,
  };
}

function buildStorage({ cart = [], customer = null, checkout = null } = {}) {
  const baseCheckout = {
    nome: customer?.nome ?? "",
    email: customer?.email ?? "",
    telefone: customer?.celular ?? "",
    cep: "",
    endereco: "",
    numero: "",
    complemento: "",
    pontoReferencia: "",
    bairroId: 0,
    tipoEntrega: "D",
    formaPagamentoId: 1,
    valorAReceber: "",
    observacao: "",
  };

  return {
    "rpmenu.site.companyId": JSON.stringify(1),
    "rpmenu.site.cart": JSON.stringify(cart),
    "rpmenu.site.customer": JSON.stringify(customer),
    "rpmenu.site.checkout": JSON.stringify(checkout ?? baseCheckout),
  };
}

async function createContext(storage) {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1600, height: 900 },
    locale: "pt-BR",
    timezoneId: "America/Sao_Paulo",
    serviceWorkers: "block",
  });

  await context.addInitScript((seed) => {
    window.__swalCalls = [];
    window.Swal = {
      fire(options) {
        window.__swalCalls.push(options);
        return Promise.resolve({ isConfirmed: true });
      },
    };

    for (const [key, value] of Object.entries(seed)) {
      window.localStorage.setItem(key, value);
    }
  }, storage);

  return { browser, context };
}

async function installMocks(page, config) {
  await page.route(`${apiBase}/**`, async (route) => {
    const request = route.request();
    const url = new URL(request.url());
    const pathname = url.pathname.replace("/rpfood/v1", "");
    const size = url.searchParams.get("tamanho") ?? "";

    if (/\/categoria\/\d+\/imagem$/i.test(pathname) || /\/produto\/\d+\/imagem$/i.test(pathname)) {
      await route.fulfill(image());
      return;
    }

    if (pathname === "/empresa/1/catalogo") {
      await route.fulfill(json(200, config.catalogo));
      return;
    }

    if (pathname === "/empresa/1/forma-pagamento") {
      await route.fulfill(json(200, config.formasPagamento ?? config.catalogo.formasPagamento ?? [payment]));
      return;
    }

    if (pathname === "/empresa/1/bairro") {
      await route.fulfill(json(200, [{ idBairro: 1, descricao: "CENTRO", taxaEntrega: 8 }]));
      return;
    }

    if (pathname === "/empresa/1/sobre") {
      await route.fulfill(
        json(200, {
          empresa: company,
          configuracao: config.catalogo.configuracao,
          horarios: [{ dia: "terça", horaAbertura: "03:00", horaFechamento: "09:00" }],
          formasPagamento: config.formasPagamento ?? config.catalogo.formasPagamento ?? [payment],
        }),
      );
      return;
    }

    if (pathname === "/empresa/1/produto/todos") {
      await route.fulfill(json(200, config.productsAll ?? []));
      return;
    }

    if (/\/empresa\/1\/categoria\/\d+\/produto$/i.test(pathname)) {
      await route.fulfill(json(200, config.productsByCategory ?? []));
      return;
    }

    if (pathname === "/empresa/1/produto/101") {
      await route.fulfill(json(200, config.productDetail));
      return;
    }

    if (pathname === "/empresa/1/produto/101/opcional") {
      await route.fulfill(json(200, config.optionsBySize?.[size] ?? []));
      return;
    }

    if (pathname === "/empresa/1/produto/101/fracao") {
      await route.fulfill(json(200, config.fractionsBySize?.[size] ?? []));
      return;
    }

    if (pathname === "/empresa/1/cliente" && request.method() === "POST") {
      config.lastClientePayload = JSON.parse(request.postData() || "{}");
      await route.fulfill(json(200, config.customerResponse ?? emptyCustomer()));
      return;
    }

    if (/^\/empresa\/1\/cliente\/\d+$/i.test(pathname)) {
      if (request.postData()) {
        config.lastClientePayload = JSON.parse(request.postData() || "{}");
      }
      await route.fulfill(json(200, config.customerResponse ?? emptyCustomer()));
      return;
    }

    if (pathname === "/empresa/1/pedido" && request.method() === "POST") {
      await route.fulfill(json(200, config.orderResponse ?? { idVenda: 99, status: "Pedido enviado", valorTotal: 30, dataPedido: new Date().toISOString() }));
      return;
    }

    if (pathname === "/empresa/1/pagamento/pix" && request.method() === "POST") {
      await route.fulfill(
        json(
          200,
          config.pixResponse ?? {
            idPix: "pix-qa",
            qrCodeBase64: "",
            qrCodeDigitavel: "000201010212PIX-QA",
            qrCodeUrl: "https://pix.local/qa",
            status: "aguardando",
            valorTotal: 30,
          },
        ),
      );
      return;
    }

    await route.fulfill(json(404, { message: `Mock nao configurado para esta rota: ${pathname}` }));
  });
}

async function saveScreenshot(page, fileName) {
  await fs.mkdir(reportDir, { recursive: true });
  await page.screenshot({ path: path.join(reportDir, fileName), fullPage: true });
}

async function attachSwalRecorder(page) {
  await page.evaluate(() => {
    window.__swalCalls = [];

    if (window.Swal?.fire) {
      window.__qaOriginalSwalFire = window.Swal.fire.bind(window.Swal);
      window.Swal.fire = (options) => {
        window.__swalCalls.push(options);
        return Promise.resolve({ isConfirmed: true });
      };
    }
  });
}

async function triggerQuantityButton(page, inputId, action) {
  await page.evaluate(
    ({ id, buttonSelector }) => {
      const input = document.getElementById(id);
      const button = input?.parentElement?.querySelector(buttonSelector);
      if (button) {
        button.click();
      }
    },
    {
      id: inputId,
      buttonSelector: action === "increase" ? "[data-increase]" : "[data-decrease]",
    },
  );
}

async function runSearchScenario() {
  const optionalProduct = productTemplate({
    descricao: "PIZZA QA OPCIONAL",
    opcionalMinimo: 1,
    restringirVenda: true,
  });

  const config = {
    catalogo: catalogPayload({}, [optionalProduct]),
    productsAll: [optionalProduct],
    productsByCategory: [optionalProduct],
    productDetail: optionalProduct,
    optionsBySize: {
      P: [optionRelation(601, "BORDA CHEDDAR")],
      M: [optionRelation(601, "BORDA CHEDDAR")],
    },
    fractionsBySize: {
      P: [optionalProduct],
      M: [optionalProduct],
    },
  };

  const { browser, context } = await createContext(buildStorage());
  const page = await context.newPage();
  try {
    await installMocks(page, config);
    await page.goto(`${baseUrl}/produtostodascategoria.html`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);
    await page
      .locator(
        'input[placeholder="Bora procurar..."], input[placeholder="Digite para filtrar os itens dessa tela."], input[placeholder="Buscar por nome, sabor ou detalhe..."]',
      )
      .first()
      .fill("QA");
    await page.waitForTimeout(300);
    await page.getByRole("button", { name: /Abrir PIZZA QA OPCIONAL/i }).first().click();
    await page.waitForTimeout(1200);

    const bodyText = await page.locator("body").innerText();
    const passed =
      bodyText.includes("PIZZA QA OPCIONAL") &&
      bodyText.includes("BORDA CHEDDAR") &&
      bodyText.includes("É isso aiiii");

    await saveScreenshot(page, "business-search-opcional.png");

    return {
      name: "pesquisa-produto-com-opcional",
      passed,
      details: passed
        ? "Busca abriu o produto com opcional no fluxo legado."
        : "A busca nao abriu corretamente o produto com opcional.",
    };
  } finally {
    await context.close();
    await browser.close();
  }
}

async function runPreserveSelectionScenario() {
  const baseProduct = productTemplate({ descricao: "PIZZA QA TAMANHO" });
  const fractionOld = fractionTemplate(102, "FRACAO BACON");
  const fractionNew = fractionTemplate(103, "FRACAO CALABRESA", { valorTamanhoP: 32, valorTamanhoM: 43 });
  const oldOption = optionEntity(501, "BORDA P", { valorTamanhoP: 5, valorTamanhoM: 7 });

  const seededCart = [
    {
      id: "item-1",
      produto: baseProduct,
      quantidade: 1,
      tamanho: "P",
      observacao: "",
      opcionais: [{ quantidade: 1, unitPrice: 5, opcional: oldOption }],
      fracoes: [{ quantidade: 1, produto: fractionOld }],
      valorUnitario: 34,
      valorTotal: 39,
    },
  ];

  const config = {
    catalogo: catalogPayload({}, [baseProduct]),
    productsAll: [baseProduct],
    productsByCategory: [baseProduct],
    productDetail: baseProduct,
    optionsBySize: {
      P: [optionRelation(501, "BORDA P", { opcional: oldOption })],
      M: [optionRelation(502, "MOLHO M", { opcional: optionEntity(502, "MOLHO M", { valorTamanhoP: 2, valorTamanhoM: 4 }) })],
    },
    fractionsBySize: {
      P: [baseProduct, fractionOld],
      M: [baseProduct, fractionNew],
    },
  };

  const { browser, context } = await createContext(buildStorage({ cart: seededCart }));
  const page = await context.newPage();
  try {
    await installMocks(page, config);
    await page.goto(`${baseUrl}/pedido-item.html`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1500);
    await page.locator('label[for="btnradio_tamanho_M"]').click();
    await page.waitForTimeout(1200);
    await page.getByRole("button", { name: "É isso aiiii" }).click();
    await page.waitForTimeout(800);

    const cart = await page.evaluate(() => JSON.parse(window.localStorage.getItem("rpmenu.site.cart") || "[]"));
    const item = cart[0] ?? {};
    const preservedOption = (item.opcionais || []).find((entry) => entry.opcional?.codigo === 501);
    const preservedFraction = (item.fracoes || []).find((entry) => entry.produto?.codigo === 102);
    const passed =
      item.tamanho === "M" &&
      preservedOption?.quantidade === 1 &&
      preservedOption?.unitPrice === 7 &&
      preservedFraction?.quantidade === 1 &&
      item.valorUnitario === 42 &&
      item.valorTotal === 49;

    await saveScreenshot(page, "business-size-change-preserve.png");

    return {
      name: "troca-tamanho-preserva-opcionais-fracoes",
      passed,
      details: passed
        ? "Troca de tamanho preservou opcional/fracao e recalculou a media do fracionado."
        : `Carrinho final divergente: ${JSON.stringify(item)}`,
    };
  } finally {
    await context.close();
    await browser.close();
  }
}

async function runProductMinScenario() {
  const baseProduct = productTemplate({ descricao: "PIZZA QA MINIMO", opcionalMinimo: 1, permiteFrac: false });
  const seededCart = [
    {
      id: "item-1",
      produto: baseProduct,
      quantidade: 1,
      tamanho: "P",
      observacao: "",
      opcionais: [],
      fracoes: [],
      valorUnitario: 30,
      valorTotal: 30,
    },
  ];

  const config = {
    catalogo: catalogPayload({}, [baseProduct]),
    productsAll: [baseProduct],
    productsByCategory: [baseProduct],
    productDetail: baseProduct,
    optionsBySize: {
      P: [optionRelation(601, "BORDA CHEDDAR")],
    },
    fractionsBySize: {
      P: [baseProduct],
    },
  };

  const { browser, context } = await createContext(buildStorage({ cart: seededCart }));
  const page = await context.newPage();
  try {
    await installMocks(page, config);
    await page.goto(`${baseUrl}/pedido-item.html`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);
    await attachSwalRecorder(page);
    await page.getByRole("button", { name: "É isso aiiii" }).click();
    await page.waitForTimeout(600);

    const swalCalls = await page.evaluate(() => window.__swalCalls || []);
    const lastCall = swalCalls.at(-1);
    const passed = lastCall?.text?.includes("1 Opcionais");

    await saveScreenshot(page, "business-required-product-option.png");

    return {
      name: "opcional-obrigatorio-produto",
      passed,
      details: passed
        ? "Bloqueou confirmacao por minimo de opcionais do produto."
        : `SweetAlert divergente: ${JSON.stringify(lastCall)}`,
    };
  } finally {
    await context.close();
    await browser.close();
  }
}

async function runGroupMinScenario() {
  const baseProduct = productTemplate({ descricao: "PIZZA QA GUARNICAO", permiteFrac: false });
  const seededCart = [
    {
      id: "item-1",
      produto: baseProduct,
      quantidade: 1,
      tamanho: "P",
      observacao: "",
      opcionais: [],
      fracoes: [],
      valorUnitario: 30,
      valorTotal: 30,
    },
  ];

  const groupOption = optionRelation(701, "CHEDDAR", {
    groupId: 10,
    groupDescription: "Borda",
    opcionalMinimo: 2,
    opcionalMaximo: 3,
  });

  const config = {
    catalogo: catalogPayload({}, [baseProduct]),
    productsAll: [baseProduct],
    productsByCategory: [baseProduct],
    productDetail: baseProduct,
    optionsBySize: { P: [groupOption] },
    fractionsBySize: { P: [baseProduct] },
  };

  const { browser, context } = await createContext(buildStorage({ cart: seededCart }));
  const page = await context.newPage();
  try {
    await installMocks(page, config);
    await page.goto(`${baseUrl}/pedido-item.html`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);
    await attachSwalRecorder(page);
    await page.getByRole("button", { name: "É isso aiiii" }).click();
    await page.waitForTimeout(600);

    const swalCalls = await page.evaluate(() => window.__swalCalls || []);
    const lastCall = swalCalls.at(-1);
    const passed = lastCall?.text?.includes("Selecione no minimo 2 em Borda.");

    await saveScreenshot(page, "business-required-group-option.png");

    return {
      name: "opcional-obrigatorio-guarnicao",
      passed,
      details: passed
        ? "Bloqueou confirmacao por minimo de guarnicao."
        : `SweetAlert divergente: ${JSON.stringify(lastCall)}`,
    };
  } finally {
    await context.close();
    await browser.close();
  }
}

async function runPhoneScenario() {
  const config = {
    catalogo: catalogPayload({ utilizaCEP: false }),
    productsAll: [],
    productsByCategory: [],
    productDetail: productTemplate(),
    optionsBySize: {},
    fractionsBySize: {},
    customerResponse: emptyCustomer({
      nome: "QA Cadastro",
      celular: "85999999999",
      telefone: "",
      enderecos: [
        {
          idEndereco: 1,
          idCliente: 9001,
          idEmpresa: 1,
          cep: "",
          endereco: "Rua QA",
          enderecoCompleto: "Rua QA - N 100",
          idBairro: 1,
          bairro: "CENTRO",
          taxaEntrega: 8,
          numero: "100",
          complemento: "",
          pontoReferencia: "",
          idCidade: 1,
          UF: "CE",
          enderecoPadrao: true,
          taxa: 8,
        },
      ],
    }),
    lastClientePayload: null,
  };

  const { browser, context } = await createContext(buildStorage());
  const page = await context.newPage();
  try {
    await installMocks(page, config);
    await page.goto(`${baseUrl}/cliente-cadastro.html`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);

    const inputs = page.locator("input");
    await inputs.nth(0).fill("QA Cadastro");
    await inputs.nth(1).fill("85999999999");
    await inputs.nth(2).fill("");
    await inputs.nth(3).fill("Rua QA");
    await inputs.nth(4).fill("100");
    await inputs.nth(5).fill("Ap 10");
    await inputs.nth(6).fill("Praca");
    await page.locator("select").selectOption("1");
    await page.getByRole("button", { name: "Cadastrar" }).click();
    await page.waitForTimeout(800);

    const payload = config.lastClientePayload;
    const passed = payload?.celular === "85999999999" && payload?.telefone === "";

    await saveScreenshot(page, "business-cadastro-phone.png");

    return {
      name: "cadastro-separa-telefone-celular",
      passed,
      details: passed
        ? "Cadastro manteve telefone vazio sem copiar o celular."
        : `Payload divergente: ${JSON.stringify(payload)}`,
    };
  } finally {
    await context.close();
    await browser.close();
  }
}

async function runProductMaxScenario() {
  const baseProduct = productTemplate({ descricao: "PIZZA QA MAXIMO", opcionalMaximo: 1, permiteFrac: false });
  const seededCart = [
    {
      id: "item-1",
      produto: baseProduct,
      quantidade: 1,
      tamanho: "P",
      observacao: "",
      opcionais: [],
      fracoes: [],
      valorUnitario: 30,
      valorTotal: 30,
    },
  ];

  const config = {
    catalogo: catalogPayload({}, [baseProduct]),
    productsAll: [baseProduct],
    productsByCategory: [baseProduct],
    productDetail: baseProduct,
    optionsBySize: {
      P: [optionRelation(801, "EXTRA QA")],
    },
    fractionsBySize: {
      P: [baseProduct],
    },
  };

  const { browser, context } = await createContext(buildStorage({ cart: seededCart }));
  const page = await context.newPage();
  try {
    await installMocks(page, config);
    await page.goto(`${baseUrl}/pedido-item.html`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);
    await attachSwalRecorder(page);
    await triggerQuantityButton(page, "opcional_801", "increase");
    await page.waitForTimeout(250);
    await triggerQuantityButton(page, "opcional_801", "increase");
    await page.waitForTimeout(500);

    const swalCalls = await page.evaluate(() => window.__swalCalls || []);
    const lastCall = swalCalls.at(-1);
    const quantity = await page.inputValue("#opcional_801");
    const passed =
      String(quantity).trim() === "1" &&
      lastCall?.title === "Erro" &&
      lastCall?.text === "Quantidade de opcional excedido.";

    await saveScreenshot(page, "business-max-product-option.png");

    return {
      name: "opcional-maximo-produto",
      passed,
      details: passed
        ? "Bloqueou incremento acima do maximo de opcionais do produto."
        : `Quantidade/alerta divergente: quantidade=${quantity} alerta=${JSON.stringify(lastCall)}`,
    };
  } finally {
    await context.close();
    await browser.close();
  }
}

async function runGroupMaxScenario() {
  const baseProduct = productTemplate({ descricao: "PIZZA QA MAX GUARNICAO", permiteFrac: false });
  const seededCart = [
    {
      id: "item-1",
      produto: baseProduct,
      quantidade: 1,
      tamanho: "P",
      observacao: "",
      opcionais: [],
      fracoes: [],
      valorUnitario: 30,
      valorTotal: 30,
    },
  ];

  const config = {
    catalogo: catalogPayload({}, [baseProduct]),
    productsAll: [baseProduct],
    productsByCategory: [baseProduct],
    productDetail: baseProduct,
    optionsBySize: {
      P: [
        optionRelation(901, "BORDA CHEDDAR", {
          groupId: 10,
          groupDescription: "Borda",
          opcionalMinimo: 0,
          opcionalMaximo: 1,
        }),
        optionRelation(902, "BORDA CATUPIRY", {
          groupId: 10,
          groupDescription: "Borda",
          opcionalMinimo: 0,
          opcionalMaximo: 1,
        }),
      ],
    },
    fractionsBySize: {
      P: [baseProduct],
    },
  };

  const { browser, context } = await createContext(buildStorage({ cart: seededCart }));
  const page = await context.newPage();
  try {
    await installMocks(page, config);
    await page.goto(`${baseUrl}/pedido-item.html`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);
    await attachSwalRecorder(page);
    await triggerQuantityButton(page, "opcional_901", "increase");
    await page.waitForTimeout(250);
    await triggerQuantityButton(page, "opcional_902", "increase");
    await page.waitForTimeout(500);

    const swalCalls = await page.evaluate(() => window.__swalCalls || []);
    const lastCall = swalCalls.at(-1);
    const quantity1 = await page.inputValue("#opcional_901");
    const quantity2 = await page.inputValue("#opcional_902");
    const passed =
      quantity1 === "1" &&
      quantity2 === "0" &&
      lastCall?.text?.includes("Limite maximo de 1 atingido para Borda.");

    await saveScreenshot(page, "business-max-group-option.png");

    return {
      name: "opcional-maximo-guarnicao",
      passed,
      details: passed
        ? "Bloqueou incremento acima do maximo da guarnicao."
        : `Quantidades/alerta divergente: q1=${quantity1} q2=${quantity2} alerta=${JSON.stringify(lastCall)}`,
    };
  } finally {
    await context.close();
    await browser.close();
  }
}

async function runFractionLimitScenario() {
  const baseProduct = productTemplate({ descricao: "PIZZA QA FRACAO LIMITE" });
  const fractions = [
    fractionTemplate(1001, "FRACAO 1"),
    fractionTemplate(1002, "FRACAO 2"),
    fractionTemplate(1003, "FRACAO 3"),
    fractionTemplate(1004, "FRACAO 4"),
  ];
  const seededCart = [
    {
      id: "item-1",
      produto: baseProduct,
      quantidade: 1,
      tamanho: "P",
      observacao: "",
      opcionais: [],
      fracoes: [],
      valorUnitario: 30,
      valorTotal: 30,
    },
  ];

  const config = {
    catalogo: catalogPayload({}, [baseProduct]),
    productsAll: [baseProduct],
    productsByCategory: [baseProduct],
    productDetail: baseProduct,
    optionsBySize: { P: [] },
    fractionsBySize: { P: [baseProduct, ...fractions] },
  };

  const { browser, context } = await createContext(buildStorage({ cart: seededCart }));
  const page = await context.newPage();
  try {
    await installMocks(page, config);
    await page.goto(`${baseUrl}/pedido-item.html`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);
    for (const code of [1001, 1002, 1003, 1004]) {
      await triggerQuantityButton(page, `fracao_${code}`, "increase");
      await page.waitForTimeout(200);
    }

    const values = await Promise.all(
      [1001, 1002, 1003, 1004].map((code) => page.inputValue(`#fracao_${code}`)),
    );
    const passed = values.join(",") === "1,1,1,0";

    await saveScreenshot(page, "business-fraction-limit.png");

    return {
      name: "limite-de-tres-fracoes",
      passed,
      details: passed
        ? "Manteve o limite de 3 fracoes como no legado."
        : `Quantidades divergentes: ${values.join(",")}`,
    };
  } finally {
    await context.close();
    await browser.close();
  }
}

async function runRestrictedAllProductsScenario() {
  const restrictedProduct = productTemplate({
    descricao: "PIZZA RESTRITA QA",
    restringirVenda: true,
  });
  const config = {
    catalogo: catalogPayload({}, [restrictedProduct]),
    productsAll: [restrictedProduct],
    productsByCategory: [],
    productDetail: restrictedProduct,
    optionsBySize: { P: [] },
    fractionsBySize: { P: [restrictedProduct] },
  };

  const { browser, context } = await createContext(buildStorage());
  const page = await context.newPage();
  try {
    await installMocks(page, config);
    await page.goto(`${baseUrl}/produtostodascategoria.html`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);

    const bodyText = await page.locator("body").innerText();
    const passed = bodyText.includes("PIZZA RESTRITA QA");

    await saveScreenshot(page, "business-all-products-restriction.png");

    return {
      name: "todos-produtos-mantem-restrito-como-legado",
      passed,
      details: passed
        ? "Tela de todos os produtos manteve item restrito, como o legado."
        : "Tela de todos os produtos ocultou item restrito indevidamente.",
    };
  } finally {
    await context.close();
    await browser.close();
  }
}

async function runCartOptionMaxScenario() {
  const baseProduct = productTemplate({ descricao: "PIZZA QA CARRINHO", opcionalMaximo: 1, permiteFrac: false });
  const option = optionEntity(1101, "BORDA CART", { valorTamanhoP: 5, valorTamanhoM: 6 });
  const seededCart = [
    {
      id: "item-1",
      produto: baseProduct,
      quantidade: 1,
      tamanho: "P",
      observacao: "",
      opcionais: [{ quantidade: 1, unitPrice: 5, opcional: option }],
      fracoes: [],
      valorUnitario: 35,
      valorTotal: 35,
    },
  ];

  const config = {
    catalogo: catalogPayload({}, [baseProduct]),
    productsAll: [baseProduct],
    productsByCategory: [baseProduct],
    productDetail: baseProduct,
    optionsBySize: { P: [optionRelation(1101, "BORDA CART", { opcional: option })] },
    fractionsBySize: { P: [baseProduct] },
    customerResponse: emptyCustomer(),
  };

  const { browser, context } = await createContext(buildStorage({ cart: seededCart, customer: emptyCustomer() }));
  const page = await context.newPage();
  try {
    await installMocks(page, config);
    await page.goto(`${baseUrl}/index.html`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);
    await attachSwalRecorder(page);
    await page.click("#barVerSacola");
    await page.waitForTimeout(400);

    const optionRow = page.locator("#painelSacola .order-check").filter({ hasText: "(UP).. BORDA CART" }).first();
    await optionRow.locator("button[data-increase]").click();
    await page.waitForTimeout(500);

    const swalCalls = await page.evaluate(() => window.__swalCalls || []);
    const lastCall = swalCalls.at(-1);
    const quantity = await optionRow.locator("input[data-value]").inputValue();
    const passed = JSON.stringify(lastCall ?? {}).includes("Quantidade de opcional excedido.");

    await saveScreenshot(page, "business-cart-option-max.png");

    return {
      name: "carrinho-opcional-maximo-produto",
      passed,
      details: passed
        ? "Sacola bloqueou opcional acima do maximo com a mesma regra do legado."
        : `Quantidade/alerta divergente: quantidade=${quantity} alerta=${JSON.stringify(lastCall)}`,
    };
  } finally {
    await context.close();
    await browser.close();
  }
}

async function runCartOptionMinGroupScenario() {
  const baseProduct = productTemplate({ descricao: "PIZZA QA CARRINHO MIN", permiteFrac: false });
  const option = optionEntity(1201, "BORDA CART MIN", { valorTamanhoP: 5 });
  const seededCart = [
    {
      id: "item-1",
      produto: baseProduct,
      quantidade: 1,
      tamanho: "P",
      observacao: "",
      opcionais: [{ quantidade: 1, unitPrice: 5, opcional: option }],
      fracoes: [],
      valorUnitario: 35,
      valorTotal: 35,
    },
  ];

  const config = {
    catalogo: catalogPayload({}, [baseProduct]),
    productsAll: [baseProduct],
    productsByCategory: [baseProduct],
    productDetail: baseProduct,
    optionsBySize: {
      P: [
        optionRelation(1201, "BORDA CART MIN", {
          groupId: 22,
          groupDescription: "Borda",
          opcionalMinimo: 1,
          opcionalMaximo: 2,
          opcional: option,
        }),
      ],
    },
    fractionsBySize: { P: [baseProduct] },
    customerResponse: emptyCustomer(),
  };

  const { browser, context } = await createContext(buildStorage({ cart: seededCart, customer: emptyCustomer() }));
  const page = await context.newPage();
  try {
    await installMocks(page, config);
    await page.goto(`${baseUrl}/index.html`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);
    await attachSwalRecorder(page);
    await page.click("#barVerSacola");
    await page.waitForTimeout(400);

    const optionRow = page.locator("#painelSacola .order-check").filter({ hasText: "(UP).. BORDA CART MIN" }).first();
    await optionRow.locator("button[data-decrease]").click();
    await page.waitForTimeout(500);

    const swalCalls = await page.evaluate(() => window.__swalCalls || []);
    const lastCall = swalCalls.at(-1);
    const quantity = await optionRow.locator("input[data-value]").inputValue();
    const passed =
      quantity === "1" &&
      lastCall?.title === "Obrigatorio" &&
      lastCall?.text === "Selecione no minimo 1 em Borda.";

    await saveScreenshot(page, "business-cart-option-min-group.png");

    return {
      name: "carrinho-opcional-minimo-guarnicao",
      passed,
      details: passed
        ? "Sacola bloqueou remocao abaixo do minimo da guarnicao como no legado."
        : `Quantidade/alerta divergente: quantidade=${quantity} alerta=${JSON.stringify(lastCall)}`,
    };
  } finally {
    await context.close();
    await browser.close();
  }
}

async function runClosedStoreRegularScenario() {
  const baseProduct = productTemplate({ descricao: "PIZZA QA FECHADA", permiteFrac: false, vendaPorTamanho: false, valFinal: 30 });
  const customer = emptyCustomer({
    enderecos: [
      {
        idEndereco: 1,
        idCliente: 9001,
        idEmpresa: 1,
        cep: "14807297",
        endereco: "Rua QA",
        enderecoCompleto: "Rua QA - N 100",
        idBairro: 1,
        bairro: "CENTRO",
        taxaEntrega: 8,
        numero: "100",
        complemento: "",
        pontoReferencia: "",
        idCidade: 1,
        UF: "CE",
        enderecoPadrao: true,
        taxa: 8,
      },
    ],
  });
  const seededCart = [
    {
      id: "item-1",
      produto: baseProduct,
      quantidade: 1,
      tamanho: "",
      observacao: "",
      opcionais: [],
      fracoes: [],
      valorUnitario: 30,
      valorTotal: 30,
    },
  ];

  const config = {
    catalogo: catalogPayload({ integracaoMercadoPago: false }, [baseProduct]),
    productsAll: [baseProduct],
    productsByCategory: [baseProduct],
    productDetail: baseProduct,
    optionsBySize: {},
    fractionsBySize: {},
    customerResponse: customer,
  };
  config.catalogo.aberta = false;

  const checkout = {
    nome: customer.nome,
    email: customer.email,
    telefone: customer.celular,
    cep: "14807297",
    endereco: "Rua QA",
    numero: "100",
    complemento: "",
    pontoReferencia: "",
    bairroId: 1,
    tipoEntrega: "D",
    formaPagamentoId: 1,
    valorAReceber: "",
    observacao: "",
  };

  const { browser, context } = await createContext(buildStorage({ cart: seededCart, customer, checkout }));
  const page = await context.newPage();
  try {
    await installMocks(page, config);
    await page.goto(`${baseUrl}/pedido-finalizar.html`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);
    await attachSwalRecorder(page);
    await page.getByRole("button", { name: "Confirmar pedido" }).click();
    await page.waitForTimeout(700);

    const swalCalls = await page.evaluate(() => window.__swalCalls || []);
    const lastCall = swalCalls.at(-1);
    const bodyText = await page.locator("body").innerText();
    const cart = await page.evaluate(() => JSON.parse(window.localStorage.getItem("rpmenu.site.cart") || "[]"));
    const passed =
      /Telefone \(DDD \+ N[uú]mero\)/i.test(bodyText) &&
      lastCall?.text === "ixee estamos fechado agora..." &&
      Array.isArray(cart) &&
      cart.length === 0;

    await saveScreenshot(page, "business-closed-store-regular.png");

    return {
      name: "loja-fechada-pedido-normal-redireciona-login",
      passed,
      details: passed
        ? "Pedido normal com loja fechada cancelou a venda e voltou ao login como no legado."
        : `Estado divergente: alerta=${JSON.stringify(lastCall)} cart=${JSON.stringify(cart)} body=${bodyText.slice(0, 180)}`,
    };
  } finally {
    await context.close();
    await browser.close();
  }
}

async function runClosedStorePixScenario() {
  const pixPayment = {
    id: 17,
    descricao: "PIX",
    permiteTroco: false,
    pagamentoOnline: true,
    pix: true,
  };
  const baseProduct = productTemplate({ descricao: "PIZZA QA PIX FECHADA", permiteFrac: false, vendaPorTamanho: false, valFinal: 30 });
  const customer = emptyCustomer({
    enderecos: [
      {
        idEndereco: 1,
        idCliente: 9001,
        idEmpresa: 1,
        cep: "14807297",
        endereco: "Rua QA",
        enderecoCompleto: "Rua QA - N 100",
        idBairro: 1,
        bairro: "CENTRO",
        taxaEntrega: 8,
        numero: "100",
        complemento: "",
        pontoReferencia: "",
        idCidade: 1,
        UF: "CE",
        enderecoPadrao: true,
        taxa: 8,
      },
    ],
  });
  const seededCart = [
    {
      id: "item-1",
      produto: baseProduct,
      quantidade: 1,
      tamanho: "",
      observacao: "",
      opcionais: [],
      fracoes: [],
      valorUnitario: 30,
      valorTotal: 30,
    },
  ];

  const config = {
    catalogo: {
      ...catalogPayload({ integracaoMercadoPago: true }, [baseProduct]),
      formasPagamento: [pixPayment],
      aberta: false,
    },
    productsAll: [baseProduct],
    productsByCategory: [baseProduct],
    productDetail: baseProduct,
    optionsBySize: {},
    fractionsBySize: {},
    customerResponse: customer,
    pixResponse: {
      idPix: "pix-fechada",
      qrCodeBase64: "",
      qrCodeDigitavel: "000201010212PIX-FECHADA",
      qrCodeUrl: "https://pix.local/fechada",
      status: "aguardando",
      valorTotal: 30,
    },
  };

  const checkout = {
    nome: customer.nome,
    email: customer.email,
    telefone: customer.celular,
    cep: "14807297",
    endereco: "Rua QA",
    numero: "100",
    complemento: "",
    pontoReferencia: "",
    bairroId: 1,
    tipoEntrega: "D",
    formaPagamentoId: 17,
    valorAReceber: "",
    observacao: "",
  };

  const { browser, context } = await createContext(buildStorage({ cart: seededCart, customer, checkout }));
  const page = await context.newPage();
  try {
    await installMocks(page, config);
    await page.goto(`${baseUrl}/pedido-finalizar.html`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);
    await page.getByRole("button", { name: "Confirmar pedido" }).click();
    await page.waitForTimeout(1200);

    const bodyText = await page.locator("body").innerText();
    const qrCodeLink = await page.locator("a[href='https://pix.local/fechada']").count();
    const passed = bodyText.includes("000201010212PIX-FECHADA") && qrCodeLink > 0;

    await saveScreenshot(page, "business-closed-store-pix.png");

    return {
      name: "loja-fechada-pix-segue-para-pagamento",
      passed,
      details: passed
        ? "Fluxo PIX seguiu para a tela de pagamento mesmo com loja fechada, como no legado."
        : `Tela de pagamento nao abriu corretamente. qrCodeLink=${qrCodeLink} body=${bodyText.slice(0, 200)}`,
    };
  } finally {
    await context.close();
    await browser.close();
  }
}

function renderReport(results) {
  const total = results.length;
  const passed = results.filter((item) => item.passed).length;
  const failed = results.filter((item) => !item.passed);

  return [
    "# QA Regras de Negocio Publico - RPMENU React",
    "",
    `- Cenarios executados: ${total}`,
    `- Aprovados: ${passed}`,
    `- Reprovados: ${failed.length}`,
    "",
    "## Resultado",
    "",
    ...results.map((item) => `- ${item.passed ? "[OK]" : "[FALHA]"} ${item.name}: ${item.details}`),
    "",
  ].join("\n");
}

const results = [];

try {
  results.push(await runSearchScenario());
  results.push(await runPreserveSelectionScenario());
  results.push(await runProductMinScenario());
  results.push(await runGroupMinScenario());
  results.push(await runProductMaxScenario());
  results.push(await runGroupMaxScenario());
  results.push(await runFractionLimitScenario());
  results.push(await runRestrictedAllProductsScenario());
  results.push(await runCartOptionMaxScenario());
  results.push(await runCartOptionMinGroupScenario());
  results.push(await runClosedStoreRegularScenario());
  results.push(await runClosedStorePixScenario());
  results.push(await runPhoneScenario());

  const report = renderReport(results);
  await fs.mkdir(path.dirname(reportFile), { recursive: true });
  await fs.writeFile(reportFile, report, "utf8");
  console.log(JSON.stringify({ total: results.length, passed: results.filter((item) => item.passed).length, failed: results.filter((item) => !item.passed) }, null, 2));
  process.exit(results.every((item) => item.passed) ? 0 : 1);
} catch (error) {
  console.error(error);
  process.exit(1);
}

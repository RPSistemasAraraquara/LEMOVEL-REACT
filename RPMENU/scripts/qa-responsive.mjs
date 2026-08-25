import fs from "node:fs/promises";
import path from "node:path";
import { chromium } from "playwright";

const baseUrl = "http://127.0.0.1:4173";
const apiBase = `${baseUrl}/rpfood/v1`;
const reportDir = path.resolve("test-results", "responsive-qa");
const transparentPng = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO2p6Y0AAAAASUVORK5CYII=",
  "base64",
);

const nowIso = new Date().toISOString();

const address = {
  idEndereco: 7001,
  idCliente: 9001,
  idEmpresa: 1,
  cep: "",
  endereco: "Rua QA",
  enderecoCompleto: "Rua QA - N 100",
  idBairro: 1,
  bairro: "CENTRO",
  taxaEntrega: 8,
  numero: "100",
  complemento: "Apto 10",
  pontoReferencia: "Proximo a praca",
  idCidade: 1,
  UF: "CE",
  enderecoPadrao: true,
  taxa: 8,
};

const company = {
  idEmpresa: 1,
  nome: "RPMENU",
  razaoSocial: "RPMENU LTDA",
  cnpj: "00000000000199",
  email: "qa@local.test",
  fone1: "(85) 99999-9999",
  endereco: {
    ...address,
    idEndereco: 0,
    idCliente: 0,
    enderecoPadrao: false,
  },
};

const config = {
  utilizaCEP: false,
  pedidoMinimo: 0,
  permiteRetiradaNoLocal: true,
  tempoRetirada: "65 min",
  tempoEntrega: "90 min",
  utilizaControleOpcionais: true,
  integracaoMercadoPago: true,
};

const categories = [
  { codigo: 1, descricao: "01-PIZZAS", imageUrl: `${apiBase}/empresa/1/categoria/1/imagem` },
  { codigo: 5, descricao: "05-REFRIGERANTES", imageUrl: `${apiBase}/empresa/1/categoria/5/imagem` },
  { codigo: 7, descricao: "07-SUCOS COPO", imageUrl: `${apiBase}/empresa/1/categoria/7/imagem` },
];

const productBase = {
  codigo: 101,
  idEmpresa: 1,
  idGrupo: 1,
  descricao: "PIZZA ATUM",
  observacao: "Pizza com tamanhos e detalhes para validar a tela no celular.",
  idSituacao: 1,
  situacao: "ATIVO",
  situacaoDescricao: "Disponivel",
  valFinal: 39,
  destaqueWeb: true,
  vendaPorTamanho: true,
  permiteFrac: false,
  valorTamanhoP: 30,
  valorTamanhoM: 39,
  valorTamanhoG: 49,
  valorTamanhoGG: 59,
  valorTamanhoExtra: 0,
  tamanhoP: "P",
  tamanhoM: "M",
  tamanhoG: "G",
  tamanhoGG: "GG",
  tamanhoExtra: "",
  tamanhoPadrao: "M",
  opcionalMinimo: 0,
  opcionalMaximo: 5,
  restringirVenda: false,
  imageUrl: `${apiBase}/empresa/1/produto/101/imagem`,
};

const productSecond = {
  ...productBase,
  codigo: 102,
  idGrupo: 5,
  descricao: "REFRIGERANTE LATA",
  observacao: "Bebida gelada para compor o pedido.",
  vendaPorTamanho: false,
  permiteFrac: false,
  valFinal: 8,
  valorTamanhoP: 0,
  valorTamanhoM: 0,
  valorTamanhoG: 0,
  valorTamanhoGG: 0,
  tamanhoP: "",
  tamanhoM: "",
  tamanhoG: "",
  tamanhoGG: "",
  tamanhoPadrao: "",
  imageUrl: `${apiBase}/empresa/1/produto/102/imagem`,
};

const productThird = {
  ...productBase,
  codigo: 103,
  idGrupo: 7,
  descricao: "SUCO LARANJA COPO",
  observacao: "Suco natural servido gelado.",
  vendaPorTamanho: false,
  permiteFrac: false,
  valFinal: 7,
  valorTamanhoP: 0,
  valorTamanhoM: 0,
  valorTamanhoG: 0,
  valorTamanhoGG: 0,
  tamanhoP: "",
  tamanhoM: "",
  tamanhoG: "",
  tamanhoGG: "",
  tamanhoPadrao: "",
  imageUrl: `${apiBase}/empresa/1/produto/103/imagem`,
};

const catalog = {
  aberta: true,
  empresa: company,
  configuracao: config,
  categorias: categories,
  destaques: [productBase, productSecond],
};

const neighborhoods = [
  { idEmpresa: 1, idBairro: 1, descricao: "CENTRO", taxa: 8 },
  { idEmpresa: 1, idBairro: 2, descricao: "ALDEOTA", taxa: 12 },
];

const payments = [
  { id: 1, idEmpresa: 1, descricao: "Dinheiro", permiteTroco: true, pagamentoOnline: false, utilizaPix: false },
  { id: 2, idEmpresa: 1, descricao: "Pix", permiteTroco: false, pagamentoOnline: true, utilizaPix: true },
];

const optionals = [
  {
    idEmpresa: 1,
    codigoProduto: 101,
    codigoOpcional: 201,
    groupId: 1,
    groupDescription: "Borda",
    opcionalMinimo: 0,
    opcionalMaximo: 1,
    opcional: {
      codigo: 201,
      idEmpresa: 1,
      descricao: "BORDA CHEDDAR",
      valor: 15,
      valorTamanhoP: 15,
      valorTamanhoM: 15,
      valorTamanhoG: 15,
      valorTamanhoGG: 15,
      valorTamanhoExtra: 0,
      tamanhoP: "P",
      tamanhoM: "M",
      tamanhoG: "G",
      tamanhoGG: "GG",
      tamanhoExtra: "",
    },
  },
];

const customer = {
  idCliente: 9001,
  idEmpresa: 1,
  nome: "RAFAEL MENDONCA",
  email: "rafael.qa@local.test",
  senha: "",
  celular: "85999999999",
  telefone: "8533333333",
  enderecos: [address],
};

const cart = [
  {
    id: "qa-item-1",
    produto: productBase,
    quantidade: 1,
    tamanho: "M",
    observacao: "",
    opcionais: [{ quantidade: 1, unitPrice: 15, opcional: optionals[0].opcional }],
    fracoes: [],
    valorUnitario: 54,
    valorTotal: 54,
  },
];

const checkout = {
  nome: customer.nome,
  email: customer.email,
  telefone: customer.celular,
  cep: address.cep,
  endereco: address.endereco,
  numero: address.numero,
  complemento: address.complemento,
  pontoReferencia: address.pontoReferencia,
  bairroId: address.idBairro,
  tipoEntrega: "D",
  formaPagamentoId: 2,
  valorAReceber: "",
  observacao: "",
};

const history = [
  {
    id: 5001,
    data: nowIso,
    taxaEntrega: 8,
    valorTotal: 62,
    valorAReceber: 0,
    troco: 0,
    observacao: "",
    tipoEntregaDescription: "Delivery",
    situacaoDescription: "Recebido",
    formaPagamento: payments[1],
    itens: [
      {
        numeroItem: 1,
        quantidade: 1,
        tamanho: "M",
        observacao: "",
        valorUnitario: 54,
        valorTotalProduto: 54,
        produto: productBase,
        opcionais: [{ quantidade: 1, valorUnitario: 15, valorTotal: 15, opcional: optionals[0].opcional }],
      },
    ],
  },
];

const trackedOrder = {
  ...history[0],
  vendaEndereco: address,
  listaStatus: [
    { data: nowIso, situacao: "R", situacaoDescricao: "Pedido recebido" },
    { data: nowIso, situacao: "P", situacaoDescricao: "Pedido em preparo" },
  ],
};

const routes = [
  { name: "index", path: "/index.html", mode: "seeded" },
  { name: "produto-por-categoria", path: "/produto-por-categoria.html", mode: "seeded" },
  { name: "pedido-item", path: "/pedido-item.html", mode: "seeded" },
  { name: "pedido-finalizar", path: "/pedido-finalizar.html", mode: "seeded" },
  { name: "pedido-acompanhamento", path: "/pedido-acompanhamento.html", mode: "seeded" },
  { name: "venda-historico", path: "/venda-historico.html", mode: "seeded" },
  { name: "cliente-endereco", path: "/cliente-endereco.html", mode: "seeded" },
];

const viewports = [
  { name: "mobile", width: 390, height: 844, isMobile: true, hasTouch: true },
  { name: "tablet", width: 768, height: 1024, isMobile: true, hasTouch: true },
];

function json(status, value) {
  return {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
    body: Buffer.from(JSON.stringify(value)),
  };
}

function buildApiPayload(url) {
  const pathname = new URL(url).pathname.replace("/rpfood/v1", "");

  if (/\/empresa\/1\/categoria\/\d+\/imagem$/i.test(pathname) || /\/empresa\/1\/produto\/\d+\/imagem$/i.test(pathname)) {
    return {
      status: 200,
      headers: { "Content-Type": "image/png", "Cache-Control": "public, max-age=60" },
      body: transparentPng,
    };
  }

  if (pathname === "/empresa/1/catalogo") return json(200, catalog);
  if (pathname === "/empresa/1/forma-pagamento") return json(200, payments);
  if (pathname === "/empresa/1/bairro") return json(200, neighborhoods);
  if (pathname === "/empresa/1/sobre") {
    return json(200, {
      aberta: true,
      empresa: company,
      configuracao: config,
      horarios: [{ dia: "Segunda", horaAbertura: "18:00", horaFechamento: "23:00", horaAbertura2: "", horaFechamento2: "" }],
      formasPagamento: payments,
    });
  }
  if (pathname === "/empresa/1/produto") return json(200, [productBase, productSecond, productThird]);
  if (pathname === "/empresa/1/produto/todos") return json(200, [productBase, productSecond, productThird]);
  if (/\/empresa\/1\/categoria\/1\/produto$/i.test(pathname)) return json(200, [productBase]);
  if (/\/empresa\/1\/categoria\/5\/produto$/i.test(pathname)) return json(200, [productSecond]);
  if (/\/empresa\/1\/categoria\/7\/produto$/i.test(pathname)) return json(200, [productThird]);
  if (/\/empresa\/1\/produto\/101$/i.test(pathname)) return json(200, productBase);
  if (/\/empresa\/1\/produto\/101\/opcional$/i.test(pathname)) return json(200, optionals);
  if (/\/empresa\/1\/produto\/101\/fracao$/i.test(pathname)) return json(200, [productBase]);
  if (pathname === "/empresa/1/cliente/9001/endereco") return json(200, [address]);
  if (pathname === "/empresa/1/cliente/9001/endereco/7001") return json(200, address);
  if (pathname === "/empresa/1/cliente/9001") return json(200, customer);
  if (pathname === "/empresa/1/cliente") return json(200, customer);
  if (pathname === "/empresa/1/cliente/9001/pedido") return json(200, history);
  if (pathname === "/empresa/1/cliente/9001/pedido/ultima") return json(200, trackedOrder);
  if (pathname === "/empresa/1/pedido") return json(200, { idVenda: 5001, status: "A", valorTotal: 62, dataPedido: nowIso });

  return null;
}

async function installApiMocks(page) {
  await page.route("**/favicon.ico", async (route) => {
    await route.fulfill({ status: 204, body: Buffer.from("") });
  });

  await page.route(`${apiBase}/**`, async (route) => {
    const payload = buildApiPayload(route.request().url());
    if (!payload) {
      await route.fulfill(json(404, { message: "Mock nao configurado para esta rota." }));
      return;
    }
    await route.fulfill(payload);
  });
}

function buildSeedStorage() {
  return {
    "rpmenu.site.companyId": JSON.stringify(1),
    "rpmenu.site.customer": JSON.stringify(customer),
    "rpmenu.site.cart": JSON.stringify(cart),
    "rpmenu.site.checkout": JSON.stringify(checkout),
    rpmenu_telefone: customer.celular,
  };
}

async function createContext(browser, viewport) {
  const context = await browser.newContext({
    viewport: { width: viewport.width, height: viewport.height },
    isMobile: viewport.isMobile,
    hasTouch: viewport.hasTouch,
    locale: "pt-BR",
    timezoneId: "America/Sao_Paulo",
    serviceWorkers: "block",
  });

  const storage = buildSeedStorage();
  await context.addInitScript((seed) => {
    for (const [key, value] of Object.entries(seed)) {
      window.localStorage.setItem(key, value);
    }
  }, storage);

  return context;
}

async function evaluateResponsiveRoute(context, viewportName, route) {
  const page = await context.newPage();
  const consoleErrors = [];
  const pageErrors = [];

  page.on("console", (message) => {
    if (message.type() === "error") {
      consoleErrors.push(message.text());
    }
  });
  page.on("pageerror", (error) => {
    pageErrors.push(error.message);
  });

  await installApiMocks(page);
  if (route.name === "pedido-acompanhamento") {
    await page.goto(`${baseUrl}/index.html`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);
    await page.locator("#btnNavAcompanhamento").click();
    await page.waitForTimeout(1800);
  } else {
    await page.goto(`${baseUrl}${route.path}`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1600);
  }

  const metrics = await page.evaluate(() => {
    const doc = document.documentElement;
    const body = document.body;
    const mainWrapper = document.querySelector("#main-wrapper");
    return {
      clientWidth: doc.clientWidth,
      scrollWidth: Math.max(doc.scrollWidth, body.scrollWidth),
      scrollHeight: Math.max(doc.scrollHeight, body.scrollHeight),
      wrapperWidth: mainWrapper ? mainWrapper.getBoundingClientRect().width : 0,
      hasHorizontalOverflow: Math.max(doc.scrollWidth, body.scrollWidth) - doc.clientWidth > 2,
      textSample: (body.innerText || "").replace(/\s+/g, " ").trim().slice(0, 240),
    };
  });

  const screenshotPath = path.join(reportDir, `${viewportName}-${route.name}.png`);
  await page.screenshot({ path: screenshotPath, fullPage: true });
  await page.close();

  return {
    viewport: viewportName,
    route: route.name,
    path: route.path,
    ...metrics,
    consoleErrors,
    pageErrors,
    screenshotPath,
  };
}

function toMarkdown(results) {
  const lines = [
    "# QA Responsivo",
    "",
    `Base URL: ${baseUrl}`,
    "",
  ];

  for (const viewportName of viewports.map((item) => item.name)) {
    lines.push(`## ${viewportName}`);
    lines.push("");

    for (const result of results.filter((item) => item.viewport === viewportName)) {
      lines.push(`- ${result.route}: overflow=${result.hasHorizontalOverflow ? "SIM" : "nao"} | console=${result.consoleErrors.length} | pageErrors=${result.pageErrors.length}`);
      lines.push(`  - screenshot: ${result.screenshotPath.replace(/\\/g, "/")}`);
      lines.push(`  - sample: ${result.textSample}`);
    }

    lines.push("");
  }

  return lines.join("\n");
}

async function main() {
  await fs.mkdir(reportDir, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const results = [];

  for (const viewport of viewports) {
    const context = await createContext(browser, viewport);
    for (const route of routes) {
      results.push(await evaluateResponsiveRoute(context, viewport.name, route));
    }
    await context.close();
  }

  await browser.close();

  const reportPath = path.join(reportDir, "summary.md");
  await fs.writeFile(reportPath, toMarkdown(results), "utf8");

  const failed = results.filter((item) => item.hasHorizontalOverflow || item.consoleErrors.length || item.pageErrors.length);
  if (failed.length) {
    console.log(JSON.stringify({ ok: false, reportPath, failed }, null, 2));
    process.exitCode = 1;
    return;
  }

  console.log(JSON.stringify({ ok: true, reportPath, results }, null, 2));
}

await main();

import fs from "node:fs/promises";
import path from "node:path";
import { chromium } from "playwright";

const baseUrl = "http://127.0.0.1:4173";
const apiBase = `${baseUrl}/rpfood/v1`;
const transparentPng = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO2p6Y0AAAAASUVORK5CYII=",
  "base64",
);

const nowIso = new Date().toISOString();
const reportDate = "2026-08-24";
const reportDir = path.resolve("test-results", "routes-qa");
const reportFile = path.resolve("test-results", "QA_ROTAS_RPMENU.md");

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
];

const productBase = {
  codigo: 101,
  idEmpresa: 1,
  idGrupo: 1,
  descricao: "PIZZA ATUM",
  observacao: "",
  valFinal: 39,
  destaqueWeb: true,
  vendaPorTamanho: true,
  permiteFrac: false,
  valorTamanhoP: 0,
  valorTamanhoM: 39,
  valorTamanhoG: 49,
  valorTamanhoGG: 0,
  valorTamanhoExtra: 0,
  tamanhoP: "",
  tamanhoM: "M",
  tamanhoG: "G",
  tamanhoGG: "",
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
  descricao: "PIZZA BACON",
  imageUrl: `${apiBase}/empresa/1/produto/102/imagem`,
};

const catalog = {
  aberta: true,
  empresa: company,
  configuracao: config,
  categorias: categories,
  destaques: [productBase],
};

const neighborhoods = [{ idEmpresa: 1, idBairro: 1, descricao: "CENTRO", taxa: 8 }];
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
      valorTamanhoP: 0,
      valorTamanhoM: 15,
      valorTamanhoG: 15,
      valorTamanhoGG: 0,
      valorTamanhoExtra: 0,
      tamanhoP: "",
      tamanhoM: "M",
      tamanhoG: "G",
      tamanhoGG: "",
      tamanhoExtra: "",
    },
  },
  {
    idEmpresa: 1,
    codigoProduto: 101,
    codigoOpcional: 202,
    groupId: 0,
    groupDescription: "",
    opcionalMinimo: 0,
    opcionalMaximo: 0,
    opcional: {
      codigo: 202,
      idEmpresa: 1,
      descricao: "ABERTA",
      valor: 50,
      valorTamanhoP: 0,
      valorTamanhoM: 50,
      valorTamanhoG: 50,
      valorTamanhoGG: 0,
      valorTamanhoExtra: 0,
      tamanhoP: "",
      tamanhoM: "M",
      tamanhoG: "G",
      tamanhoGG: "",
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
    opcionais: [
      { quantidade: 1, unitPrice: 15, opcional: optionals[0].opcional },
      { quantidade: 1, unitPrice: 50, opcional: optionals[1].opcional },
    ],
    fracoes: [],
    valorUnitario: 104,
    valorTotal: 104,
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
    valorTotal: 112,
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
        valorUnitario: 104,
        valorTotalProduto: 104,
        produto: productBase,
        opcionais: [
          { quantidade: 1, valorUnitario: 15, valorTotal: 15, opcional: optionals[0].opcional },
          { quantidade: 1, valorUnitario: 50, valorTotal: 50, opcional: optionals[1].opcional },
        ],
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

const pixPayment = {
  idPix: "pix-qa-001",
  qrCodeBase64: transparentPng.toString("base64"),
  qrCodeDigitavel: "000201010212pixqa001",
  qrCodeUrl: "https://example.com/pix-qa-001",
  status: "pending",
  valorTotal: 112,
};

const adminSession = {
  token: "qa-admin-token",
  usuario: {
    codigo: 1,
    nome: "ADMIN QA",
    email: "1",
  },
};

const adminDashboard = {
  sincronizacao: "07/04/2026 12:00:00",
  qtdeVendas: "12",
  valorVendas: "1.240,00",
  taxaEntrega: "82,00",
  topClientes: [
    { label: "RAFAEL MENDONCA", value: "5 Compras" },
    { label: "CLIENTE QA", value: "3 Compras" },
  ],
  topBairros: [
    { label: "CENTRO", value: "R$120,00" },
    { label: "ALDEOTA", value: "R$85,00" },
  ],
  topProdutos: [
    { label: "PIZZA ATUM", value: "Qtde: 4 | R$416,00" },
    { label: "PIZZA BACON", value: "Qtde: 2 | R$78,00" },
  ],
};

const routes = [
  { name: "index", path: "/index.html", mode: "anon", expectedPath: "/index.html", text: ["Categorias", "Bora procurar"] },
  { name: "login", path: "/login.html", mode: "anon", expectedPath: "/login.html", text: ["Bora colocar seus dados"] },
  { name: "cadastro", path: "/cliente-cadastro.html", mode: "anon", expectedPath: "/cliente-cadastro.html", text: ["Dados de Cadastro"] },
  { name: "esqueci-minha-senha", path: "/esqueci-minha-senha.html", mode: "anon", expectedPath: "/esqueci-minha-senha.html", text: ["Esqueci minha Senha"] },
  { name: "sobre", path: "/sobre.html", mode: "anon", expectedPath: "/sobre.html", text: ["Sobre a Loja"] },
  { name: "produtos-categoria", path: "/produto-por-categoria.html", mode: "anon", expectedPath: "/produto-por-categoria.html", text: ["Digite para filtrar os itens dessa tela.", "PIZZA ATUM"] },
  { name: "produtos-todas-categorias", path: "/produtostodascategoria.html", mode: "anon", expectedPath: "/produtostodascategoria.html", text: ["Digite para filtrar os itens dessa tela.", "PIZZA ATUM"] },
  { name: "erro-404", path: "/erro-404.html", mode: "anon", expectedPath: "/erro-404.html", text: ["404"] },
  { name: "admin-login", path: "/admin/login.html", mode: "anon", expectedPath: "/admin/login.html", text: ["Entre com os dados de ADM", "Administrativo"] },
  { name: "admin-index-bloqueado", path: "/admin/index.html", mode: "anon", expectedPath: "/admin/index.html", text: ["Entre com os dados de ADM", "Administrativo"] },
  { name: "admin-index2-bloqueado", path: "/admin/index2.html", mode: "anon", expectedPath: "/admin/index2.html", text: ["Entre com os dados de ADM", "Administrativo"] },
  { name: "admin-index", path: "/admin/index.html", mode: "admin", expectedPath: "/admin/index.html", text: ["Administrativo", "Top 10 clientes"] },
  { name: "admin-index2", path: "/admin/index2.html", mode: "admin", expectedPath: "/admin/index2.html", text: ["ADMIN Index2", "Voltar para o Admin"] },
  { name: "cliente-dados", path: "/cliente-dados.html", mode: "seeded", expectedPath: "/cliente-dados.html", text: ["Meus dados"] },
  { name: "cliente-endereco", path: "/cliente-endereco.html", mode: "seeded", expectedPath: "/cliente-endereco.html", text: ["Novo Endereco", "Cadastro Endereço", "Cadastro Endereco"] },
  { name: "novo-endereco", path: "/novo-endereco.html", mode: "seeded", expectedPath: "/novo-endereco.html", text: ["Novo Endereco"] },
  { name: "venda-historico", path: "/venda-historico.html", mode: "seeded", expectedPath: "/venda-historico.html", text: ["Quero de novo", "PIZZA ATUM"] },
  { name: "pedido-item", path: "/pedido-item.html", mode: "seeded", expectedPath: "/pedido-item.html", text: ["PIZZA ATUM", "E isso aiiii"] },
  { name: "pedido-finalizar", path: "/pedido-finalizar.html", mode: "seeded", expectedPath: "/pedido-finalizar.html", text: ["Boraa Fechar", "Confirmar pedido"] },
  { name: "cliente-endereco-seletor", path: "/cliente.endereco.html", mode: "seeded", expectedPath: "/cliente.endereco.html", text: ["Meus Enderecos"] },
  { name: "pedido-acompanhamento", path: "/pedido-acompanhamento.html", mode: "seeded", expectedPath: "/pedido-acompanhamento.html", text: ["Pedido", "Pedido recebido", "Pedido em preparo"] },
  { name: "pedido-pagamento-direto", path: "/pedido-pagamento.html", mode: "seeded", expectedPath: "/pedido-finalizar.html", text: ["Fluxo de pagamento precisa ser iniciado novamente.", "Confirmar pedido"] },
];

function buildApiPayload(url) {
  const pathname = new URL(url).pathname.replace("/rpfood/v1", "");

  if (/\/empresa\/1\/categoria\/\d+\/imagem$/i.test(pathname) || /\/empresa\/1\/produto\/\d+\/imagem$/i.test(pathname)) {
    return {
      status: 200,
      headers: { "Content-Type": "image/png", "Cache-Control": "public, max-age=60" },
      body: transparentPng,
    };
  }

  if (pathname === "/empresa/1/catalogo") {
    return json(200, catalog);
  }
  if (pathname === "/empresa/1/forma-pagamento") {
    return json(200, payments);
  }
  if (pathname === "/empresa/1/bairro") {
    return json(200, neighborhoods);
  }
  if (pathname === "/empresa/1/sobre") {
    return json(200, {
      aberta: true,
      empresa: company,
      configuracao: config,
      horarios: [{ dia: "Segunda", horaAbertura: "18:00", horaFechamento: "23:00", horaAbertura2: "", horaFechamento2: "" }],
      formasPagamento: payments,
    });
  }
  if (pathname === "/empresa/1/produto") {
    return json(200, [productBase, productSecond]);
  }
  if (pathname === "/empresa/1/produto/todos") {
    return json(200, [productBase, productSecond]);
  }
  if (/\/empresa\/1\/categoria\/\d+\/produto$/i.test(pathname)) {
    return json(200, [productBase, productSecond]);
  }
  if (/\/empresa\/1\/produto\/101$/i.test(pathname)) {
    return json(200, productBase);
  }
  if (/\/empresa\/1\/produto\/101\/opcional$/i.test(pathname)) {
    return json(200, optionals);
  }
  if (/\/empresa\/1\/produto\/101\/fracao$/i.test(pathname)) {
    return json(200, [productBase, productSecond]);
  }
  if (pathname === "/empresa/1/cliente/9001/endereco") {
    return json(200, [address]);
  }
  if (pathname === "/empresa/1/cliente/9001/endereco/7001") {
    return json(200, address);
  }
  if (pathname === "/empresa/1/cliente/9001") {
    return json(200, customer);
  }
  if (pathname === "/empresa/1/cliente") {
    return json(200, customer);
  }
  if (pathname === "/empresa/1/cliente/9001/pedido") {
    return json(200, history);
  }
  if (pathname === "/empresa/1/cliente/9001/pedido/ultima") {
    return json(200, trackedOrder);
  }
  if (pathname === "/empresa/1/pagamento/pix") {
    return json(200, pixPayment);
  }
  if (pathname === "/empresa/1/pagamento/pix/status") {
    return json(200, pixPayment);
  }
  if (pathname === "/empresa/1/pagamento/pix/confirmar") {
    return json(200, { idVenda: 5001, status: "A", valorTotal: 112, dataPedido: nowIso });
  }
  if (pathname === "/empresa/1/pedido") {
    return json(200, { idVenda: 5001, status: "A", valorTotal: 112, dataPedido: nowIso });
  }
  if (pathname === "/empresa/1/admin/login") {
    return json(200, adminSession);
  }
  if (pathname === "/empresa/1/admin/dashboard") {
    return json(200, adminDashboard);
  }
  if (pathname === "/empresa/1/admin/logout") {
    return {
      status: 204,
      headers: {},
      body: Buffer.from(""),
    };
  }
  if (pathname === "/empresa/1/auth/esqueci-senha") {
    return json(200, {});
  }

  return null;
}

function json(status, value) {
  return {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
    body: Buffer.from(JSON.stringify(value)),
  };
}

function normalize(value) {
  return (value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
}

async function installApiMocks(page) {
  await page.route(`${apiBase}/**`, async (route) => {
    const payload = buildApiPayload(route.request().url());
    if (!payload) {
      await route.fulfill(json(404, { message: "Mock nao configurado para esta rota." }));
      return;
    }

    await route.fulfill(payload);
  });
}

function buildSeedStorage(mode = "seeded") {
  const storage = {
    "rpmenu.site.companyId": JSON.stringify(1),
    "rpmenu.site.customer": JSON.stringify(customer),
    "rpmenu.site.cart": JSON.stringify(cart),
    "rpmenu.site.checkout": JSON.stringify(checkout),
    rpmenu_telefone: customer.celular,
  };

  if (mode === "admin") {
    storage["rpmenu.site.adminSession"] = JSON.stringify(adminSession);
  }

  return storage;
}

async function createContext(browser, mode) {
  const context = await browser.newContext({
    viewport: { width: 1600, height: 900 },
    locale: "pt-BR",
    timezoneId: "America/Sao_Paulo",
    serviceWorkers: "block",
  });

  if (mode === "seeded" || mode === "admin") {
    const seededStorage = buildSeedStorage(mode);
    await context.addInitScript((storage) => {
      for (const [key, value] of Object.entries(storage)) {
        window.localStorage.setItem(key, value);
      }
    }, seededStorage);
  }

  return context;
}

async function evaluateScenario(context, scenario) {
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
  await page.goto(`${baseUrl}${scenario.path}`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(1200);

  const snapshot = await page.evaluate(() => {
    const wrapper = document.querySelector("#main-wrapper");
    const text = (document.body.innerText || "").replace(/\s+/g, " ").trim();
    const errorBlocks = Array.from(document.querySelectorAll("div"))
      .map((element) => (element.textContent || "").replace(/\s+/g, " ").trim())
      .filter((value) => value && (value.includes("Erro") || value.includes("Telas administrativas") || value.includes("Fluxo de pagamento")));

    return {
      title: document.title,
      path: window.location.pathname,
      text,
      companyId: window.localStorage.getItem("rpmenu.site.companyId"),
      customer: window.localStorage.getItem("rpmenu.site.customer"),
      cart: window.localStorage.getItem("rpmenu.site.cart"),
      wrapperClass: wrapper ? wrapper.className : "",
      wrapperOpacity: wrapper ? window.getComputedStyle(wrapper).opacity : "",
      wrapperDisplay: wrapper ? window.getComputedStyle(wrapper).display : "",
      errorBlocks: errorBlocks.slice(0, 5),
    };
  });

  const screenshotPath = path.join(reportDir, `${scenario.name}.png`);
  await page.screenshot({ path: screenshotPath, fullPage: true });
  await page.close();

  const matchedText = scenario.text.some((token) => snapshot.text.includes(token));
  const matchedNormalizedText = scenario.text.some((token) => normalize(snapshot.text).includes(normalize(token)));
  const normalizedPath = snapshot.path.toLowerCase();
  const expectedPath = scenario.expectedPath.toLowerCase();
  const wrapperLooksVisible =
    snapshot.wrapperClass === "" ||
    (snapshot.wrapperClass.includes("show") && snapshot.wrapperOpacity !== "0" && snapshot.wrapperDisplay !== "none");

  const passed =
    normalizedPath.endsWith(expectedPath) &&
    (matchedText || matchedNormalizedText) &&
    wrapperLooksVisible &&
    pageErrors.length === 0;

  return {
    ...scenario,
    passed,
    finalPath: snapshot.path,
    title: snapshot.title,
    textSample: snapshot.text.slice(0, 240),
    wrapperClass: snapshot.wrapperClass,
    wrapperOpacity: snapshot.wrapperOpacity,
    wrapperDisplay: snapshot.wrapperDisplay,
    consoleErrors,
    pageErrors,
    errorBlocks: snapshot.errorBlocks,
    screenshotPath,
    storageCompanyId: snapshot.companyId,
    storageCustomer: snapshot.customer,
    storageCart: snapshot.cart,
  };
}

async function runPaymentFlow(context) {
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
  await page.goto(`${baseUrl}/pedido-finalizar.html`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(1200);
  await page.getByRole("button", { name: "Confirmar pedido" }).click();
  await page.waitForTimeout(1200);

  const snapshot = await page.evaluate(() => ({
    path: window.location.pathname,
    text: (document.body.innerText || "").replace(/\s+/g, " ").trim(),
  }));

  const screenshotPath = path.join(reportDir, "pedido-pagamento-fluxo.png");
  await page.screenshot({ path: screenshotPath, fullPage: true });
  await page.close();

  return {
    name: "pedido-pagamento-fluxo",
    path: "/pedido-finalizar.html -> confirmar pedido",
    mode: "seeded",
    expectedPath: "/pedido-pagamento.html",
    passed:
      snapshot.path.toLowerCase().endsWith("/pedido-pagamento.html") &&
      snapshot.text.includes("Pagamento Seguro") &&
      pageErrors.length === 0,
    finalPath: snapshot.path,
    title: "",
    textSample: snapshot.text.slice(0, 240),
    wrapperClass: "",
    wrapperOpacity: "",
    wrapperDisplay: "",
    consoleErrors,
    pageErrors,
    errorBlocks: [],
    screenshotPath,
  };
}

async function writeReport(results) {
  const total = results.length;
  const passed = results.filter((item) => item.passed).length;
  const failed = results.filter((item) => !item.passed);

  const lines = [
    `# QA Tela a Tela - RPMENU React - ${reportDate}`,
    "",
    `- Data: ${reportDate}`,
    `- Ambiente: ${baseUrl}`,
    `- API: ${apiBase}`,
    `- Resultado geral: ${passed}/${total} cenarios aprovados`,
    "",
    "## Resumo",
    "",
    ...failed.length
      ? failed.map((item) => `- Falha: \`${item.name}\` -> final \`${item.finalPath}\``)
      : ["- Todos os cenarios validados passaram."],
    "",
    "## Cenarios",
    "",
    "| Cenario | Contexto | Resultado | Rota final | Observacao |",
    "| --- | --- | --- | --- | --- |",
    ...results.map((item) => {
      const note =
        item.errorBlocks[0] ||
        item.pageErrors[0] ||
        item.consoleErrors[0] ||
        item.textSample.replace(/\|/g, "/").slice(0, 120);
      return `| ${item.name} | ${item.mode} | ${item.passed ? "OK" : "FALHA"} | \`${item.finalPath}\` | ${note} |`;
    }),
    "",
    "## Capturas",
    "",
    ...results.map((item) => `- [${path.basename(item.screenshotPath)}](${item.screenshotPath.replace(/\\/g, "/")})`),
    "",
  ];

  await fs.writeFile(reportFile, lines.join("\n"), "utf8");
}

async function main() {
  await fs.mkdir(reportDir, { recursive: true });

  const browser = await chromium.launch({
    channel: "msedge",
    headless: true,
  });

  const anonContext = await createContext(browser, "anon");
  const seededContext = await createContext(browser, "seeded");

  const results = [];

  for (const scenario of routes.filter((item) => item.mode === "anon")) {
    results.push(await evaluateScenario(anonContext, scenario));
  }

  for (const scenario of routes.filter((item) => item.mode === "seeded")) {
    results.push(await evaluateScenario(seededContext, scenario));
  }

  const adminContext = await createContext(browser, "admin");

  for (const scenario of routes.filter((item) => item.mode === "admin")) {
    results.push(await evaluateScenario(adminContext, scenario));
  }

  results.push(await runPaymentFlow(seededContext));

  await anonContext.close();
  await seededContext.close();
  await adminContext.close();
  await browser.close();

  await writeReport(results);

  const failed = results.filter((item) => !item.passed);
  console.log(JSON.stringify({ total: results.length, passed: results.length - failed.length, failed }, null, 2));

  if (failed.length) {
    process.exitCode = 1;
  }
}

await main();

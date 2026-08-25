import type {
  AdminDashboard,
  AdminSession,
  AdminTopItem,
  AdminUser,
  Bairro,
  Catalogo,
  Categoria,
  Cliente,
  Configuracao,
  Endereco,
  Empresa,
  FormaPagamento,
  HorarioFuncionamento,
  Opcional,
  PagamentoPix,
  PagamentoPixConfirmacaoRequest,
  PagamentoPixStatusRequest,
  PedidoCriado,
  PedidoPayload,
  PedidoRecuperado,
  Produto,
  ProdutoOpcional,
  SobreLoja,
  VendaAcompanhamento,
  VendaHistorico,
  VendaItem,
  VendaItemOpcional,
  VendaStatusLog,
} from "./types";
import { normalizeMaxFractionParts } from "./pedidoItemRules";

const DEFAULT_API_URL = "http://127.0.0.1:9000/rpfood/v1";

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" ? (value as Record<string, unknown>) : {};
}

function pick(source: Record<string, unknown>, ...keys: string[]): unknown {
  for (const key of keys) {
    if (key in source) {
      return source[key];
    }
  }

  return undefined;
}

function toStringValue(value: unknown): string {
  if (typeof value === "string") {
    return value;
  }

  if (value === null || value === undefined) {
    return "";
  }

  return String(value);
}

function firstStringValue(...values: unknown[]): string {
  for (const value of values) {
    const text = toStringValue(value).trim();
    if (text) {
      return text;
    }
  }

  return "";
}

function normalizeBase64ImageValue(value: string): string {
  const trimmed = value.trim();
  const dataUriMatch = trimmed.match(/^data:image\/[a-zA-Z0-9+.-]+;base64,(.+)$/);
  return dataUriMatch?.[1]?.trim() ?? trimmed;
}

function digitsOnly(value: string): string {
  return value.replace(/\D/g, "");
}

function toNumber(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  const normalized = toStringValue(value).trim().replace(",", ".");
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function toBoolean(value: unknown): boolean {
  if (typeof value === "boolean") {
    return value;
  }

  const normalized = toStringValue(value).trim().toLowerCase();
  return normalized === "true" || normalized === "1" || normalized === "sim" || normalized === "s" || normalized === "yes";
}

function toArray(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

function normalizeError(data: unknown, fallback: string): string {
  const record = asRecord(data);
  const message = pick(record, "message", "Message", "error", "Error");
  const text = toStringValue(message).trim();
  return text || fallback;
}

function baseUrl(): string {
  return (import.meta.env.VITE_RPMENU_API_URL ?? import.meta.env.VITE_RPFOOD_API_URL ?? DEFAULT_API_URL).replace(/\/+$/, "");
}

function buildUrl(path: string): string {
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  return `${baseUrl()}${normalizedPath}`;
}

/**
 * URL de imagem estavel.
 *
 * Antes cada chamada carimbava `v=Date.now()-nonce`, o que gerava uma URL nova a
 * cada carregamento e anulava tanto o cache do navegador quanto o do service
 * worker. A troca de imagem no cadastro continua aparecendo na hora porque a API
 * responde com ETag e revalida (Cache-Control: max-age=300).
 *
 * `cacheKey` segue disponivel para forcar a releitura em telas administrativas,
 * onde o lojista precisa ver o upload imediatamente.
 */
function withImageCacheBuster(url: string, cacheKey?: string): string {
  if (!cacheKey) {
    return url;
  }

  const separator = url.includes("?") ? "&" : "?";
  return `${url}${separator}v=${encodeURIComponent(cacheKey)}`;
}

function buildCategoryImageUrl(
  companyId: number,
  categoryId: number,
  variant: "full" | "thumb" = "full",
  cacheKey?: string,
): string {
  const variantQuery = variant === "thumb" ? "?variant=thumb" : "";
  return withImageCacheBuster(buildUrl(`/empresa/${companyId}/categoria/${categoryId}/imagem${variantQuery}`), cacheKey);
}

function buildProductImageUrl(
  companyId: number,
  productId: number,
  variant: "full" | "thumb" = "full",
  cacheKey?: string,
): string {
  const variantQuery = variant === "thumb" ? "?variant=thumb" : "";
  return withImageCacheBuster(buildUrl(`/empresa/${companyId}/produto/${productId}/imagem${variantQuery}`), cacheKey);
}

function normalizeEndereco(raw: unknown): Endereco {
  const record = asRecord(raw);
  const taxa = toNumber(pick(record, "taxa", "Taxa", "taxaEntrega", "TaxaEntrega"));

  return {
    idEndereco: toNumber(pick(record, "idEndereco", "IdEndereco")),
    idCliente: toNumber(pick(record, "idCliente", "IdCliente")),
    idEmpresa: toNumber(pick(record, "idEmpresa", "IdEmpresa")),
    cep: toStringValue(pick(record, "cep", "CEP")),
    endereco: toStringValue(pick(record, "endereco", "Endereco")),
    enderecoCompleto: toStringValue(pick(record, "enderecoCompleto", "EnderecoCompleto")),
    idBairro: toNumber(pick(record, "idBairro", "IdBairro")),
    bairro: toStringValue(pick(record, "bairro", "Bairro", "Descricao")),
    taxaEntrega: toNumber(pick(record, "taxaEntrega", "TaxaEntrega", "taxa", "Taxa"), taxa),
    numero: toStringValue(pick(record, "numero", "Numero")),
    complemento: toStringValue(pick(record, "complemento", "Complemento")),
    pontoReferencia: toStringValue(pick(record, "pontoReferencia", "PontoReferencia")),
    idCidade: toNumber(pick(record, "idCidade", "IdCidade")),
    UF: toStringValue(pick(record, "UF", "uf")),
    enderecoPadrao: toBoolean(pick(record, "enderecoPadrao", "EnderecoPadrao")),
    taxa,
  };
}

function normalizeEmpresa(raw: unknown): Empresa {
  const record = asRecord(raw);

  return {
    idEmpresa: toNumber(pick(record, "idEmpresa", "IdEmpresa")),
    nome: toStringValue(pick(record, "nome", "Nome")),
    razaoSocial: toStringValue(pick(record, "razaoSocial", "RazaoSocial")),
    cnpj: toStringValue(pick(record, "cnpj", "CNPJ")),
    email: toStringValue(pick(record, "email", "Email")),
    fone1: toStringValue(pick(record, "fone1", "Fone1")),
    endereco: normalizeEndereco(pick(record, "endereco", "Endereco")),
    quantidadeMaximaFracaoProdutos: normalizeMaxFractionParts(
      pick(record, "quantidadeMaximaFracaoProdutos", "QuantidadeMaximaFracaoProdutos", "quantidade_maxima_fracao_produtos"),
    ),
  };
}

function normalizeConfiguracao(raw: unknown): Configuracao {
  const record = asRecord(raw);

  return {
    utilizaCEP: toBoolean(pick(record, "UtilizarCEP", "utilizarCEP", "utilizaCEP", "UtilizaCEP")),
    pedidoMinimo: toNumber(pick(record, "pedidoMinimo", "PedidoMinimo")),
    permiteRetiradaNoLocal: toBoolean(
      pick(
        record,
        "PermiteRetiradanoLocal",
        "permiteRetiradanoLocal",
        "PermiteRetiradaNoLocal",
        "permiteRetiradaNoLocal",
        "UtilizaRetirada",
        "utilizaRetirada",
        "UtilizaTipoEntregaRetirada",
        "utilizaTipoEntregaRetirada",
        "utiliza_tipo_entrega_retirada",
      ),
    ),
    tempoRetirada: toStringValue(
      pick(record, "TempoRetiradaRPFood", "tempoRetiradaRPFood", "tempoRetirada"),
    ),
    tempoEntrega: toStringValue(
      pick(record, "TempoEntregaRPFood", "tempoEntregaRPFood", "tempoEntrega"),
    ),
    utilizaControleOpcionais: toBoolean(
      pick(record, "utilizacontroleopcionais", "UtilizaControleOpcionais"),
    ),
    integracaoMercadoPago: toBoolean(
      pick(record, "IntegracaoMercadoPago", "integracaoMercadoPago"),
    ),
  };
}

function normalizeCategoria(raw: unknown, companyId: number): Categoria {
  const record = asRecord(raw);
  const codigo = toNumber(pick(record, "codigo", "Codigo"));

  return {
    codigo,
    descricao: toStringValue(pick(record, "descricao", "Descricao")),
    imageUrl: buildCategoryImageUrl(companyId, codigo),
    thumbnailUrl: buildCategoryImageUrl(companyId, codigo, "thumb"),
  };
}

function normalizeProduto(raw: unknown, fallbackCompanyId: number): Produto {
  const record = asRecord(raw);
  const companyId = toNumber(pick(record, "idEmpresa", "IdEmpresa"), fallbackCompanyId);
  const codigo = toNumber(pick(record, "codigo", "Codigo"));

  return {
    codigo,
    idEmpresa: companyId,
    idGrupo: toNumber(pick(record, "idGrupo", "IdGrupo")),
    descricao: toStringValue(pick(record, "descricao", "Descricao")),
    observacao: toStringValue(pick(record, "observacao", "Observacao")),
    idSituacao: toNumber(pick(record, "id_situacao", "idSituacao", "IdSituacao", "situacao", "Situacao")),
    situacao: toStringValue(pick(record, "situacao", "Situacao")),
    situacaoDescricao: toStringValue(pick(record, "situacaoDescricao", "SituacaoDescricao")),
    valFinal: toNumber(pick(record, "valFinal", "ValFinal")),
    destaqueWeb: toBoolean(pick(record, "destaqueWeb", "DestaqueWeb")),
    vendaPorTamanho: toBoolean(pick(record, "vendaPorTamanho", "VendaPorTamanho")),
    permiteFrac: toBoolean(pick(record, "permiteFrac", "PermiteFrac")),
    valorTamanhoP: toNumber(pick(record, "valorTamanhoP", "ValorTamanhoP")),
    valorTamanhoM: toNumber(pick(record, "valorTamanhoM", "ValorTamanhoM")),
    valorTamanhoG: toNumber(pick(record, "valorTamanhoG", "ValorTamanhoG")),
    valorTamanhoGG: toNumber(pick(record, "valorTamanhoGG", "ValorTamanhoGG")),
    valorTamanhoExtra: toNumber(pick(record, "valorTamanhoExtra", "ValorTamanhoExtra")),
    tamanhoP: toStringValue(pick(record, "tamanhoP", "TamanhoP")),
    tamanhoM: toStringValue(pick(record, "tamanhoM", "TamanhoM")),
    tamanhoG: toStringValue(pick(record, "tamanhoG", "TamanhoG")),
    tamanhoGG: toStringValue(pick(record, "tamanhoGG", "TamanhoGG")),
    tamanhoExtra: toStringValue(pick(record, "tamanhoExtra", "TamanhoExtra")),
    tamanhoPadrao: toStringValue(pick(record, "tamanhoPadrao", "TamanhoPadrao")),
    opcionalMinimo: toNumber(pick(record, "OpcionalMinimo", "opcionalMinimo")),
    opcionalMaximo: toNumber(pick(record, "OpcionalMaximo", "opcionalMaximo")),
    restringirVenda: toBoolean(pick(record, "restringirVenda", "RestringirVenda")),
    imageUrl: buildProductImageUrl(companyId, codigo),
    thumbnailUrl: buildProductImageUrl(companyId, codigo, "thumb"),
  };
}

function normalizeOpcional(raw: unknown): Opcional {
  const record = asRecord(raw);

  return {
    codigo: toNumber(pick(record, "codigo", "Codigo")),
    idEmpresa: toNumber(pick(record, "idEmpresa", "IdEmpresa")),
    descricao: toStringValue(pick(record, "descricao", "Descricao")),
    valor: toNumber(pick(record, "valor", "Valor")),
    valorTamanhoP: toNumber(pick(record, "valorTamanhoP", "ValorTamanhoP")),
    valorTamanhoM: toNumber(pick(record, "valorTamanhoM", "ValorTamanhoM")),
    valorTamanhoG: toNumber(pick(record, "valorTamanhoG", "ValorTamanhoG")),
    valorTamanhoGG: toNumber(pick(record, "valorTamanhoGG", "ValorTamanhoGG")),
    valorTamanhoExtra: toNumber(pick(record, "valorTamanhoExtra", "ValorTamanhoExtra")),
    tamanhoP: toStringValue(pick(record, "tamanhoP", "TamanhoP")),
    tamanhoM: toStringValue(pick(record, "tamanhoM", "TamanhoM")),
    tamanhoG: toStringValue(pick(record, "tamanhoG", "TamanhoG")),
    tamanhoGG: toStringValue(pick(record, "tamanhoGG", "TamanhoGG")),
    tamanhoExtra: toStringValue(pick(record, "tamanhoExtra", "TamanhoExtra")),
  };
}

function normalizeProdutoOpcional(raw: unknown): ProdutoOpcional {
  const record = asRecord(raw);
  const guarnicao = asRecord(pick(record, "Guarnicao", "guarnicao"));

  return {
    idEmpresa: toNumber(pick(record, "idEmpresa", "IdEmpresa")),
    codigoProduto: toNumber(pick(record, "codigoProduto", "CodigoProduto")),
    codigoOpcional: toNumber(pick(record, "codigoOpcional", "CodigoOpcional")),
    groupId: toNumber(pick(guarnicao, "Id", "id"), toNumber(pick(record, "IdGuarnicao", "idGuarnicao"))),
    groupDescription: toStringValue(pick(guarnicao, "Descricao", "descricao")),
    opcionalMinimo: toNumber(pick(guarnicao, "OpcionalMinimo", "opcionalMinimo")),
    opcionalMaximo: toNumber(pick(guarnicao, "OpcionalMaximo", "opcionalMaximo")),
    opcional: normalizeOpcional(pick(record, "opcional", "Opcional")),
  };
}

function normalizeFormaPagamento(raw: unknown): FormaPagamento {
  const record = asRecord(raw);

  return {
    id: toNumber(pick(record, "id", "Id")),
    idEmpresa: toNumber(pick(record, "idEmpresa", "IdEmpresa")),
    descricao: toStringValue(pick(record, "descricao", "Descricao")),
    permiteTroco: toBoolean(pick(record, "permiteTroco", "PermiteTroco")),
    pagamentoOnline: toBoolean(pick(record, "PagamentoOnline", "pagamentoOnline")),
    utilizaPix: toBoolean(pick(record, "UtilizaPIX", "UtilizaPix", "utilizaPIX", "utilizaPix")),
  };
}

function normalizeBairro(raw: unknown): Bairro {
  const record = asRecord(raw);

  return {
    idEmpresa: toNumber(pick(record, "IdEmpresa", "idEmpresa")),
    idBairro: toNumber(pick(record, "IdBairro", "idBairro")),
    descricao: toStringValue(pick(record, "Descricao", "descricao")),
    taxa: toNumber(pick(record, "taxa", "Taxa")),
  };
}

function normalizeCliente(raw: unknown): Cliente {
  const record = asRecord(raw);

  return {
    idCliente: toNumber(pick(record, "idCliente", "IdCliente")),
    idEmpresa: toNumber(pick(record, "idEmpresa", "IdEmpresa")),
    nome: toStringValue(pick(record, "nome", "Nome")),
    email: toStringValue(pick(record, "email", "Email")),
    senha: toStringValue(pick(record, "senha", "Senha")),
    celular: toStringValue(pick(record, "celular", "Celular")),
    telefone: toStringValue(pick(record, "telefone", "Telefone")),
    enderecos: toArray(pick(record, "enderecos", "Enderecos")).map((item) => normalizeEndereco(item)),
  };
}

function normalizeAdminUser(raw: unknown): AdminUser {
  const record = asRecord(raw);

  return {
    codigo: toNumber(pick(record, "codigo", "Codigo")),
    nome: toStringValue(pick(record, "nome", "Nome")),
    email: toStringValue(pick(record, "email", "Email")),
  };
}

function normalizeAdminTopItem(raw: unknown): AdminTopItem {
  const record = asRecord(raw);

  return {
    label: toStringValue(pick(record, "label", "Label")),
    value: toStringValue(pick(record, "value", "Value")),
  };
}

function normalizeAdminSession(raw: unknown): AdminSession {
  const record = asRecord(raw);

  return {
    token: toStringValue(pick(record, "token", "Token")),
    usuario: normalizeAdminUser(pick(record, "usuario", "Usuario")),
  };
}

function normalizeAdminDashboard(raw: unknown): AdminDashboard {
  const record = asRecord(raw);

  return {
    sincronizacao: toStringValue(pick(record, "sincronizacao", "Sincronizacao")),
    qtdeVendas: toStringValue(pick(record, "qtdeVendas", "QtdeVendas")),
    valorVendas: toStringValue(pick(record, "valorVendas", "ValorVendas")),
    taxaEntrega: toStringValue(pick(record, "taxaEntrega", "TaxaEntrega")),
    topClientes: toArray(pick(record, "topClientes", "TopClientes")).map((item) =>
      normalizeAdminTopItem(item),
    ),
    topBairros: toArray(pick(record, "topBairros", "TopBairros")).map((item) =>
      normalizeAdminTopItem(item),
    ),
    topProdutos: toArray(pick(record, "topProdutos", "TopProdutos")).map((item) =>
      normalizeAdminTopItem(item),
    ),
  };
}

function normalizeHorarioFuncionamento(raw: unknown): HorarioFuncionamento {
  const record = asRecord(raw);

  return {
    dia: toStringValue(pick(record, "dia", "Dia")),
    horaAbertura: toStringValue(pick(record, "horaAbertura", "HoraAbertura")),
    horaFechamento: toStringValue(pick(record, "horaFechamento", "HoraFechamento")),
    horaAbertura2: toStringValue(pick(record, "horaAbertura2", "HoraAbertura2")),
    horaFechamento2: toStringValue(pick(record, "horaFechamento2", "HoraFechamento2")),
  };
}

function normalizeVendaItemOpcional(raw: unknown): VendaItemOpcional {
  const record = asRecord(raw);

  return {
    quantidade: toNumber(pick(record, "quantidade", "Quantidade")),
    valorUnitario: toNumber(pick(record, "valorUnitario", "ValorUnitario")),
    valorTotal: toNumber(pick(record, "valorTotal", "ValorTotal")),
    opcional: normalizeOpcional(pick(record, "opcional", "Opcional")),
  };
}

function normalizeVendaStatusLog(raw: unknown): VendaStatusLog {
  const record = asRecord(raw);
  return {
    data: toStringValue(pick(record, "data", "Data")),
    situacao: toStringValue(pick(record, "situacao", "Situacao")),
    situacaoDescricao: toStringValue(pick(record, "situacaoDescricao", "SituacaoDescricao")),
  };
}

function normalizeVendaItem(raw: unknown, companyId: number): VendaItem {
  const record = asRecord(raw);

  return {
    numeroItem: toNumber(pick(record, "numeroItem", "NumeroItem")),
    quantidade: toNumber(pick(record, "quantidade", "Quantidade")),
    tamanho: toStringValue(pick(record, "tamanho", "Tamanho")),
    observacao: toStringValue(pick(record, "observacao", "Observacao")),
    valorUnitario: toNumber(pick(record, "valorUnitario", "ValorUnitario")),
    valorTotalProduto: toNumber(pick(record, "valorTotalProduto", "ValorTotalProduto")),
    produto: normalizeProduto(pick(record, "produto", "Produto"), companyId),
    opcionais: toArray(pick(record, "opcionais", "Opcionais")).map((item) => normalizeVendaItemOpcional(item)),
  };
}

function normalizeVenda(raw: unknown, fallbackCompanyId: number): VendaAcompanhamento {
  const record = asRecord(raw);
  const companyId = toNumber(pick(record, "idEmpresa", "IdEmpresa"), fallbackCompanyId);

  return {
    id: toNumber(pick(record, "id", "Id")),
    data: toStringValue(pick(record, "data", "Data")),
    taxaEntrega: toNumber(pick(record, "taxaEntrega", "TaxaEntrega")),
    valorTotal: toNumber(pick(record, "valorTotal", "ValorTotal")),
    valorAReceber: toNumber(pick(record, "valorAReceber", "ValorAReceber")),
    troco: toNumber(pick(record, "troco", "Troco")),
    observacao: toStringValue(pick(record, "observacao", "Observacao")),
    tipoEntregaDescription: toStringValue(
      pick(record, "tipoEntregaDescription", "TipoEntregaDescription"),
    ),
    situacaoDescription: toStringValue(
      pick(record, "situacaoDescription", "SituacaoDescription"),
    ),
    formaPagamento: normalizeFormaPagamento(pick(record, "formaPagamento", "FormaPagamento")),
    vendaEndereco: normalizeEndereco(pick(record, "vendaEndereco", "VendaEndereco")),
    listaStatus: toArray(pick(record, "listaStatus", "ListaStatus")).map((item) => normalizeVendaStatusLog(item)),
    itens: toArray(pick(record, "itens", "Itens")).map((item) => normalizeVendaItem(item, companyId)),
  };
}

function normalizeCatalogo(raw: unknown, companyId: number): Catalogo {
  const record = asRecord(raw);
  const empresa = normalizeEmpresa(pick(record, "empresa", "Empresa"));
  const normalizedCompanyId = empresa.idEmpresa || companyId;

  return {
    aberta: toBoolean(pick(record, "aberta", "Aberta")),
    empresa,
    configuracao: normalizeConfiguracao(pick(record, "configuracao", "Configuracao")),
    categorias: toArray(pick(record, "categorias", "Categorias")).map((item) =>
      normalizeCategoria(item, normalizedCompanyId),
    ),
    destaques: toArray(pick(record, "destaques", "Destaques")).map((item) =>
      normalizeProduto(item, normalizedCompanyId),
    ),
  };
}

function normalizeSobre(raw: unknown): SobreLoja {
  const record = asRecord(raw);
  const empresa = normalizeEmpresa(pick(record, "empresa", "Empresa"));

  return {
    aberta: toBoolean(pick(record, "aberta", "Aberta")),
    empresa,
    configuracao: normalizeConfiguracao(pick(record, "configuracao", "Configuracao")),
    horarios: toArray(pick(record, "horarios", "Horarios")).map((item) =>
      normalizeHorarioFuncionamento(item),
    ),
    formasPagamento: toArray(pick(record, "formasPagamento", "FormasPagamento")).map((item) =>
      normalizeFormaPagamento(item),
    ),
  };
}

function normalizePedidoRecuperado(raw: unknown, companyId: number): PedidoRecuperado {
  const record = asRecord(raw);

  return {
    cliente: normalizeCliente(pick(record, "cliente", "Cliente")),
    endereco: normalizeEndereco(pick(record, "endereco", "Endereco")),
    formaPagamento: normalizeFormaPagamento(pick(record, "formaPagamento", "FormaPagamento")),
    itens: toArray(pick(record, "itens", "Itens")).map((item) => {
      const itemRecord = asRecord(item);
      return {
        quantidade: toNumber(pick(itemRecord, "quantidade", "Quantidade")),
        tamanho: toStringValue(pick(itemRecord, "tamanho", "Tamanho")),
        observacao: toStringValue(pick(itemRecord, "observacao", "Observacao")),
        valorUnitario: toNumber(pick(itemRecord, "valorUnitario", "ValorUnitario")),
        valorTotalProduto: toNumber(pick(itemRecord, "valorTotalProduto", "ValorTotalProduto")),
        produto: normalizeProduto(pick(itemRecord, "produto", "Produto"), companyId),
        opcionais: toArray(pick(itemRecord, "opcionais", "Opcionais")).map((option) => ({
          quantidade: toNumber(pick(asRecord(option), "quantidade", "Quantidade")),
          opcional: normalizeOpcional(pick(asRecord(option), "opcional", "Opcional")),
        })),
        fracoes: toArray(pick(itemRecord, "fracoes", "Fracoes")).map((fraction) => ({
          quantidade: toNumber(pick(asRecord(fraction), "quantidade", "Quantidade"), 1),
          produto: normalizeProduto(pick(asRecord(fraction), "produto", "Produto"), companyId),
        })),
      };
    }),
    observacao: toStringValue(pick(record, "observacao", "Observacao")),
    tipoEntrega: toStringValue(pick(record, "tipoEntrega", "TipoEntrega")),
    valorAReceber: toNumber(pick(record, "valorAReceber", "ValorAReceber")),
    taxaEntrega: toNumber(pick(record, "taxaEntrega", "TaxaEntrega")),
    valorTotal: toNumber(pick(record, "valorTotal", "ValorTotal")),
  };
}

function normalizePagamentoPix(raw: unknown): PagamentoPix {
  const rootRecord = asRecord(raw);
  const nestedRecord = asRecord(
    pick(rootRecord, "pagamento", "Pagamento", "payment", "Payment", "data", "Data"),
  );
  const record = Object.keys(nestedRecord).length ? nestedRecord : rootRecord;
  const pointOfInteraction = asRecord(
    pick(record, "point_of_interaction", "pointOfInteraction", "PointOfInteraction"),
  );
  const transactionData = asRecord(
    pick(pointOfInteraction, "transaction_data", "transactionData", "TransactionData"),
  );
  const qrCodeBase64 = firstStringValue(
    pick(record, "qrCodeBase64", "QrCodeBase64", "QRCodeBase64", "qrcodeBase64", "qrcodebase64", "qr_code_base64"),
    pick(transactionData, "qr_code_base64", "qrCodeBase64", "QrCodeBase64", "QRCodeBase64"),
  );
  const qrCodeDigitavel = firstStringValue(
    pick(record, "qrCodeDigitavel", "QrCodeDigitavel", "QRCodeDigitavel", "qrcodeDigitavel", "qrcode", "qrCode", "QrCode", "QRCode", "qr_code", "codigoPix", "codigoDigitavel"),
    pick(transactionData, "qr_code", "qrCode", "QrCode", "QRCode"),
  );
  const qrCodeUrl = firstStringValue(
    pick(record, "qrCodeUrl", "qrCodeURL", "QrCodeUrl", "QrCodeURL", "QRCodeUrl", "QRCodeURL", "qrcodeUrl", "qrcodeurl", "ticketUrl", "ticket_url", "url", "Url", "URL"),
    pick(transactionData, "ticket_url", "ticketUrl", "qrCodeUrl", "qrCodeURL"),
  );

  return {
    idPix: firstStringValue(pick(record, "idPix", "IdPix", "idPIX", "IdPIX", "id", "ID")),
    qrCodeBase64: normalizeBase64ImageValue(qrCodeBase64),
    qrCodeDigitavel,
    qrCodeUrl,
    status: firstStringValue(pick(record, "status", "Status")),
    valorTotal: toNumber(pick(record, "valorTotal", "ValorTotal", "transaction_amount", "transactionAmount")),
  };
}

async function request<T>(
  path: string,
  init: RequestInit,
  transform: (raw: unknown) => T,
): Promise<T> {
  const response = await fetch(buildUrl(path), {
    ...init,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      ...(init.headers ?? {}),
    },
  });

  const contentType = response.headers.get("content-type") ?? "";
  const hasJson = contentType.includes("application/json");
  const responseText = await response.text();
  const trimmedText = responseText.trim();
  let data: unknown = responseText;
  if (trimmedText && (hasJson || trimmedText.startsWith("{") || trimmedText.startsWith("["))) {
    try {
      data = JSON.parse(trimmedText);
    } catch {
      data = responseText;
    }
  }

  if (!response.ok) {
    const fallback = typeof data === "string" && data.trim() ? data.trim() : `Erro ${response.status}`;
    throw new Error(normalizeError(data, fallback));
  }

  return transform(data);
}

export const apiConfig = {
  baseUrl: baseUrl(),
  defaultEmpresaId: toNumber(import.meta.env.VITE_RPMENU_EMPRESA_ID ?? import.meta.env.VITE_RPFOOD_EMPRESA_ID ?? "1", 1),
};

export async function fetchCatalogo(companyId: number): Promise<Catalogo> {
  return request(`/empresa/${companyId}/catalogo`, { method: "GET" }, (raw) =>
    normalizeCatalogo(raw, companyId),
  );
}

export async function fetchProdutosPorCategoria(
  companyId: number,
  categoryId: number,
  filtro?: string,
): Promise<Produto[]> {
  const query = filtro?.trim() ? `?filtro=${encodeURIComponent(filtro.trim())}` : "";
  return request(`/empresa/${companyId}/categoria/${categoryId}/produto${query}`, { method: "GET" }, (raw) =>
    toArray(raw).map((item) => normalizeProduto(item, companyId)),
  );
}

export async function fetchProdutos(companyId: number, filtro?: string): Promise<Produto[]> {
  const query = filtro?.trim() ? `?filtro=${encodeURIComponent(filtro.trim())}` : "";
  return request(`/empresa/${companyId}/produto/todos${query}`, { method: "GET" }, (raw) =>
    toArray(raw).map((item) => normalizeProduto(item, companyId)),
  );
}

export async function fetchProdutoDetalhe(companyId: number, productId: number): Promise<Produto> {
  return request(`/empresa/${companyId}/produto/${productId}`, { method: "GET" }, (raw) =>
    normalizeProduto(raw, companyId),
  );
}

export async function fetchProdutoOpcionais(
  companyId: number,
  productId: number,
  tamanho: string,
): Promise<ProdutoOpcional[]> {
  const query = tamanho ? `?tamanho=${encodeURIComponent(tamanho)}` : "";
  return request(`/empresa/${companyId}/produto/${productId}/opcional${query}`, { method: "GET" }, (raw) =>
    toArray(raw).map((item) => normalizeProdutoOpcional(item)),
  );
}

export async function fetchProdutoFracoes(
  companyId: number,
  productId: number,
  tamanho: string,
): Promise<Produto[]> {
  const query = tamanho ? `?tamanho=${encodeURIComponent(tamanho)}` : "";
  return request(`/empresa/${companyId}/produto/${productId}/fracao${query}`, { method: "GET" }, (raw) =>
    toArray(raw).map((item) => normalizeProduto(item, companyId)),
  );
}

export async function fetchFormasPagamento(companyId: number): Promise<FormaPagamento[]> {
  return request(`/empresa/${companyId}/forma-pagamento`, { method: "GET" }, (raw) =>
    toArray(raw).map((item) => normalizeFormaPagamento(item)),
  );
}

export async function fetchBairros(companyId: number): Promise<Bairro[]> {
  return request(`/empresa/${companyId}/bairro`, { method: "GET" }, (raw) =>
    toArray(raw).map((item) => normalizeBairro(item)),
  );
}

export async function buscarEnderecoPorCep(companyId: number, cep: string): Promise<Endereco> {
  return request(`/empresa/${companyId}/cep/${digitsOnly(cep)}`, { method: "GET" }, (raw) =>
    normalizeEndereco(raw),
  );
}

export async function buscarEnderecoPorBairro(
  companyId: number,
  bairroId: number,
): Promise<Endereco> {
  return request(`/empresa/${companyId}/bairro/${bairroId}/endereco`, { method: "GET" }, (raw) =>
    normalizeEndereco(raw),
  );
}

export async function loginCliente(companyId: number, telefone: string): Promise<Cliente> {
  return request(
    `/empresa/${companyId}/auth/login`,
    {
      method: "POST",
      body: JSON.stringify({ telefone }),
    },
    (raw) => normalizeCliente(raw),
  );
}

export async function loginAdmin(
  companyId: number,
  login: string,
  senha: string,
): Promise<AdminSession> {
  return request(
    `/empresa/${companyId}/admin/login`,
    {
      method: "POST",
      body: JSON.stringify({ login, senha }),
    },
    (raw) => normalizeAdminSession(raw),
  );
}

export async function fetchAdminDashboard(
  companyId: number,
  token: string,
): Promise<AdminDashboard> {
  return request(
    `/empresa/${companyId}/admin/dashboard`,
    {
      method: "GET",
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
    (raw) => normalizeAdminDashboard(raw),
  );
}

export async function logoutAdmin(companyId: number, token: string): Promise<void> {
  return request(
    `/empresa/${companyId}/admin/logout`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({}),
    },
    () => undefined,
  );
}

export async function esqueciMinhaSenhaCliente(companyId: number, email: string): Promise<void> {
  return request(
    `/empresa/${companyId}/auth/esqueci-senha`,
    {
      method: "POST",
      body: JSON.stringify({ email }),
    },
    () => undefined,
  );
}

export async function fetchCliente(companyId: number, customerId: number): Promise<Cliente> {
  return request(`/empresa/${companyId}/cliente/${customerId}`, { method: "GET" }, (raw) =>
    normalizeCliente(raw),
  );
}

export async function salvarCliente(companyId: number, cliente: Cliente): Promise<Cliente> {
  const method = cliente.idCliente > 0 ? "PUT" : "POST";
  const path =
    cliente.idCliente > 0
      ? `/empresa/${companyId}/cliente/${cliente.idCliente}`
      : `/empresa/${companyId}/cliente`;

  return request(
    path,
    {
      method,
      body: JSON.stringify(cliente),
    },
    (raw) => normalizeCliente(raw),
  );
}

export async function fetchEnderecosCliente(
  companyId: number,
  customerId: number,
): Promise<Endereco[]> {
  return request(`/empresa/${companyId}/cliente/${customerId}/endereco`, { method: "GET" }, (raw) =>
    toArray(raw).map((item) => normalizeEndereco(item)),
  );
}

export async function fetchEnderecoCliente(
  companyId: number,
  customerId: number,
  addressId: number,
): Promise<Endereco> {
  return request(
    `/empresa/${companyId}/cliente/${customerId}/endereco/${addressId}`,
    { method: "GET" },
    (raw) => normalizeEndereco(raw),
  );
}

export async function salvarEnderecoCliente(
  companyId: number,
  customerId: number,
  endereco: Endereco,
): Promise<Cliente> {
  const method = endereco.idEndereco > 0 ? "PUT" : "POST";
  const path =
    endereco.idEndereco > 0
      ? `/empresa/${companyId}/cliente/${customerId}/endereco/${endereco.idEndereco}`
      : `/empresa/${companyId}/cliente/${customerId}/endereco`;

  return request(
    path,
    {
      method,
      body: JSON.stringify(endereco),
    },
    (raw) => normalizeCliente(raw),
  );
}

export async function definirEnderecoPadraoCliente(
  companyId: number,
  customerId: number,
  addressId: number,
): Promise<Cliente> {
  return request(
    `/empresa/${companyId}/cliente/${customerId}/endereco/${addressId}/padrao`,
    {
      method: "PUT",
      body: JSON.stringify({}),
    },
    (raw) => normalizeCliente(raw),
  );
}

export async function fetchPedidosCliente(
  companyId: number,
  customerId: number,
): Promise<VendaHistorico[]> {
  return request(`/empresa/${companyId}/cliente/${customerId}/pedido`, { method: "GET" }, (raw) =>
    toArray(raw).map((item) => normalizeVenda(item, companyId)),
  );
}

export async function fetchUltimoPedidoCliente(
  companyId: number,
  customerId: number,
): Promise<VendaAcompanhamento | null> {
  return request(`/empresa/${companyId}/cliente/${customerId}/pedido/ultima`, { method: "GET" }, (raw) => {
    if (!raw) {
      return null;
    }

    const record = asRecord(raw);
    if (Object.keys(record).length === 0) {
      return null;
    }

    return normalizeVenda(record, companyId);
  });
}

export async function repetirPedido(
  companyId: number,
  customerId: number,
  saleId: number,
  cliente: Cliente,
): Promise<PedidoRecuperado> {
  return request(
    `/empresa/${companyId}/cliente/${customerId}/pedido/${saleId}/repetir`,
    {
      method: "POST",
      body: JSON.stringify({ cliente }),
    },
    (raw) => normalizePedidoRecuperado(raw, companyId),
  );
}

export async function criarPedido(companyId: number, payload: PedidoPayload): Promise<PedidoCriado> {
  return request(
    `/empresa/${companyId}/pedido`,
    {
      method: "POST",
      body: JSON.stringify(payload),
    },
    (raw) => {
      const record = asRecord(raw);
      return {
        idVenda: toNumber(pick(record, "idVenda", "IdVenda")),
        status: toStringValue(pick(record, "status", "Status")),
        valorTotal: toNumber(pick(record, "valorTotal", "ValorTotal")),
        dataPedido: toStringValue(pick(record, "dataPedido", "DataPedido")),
      };
    },
  );
}

export async function iniciarPagamentoPix(
  companyId: number,
  payload: PedidoPayload,
): Promise<PagamentoPix> {
  return request(
    `/empresa/${companyId}/pagamento/pix`,
    {
      method: "POST",
      body: JSON.stringify(payload),
    },
    (raw) => normalizePagamentoPix(raw),
  );
}

export async function consultarPagamentoPix(
  companyId: number,
  payload: PagamentoPixStatusRequest,
): Promise<PagamentoPix> {
  return request(
    `/empresa/${companyId}/pagamento/pix/status`,
    {
      method: "POST",
      body: JSON.stringify(payload),
    },
    (raw) => normalizePagamentoPix(raw),
  );
}

export async function confirmarPagamentoPix(
  companyId: number,
  payload: PagamentoPixConfirmacaoRequest,
): Promise<PedidoCriado> {
  return request(
    `/empresa/${companyId}/pagamento/pix/confirmar`,
    {
      method: "POST",
      body: JSON.stringify(payload),
    },
    (raw) => {
      const record = asRecord(raw);
      return {
        idVenda: toNumber(pick(record, "idVenda", "IdVenda")),
        status: toStringValue(pick(record, "status", "Status")),
        valorTotal: toNumber(pick(record, "valorTotal", "ValorTotal")),
        dataPedido: toStringValue(pick(record, "dataPedido", "DataPedido")),
      };
    },
  );
}

export async function fetchSobre(companyId: number): Promise<SobreLoja> {
  return request(`/empresa/${companyId}/sobre`, { method: "GET" }, (raw) => normalizeSobre(raw));
}

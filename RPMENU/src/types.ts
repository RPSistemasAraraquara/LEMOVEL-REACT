export interface Endereco {
  idEndereco: number;
  idCliente: number;
  idEmpresa: number;
  cep: string;
  endereco: string;
  enderecoCompleto?: string;
  idBairro: number;
  bairro: string;
  taxaEntrega: number;
  numero: string;
  complemento: string;
  pontoReferencia: string;
  idCidade: number;
  UF: string;
  enderecoPadrao: boolean;
  taxa: number;
}

export interface Empresa {
  idEmpresa: number;
  nome: string;
  razaoSocial: string;
  cnpj: string;
  email: string;
  fone1: string;
  endereco: Endereco;
  /** Total de partes que um item fracionado pode ter (2 a 4). Espelha empresas.quantidade_maxima_fracao_produtos. */
  quantidadeMaximaFracaoProdutos: number;
}

export interface Configuracao {
  utilizaCEP: boolean;
  pedidoMinimo: number;
  permiteRetiradaNoLocal: boolean;
  tempoRetirada: string;
  tempoEntrega: string;
  utilizaControleOpcionais: boolean;
  integracaoMercadoPago: boolean;
}

export interface HorarioFuncionamento {
  dia: string;
  horaAbertura: string;
  horaFechamento: string;
  horaAbertura2: string;
  horaFechamento2: string;
}

export interface Categoria {
  codigo: number;
  descricao: string;
  imageUrl: string;
  thumbnailUrl?: string;
  temImagem?: boolean;
}

export interface Produto {
  codigo: number;
  idEmpresa: number;
  idGrupo: number;
  descricao: string;
  observacao: string;
  idSituacao: number;
  situacao: string;
  situacaoDescricao: string;
  valFinal: number;
  destaqueWeb: boolean;
  vendaPorTamanho: boolean;
  permiteFrac: boolean;
  valorTamanhoP: number;
  valorTamanhoM: number;
  valorTamanhoG: number;
  valorTamanhoGG: number;
  valorTamanhoExtra: number;
  tamanhoP: string;
  tamanhoM: string;
  tamanhoG: string;
  tamanhoGG: string;
  tamanhoExtra: string;
  tamanhoPadrao: string;
  opcionalMinimo: number;
  opcionalMaximo: number;
  restringirVenda: boolean;
  imageUrl: string;
  thumbnailUrl?: string;
  temImagem?: boolean;
}

export interface Opcional {
  codigo: number;
  idEmpresa: number;
  descricao: string;
  valor: number;
  valorTamanhoP: number;
  valorTamanhoM: number;
  valorTamanhoG: number;
  valorTamanhoGG: number;
  valorTamanhoExtra: number;
  tamanhoP: string;
  tamanhoM: string;
  tamanhoG: string;
  tamanhoGG: string;
  tamanhoExtra: string;
}

export interface ProdutoOpcional {
  idEmpresa: number;
  codigoProduto: number;
  codigoOpcional: number;
  groupId: number;
  groupDescription: string;
  opcionalMinimo: number;
  opcionalMaximo: number;
  opcional: Opcional;
}

export interface FormaPagamento {
  id: number;
  idEmpresa: number;
  descricao: string;
  permiteTroco: boolean;
  pagamentoOnline: boolean;
  utilizaPix: boolean;
}

export interface Bairro {
  idEmpresa: number;
  idBairro: number;
  descricao: string;
  taxa: number;
}

export interface Cliente {
  idCliente: number;
  idEmpresa: number;
  nome: string;
  email: string;
  senha: string;
  celular: string;
  telefone: string;
  enderecos: Endereco[];
}

export interface AdminUser {
  codigo: number;
  nome: string;
  email: string;
}

export interface AdminTopItem {
  label: string;
  value: string;
}

export interface AdminDashboard {
  sincronizacao: string;
  qtdeVendas: string;
  valorVendas: string;
  taxaEntrega: string;
  topClientes: AdminTopItem[];
  topBairros: AdminTopItem[];
  topProdutos: AdminTopItem[];
}

export interface AdminSession {
  token: string;
  usuario: AdminUser;
}

export interface Catalogo {
  aberta: boolean;
  empresa: Empresa;
  configuracao: Configuracao;
  categorias: Categoria[];
  destaques: Produto[];
}

export interface SobreLoja {
  aberta: boolean;
  empresa: Empresa;
  configuracao: Configuracao;
  horarios: HorarioFuncionamento[];
  formasPagamento: FormaPagamento[];
}

export interface VendaItemOpcional {
  quantidade: number;
  valorUnitario: number;
  valorTotal: number;
  opcional: Opcional;
}

export interface VendaItem {
  numeroItem: number;
  quantidade: number;
  tamanho: string;
  observacao: string;
  valorUnitario: number;
  valorTotalProduto: number;
  produto: Produto;
  opcionais: VendaItemOpcional[];
}

export interface VendaHistorico {
  id: number;
  data: string;
  taxaEntrega: number;
  valorTotal: number;
  valorAReceber: number;
  troco: number;
  observacao: string;
  tipoEntregaDescription: string;
  situacaoDescription: string;
  formaPagamento: FormaPagamento;
  itens: VendaItem[];
}

export interface VendaStatusLog {
  data: string;
  situacao: string;
  situacaoDescricao: string;
}

export interface VendaAcompanhamento extends VendaHistorico {
  vendaEndereco: Endereco;
  listaStatus: VendaStatusLog[];
}

export interface PedidoItemOpcionalPayload {
  quantidade: number;
  opcional: Opcional;
}

export interface PedidoItemPayload {
  quantidade: number;
  tamanho: string;
  observacao: string;
  produto: Produto;
  opcionais: PedidoItemOpcionalPayload[];
  fracoes: Array<{ quantidade: number; produto: Produto }>;
}

export interface PedidoPayload {
  cliente: Cliente;
  endereco: Endereco;
  formaPagamento: FormaPagamento;
  itens: PedidoItemPayload[];
  observacao: string;
  tipoEntrega: string;
  valorAReceber: number;
}

export interface PedidoRecuperadoItem {
  quantidade: number;
  tamanho: string;
  observacao: string;
  valorUnitario: number;
  valorTotalProduto: number;
  produto: Produto;
  opcionais: PedidoItemOpcionalPayload[];
  fracoes: Array<{ quantidade: number; produto: Produto }>;
}

export interface PedidoRecuperado {
  cliente: Cliente;
  endereco: Endereco;
  formaPagamento: FormaPagamento;
  itens: PedidoRecuperadoItem[];
  observacao: string;
  tipoEntrega: string;
  valorAReceber: number;
  taxaEntrega: number;
  valorTotal: number;
}

export interface PedidoCriado {
  idVenda: number;
  status: string;
  valorTotal: number;
  dataPedido: string;
}

export interface PagamentoPix {
  idPix: string;
  qrCodeBase64: string;
  qrCodeDigitavel: string;
  qrCodeUrl: string;
  status: string;
  valorTotal: number;
}

export interface PagamentoPixStatusRequest {
  clienteNome: string;
  clienteEmail: string;
  idPix: string;
  valorPedido: number;
}

export interface PagamentoPixConfirmacaoRequest {
  pedido: PedidoPayload;
  idPix: string;
  qrCodeUrl: string;
  statusPagamento: string;
  valorPagamento: number;
}

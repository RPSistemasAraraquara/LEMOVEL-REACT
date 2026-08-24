export type TabletSettings = {
  baseUrl: string;
  empresaId: number;
  mesaNumero: number;
  terminalName: string;
  pollingMs: number;
  cobrarMaiorValorFracionado: boolean;
  configured: boolean;
  utilizaCardapioTablet: boolean;
};

export type CompanyStatus = {
  idEmpresa: number;
  nome?: string;
  utilizaCardapioTablet: boolean;
};

export type WaiterProfile = {
  idUsuario: number;
  nome: string;
  login: string;
};

export type Category = {
  id: number;
  descricao: string;
  permiteVendaApp?: boolean;
};

export type ProductOptional = {
  idOpcional: number;
  descricao: string;
  valor: number;
  gratis?: boolean;
  opcionalP?: string;
  opcionalM?: string;
  opcionalG?: string;
  opcionalGG?: string;
  opcionalExtra?: string;
  valorOpcionalP?: number;
  valorOpcionalM?: number;
  valorOpcionalG?: number;
  valorOpcionalGG?: number;
  valorOpcionalExtra?: number;
};

export type MenuItem = {
  id: number;
  idProduto: number;
  descricao: string;
  descricaoCurta?: string;
  codReferencia?: string;
  imagem?: string;
  valorVenda: number;
  valorUnitario?: number;
  idCategoria?: number;
  b_venda_mobile?: boolean;
  vendaPorTamanho?: boolean;
  tamanhoPadrao?: string;
  tamanhoP?: string;
  tamanhoM?: string;
  tamanhoG?: string;
  tamanhoGG?: string;
  tamanhoExtra?: string;
  valorTamanhoP?: number;
  valorTamanhoM?: number;
  valorTamanhoG?: number;
  valorTamanhoGG?: number;
  valorTamanhoExtra?: number;
  usaQuantidadeDecimal?: boolean;
  permiteFracao?: boolean;
  opcionais?: ProductOptional[];
};

export type ProductSizeOption = {
  code: string;
  label: string;
  value: number;
};

export type LaunchOptionalPayload = {
  idOpcional: number;
  descricao: string;
  valor: number;
  gratis: boolean;
};

export type LaunchItemPayload = {
  mobileLaunchId: string;
  MobileLaunchId: string;
  idProduto: number;
  quantidade: number;
  valorUnitario: number;
  valorTotal: number;
  desconto: number;
  acrescimo: number;
  tamanho: string;
  vendaPorTamanho: boolean;
  descricaoTamanho: string;
  observacao?: string;
  idMesaVinculada: number;
  idGarcom: number;
  terminalImpressao: string;
  TerminalImpressao: string;
  opcionais: LaunchOptionalPayload[];
  fracoes?: LaunchItemFractionPayload[];
};

export type LaunchItemFractionPayload = {
  mobileLaunchId?: string;
  MobileLaunchId?: string;
  idProduto: number;
  produtoDescricao: string;
  quantidade: number;
  valorUnitario: number;
  valorTotal: number;
  acrescimo: number;
  observacao?: string;
  descricaoTamanho?: string;
  opcionais: LaunchOptionalPayload[];
};

export type CartItem = {
  lineId: string;
  product: MenuItem;
  quantidade: number;
  valorUnitario: number;
  tamanho: string;
  descricaoTamanho: string;
  observacao?: string;
  opcionais: LaunchOptionalPayload[];
  fracoes?: LaunchItemFractionPayload[];
};

export type SaleLineOptional = {
  idOpcional: number;
  descricao: string;
  valor: number;
  gratis?: boolean;
};

export type SaleLineFraction = {
  idProduto: number;
  produtoDescricao: string;
  numeroItem?: number;
  quantidade: number;
  valorUnitario: number;
  valorTotal: number;
  acrescimo?: number;
  observacao?: string;
  descricaoTamanho?: string;
  opcionais?: SaleLineOptional[];
};

export type SaleLine = {
  idProduto: number;
  produtoDescricao: string;
  imagem?: string;
  numeroItem: number;
  itemFracionado: number;
  situacao?: string;
  quantidade: number;
  valorUnitario: number;
  valorTotal: number;
  desconto: number;
  acrescimo: number;
  idGarcom?: number;
  nomeGarcom?: string;
  tamanho: string;
  descricaoTamanho?: string;
  dataHora?: string;
  observacao?: string;
  vendaPorTamanho: boolean;
  idMesaVinculada?: number;
  opcionais?: SaleLineOptional[];
  fracoes?: SaleLineFraction[];
};

export type TableOrder = {
  idMesa: number;
  numeroMesa?: number;
  nomeMesaComanda: string;
  situacao: string;
  statusOriginal?: string;
  statusCode?: string;
  valorTotal?: number;
  idVenda?: number;
  venda?: {
    idVenda?: number;
    situacao?: string;
    nomeMesaComanda?: string;
    valorTotal?: number;
  };
};

export type Sale = {
  idVenda: number;
  valor: number;
  valorTotal?: number;
  situacao?: string;
  numeroMesa?: number;
  nomeMesaComanda?: string;
  itens?: SaleLine[];
};

export type TabletSession = {
  idVenda: number;
  idMesa: number;
  mesaNumero: number;
  waiterId: number;
  waiterName: string;
  waiterLogin: string;
  openedAt: string;
  terminalName: string;
};

export type PendingOrder = {
  queueId: string;
  createdAt: string;
  updatedAt: string;
  attempts: number;
  lastError?: string;
  session: TabletSession;
  settings: TabletSettings;
  items: CartItem[];
  total: number;
};

export type TabletDiagnostics = {
  lastSyncAt?: string;
  lastSyncOk?: boolean;
  lastSyncError?: string;
  lastCatalogAt?: string;
  lastCatalogSource?: 'api';
  lastPingAt?: string;
  lastPingOk?: boolean;
  lastPingMs?: number;
  lastSendAt?: string;
  lastSendOk?: boolean;
  lastSendError?: string;
  pendingOrderCount?: number;
  lastModuleCheckAt?: string;
  utilizaCardapioTablet?: boolean;
};

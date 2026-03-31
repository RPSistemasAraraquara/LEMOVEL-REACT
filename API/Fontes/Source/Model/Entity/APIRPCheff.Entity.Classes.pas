unit APIRPCheff.Entity.Classes;

interface

uses
  APIRPCheff.Entity.Caixa,
  APIRPCheff.Entity.CaixaItem,
  APIRPCheff.Entity.Categoria,
  APIRPCheff.Entity.CatracaMobile,
  APIRPCheff.Entity.Comanda,
  APIRPCheff.Entity.Composicao,
  APIRPCheff.Entity.Configuracao,
  APIRPCheff.Entity.Empresa,
  APIRPCheff.Entity.EncerraVenda,
  APIRPCheff.Entity.EncerraVendaItem,
  APIRPCheff.Entity.Error,
  APIRPCheff.Entity.Exceptions,
  APIRPCheff.Entity.FormaPagamento,
  APIRPCheff.Entity.MateriaisComposicao,
  APIRPCheff.Entity.Mesa,
  APIRPCheff.Entity.MovimentoEstoque,
  APIRPCheff.Entity.MovimentoEstoqueComposicao,
  APIRPCheff.Entity.Opcional,
  APIRPCheff.Entity.Produto,
  APIRPCheff.Entity.Promocao,
  APIRPCheff.Entity.SetorEstoqueComposicao,
  APIRPCheff.Entity.SetorEstoqueMaterial,
  APIRPCheff.Entity.TipoMovimento,
  APIRPCheff.Entity.Usuario,
  APIRPCheff.Entity.Venda,
  APIRPCheff.Entity.VendaItem,
  APIRPCheff.Entity.VendaItemOpcional,
  APIRPCheff.Entity.VendaPagamentoAntecipado,
  APIRPCheff.Entity.VendaPrePago,
  APIRPCheff.Entity.ImpressaoProducao,
  APIRPCheff.Entity.CancelamentoPagamentoStone,
  APIRPCheff.Entity.PagamentoStonePOS,
  APIRPCheff.Entity.MovimentoEstoqueOpcional,
  APIRPCheff.Entity.SetorEstoqueOpcional,
  APIRPCheff.Entity.Venda.PagamentoAntecipadoItens;

type
  TAPIRPCheffEntityCaixa                          = APIRPCheff.Entity.Caixa.TAPIRPCheffEntityCaixa;
  TAPIRPCheffEntityCaixaItem                      = APIRPCheff.Entity.CaixaItem.TAPIRPCheffEntityCaixaItem;
  TAPIRPCheffEntityCategoria                      = APIRPCheff.Entity.Categoria.TAPIRPCheffEntityCategoria;
  TAPIRPCheffEntityCatracaMobile                  = APIRPCheff.Entity.CatracaMobile.TAPIRPCheffEntityCatracaMobile;
  TAPIRPCheffEntityComanda                        = APIRPCheff.Entity.Comanda.TAPIRPCheffEntityComanda;
  TAPIRPCheffEntityComposicao                     = APIRPCheff.Entity.Composicao.TAPIRPCheffEntityComposicao;
  TAPIRPCheffEntityConfiguracaoComanda            = APIRPCheff.Entity.Configuracao.TAPIRPCheffEntityConfiguracaoComanda;
  TAPIRPCheffEntityConfiguracaoMesa               = APIRPCheff.Entity.Configuracao.TAPIRPCheffEntityConfiguracaoMesa;
  TAPIRPCheffEntityConfiguracaoMesaComanda        = APIRPCheff.Entity.Configuracao.TAPIRPCheffEntityConfiguracaoMesaComanda;
  TAPIRPCheffEntityEmpresa                        = APIRPCheff.Entity.Empresa.TAPIRPCheffEntityEmpresa;
  TAPIRPCheffEntityEncerraVenda                   = APIRPCheff.Entity.EncerraVenda.TAPIRPCheffEntityEncerraVenda;
  TAPIRPCheffEntityEncerraVendaItem               = APIRPCheff.Entity.EncerraVendaItem.TAPIRPCheffEntityEncerraVendaItem;
  TAPIRPCheffEntityError                          = APIRPCheff.Entity.Error.TAPIRPCheffEntityError;
  EConflictError                                  = APIRPCheff.Entity.Exceptions.EConflictError;
  TAPIRPCheffEntityFormaPagamento                 = APIRPCheff.Entity.FormaPagamento.TAPIRPCheffEntityFormaPagamento;
  TAPIRPCheffEntityMateriaisComposicao            = APIRPCheff.Entity.MateriaisComposicao.TAPIRPCheffEntityMateriaisComposicao;
  TAPIRPCheffEntityMesa                           = APIRPCheff.Entity.Mesa.TAPIRPCheffEntityMesa;
  TAPIRPCheffEntityMovimentoEstoque               = APIRPCheff.Entity.MovimentoEstoque.TAPIRPCheffEntityMovimentoEstoque;
  TAPIRPCheffEntityMovimentoEstoqueComposicao     = APIRPCheff.Entity.MovimentoEstoqueComposicao.TAPIRPCheffEntityMovimentoEstoqueComposicao;
  TAPIRPCheffEntityOpcional                       = APIRPCheff.Entity.Opcional.TAPIRPCheffEntityOpcional;
  TAPIRPCheffEntityProduto                        = APIRPCheff.Entity.Produto.TAPIRPCheffEntityProduto;
  TAPIRPCheffEntityPromocao                       = APIRPCheff.Entity.Promocao.TAPIRPCheffEntityPromocao;
  TAPIRPCheffEntitySetorEstoqueComposicao         = APIRPCheff.Entity.SetorEstoqueComposicao.TAPIRPCheffEntitySetorEstoqueComposicao;
  TAPIRPCheffEntitySetorEstoqueMaterial           = APIRPCheff.Entity.SetorEstoqueMaterial.TAPIRPCheffEntitySetorEstoqueMaterial;
  TAPIRPCheffEntityTipoMovimento                  = APIRPCheff.Entity.TipoMovimento.TAPIRPCheffEntityTipoMovimento;
  TAPIRPCheffEntityUsuario                        = APIRPCheff.Entity.Usuario.TAPIRPCheffEntityUsuario;
  TAPIRPCheffEntityLogin                          = APIRPCheff.Entity.Usuario.TAPIRPCheffEntityLogin;
  TAPIRPCheffEntityVenda                          = APIRPCheff.Entity.Venda.TAPIRPCheffEntityVenda;
  TAPIRPCheffEntityVendaPatchCouvert              = APIRPCheff.Entity.Venda.TAPIRPCheffEntityVendaPatchCouvert;
  TAPIRPCheffEntityVendaPatchNomeMesaComanda      = APIRPCheff.Entity.Venda.TAPIRPCheffEntityVendaPatchNomeMesaComanda;
  TAPIRPCheffEntityVendaPatchPreFechamento        = APIRPCheff.Entity.Venda.TAPIRPCheffEntityVendaPatchPreFechamento;
  TAPIRPCheffEntityVendaPostAbertura              = APIRPCheff.Entity.Venda.TAPIRPCheffEntityVendaPostAbertura;
  TAPIRPCheffEntityVendaPostFechamento            = APIRPCheff.Entity.Venda.TAPIRPCheffEntityVendaPostFechamento;
  TAPIRPCheffEntityVendaItem                      = APIRPCheff.Entity.VendaItem.TAPIRPCheffEntityVendaItem;
  TAPIRPCheffEntityVendaItemFracao                = APIRPCheff.Entity.VendaItem.TAPIRPCheffEntityVendaItemFracao;
  TAPIRPCheffEntityVendaItemCancelamento          = APIRPCheff.Entity.VendaItem.TAPIRPCheffEntityVendaItemCancelamento;
  TAPIRPCheffEntityVendaItemOpcional              = APIRPCheff.Entity.VendaItemOpcional.TAPIRPCheffEntityVendaItemOpcional;
  TAPIRPCheffEntityVendaPagamentoAntecipado       = APIRPCheff.Entity.VendaPagamentoAntecipado.TAPIRPCheffEntityVendaPagamentoAntecipado;
  TAPIRPCheffEntityVendaPrePago                   = APIRPCheff.Entity.VendaPrePago.TAPIRPCheffEntityVendaPrePago;
  TAPIRPCheffEntityImpressaoProducao              = APIRPCheff.Entity.ImpressaoProducao.TAPIRPCheffEntityImpressaoProducao;
  TAPIRPCheffEntityCancelamentoPagamentoStone     = APIRPCheff.Entity.CancelamentoPagamentoStone.TAPIRPCheffEntityCancelamentoPagamentoStone;
  TAPIRPCheffEntityPagamentoStonePOS              = APIRPCheff.Entity.PagamentoStonePOS.TAPIRPCheffEntityPagamentoStonePOS;
  TAPIRPCheffEntityMovimentoEstoqueOpcional       = APIRPCheff.Entity.MovimentoEstoqueOpcional.TAPIRPCheffEntityMovimentoEstoqueOpcional;
  TAPIRPCheffEntitySetorEstoqueOpcional           = APIRPCheff.Entity.SetorEstoqueOpcional.TAPIRPCheffEntitySetorEstoqueOpcional;
  TAPIRPCheffEntityVendaPagamentoAntecipadoItens  = APIRPCheff.Entity.Venda.PagamentoAntecipadoItens.TAPIRPCheffEntityVendaPagamentoAntecipadoItens;

implementation

end.

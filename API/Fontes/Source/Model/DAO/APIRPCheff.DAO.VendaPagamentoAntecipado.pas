unit APIRPCheff.DAO.VendaPagamentoAntecipado;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  Data.DB,
  System.Generics.Collections,
  System.SysUtils;

type
  TAPIRPCheffDAOVendaPagamentoAntecipado = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityVendaPagamentoAntecipado>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityVendaPagamentoAntecipado; override;
  public
    function Listar(AIdVenda: Integer): TObjectList<TAPIRPCheffEntityVendaPagamentoAntecipado>;
    procedure Inserir(AValue:TAPIRPCheffEntityVendaPagamentoAntecipado);
    function BuscarUltimoIdVenda(AidVenda: Integer):Integer;
  end;

implementation

uses
  APIRPCheff.DAO.Factory;

{ TAPIRPCheffDAOVendaPagamentoAntecipado }

procedure TAPIRPCheffDAOVendaPagamentoAntecipado.Inserir(AValue: TAPIRPCheffEntityVendaPagamentoAntecipado);
begin
  StartTransaction;
  try
    Query.SQL('INSERT INTO venda_pag_antecipado( id_venda, id_empresa,                  ')
    .SQL(' id_formapgto, valor, data_hora, id_caixa, id_caixaitem,                      ')
    .SQL(' observacao, id_usuario, id_situacao, b_taxa, valor_taxa, valor_prod,         ')
    .SQL(' hash_terminal, autorizacao, acquirerdocument)                                ')
    .SQL(' VALUES (:id_venda, :id_empresa, :id_formapgto, :valor, :data_hora,           ')
    .SQL(' :id_caixa, :id_caixaitem, :observacao, :id_usuario, :id_situacao, :b_taxa,   ')
    .SQL(' :valor_taxa, :valor_prod, :hash_terminal, :autorizacao,                      ')
    .SQL(' coalesce(nullif(:acquirerdocument, ' + QuotedStr('') + '),                   ')
    .SQL('   (select formapgto.cnpjCred from formapgto                                  ')
    .SQL('    where formapgto.emp_001 = :id_empresa and formapgto.for_001 = :id_formapgto), ')
    .SQL('   ' + QuotedStr('') + '))                                                     ')

    .ParamAsInteger ('id_venda', AValue.idVenda)
    .ParamAsInteger ('id_empresa', FIdEmpresa)
    .ParamAsInteger ('id_formapgto', AValue.idFormaPagamento)
    .ParamAsCurrency ('valor', AValue.valor)
    .ParamAsDateTime('data_hora', AValue.dataHora)
    .ParamAsInteger('id_caixa', AValue.IdCaixa)
    .ParamAsInteger('id_caixaitem', AValue.IdCaixaItem)
    .ParamAsString('observacao', AValue.Observacao)
    .ParamAsInteger  ('id_usuario', AValue.IdUsuarioLancamento)
    .ParamAsInteger('id_situacao', AValue.situacao.DBValue)
    .ParamAsBoolean('b_taxa', AValue.TaxaServico)
    .ParamAsCurrency ('valor_taxa', AValue.ValorTaxaServico)
    .ParamAsCurrency ('valor_prod', AValue.ValorProduto)
    .ParamAsString('hash_terminal', AValue.hash_terminal)
    .ParamAsString('autorizacao', AValue.autorizacao)
    .ParamAsString('acquirerdocument', AValue.acquirerdocument)
    .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

function TAPIRPCheffDAOVendaPagamentoAntecipado.BuscarUltimoIdVenda(AidVenda: Integer):Integer;
var
LDataSet: TDataSet;
begin
  LDataSet:=  FQuery.SQL(' select coalesce(max(id_venda_pag_antecipado),0) as id_venda_pag_antecipado from venda_pag_antecipado where id_empresa = :id_empresa and id_venda = :id_venda    ')
  .ParamAsInteger('id_venda',AidVenda)
  .ParamAsInteger('id_empresa',FIdEmpresa)
  .OpenDataSet;
  try
    Result:=LDataSet.FieldByName('id_venda_pag_antecipado').AsInteger;
  finally
     FreeAndNil(LDataSet);
  end;

end;

function TAPIRPCheffDAOVendaPagamentoAntecipado.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityVendaPagamentoAntecipado;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityVendaPagamentoAntecipado.Create;
    try
      Result.idVenda                                := ADataSet.FieldByName('id_venda').AsInteger;
      Result.idVendaPagamentoAntecipado             := ADataSet.FieldByName('id_venda_pag_antecipado').AsInteger;
      Result.idEmpresa                              := ADataSet.FieldByName('id_empresa').AsInteger;
      Result.dataHora                               := ADataSet.FieldByName('data_hora').AsDateTime;
      Result.valor                                  := ADataSet.FieldByName('valor').AsCurrency;
      Result.idFormaPagamento                       := ADataSet.FieldByName('id_formapgto').AsInteger;
      Result.IdCaixa                                := ADataSet.FieldByName('id_caixa').AsInteger;
      Result.IdCaixaItem                            := ADataSet.FieldByName('id_caixaitem').AsInteger;
      Result.Observacao                             := ADataSet.FieldByName('observacao').asstring;
      Result.IdUsuarioLancamento                    := ADataSet.FieldByName('id_usuario').AsInteger;
      Result.TaxaServico                            := ADataSet.FieldByName('b_taxa').AsBoolean;
      Result.ValorTaxaServico                       := ADataSet.FieldByName('valor_taxa').AsCurrency;
      Result.ValorProduto                           := ADataSet.FieldByName('valor_prod').AsCurrency;
      Result.hash_terminal                          := ADataSet.FieldByName('hash_terminal').AsString;
      Result.autorizacao                            := ADataSet.FieldByName('autorizacao').AsString;
      Result.acquirerdocument                       := ADataSet.FieldByName('acquirerdocument').AsString;
      if ADataSet.FieldByName('exibir_forma_app').AsBoolean then
      begin
        Result.formaPagamento.codigo                         := Result.idFormaPagamento;
        Result.formaPagamento.idEmpresa                      := Result.idEmpresa;
        Result.formaPagamento.descricao                      := ADataSet.FieldByName('for_002').AsString;
        Result.formaPagamento.sfiCodigo                      := ADataSet.FieldByName('sfi_codigo').AsInteger;
        Result.formaPagamento.cortesia                       := ADataSet.FieldByName('b_cortesia').AsBoolean;
        Result.formaPagamento.utilizaControleCartao          := ADataSet.FieldByName('utiliza_controle_cartao').AsBoolean;
        Result.formaPagamento.idContaCorrente                := ADataSet.FieldByName('id_contacorrente').AsInteger;
        Result.formaPagamento.taxaCartao                     := ADataSet.FieldByName('taxa_cartao').AsCurrency;
        Result.formaPagamento.prazoCartao                    := ADataSet.FieldByName('prazo_cartao').AsInteger;
        Result.formaPagamento.utilizaPagamentoOnline         := ADataSet.FieldByName('utilizaPagamentoOnline').AsBoolean;
        Result.formaPagamento.PermitePagamentoParceladoOnline := ADataSet.FieldByName('permite_pag_parcelado').AsBoolean;
        Result.formaPagamento.Juros                          := ADataSet.FieldByName('juros').AsFloat;
        Result.formaPagamento.emiteFiscal                    := ADataSet.FieldByName('emite_fiscal').AsBoolean;
        Result.formaPagamento.ExibirFormaPgtoAPP             := ADataSet.FieldByName('exibir_forma_app').AsBoolean;
      end
      else
        Result.formaPagamento := nil;
      Result.situacao.FromDBValue(ADataSet.FieldByName('id_situacao').AsInteger);
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TAPIRPCheffDAOVendaPagamentoAntecipado.Listar(AIdVenda: Integer): TObjectList<TAPIRPCheffEntityVendaPagamentoAntecipado>;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := FQuery.SQL('where venda_pag_antecipado.id_empresa = :idEmpresa')
    .SQL('and venda_pag_antecipado.id_venda = :idVenda and id_situacao=4')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda)
    .OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

procedure TAPIRPCheffDAOVendaPagamentoAntecipado.Select;
begin
  FQuery.SQL('select venda_pag_antecipado.id_venda_pag_antecipado,                                                      ')
    .SQL('  venda_pag_antecipado.id_venda, venda_pag_antecipado.id_empresa,                                             ')
    .SQL('  venda_pag_antecipado.id_formapgto, venda_pag_antecipado.valor,                                              ')
    .SQL('  venda_pag_antecipado.data_hora, venda_pag_antecipado.id_situacao,                                           ')
    .SQL('  formapgto.for_002, formapgto.sit_001, formapgto.sfi_codigo, formapgto.b_cortesia,                           ')
    .SQL('  formapgto.permite_pag_parcelado, formapgto.utiliza_controle_cartao, formapgto.id_contacorrente,              ')
    .SQL('  formapgto.taxa_cartao, formapgto.prazo_cartao, formapgto.utilizaPagamentoOnline,                             ')
    .SQL('  formapgto.juros, formapgto.emite_fiscal, formapgto.exibir_forma_app,                                         ')
    .SQL('  venda_pag_antecipado.id_caixa, venda_pag_antecipado.id_caixaitem, venda_pag_antecipado.observacao,          ')
    .SQL('  venda_pag_antecipado.id_usuario,  venda_pag_antecipado.b_taxa, venda_pag_antecipado.valor_taxa,             ')
    .SQL('  venda_pag_antecipado.valor_prod, venda_pag_antecipado.hash_terminal,                                        ')
    .SQL('  venda_pag_antecipado.autorizacao, venda_pag_antecipado.acquirerdocument                                     ')
    .SQL('  from venda_pag_antecipado                                                                                   ')
    .SQL('  join formapgto on venda_pag_antecipado.id_formapgto = formapgto.for_001')
    .SQL('  and venda_pag_antecipado.id_empresa = formapgto.emp_001');
end;

end.

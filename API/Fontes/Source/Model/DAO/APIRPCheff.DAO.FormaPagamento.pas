
unit APIRPCheff.DAO.FormaPagamento;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils,
  System.Generics.Collections;

type
  TAPIRPCheffDAOFormaPagamento = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityFormaPagamento>)
  private
    procedure SelectFormaPagamento;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityFormaPagamento; override;
  public
    function ListarPagamentosDaVenda(const AIdVenda: Integer): TObjectList<TAPIRPCheffEntityFormaPagamento>;
    function Lista: TObjectList<TAPIRPCheffEntityFormaPagamento>;
    function GetFormaPagamento(ACodigo: Integer): TAPIRPCheffEntityFormaPagamento;
    function GetFormaDinheiro: TAPIRPCheffEntityFormaPagamento;
  end;

implementation

{ TAPIRPCheffDAOFormaPagamento }

function TAPIRPCheffDAOFormaPagamento.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityFormaPagamento;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityFormaPagamento.Create;
    try
      Result.codigo                           := ADataSet.FieldByName('for_001').AsInteger;
      Result.idEmpresa                        := ADataSet.FieldByName('emp_001').AsInteger;
      Result.descricao                        := ADataSet.FieldByName('for_002').AsString;
      Result.sfiCodigo                        := ADataSet.FieldByName('sfi_codigo').AsInteger;
      Result.cortesia                         := ADataSet.FieldByName('b_cortesia').AsBoolean;
      Result.utilizaControleCartao            := ADataSet.FieldByName('utiliza_controle_cartao').AsBoolean;
      Result.idContaCorrente                  := ADataSet.FieldByName('id_contacorrente').AsInteger;
      Result.taxaCartao                       := ADataSet.FieldByName('taxa_cartao').AsCurrency;
      Result.prazoCartao                      := ADataSet.FieldByName('prazo_cartao').AsInteger;
      Result.utilizaPagamentoOnline           := ADataSet.FieldByName('utilizaPagamentoOnline').AsBoolean;
      Result.PermitePagamentoParceladoOnline  := ADataSet.FieldByName('permite_pag_parcelado').AsBoolean;
      Result.Juros                            := ADataSet.FieldByName('juros').AsFloat;
      Result.emiteFiscal                      := ADataSet.FieldByName('emite_fiscal').AsBoolean;
      Result.ExibirFormaPgtoAPP               := ADataSet.FieldByName('exibir_forma_app').AsBoolean;
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TAPIRPCheffDAOFormaPagamento.GetFormaDinheiro: TAPIRPCheffEntityFormaPagamento;
var
  LDataSet: TDataSet;
begin
  SelectFormaPagamento;
  LDataSet := FQuery.SQL('where emp_001 = :idEmpresa')
    .SQL('and sfi_codigo = 1 and exibir_forma_app=true')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .OpenDataSet;
  try
    Result := DataSetToEntity(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOFormaPagamento.GetFormaPagamento(ACodigo: Integer): TAPIRPCheffEntityFormaPagamento;
var
  LDataSet: TDataSet;
begin
  SelectFormaPagamento;
  LDataSet := FQuery.SQL('where emp_001 = :idEmpresa')
    .SQL('and for_001 = :codigo and exibir_forma_app=true')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('codigo', ACodigo)
    .OpenDataSet;
  try
    Result := DataSetToEntity(LDataSet);
  finally
    LDataSet.Free;
  end;
end;

function TAPIRPCheffDAOFormaPagamento.Lista: TObjectList<TAPIRPCheffEntityFormaPagamento>;
begin
  SelectFormaPagamento;
  FQuery.SQL('where emp_001 = :idEmpresa')
    .SQL('and sit_001 = 4 and exibir_forma_app=true')
    .SQL('and ((b_fiado and id_conta is not null) or (not b_fiado))')
    .SQL('order by for_002')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .Open;

  Result := DataSetToList(FQuery.DataSet);
end;

function TAPIRPCheffDAOFormaPagamento.ListarPagamentosDaVenda(const AIdVenda: Integer): TObjectList<TAPIRPCheffEntityFormaPagamento>;
var
  LDataSet: TDataSet;
begin
  SelectFormaPagamento;
  LDataSet := Query.SQL('where formapgto.for_001 in (')
    .SQL('  select id_formapgto from caixaItem where id_venda = :idVenda)')
    .ParamAsInteger('idVenda', AIdVenda)
    .OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    LDataSet.Free;
  end;
end;

procedure TAPIRPCheffDAOFormaPagamento.SelectFormaPagamento;
begin
  FQuery.SQL('select formapgto.emp_001, formapgto.for_001, formapgto.for_002, formapgto.sfi_codigo,')
    .SQL('  formapgto.b_cortesia, formapgto.permite_pag_parcelado, formapgto.utiliza_controle_cartao,')
    .SQL('  formapgto.id_contacorrente, formapgto.taxa_cartao, formapgto.prazo_cartao,')
    .SQL('  formapgto.utilizaPagamentoOnline, formapgto.juros, formapgto.emite_fiscal,formapgto.exibir_forma_app')
    .SQL('from formapgto');
end;

end.

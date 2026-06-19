unit APIRPCheff.DAO.EncerraVendaItem;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.Generics.Collections,
  System.SysUtils;

type
  TAPIRPCheffDAOEncerraVendaItem = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityEncerraVendaItem>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityEncerraVendaItem; override;
  public
    function Listar(AIdVenda: Integer): TObjectList<TAPIRPCheffEntityEncerraVendaItem>;
    procedure Inserir(AValue: TAPIRPCheffEntityEncerraVendaItem);
  end;

implementation

{ TAPIRPCheffDAOEncerraVendaItem }

function TAPIRPCheffDAOEncerraVendaItem.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityEncerraVendaItem;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityEncerraVendaItem.Create;
    try
      Result.idEmpresa                := ADataSet.FieldByName('emp_001').AsInteger;
      Result.idEncerraVenda           := ADataSet.FieldByName('enc_001').AsInteger;
      Result.numeroItem               := ADataSet.FieldByName('ite_001').AsInteger;
      Result.valor                    := ADataSet.FieldByName('ite_003').AsCurrency;
      Result.idFormaPgto              := ADataSet.FieldByName('id_formaPgto').AsInteger;
      Result.trocoDinheiro            := ADataSet.FieldByName('troco_dinheiro').AsCurrency;
      Result.novaVenda                := ADataSet.FieldByName('b_nova_venda').AsBoolean;
      Result.hash_terminal            := ADataSet.FieldByName('hash_terminal').AsString;
      Result.autorizacao              := ADataSet.FieldByName('autorizacao').AsString;
      Result.acquirerdocument         := ADataSet.FieldByName('acquirerdocument').AsString;
      Result.formaPagamento.idEmpresa := Result.idEmpresa;
      Result.formaPagamento.codigo    := Result.idFormaPgto;
      Result.formaPagamento.descricao := ADataSet.FieldByName('for_002').AsString;
      Result.formaPagamento.sfiCodigo := ADataSet.FieldByName('sfi_codigo').AsInteger;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffDAOEncerraVendaItem.Inserir(AValue: TAPIRPCheffEntityEncerraVendaItem);
begin
  StartTransaction;
  try
    FQuery.SQL('insert into encerraVendaItem (')
      .SQL('  emp_001, enc_001, ite_001, ite_002, ite_003, ite_004,')
      .SQL('  ite_005, id_formaPgto, troco_dinheiro, b_nova_venda,')
      .SQL('  hash_terminal, autorizacao, acquirerdocument)')
      .SQL('values (')
      .SQL('  :emp_001, :enc_001, :ite_001, localtimestamp, :ite_003, :ite_004,')
      .SQL('  :ite_005, :id_formaPgto, :troco_dinheiro, :b_nova_venda,')
      .SQL('  :hash_terminal, :autorizacao,')
      .SQL('  coalesce(nullif(:acquirerdocument, ' + QuotedStr('') + '),')
      .SQL('    (select formapgto.cnpjCred from formapgto')
      .SQL('     where formapgto.emp_001 = :emp_001 and formapgto.for_001 = :id_formaPgto),')
      .SQL('    ' + QuotedStr('') + '))')
      .ParamAsInteger('emp_001', AValue.idEmpresa)
      .ParamAsInteger('enc_001', AValue.idEncerraVenda)
      .ParamAsInteger('ite_001', AValue.numeroItem)
      .ParamAsCurrency('ite_003', AValue.valor)
      .ParamAsInteger('ite_004', AValue.numeroItem)
      .ParamAsCurrency('ite_005', 0)
      .ParamAsInteger('id_formaPgto', AValue.idFormaPgto)
      .ParamAsCurrency('troco_dinheiro', AValue.trocoDinheiro)
      .ParamAsBoolean('b_nova_venda', AValue.novaVenda)
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

function TAPIRPCheffDAOEncerraVendaItem.Listar(AIdVenda: Integer): TObjectList<TAPIRPCheffEntityEncerraVendaItem>;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := FQuery.SQL('where encerraVenda.ven_001 = :idVenda')
    .SQL('and encerraVendaItem.emp_001 = :idEmpresa')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda)
    .OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

procedure TAPIRPCheffDAOEncerraVendaItem.Select;
begin
  FQuery.SQL('select encerraVendaItem.emp_001, encerraVendaItem.enc_001, encerraVendaItem.ite_001,')
    .SQL('  encerraVendaItem.ite_002, encerraVendaItem.ite_003, encerraVendaItem.ite_004,')
    .SQL('  encerraVendaItem.ite_005, encerraVendaItem.id_formaPgto, encerraVendaItem.troco_dinheiro,')
    .SQL('  encerraVendaItem.b_nova_venda, encerraVendaItem.hash_terminal,')
    .SQL('  encerraVendaItem.autorizacao, encerraVendaItem.acquirerdocument,')
    .SQL('  formaPgto.for_001, formaPgto.for_002, formaPgto.sit_001, formaPgto.sfi_codigo')
    .SQL('from encerraVendaItem')
    .SQL('join formaPgto on encerraVendaItem.id_formaPgto = formaPgto.for_001')
    .SQL('join encerraVenda on encerraVendaItem.enc_001 = encerraVenda.enc_001');
end;

end.

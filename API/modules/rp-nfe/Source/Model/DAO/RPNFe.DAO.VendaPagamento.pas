unit RPNFe.DAO.VendaPagamento;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB,
  RPNFe.Entity.Classes,
  RPNFe.DAO.Base;

type
  TRPNFeDAOVendaPagamento = class(TRPNFeDAOBase<TRPNFeEntityVendaPagamento>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityVendaPagamento; override;
  public
    function Listar(AIdEmpresa, AIdVenda: Integer): TObjectList<TRPNFeEntityVendaPagamento>;
  end;

implementation

{ TRPNFeDAOVendaPagamento }

function TRPNFeDAOVendaPagamento.DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityVendaPagamento;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TRPNFeEntityVendaPagamento.Create;
    try
      Result.IdVenda := ADataSet.FieldByName('VEN_001').AsInteger;
      Result.NumeroPagamento := ADataSet.FieldByName('ITE_001').AsInteger;
      Result.Valor := ADataSet.FieldByName('ITE_003').AsCurrency;
      Result.Troco := ADataSet.FieldByName('troco_dinheiro').AsCurrency;
      Result.Autorizacao := ADataSet.FieldByName('AUTORIZACAO').AsString;
      Result.Forma.IdFormaPagamento := ADataSet.FieldByName('FOR_001').AsInteger;
      Result.Forma.IdEmpresa := ADataSet.FieldByName('EMP_001').AsInteger;
      Result.Forma.SfiCodigo := ADataSet.FieldByName('SFI_CODIGO').AsInteger;
      Result.Forma.CnpjCredenciadora := ADataSet.FieldByName('CNPJCRED').AsString;
      Result.Forma.BandeiraCartao := ADataSet.FieldByName('BANDEIRA_CARTAO').AsString;
      Result.Forma.TipoIntegracao := ADataSet.FieldByName('TIPO_INTEGRACAO').AsInteger;
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TRPNFeDAOVendaPagamento.Listar(AIdEmpresa,
  AIdVenda: Integer): TObjectList<TRPNFeEntityVendaPagamento>;
begin
  Select;
  Query.SQL('where encerraVenda.ven_001 = :idVenda')
    .SQL('and encerraVenda.emp_001 = :idEmpresa')
    .SQL('and encerraVendaItem.b_nova_venda = false')
    .ParamAsInteger('idVenda', AIdVenda)
    .ParamAsInteger('idEmpresa', AIdEmpresa);
  Result := OpenQueryToList;
end;

procedure TRPNFeDAOVendaPagamento.Select;
begin
  Query.SQL('select formaPgto.for_001, formaPgto.sfi_codigo, formaPgto.cnpjCred, formaPgto.bandeira_cartao,')
    .SQL('  formaPgto.tipo_integracao, encerraVendaItem.ite_001, encerraVendaItem.ite_003,')
    .SQL('  encerraVendaItem.autorizacao, encerraVendaItem.troco_dinheiro,')
    .SQL('  encerraVendaItem.emp_001, encerraVenda.ven_001')
    .SQL('from encerraVenda')
    .SQL('inner join encerraVendaItem on encerraVendaItem.enc_001 = encerraVenda.enc_001')
    .SQL('and encerraVendaItem.emp_001 = encerraVenda.emp_001')
    .SQL('inner join formaPgto on formaPgto.emp_001 = encerraVendaItem.emp_001')
    .SQL('and formaPgto.for_001 = encerraVendaItem.id_formaPgto');
end;

end.

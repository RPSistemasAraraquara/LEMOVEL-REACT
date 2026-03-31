unit RPNFe.DAO.Venda;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB,
  RPNFe.Entity.Classes,
  RPNFe.DAO.Base;

type
  TRPNFeDAOVenda = class(TRPNFeDAOBase<TRPNFeEntityVenda>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityVenda; override;
  public
    procedure AtualizarEmissao(AIdVenda: Integer; ANotaEletronica: TRPNFeEntityNFeNotaEletronica);
    function Buscar(AIdVenda: Integer): TRPNFeEntityVenda;
    function Xml(const AIdVenda: Integer): string;
  end;

implementation

{ TRPNFeDAOVenda }

procedure TRPNFeDAOVenda.AtualizarEmissao(AIdVenda: Integer; ANotaEletronica: TRPNFeEntityNFeNotaEletronica);
begin
  Query.SQL('update venda set ven_036 = :serie, ven_038 = :chaveNFe, ven_037 = :dataEmissao, ')
    .SQL('numero_cupom = :numNFe, serie_cupom = :serie, nfce_contingencia = :contingencia,')
    .SQL('tipoFiscal = :tipoFiscal, xml_cfe = :xml')
    .SQL('where ven_001 = :idVenda')
    .ParamAsInteger('idVenda', AIdVenda)
    .ParamAsInteger('serie', ANotaEletronica.Serie)
    .ParamAsString('chaveNFe', ANotaEletronica.ChaveNFe)
    .ParamAsDateTime('dataEmissao', ANotaEletronica.DataAutorizacao)
    .ParamAsInteger('numNFe', ANotaEletronica.NumeroNFe)
    .ParamAsBoolean('contingencia', ANotaEletronica.Contingencia)
    .ParamAsString('tipoFiscal', ANotaEletronica.ModeloDescription, True)
    .ParamAsString('xml', ANotaEletronica.Xml, True)
    .ExecSQL;
end;

function TRPNFeDAOVenda.Buscar(AIdVenda: Integer): TRPNFeEntityVenda;
begin
  Select;
  Query.SQL('where venda.ven_001 = :idVenda')
    .ParamAsInteger('idVenda', AIdVenda);
  Result := OpenQueryToEntity;
end;

function TRPNFeDAOVenda.DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityVenda;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TRPNFeEntityVenda.Create;
    try
      Result.Id := ADataSet.FieldByName('ven_001').AsInteger;
      Result.IdEmpresa := ADataSet.FieldByName('emp_001').AsInteger;
      Result.Data := ADataSet.FieldByName('ven_004').AsDateTime;
      Result.Valor := ADataSet.FieldByName('total_venda').AsCurrency;
      Result.ValorTaxaServico := ADataSet.FieldByName('ven_008').AsCurrency;
      Result.IdCaixaAbertura := ADataSet.FieldByName('id_caixa_abertura').AsInteger;
      Result.PainelSenha := ADataSet.FieldByName('painel_senha').AsString;
      Result.TipoVenda := ADataSet.FieldByName('ven_024').AsString;
      Result.DataEmissao := ADataSet.FieldByName('ven_037').AsDateTime;
      Result.ChaveEletronica := ADataSet.FieldByName('ven_038').AsString;
      Result.Cliente.Nome := ADataSet.FieldByName('cliente').AsString;
      Result.Cliente.CpfCnpj := ADataSet.FieldByName('cpfCnpjCliente').AsString;
      Result.Cliente.Logradouro := ADataSet.FieldByName('cep_004').AsString;
      Result.Cliente.Numero := ADataSet.FieldByName('cli_008').AsString;
      Result.Cliente.Complemento := ADataSet.FieldByName('cli_009').AsString;
      Result.Cliente.Bairro := ADataSet.FieldByName('cep_003').AsString;
      Result.Cliente.CodigoIBGE := ADataSet.FieldByName('cid_003').AsString;
      Result.Cliente.Cidade := ADataSet.FieldByName('cidade_desc').AsString;
      Result.Cliente.UF := ADataSet.FieldByName('uf').AsString;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TRPNFeDAOVenda.Select;
begin
  Query.SQL('select venda.ven_001, venda.emp_001, venda.ven_024, venda.id_caixa_abertura, venda.ven_004,')
    .SQL('  coalesce(encerraVenda.ven_cpfConsum, clientes.cli_004) AS cpfCnpjCliente, ')
    .SQL('  coalesce(venda.nome_cliente, clientes.cli_002) AS cliente,')
    .SQL('  ven_008, ven_009 as total_venda, ven_037, ven_038,')
    .SQL('  venda.painel_senha, encerraVenda.enc_006, encerraVenda.enc_007,')
    .SQL('  clientes.cep_004, clientes.cli_008, clientes.cli_009, clientes.cep_003,')
    .SQL('  clientes.cli_001, clientes.cidade_desc, clientes.uf, cidades.cid_003')
    .SQL('from venda')
    .SQL('inner join encerraVenda on encerraVenda.ven_001 = venda.ven_001')
    .SQL('and encerraVenda.emp_001 = venda.emp_001')
    .SQL('left join clientes on venda.cli_001 = clientes.cli_001')
    .SQL('and venda.emp_001 = clientes.emp_001')
    .SQL('left join cidades on clientes.cid_001 = cidades.cid_001')
end;

function TRPNFeDAOVenda.Xml(const AIdVenda: Integer): string;
var
  LDataSet: TDataSet;
begin
  LDataSet := Query.SQL('select xml_cfe from venda where ven_001 = ' + AIdVenda.ToString)
    .OpenDataSet;
  try
    Result := LDataSet.FieldByName('xml_cfe').AsString;
  finally
    LDataSet.Free;
  end;
end;

end.

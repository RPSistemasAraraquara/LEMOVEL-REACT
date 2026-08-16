unit RPNFe.DAO.Empresa;

interface

uses
  System.SysUtils,
  Data.DB,
  RPNFe.Entity.Classes,
  RPNFe.DAO.Base;

type
  TRPNFeDAOEmpresa = class(TRPNFeDAOBase<TRPNFeEntityEmpresa>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityEmpresa; override;
  public
    function Buscar(AIdEmpresa: Integer): TRPNFeEntityEmpresa;
    // Alocacao ATOMICA e DURAVEL do proximo nNF: um unico UPDATE..RETURNING
    // com lock de linha - mesmo que a conexao do pool esteja com snapshot
    // velho/transacao vazada, o UPDATE le o valor mais atual comitado (era
    // SELECT separado + incremento, e uma leitura velha repetia nNF ja usado
    // na SEFAZ = Duplicidade). Commit explicito ANTES do envio: numero
    // consumido nao pode ser desfeito por rollback depois da autorizacao.
    function AlocarNumeroNFCe(AIdEmpresa: Integer): Integer;
    procedure AtualizarNumeroNFCe(AIdEmpresa: Integer);
    // Semente de numeracao (override da API): eleva empresas.numero_nfce ao
    // piso informado SEM nunca diminuir (greatest) - persistir e obrigatorio,
    // senao a proxima emissao rele o valor antigo do banco e repete o nNF.
    procedure SementeNumeroNFCe(AIdEmpresa, ANumero: Integer);
    procedure AtualizarNumeroNFe(AIdEmpresa: Integer);
    procedure AtualizarNumeracao(AIdEmpresa, AModelo: Integer);
  end;

implementation

{ TRPNFeDAOEmpresa }

procedure TRPNFeDAOEmpresa.AtualizarNumeracao(AIdEmpresa, AModelo: Integer);
begin
  if AModelo = 55 then
    AtualizarNumeroNFe(AIdEmpresa)
  else
    AtualizarNumeroNFCe(AIdEmpresa);
end;

function TRPNFeDAOEmpresa.AlocarNumeroNFCe(AIdEmpresa: Integer): Integer;
var
  LDataSet: TDataSet;
begin
  StartTransaction;
  try
    LDataSet := Query.SQL('update empresas set numero_nfce = coalesce(numero_nfce, 0) + 1')
      .SQL('where emp_001 = :idEmpresa')
      .SQL('returning numero_nfce')
      .ParamAsInteger('idEmpresa', AIdEmpresa)
      .OpenDataSet;
    try
      if (LDataSet = nil) or LDataSet.IsEmpty then
        raise Exception.CreateFmt('Empresa %d não encontrada ao alocar numeração da NFC-e.', [AIdEmpresa]);
      Result := LDataSet.FieldByName('numero_nfce').AsInteger;
    finally
      FreeAndNil(LDataSet);
    end;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TRPNFeDAOEmpresa.AtualizarNumeroNFCe(AIdEmpresa: Integer);
begin
  Query.SQL('update empresas set numero_nfce = coalesce(numero_nfce, 0) + 1')
    .SQL('where emp_001 = :idEmpresa')
    .ParamAsInteger('idEmpresa', AIdEmpresa)
    .ExecSQL;
end;

procedure TRPNFeDAOEmpresa.SementeNumeroNFCe(AIdEmpresa, ANumero: Integer);
begin
  Query.SQL('update empresas set numero_nfce = greatest(coalesce(numero_nfce, 0), :numero)')
    .SQL('where emp_001 = :idEmpresa')
    .ParamAsInteger('numero', ANumero)
    .ParamAsInteger('idEmpresa', AIdEmpresa)
    .ExecSQL;
end;

procedure TRPNFeDAOEmpresa.AtualizarNumeroNFe(AIdEmpresa: Integer);
begin
  Query.SQL('update empresas set numero_nfe = coalesce(numero_nfe, 0) + 1')
    .SQL('where emp_001 = :idEmpresa')
    .ParamAsInteger('idEmpresa', AIdEmpresa)
    .ExecSQL;
end;

function TRPNFeDAOEmpresa.Buscar(AIdEmpresa: Integer): TRPNFeEntityEmpresa;
begin
  Select;
  Query.SQL('where emp_001 = :idEmpresa')
    .ParamAsInteger('idEmpresa', AIdEmpresa);
  Result := OpenQueryToEntity;
end;

function TRPNFeDAOEmpresa.DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityEmpresa;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TRPNFeEntityEmpresa.Create;
    try
      Result.Id := ADataSet.FieldByName('emp_001').AsInteger;
      Result.Nome := ADataSet.FieldByName('emp_003').AsString;
      Result.RazaoSocial := ADataSet.FieldByName('emp_002').AsString;
      Result.Cnpj := ADataSet.FieldByName('emp_004').AsString;
      Result.CrtCodigo := ADataSet.FieldByName('crt_codigo').AsInteger;
      Result.InscricaoEstadual := ADataSet.FieldByName('emp_005').AsString;
      Result.Cnae := ADataSet.FieldByName('cnae').AsString;
      Result.Telefone := ADataSet.FieldByName('emp_013').AsString;
      Result.Celular := ADataSet.FieldByName('celular').AsString;
      Result.Cep := ADataSet.FieldByName('cep_002').AsString;
      Result.Logradouro := ADataSet.FieldByName('cep_004').AsString;
      Result.Numero := ADataSet.FieldByName('emp_007').AsString;
      Result.Complemento := ADataSet.FieldByName('emp_008').AsString;
      Result.Bairro := ADataSet.FieldByName('cep_003').AsString;
      Result.CodigoIBGE := ADataSet.FieldByName('cid_003').AsString;
      Result.Cidade := ADataSet.FieldByName('cid_002').AsString;
      Result.UF := ADataSet.FieldByName('est_003').AsString;
      Result.NFCeSerie := ADataSet.FieldByName('serie_nfce').AsInteger;
      Result.NFCeTerminal := ADataSet.FieldByName('b_nfce_terminal').AsBoolean;
      Result.NFCeNumero := ADataSet.FieldByName('numero_nfce').AsInteger;
      Result.NFeSerie := ADataSet.FieldByName('serie_nfe').AsInteger;
      Result.NFeNumero := ADataSet.FieldByName('numero_nfe').AsInteger;
      Result.AliquotaMunicipalPadrao := ADataSet.FieldByName('aliqMunicipalPadrao').AsFloat;
      Result.AliquotaEstadualPadrao := ADataSet.FieldByName('aliqEstadualPadrao').AsFloat;
      Result.AliquotaFederalPadrao := ADataSet.FieldByName('aliqFedNacionalPadrao').AsFloat;
      Result.AliqCbs := ADataSet.FieldByName('aliq_cbs').AsFloat;
      Result.AliqIbsUf := ADataSet.FieldByName('aliq_ibs_uf').AsFloat;
      Result.AliqIbsMun := ADataSet.FieldByName('aliq_ibs_mun').AsFloat;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TRPNFeDAOEmpresa.Select;
begin
  Query.SQL('select empresas.emp_001, empresas.b_nfce_terminal, empresas.numero_nfce,')
    .SQL('  empresas.serie_nfce, empresas.emp_004, empresas.emp_005, empresas.emp_002,')
    .SQL('  empresas.serie_nfe, empresas.numero_nfe,')
    .SQL('  empresas.emp_003, empresas.emp_013, empresas.celular, empresas.emp_006,')
    .SQL('  empresas.cnae, empresas.cep_002, empresas.cep_004, empresas.emp_007, empresas.emp_008,')
    .SQL('  empresas.aliqMunicipalPadrao, empresas.aliqEstadualPadrao,')
    .SQL('  empresas.aliqFedNacionalPadrao, empresas.crt_codigo,')
    .SQL('  empresas.cep_003, empresas.crt_codigo, cidades.cid_002, cidades.cid_003,')
    .SQL('  estados.est_003,')
    .SQL('  empresas.aliq_cbs, estados.aliq_ibs_uf, cidades.aliq_ibs_mun')
    .SQL('from empresas')
    .SQL('left join cidades on empresas.cid_001 = cidades.cid_001')
    .SQL('left join estados on cidades.est_001 = estados.est_001')
end;

end.

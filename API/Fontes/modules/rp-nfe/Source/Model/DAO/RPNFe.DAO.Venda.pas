unit RPNFe.DAO.Venda;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB,
  ADRConn.Model.Interfaces,
  RPNFe.Entity.Classes,
  RPNFe.DAO.Base;

type
  TRPNFeDAOVenda = class(TRPNFeDAOBase<TRPNFeEntityVenda>)
  private
    procedure Select;
    function QueryAtualizarEmissao(AIdEmpresa, AIdVenda: Integer;
      ANotaEletronica: TRPNFeEntityNFeNotaEletronica): IADRQuery;
    procedure ValidarBackendNFCe(ABackend: Integer);
    procedure InvalidarSessaoNFCe;
    procedure ReverterTransacaoNFCe;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityVenda; override;
  public
    function BloquearEmissaoNFCe(AIdEmpresa, AIdVenda: Integer): Integer;
    procedure DesbloquearEmissaoNFCe(AIdEmpresa, AIdVenda, ABackend: Integer);
    function BuscarTentativaNFCe(AIdEmpresa, AIdVenda, ABackend: Integer;
      out ATentativa: TRPNFeEntityTentativaNFCe): Boolean;
    procedure AtualizarCpfConsumidorNFCe(AIdEmpresa, AIdVenda, ABackend: Integer; const ACpfCnpj: string);
    procedure RegistrarTentativaNFCe(AIdEmpresa, AIdVenda, ABackend: Integer;
      const ATentativa: TRPNFeEntityTentativaNFCe);
    procedure RetirarTentativaNFCe(AIdEmpresa, AIdVenda, ABackend: Integer; const AChave: string);
    procedure ConcluirEmissaoNFCe(AIdEmpresa, AIdVenda, ABackend: Integer;
      const ATentativa: TRPNFeEntityTentativaNFCe; ANota: TRPNFeEntityNFeNotaEletronica);
    procedure AtualizarEmissao(AIdEmpresa, AIdVenda: Integer; ANotaEletronica: TRPNFeEntityNFeNotaEletronica);
    function Buscar(AIdEmpresa, AIdVenda: Integer): TRPNFeEntityVenda;
    function Xml(const AIdVenda: Integer): string;
  end;

implementation

uses
  PgAccess;

const
  // Bloqueio da sessão física mantida pela requisição. Não abre transação durante o envio.
  SQLChaveBloqueioNFCe = 'pg_catalog.hashtextextended(' +
    'pg_catalog.concat(''rpcheff:emissao:nfce:'', cast(:idEmpresa as integer), '':'', cast(:idVenda as integer)), 0)';

function TRPNFeDAOVenda.BloquearEmissaoNFCe(AIdEmpresa, AIdVenda: Integer): Integer;
var
  LDataSet: TDataSet;
begin
  if TPgQuery(Query.Component).Connection.InTransaction then
    raise Exception.Create('A emissão da NFC-e exige que o fechamento da venda esteja confirmado.');

  try
    LDataSet := Query.SQL('select pg_catalog.pg_backend_pid() as pid,')
      .SQL('pg_catalog.pg_try_advisory_lock(' + SQLChaveBloqueioNFCe + ') as bloqueado')
      .ParamAsInteger('idEmpresa', AIdEmpresa)
      .ParamAsInteger('idVenda', AIdVenda)
      .OpenDataSet;
    try
      Result := 0;
      if LDataSet.FieldByName('bloqueado').AsBoolean then
        Result := LDataSet.FieldByName('pid').AsInteger;
    finally
      LDataSet.Free;
    end;
  except
    // Se o servidor adquiriu o bloqueio mas a resposta falhou, não devolva a sessão ao pool.
    InvalidarSessaoNFCe;
    raise;
  end;

  if Result = 0 then
    raise Exception.Create('Já existe uma emissão de NFC-e em andamento para esta venda.');
end;

procedure TRPNFeDAOVenda.DesbloquearEmissaoNFCe(AIdEmpresa, AIdVenda, ABackend: Integer);
var
  LDataSet: TDataSet;
  LLiberado: Boolean;
begin
  if (ABackend = 0) or not TPgQuery(Query.Component).Connection.Connected then
    Exit;

  try
    LDataSet := Query.SQL('select case when pg_catalog.pg_backend_pid() = :backend then')
      .SQL('pg_catalog.pg_advisory_unlock(' + SQLChaveBloqueioNFCe + ') else true end as liberado')
      .ParamAsInteger('backend', ABackend)
      .ParamAsInteger('idEmpresa', AIdEmpresa)
      .ParamAsInteger('idVenda', AIdVenda)
      .OpenDataSet;
    try
      LLiberado := LDataSet.FieldByName('liberado').AsBoolean;
    finally
      LDataSet.Free;
    end;
  except
    InvalidarSessaoNFCe;
    Exit;
  end;

  if not LLiberado then
    InvalidarSessaoNFCe;
end;

procedure TRPNFeDAOVenda.InvalidarSessaoNFCe;
begin
  // Encerra o backend físico. O pool reconecta o componente ao entregá-lo novamente.
  TPgQuery(Query.Component).Connection.Connected := False;
end;

procedure TRPNFeDAOVenda.ReverterTransacaoNFCe;
begin
  try
    if TPgQuery(Query.Component).Connection.InTransaction then
      Rollback;
  except
    InvalidarSessaoNFCe;
  end;
end;

procedure TRPNFeDAOVenda.ValidarBackendNFCe(ABackend: Integer);
var
  LDataSet: TDataSet;
begin
  LDataSet := Query.SQL('select pg_catalog.pg_backend_pid() = :backend as mesma_sessao')
    .ParamAsInteger('backend', ABackend)
    .OpenDataSet;
  try
    if not LDataSet.FieldByName('mesma_sessao').AsBoolean then
      raise Exception.Create('A conexão da emissão de NFC-e mudou. Tente novamente na mesma venda.');
  finally
    LDataSet.Free;
  end;
end;

function TRPNFeDAOVenda.BuscarTentativaNFCe(AIdEmpresa, AIdVenda, ABackend: Integer;
  out ATentativa: TRPNFeEntityTentativaNFCe): Boolean;
var
  LDataSet: TDataSet;
begin
  ATentativa := Default(TRPNFeEntityTentativaNFCe);
  LDataSet := Query.SQL('select pg_catalog.pg_backend_pid() = :backend as mesma_sessao,')
    .SQL('v.ven_001, v.ven_038, exists (select 1 from public.encerravenda e')
    .SQL('where e.emp_001 = v.emp_001 and e.ven_001 = v.ven_001) as encerrada,')
    .SQL('t.chave, t.xml_assinado, t.ambiente, t.contingencia')
    .SQL('from (select 1) origem')
    .SQL('left join public.venda v on v.emp_001 = :idEmpresa and v.ven_001 = :idVenda')
    .SQL('left join public.nfce_emissao_tentativa t on t.emp_001 = v.emp_001 and t.ven_001 = v.ven_001')
    .ParamAsInteger('backend', ABackend)
    .ParamAsInteger('idEmpresa', AIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda)
    .OpenDataSet;
  try
    if not LDataSet.FieldByName('mesma_sessao').AsBoolean then
      raise Exception.Create('A conexão da emissão de NFC-e mudou. Tente novamente na mesma venda.');
    if LDataSet.FieldByName('ven_001').IsNull then
      raise Exception.Create('Venda não encontrada para emissão da NFC-e.');
    if not LDataSet.FieldByName('encerrada').AsBoolean then
      raise Exception.Create('O fechamento da venda é obrigatório para emitir a NFC-e.');
    if Trim(LDataSet.FieldByName('ven_038').AsString) <> '' then
      raise Exception.Create('Esta venda já possui um documento fiscal. Consulte ou reimprima a nota.');

    Result := not LDataSet.FieldByName('chave').IsNull;
    if Result then
    begin
      ATentativa.Chave        := LDataSet.FieldByName('chave').AsString;
      ATentativa.XmlAssinado  := LDataSet.FieldByName('xml_assinado').AsString;
      ATentativa.Ambiente     := LDataSet.FieldByName('ambiente').AsInteger;
      ATentativa.Contingencia := LDataSet.FieldByName('contingencia').AsBoolean;
    end;
  finally
    LDataSet.Free;
  end;
end;

procedure TRPNFeDAOVenda.AtualizarCpfConsumidorNFCe(AIdEmpresa, AIdVenda, ABackend: Integer;
  const ACpfCnpj: string);
var
  LDataSet: TDataSet;
begin
  StartTransaction;
  try
    LDataSet := Query.SQL('with venda_sem_nota as (select v.emp_001, v.ven_001 from public.venda v')
      .SQL('where v.emp_001 = :idEmpresa and v.ven_001 = :idVenda')
      .SQL('and coalesce(btrim(v.ven_038), '''') = '''' for no key update of v)')
      .SQL('update public.encerravenda e set ven_cpfconsum = :cpf from venda_sem_nota v')
      .SQL('where e.emp_001 = v.emp_001 and e.ven_001 = v.ven_001')
      .SQL('and e.enc_001 = (select max(x.enc_001) from public.encerravenda x')
      .SQL('  where x.emp_001 = v.emp_001 and x.ven_001 = v.ven_001)')
      .SQL('and pg_catalog.pg_backend_pid() = :backend')
      .SQL('and not exists (select 1 from public.nfce_emissao_tentativa t')
      .SQL('  where t.emp_001 = v.emp_001 and t.ven_001 = v.ven_001)')
      .SQL('returning e.enc_001')
      .ParamAsString('cpf', ACpfCnpj, True)
      .ParamAsInteger('idEmpresa', AIdEmpresa)
      .ParamAsInteger('idVenda', AIdVenda)
      .ParamAsInteger('backend', ABackend)
      .OpenDataSet;
    try
      if LDataSet.IsEmpty then
        raise Exception.Create('CPF/CNPJ da NFC-e não alterado. Verifique o fechamento e a situação da emissão.');
    finally
      LDataSet.Free;
    end;
    Commit;
  except
    ReverterTransacaoNFCe;
    raise;
  end;
end;

procedure TRPNFeDAOVenda.RegistrarTentativaNFCe(AIdEmpresa, AIdVenda, ABackend: Integer;
  const ATentativa: TRPNFeEntityTentativaNFCe);
var
  LDataSet: TDataSet;
  LDigito: Char;
begin
  if (Length(ATentativa.Chave) <> 44) or (Trim(ATentativa.XmlAssinado) = '') or
    ((ATentativa.Ambiente <> 1) and (ATentativa.Ambiente <> 2)) then
    raise Exception.Create('Os dados da tentativa de NFC-e estão incompletos ou inválidos.');
  for LDigito in ATentativa.Chave do
    if not CharInSet(LDigito, ['0'..'9']) then
      raise Exception.Create('A chave da tentativa de NFC-e deve conter somente dígitos.');

  StartTransaction;
  try
    Query.SQL('set local synchronous_commit = on').ExecSQL;
    LDataSet := Query.SQL('insert into public.nfce_emissao_tentativa')
      .SQL('(emp_001, ven_001, chave, xml_assinado, ambiente, contingencia)')
      .SQL('select v.emp_001, v.ven_001, :chave, :xml, :ambiente, :contingencia')
      .SQL('from public.venda v where v.emp_001 = :idEmpresa and v.ven_001 = :idVenda')
      .SQL('and coalesce(btrim(v.ven_038), '''') = '''' and pg_catalog.pg_backend_pid() = :backend')
      .SQL('and exists (select 1 from public.encerravenda e')
      .SQL('  where e.emp_001 = v.emp_001 and e.ven_001 = v.ven_001)')
      .SQL('for no key update of v')
      .SQL('on conflict (emp_001, ven_001) do nothing')
      .SQL('returning ven_001')
      .ParamAsInteger('idEmpresa', AIdEmpresa)
      .ParamAsInteger('idVenda', AIdVenda)
      .ParamAsInteger('backend', ABackend)
      .ParamAsString('chave', ATentativa.Chave)
      .ParamAsString('xml', ATentativa.XmlAssinado)
      .ParamAsInteger('ambiente', ATentativa.Ambiente)
      .ParamAsBoolean('contingencia', ATentativa.Contingencia)
      .OpenDataSet;
    try
      if LDataSet.IsEmpty then
        raise Exception.Create('A tentativa da NFC-e não foi registrada. Consulte a situação fiscal da venda.');
    finally
      LDataSet.Free;
    end;
    Commit;
  except
    ReverterTransacaoNFCe;
    raise;
  end;
end;

procedure TRPNFeDAOVenda.RetirarTentativaNFCe(AIdEmpresa, AIdVenda, ABackend: Integer;
  const AChave: string);
var
  LDataSet: TDataSet;
begin
  StartTransaction;
  try
    Query.SQL('set local synchronous_commit = on').ExecSQL;
    LDataSet := Query.SQL('delete from public.nfce_emissao_tentativa')
      .SQL('where emp_001 = :idEmpresa and ven_001 = :idVenda and chave = :chave')
      .SQL('and pg_catalog.pg_backend_pid() = :backend')
      .SQL('returning ven_001')
      .ParamAsInteger('idEmpresa', AIdEmpresa)
      .ParamAsInteger('idVenda', AIdVenda)
      .ParamAsInteger('backend', ABackend)
      .ParamAsString('chave', AChave)
      .OpenDataSet;
    try
      if LDataSet.IsEmpty then
        raise Exception.Create('A tentativa da NFC-e não pôde ser retirada. Consulte a situação fiscal da venda.');
    finally
      LDataSet.Free;
    end;
    Commit;
  except
    ReverterTransacaoNFCe;
    raise;
  end;
end;

procedure TRPNFeDAOVenda.ConcluirEmissaoNFCe(AIdEmpresa, AIdVenda, ABackend: Integer;
  const ATentativa: TRPNFeEntityTentativaNFCe; ANota: TRPNFeEntityNFeNotaEletronica);
var
  LDataSet: TDataSet;
begin
  if not Assigned(ANota) or (ANota.Modelo <> 65) or (ANota.ChaveNFe <> ATentativa.Chave) or
    (ANota.Contingencia <> ATentativa.Contingencia) or (Trim(ANota.Xml) = '') then
    raise Exception.Create('O documento fiscal recebido não corresponde à tentativa registrada.');

  StartTransaction;
  try
    ValidarBackendNFCe(ABackend);
    Query.SQL('set local synchronous_commit = on').ExecSQL;
    LDataSet := QueryAtualizarEmissao(AIdEmpresa, AIdVenda, ANota)
      .SQL('and coalesce(btrim(ven_038), '''') = '''' and pg_catalog.pg_backend_pid() = :backend')
      .SQL('returning ven_001')
      .ParamAsInteger('backend', ABackend)
      .OpenDataSet;
    try
      if LDataSet.IsEmpty then
        raise Exception.Create('Não foi possível gravar a NFC-e. Consulte a situação fiscal da venda.');
    finally
      LDataSet.Free;
    end;

    LDataSet := Query.SQL('update public.encerravenda set ven_satstatus = 23')
      .SQL('where emp_001 = :idEmpresa and ven_001 = :idVenda and pg_catalog.pg_backend_pid() = :backend')
      .SQL('returning enc_001')
      .ParamAsInteger('idEmpresa', AIdEmpresa)
      .ParamAsInteger('idVenda', AIdVenda)
      .ParamAsInteger('backend', ABackend)
      .OpenDataSet;
    try
      if LDataSet.IsEmpty then
        raise Exception.Create('Não foi possível gravar a NFC-e. A venda está sem fechamento.');
    finally
      LDataSet.Free;
    end;

    LDataSet := Query.SQL('delete from public.nfce_emissao_tentativa')
      .SQL('where emp_001 = :idEmpresa and ven_001 = :idVenda and chave = :chave')
      .SQL('and ambiente = :ambiente and contingencia = :contingencia')
      .SQL('and pg_catalog.pg_backend_pid() = :backend')
      .SQL('returning ven_001')
      .ParamAsInteger('idEmpresa', AIdEmpresa)
      .ParamAsInteger('idVenda', AIdVenda)
      .ParamAsInteger('backend', ABackend)
      .ParamAsString('chave', ATentativa.Chave)
      .ParamAsInteger('ambiente', ATentativa.Ambiente)
      .ParamAsBoolean('contingencia', ATentativa.Contingencia)
      .OpenDataSet;
    try
      if LDataSet.IsEmpty then
        raise Exception.Create('A gravação da NFC-e exige uma tentativa fiscal correspondente à nota.');
    finally
      LDataSet.Free;
    end;
    Commit;
  except
    ReverterTransacaoNFCe;
    raise;
  end;
end;

function TRPNFeDAOVenda.QueryAtualizarEmissao(AIdEmpresa, AIdVenda: Integer;
  ANotaEletronica: TRPNFeEntityNFeNotaEletronica): IADRQuery;
begin
  Result := Query.SQL('update public.venda set ven_036 = :serie, ven_038 = :chaveNFe, ven_037 = :dataEmissao,')
    .SQL('numero_cupom = :numNFe, serie_cupom = :serie, nfce_contingencia = :contingencia,')
    .SQL('tipoFiscal = :tipoFiscal, xml_cfe = :xml,')
    .SQL('nfce_contingencia_enviada = false, nfce_inutilizada = false')
    .SQL('where ven_001 = :idVenda and emp_001 = :idEmpresa')
    .ParamAsInteger('idEmpresa', AIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda)
    .ParamAsInteger('serie', ANotaEletronica.Serie)
    .ParamAsString('chaveNFe', ANotaEletronica.ChaveNFe)
    .ParamAsDateTime('dataEmissao', ANotaEletronica.DataAutorizacao)
    .ParamAsInteger('numNFe', ANotaEletronica.NumeroNFe)
    .ParamAsBoolean('contingencia', ANotaEletronica.Contingencia)
    .ParamAsString('tipoFiscal', ANotaEletronica.ModeloDescription, True)
    .ParamAsString('xml', ANotaEletronica.Xml, True);
end;

procedure TRPNFeDAOVenda.AtualizarEmissao(AIdEmpresa, AIdVenda: Integer;
  ANotaEletronica: TRPNFeEntityNFeNotaEletronica);
begin
  StartTransaction;
  try
    QueryAtualizarEmissao(AIdEmpresa, AIdVenda, ANotaEletronica).ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;


function TRPNFeDAOVenda.Buscar(AIdEmpresa, AIdVenda: Integer): TRPNFeEntityVenda;
begin
  Select;
  Query.SQL('where venda.emp_001 = :idEmpresa and venda.ven_001 = :idVenda')
    .SQL('order by encerraVenda.enc_001 desc')
    .SQL('limit 1')
    .ParamAsInteger('idEmpresa', AIdEmpresa)
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

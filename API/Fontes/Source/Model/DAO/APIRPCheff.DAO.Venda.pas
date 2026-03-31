unit APIRPCheff.DAO.Venda;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  Data.DB,
  System.SysUtils,
  System.Generics.Collections;

type
  TAPIRPCheffDAOVenda = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityVenda>)
  private
    procedure Select;


  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityVenda; override;
  public
    function ListarPrePago: TObjectList<TAPIRPCheffEntityVenda>;
    procedure AtualizarCouvert(ACouvert: TAPIRPCheffEntityVendaPatchCouvert);
    procedure AtualizarNomeMesaComanda(AIdVenda: Integer; ANome: string);
    procedure AtualizarTotalVenda(AIdEmpresa, AIdVenda: Integer); overload;
    procedure AtualizarTotalVenda(AIdEmpresa, AIdVenda: Integer; AValor, AValorTaxa, APercentualTaxa: Currency); overload;
    procedure FinalizarVenda(AFechamento: TAPIRPCheffEntityVendaPostFechamento);
    function AtualizarNumeroCupom(AIdVenda: Integer): Integer;
    function Buscar(AIdVenda: Integer): TAPIRPCheffEntityVenda;
    function BuscarComMesaAguardandoLimpeza(ANumeroMesa: Integer): TAPIRPCheffEntityVenda;
    procedure Inserir(AVenda: TAPIRPCheffEntityVenda);
    procedure PreFechamento(APreFechamento: TAPIRPCheffEntityVendaPatchPreFechamento);
    procedure TransferirComanda(AIdVenda, ANumeroComanda: Integer);
    procedure TransferirMesa(AIdVenda, ANumeroMesa: Integer);
    function GetValorPago(AIdVenda: Integer): Currency;
    procedure IgnorarTaxaGarcom(AidVenda: Integer; AIgnorarTaxaGarcom: Boolean);
    procedure ReabrirMesaComanda(AIdVenda, AIdEmpresa: Integer);
    procedure JuntarItensVenda(AIdVendaOrigem, AIdVendaDestino: Integer);
    procedure MoverPagamentosAntecipados(AIdVendaOrigem, AIdVendaDestino: Integer);
    procedure DeletarVendaJuncao(AIdVendaOrigem: Integer);
  end;

implementation

{ TAPIRPCheffDAOVenda }

uses
  APIRPCheff.DAO.Factory;

procedure TAPIRPCheffDAOVenda.AtualizarCouvert(ACouvert: TAPIRPCheffEntityVendaPatchCouvert);
begin
  StartTransaction;
  try
    Query.SQL('update venda set nro_pessoas = :nro_pessoas,')
      .SQL('nro_couvert_f = :nro_couvert_f, nro_couvert_m = :nro_couvert_m')
      .SQL('where ven_001 = :ven_001 and emp_001 = :emp_001')
      .ParamAsInteger('nro_pessoas', ACouvert.numeroPessoas)
      .ParamAsInteger('nro_couvert_f', ACouvert.numeroCouvertFeminino)
      .ParamAsInteger('nro_couvert_m', ACouvert.numeroCouvertMasculino)
      .ParamAsInteger('emp_001', ACouvert.idEmpresa)
      .ParamAsInteger('ven_001', ACouvert.idVenda)
      .ExecSQL;
    Commit;
    AtualizarTotalVenda(ACouvert.idEmpresa, ACouvert.idVenda);
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVenda.FinalizarVenda(AFechamento: TAPIRPCheffEntityVendaPostFechamento);
begin
  StartTransaction;
  try
    Query.SQL('update venda set id_usuario_fech = :idUsuario,')
      .SQL('  imprimir_fech_mobile = :imprimirMobile,')
      .SQL('  fech_mobile_imp_interna = :interna,')
      .SQL('  b_visualizar_fech = :visualizarFechamento,')
      .SQL('  sit_001 = 1, ven_015 = 0, xml_fech_visualizar = null')
      .SQL('where ven_001 = :idVenda')
      .SQL('and emp_001 = :idEmpresa')
      .ParamAsInteger('idUsuario', AFechamento.idUsuario)
      .ParamAsBoolean('imprimirMobile', AFechamento.ImprimirMobile)
      .ParamAsBoolean('interna', AFechamento.impressoraInterna)
      .ParamAsBoolean('visualizarFechamento', AFechamento.VisualizarFechamento)
      .ParamAsInteger('idVenda', AFechamento.idVenda)
      .ParamAsInteger('idEmpresa', AFechamento.idEmpresa)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVenda.AtualizarNomeMesaComanda(AIdVenda: Integer; ANome: string);
begin
  StartTransaction;
  try
    Query.SQL('update venda set nome_mesa_comanda = :nome')
      .SQL('where ven_001 = :idVenda')
      .SQL('and emp_001 = :idEmpresa')
      .ParamAsInteger('idVenda', AIdVenda)
      .ParamAsInteger('idEmpresa', FIdEmpresa)
      .ParamAsString('nome', ANome, True)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

function TAPIRPCheffDAOVenda.AtualizarNumeroCupom(AIdVenda: Integer): Integer;
begin
  StartTransaction;
  try
    Result := ProximoId(FIdEmpresa, 'venda', 'numero_cupom', 'emp_001');
    FQuery.SQL('update venda set numero_cupom = :cupom')
      .SQL('where emp_001 = :idEmpresa')
      .SQL('and ven_001 = :idVenda')
      .ParamAsInteger('cupom', Result)
      .ParamAsInteger('idEmpresa', FIdEmpresa)
      .ParamAsInteger('idVenda', AIdVenda)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVenda.AtualizarTotalVenda(AIdEmpresa, AIdVenda: Integer; AValor, AValorTaxa, APercentualTaxa: Currency);
var
  LPercentual: Double;
begin
  StartTransaction;
  try
    Query.SQL('update venda set ven_009 = :valorTotal, ven_008 = :valorTaxa, ignorar_taxa_garcom = :ignorartaxa, ')
      .SQL('taxa_valor_garcom = :valorTaxa, taxa_percentual_garcom = :percentualTaxa')
      .SQL('where emp_001 = :idEmpresa')
      .SQL('and ven_001 = :idVenda')
      .ParamAsCurrency('valorTotal', AValor)
      .ParamAsCurrency('valorTaxa', AValorTaxa)
      .ParamAsInteger('idVenda', AIdVenda)
      .ParamAsInteger('idEmpresa', AIdEmpresa)
      .ParamAsFloat('percentualTaxa', APercentualTaxa)
      .ParamAsBoolean('ignorartaxa', APercentualTaxa <= 0)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;
procedure TAPIRPCheffDAOVenda.IgnorarTaxaGarcom(AidVenda:Integer;AIgnorarTaxaGarcom:Boolean);
begin
    StartTransaction;
   try
    Query.SQL('update venda set  ignorar_taxa_garcom =:ignorartaxa')
      .SQL('where emp_001 = :idEmpresa')
      .SQL('and ven_001 = :idVenda')
      .ParamAsInteger('idVenda', AIdVenda)
      .ParamAsInteger('idEmpresa', FIdEmpresa)
      .ParamAsBoolean('ignorartaxa', AIgnorarTaxaGarcom)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;

end;

procedure TAPIRPCheffDAOVenda.ReabrirMesaComanda(AIdVenda, AIdEmpresa: Integer);
begin
  StartTransaction;
  try
    Query.SQL('update venda set sit_001 = 8')
      .SQL('where ven_001 = :idVenda and emp_001 = :idEmpresa and sit_001 = 21')
      .ParamAsInteger('idVenda', AIdVenda)
      .ParamAsInteger('idEmpresa', AIdEmpresa)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVenda.JuntarItensVenda(AIdVendaOrigem, AIdVendaDestino: Integer);
begin
  StartTransaction;
  try
    // Renumera os itens da venda origem e move para venda destino
    Query.SQL('WITH renumerados AS (')
      .SQL('  SELECT emp_001, ven_001, ite_001,')
      .SQL('    ROW_NUMBER() OVER (ORDER BY ite_001)')
      .SQL('    + COALESCE((SELECT MAX(ite_001) FROM vendaitem WHERE emp_001 = :idEmpresa AND ven_001 = :idVendaDestino), 0)')
      .SQL('    AS novo_numero')
      .SQL('  FROM vendaitem')
      .SQL('  WHERE emp_001 = :idEmpresa AND ven_001 = :idVendaOrigem')
      .SQL(')')
      .SQL('UPDATE vendaitemopcional vio SET')
      .SQL('  id_venda = :idVendaDestino,')
      .SQL('  id_vendaitem = r.novo_numero')
      .SQL('FROM renumerados r')
      .SQL('WHERE vio.id_empresa = r.emp_001')
      .SQL('  AND vio.id_venda = r.ven_001')
      .SQL('  AND vio.id_vendaitem = r.ite_001')
      .ParamAsInteger('idEmpresa', FIdEmpresa)
      .ParamAsInteger('idVendaDestino', AIdVendaDestino)
      .ParamAsInteger('idVendaOrigem', AIdVendaOrigem)
      .ExecSQL;

    // Agora move os itens renumerados
    Query.SQL('WITH renumerados AS (')
      .SQL('  SELECT emp_001, ven_001, ite_001,')
      .SQL('    ROW_NUMBER() OVER (ORDER BY ite_001)')
      .SQL('    + COALESCE((SELECT MAX(ite_001) FROM vendaitem WHERE emp_001 = :idEmpresa AND ven_001 = :idVendaDestino), 0)')
      .SQL('    AS novo_numero')
      .SQL('  FROM vendaitem')
      .SQL('  WHERE emp_001 = :idEmpresa AND ven_001 = :idVendaOrigem')
      .SQL(')')
      .SQL('UPDATE vendaitem vi SET')
      .SQL('  ven_001 = :idVendaDestino,')
      .SQL('  ite_001 = r.novo_numero')
      .SQL('FROM renumerados r')
      .SQL('WHERE vi.emp_001 = r.emp_001')
      .SQL('  AND vi.ven_001 = r.ven_001')
      .SQL('  AND vi.ite_001 = r.ite_001')
      .ParamAsInteger('idEmpresa', FIdEmpresa)
      .ParamAsInteger('idVendaDestino', AIdVendaDestino)
      .ParamAsInteger('idVendaOrigem', AIdVendaOrigem)
      .ExecSQL;

    Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVenda.MoverPagamentosAntecipados(AIdVendaOrigem, AIdVendaDestino: Integer);
begin
  StartTransaction;
  try
    Query.SQL('UPDATE venda_pag_antecipado SET id_venda = :idVendaDestino,')
      .SQL('id_caixa = NULL, id_caixaitem = NULL')
      .SQL('WHERE id_venda = :idVendaOrigem AND id_empresa = :idEmpresa')
      .ParamAsInteger('idVendaDestino', AIdVendaDestino)
      .ParamAsInteger('idVendaOrigem', AIdVendaOrigem)
      .ParamAsInteger('idEmpresa', FIdEmpresa)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVenda.DeletarVendaJuncao(AIdVendaOrigem: Integer);
begin
  StartTransaction;
  try
    Query.SQL('DELETE FROM vendaitemopcional')
      .SQL('WHERE id_venda = :idVenda AND id_empresa = :idEmpresa')
      .ParamAsInteger('idVenda', AIdVendaOrigem)
      .ParamAsInteger('idEmpresa', FIdEmpresa)
      .ExecSQL;

    Query.SQL('DELETE FROM vendaitem')
      .SQL('WHERE ven_001 = :idVenda AND emp_001 = :idEmpresa')
      .ParamAsInteger('idVenda', AIdVendaOrigem)
      .ParamAsInteger('idEmpresa', FIdEmpresa)
      .ExecSQL;

    Query.SQL('DELETE FROM venda_pag_antecipado')
      .SQL('WHERE id_venda = :idVenda AND id_empresa = :idEmpresa')
      .ParamAsInteger('idVenda', AIdVendaOrigem)
      .ParamAsInteger('idEmpresa', FIdEmpresa)
      .ExecSQL;

    Query.SQL('DELETE FROM caixaitem')
      .SQL('WHERE id_venda = :idVenda AND id_empresa = :idEmpresa')
      .ParamAsInteger('idVenda', AIdVendaOrigem)
      .ParamAsInteger('idEmpresa', FIdEmpresa)
      .ExecSQL;

    Query.SQL('DELETE FROM venda')
      .SQL('WHERE ven_001 = :idVenda AND emp_001 = :idEmpresa')
      .ParamAsInteger('idVenda', AIdVendaOrigem)
      .ParamAsInteger('idEmpresa', FIdEmpresa)
      .ExecSQL;

    Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVenda.AtualizarTotalVenda(AIdEmpresa, AIdVenda: Integer);
begin
  StartTransaction;
  try
    Query.SQL('select fn_calcula_total_venda(:idVenda, :idEmpresa)')
      .ParamAsInteger('idVenda', AIdVenda)
      .ParamAsInteger('idEmpresa', AIdEmpresa)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

function TAPIRPCheffDAOVenda.Buscar(AIdVenda: Integer): TAPIRPCheffEntityVenda;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL('where venda.emp_001 = :idEmpresa')
    .SQL('and venda.ven_001 = :idVenda')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda)
    .OpenDataSet;
  try
    Result := DataSetToEntity(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOVenda.BuscarComMesaAguardandoLimpeza(ANumeroMesa: Integer): TAPIRPCheffEntityVenda;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL('where venda.emp_001 = :idEmpresa')
    .SQL('and venda.ven_025 = :numeroMesa')
    .SQL('and ven_015 = 1')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('numeroMesa', ANumeroMesa)
    .OpenDataSet;
  try
    Result := DataSetToEntity(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOVenda.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityVenda;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityVenda.Create;
    try
      Result.idEmpresa                    := ADataSet.FieldByName('emp_001').AsInteger;
      Result.idVenda                      := ADataSet.FieldByName('ven_001').AsInteger;
      Result.data                         := ADataSet.FieldByName('ven_004').AsDateTime;
      Result.valorTaxaServico             := ADataSet.FieldByName('ven_008').AsCurrency;
      Result.valor                        := ADataSet.FieldByName('ven_009').AsCurrency;
      Result.dataAbertura                 := ADataSet.FieldByName('dat_001_1').AsDateTime;
      Result.idCliente                    := ADataSet.FieldByName('cli_001').AsInteger;
      Result.idUsuario                    := ADataSet.FieldByName('usu_001_1').AsInteger;
      Result.idUsuarioPreFechamento       := ADataSet.FieldByName('usu_001_2').AsInteger;
      Result.terminalAbertura             := ADataSet.FieldByName('terminal_abertura').AsString;
      Result.idCaixa                      := ADataSet.FieldByName('id_caixa_abertura').AsInteger;
      Result.nomeMesaComanda              := ADataSet.FieldByName('nome_mesa_comanda').AsString;
      Result.numeroMesa                   := ADataSet.FieldByName('ven_025').AsInteger;
      Result.numeroComanda                := ADataSet.FieldByName('ven_026').AsInteger;
      Result.numeroPessoas                := ADataSet.FieldByName('nro_pessoas').AsInteger;
      Result.numeroCouvertMasculino       := ADataSet.FieldByName('nro_couvert_m').AsInteger;
      Result.numeroCouvertFeminino        := ADataSet.FieldByName('nro_couvert_f').AsInteger;
      Result.imprimirPreFechamento        := ADataSet.FieldByName('imprimir_prefechamento_mobile').AsBoolean;
      Result.numeroCupom                  := ADataSet.FieldByName('numero_cupom').AsInteger;
      Result.valorEntrada                 := ADataSet.FieldByName('valor_entrada').AsCurrency;
      Result.taxaCartao                   := ADataSet.FieldByName('taxa_cartao_reter').AsCurrency;
      Result.totalPrePago                 := ADataSet.FieldByName('total_pre').AsCurrency;
      Result.chaveEletronica := ADataSet.FieldByName('ven_038').AsString;
      Result.situacao.FromDBValue(ADataSet.FieldByName('sit_001').AsInteger);
      Result.tipoVenda.FromDBValue(ADataSet.FieldByName('ven_024').AsString);

      if Result.idCliente > 0 then
      begin
        Result.cliente.id         := Result.idCliente;
        Result.cliente.nome       := ADataSet.FieldByName('cli_002').AsString;
        Result.cliente.documento  := ADataSet.FieldByName('cli_004').AsString;
      end;
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TAPIRPCheffDAOVenda.GetValorPago(AIdVenda: Integer): Currency;
var
  LPagamentos: TObjectList<TAPIRPCheffEntityVendaPagamentoAntecipado>;
  I: Integer;
begin
  Result := 0;
  LPagamentos := TAPIRPCheffDAOFactory(FactoryDAO).VendaPagamentoAntecipadoDAO
    .Listar(AIdVenda);
  try
    for I := 0 to Pred(LPagamentos.Count) do
    begin
      if LPagamentos[I].situacao = sAtivo then
        Result := Result + LPagamentos[I].valor;
    end;
  finally
    FreeAndNil(LPagamentos);
  end;
end;

procedure TAPIRPCheffDAOVenda.Inserir(AVenda: TAPIRPCheffEntityVenda);
begin
  StartTransaction;
  try
    AVenda.idVenda := Self.ProximoId(FIdEmpresa, 'venda', 'ven_001', 'emp_001');
    Query.SQL('insert into venda (')
      .SQL(' ven_001,  emp_001, dat_001_1, ven_025, cli_001,')
      .SQL(' sit_001, usu_001_1, ven_024, ven_029, ven_004, ')
      .SQL(' id_caixa_abertura, ven_026, terminal_abertura, nome_mesa_comanda,')
      .SQL(' nro_pessoas)')
      .SQL('values (')
      .SQL(' :ven_001, :emp_001, :dat_001_1, :ven_025, :cli_001,')
      .SQL(' :sit_001, :usu_001_1, :VEN_024, :ven_029, :ven_004,')
      .SQL(' :id_caixa_abertura, :ven_026, :terminal_abertura, :nome_mesa_comanda,')
      .SQL(' :nro_pessoas)')
      .ParamAsInteger('ven_001', AVenda.idVenda)
      .ParamAsInteger('emp_001', FIdEmpresa)
      .ParamAsDateTime('dat_001_1', AVenda.dataAbertura)
      .ParamAsInteger('ven_025', AVenda.numeroMesa, True)
      .ParamAsInteger('cli_001', AVenda.idCliente)
      .ParamAsInteger('sit_001', AVenda.situacao.DBValue)
      .ParamAsInteger('usu_001_1', AVenda.idUsuario, True)
      .ParamAsString('ven_024', AVenda.tipoVenda.DBValue)
      .ParamAsInteger('ven_029', AVenda.idVenda)
      .ParamAsDateTime('ven_004', AVenda.data)
      .ParamAsInteger('id_caixa_abertura', AVenda.idCaixa)
      .ParamAsInteger('ven_026', AVenda.numeroComanda, True)
      .ParamAsString('terminal_abertura', AVenda.terminalAbertura, True)
      .ParamAsString('nome_mesa_comanda', AVenda.nomeMesaComanda, True)
      .ParamAsInteger('nro_pessoas', AVenda.numeroPessoas, True)
      .ExecSQL;

    Commit;
  except
    Rollback;
    raise;
  end;
end;

function TAPIRPCheffDAOVenda.ListarPrePago: TObjectList<TAPIRPCheffEntityVenda>;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL('where venda.emp_001 = :idEmpresa')
    .SQL('and venda.sit_001 = 8')
    .SQL('and venda.ven_024 = ''C'' ')
    .SQL('and venda.cli_001 > 0')
    .SQL('order by venda.ven_026')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

procedure TAPIRPCheffDAOVenda.PreFechamento(APreFechamento: TAPIRPCheffEntityVendaPatchPreFechamento);
begin
  StartTransaction;
  try
    Query.SQL('update venda set sit_001 = 21, nro_pessoas = :nro_pessoas,')
      .SQL('nro_couvert_f = :nro_couvert_f, nro_couvert_m = :nro_couvert_m,')
      .SQL('dat_001_2 = :data, usu_001_2 = :idUsuario, ')
      .SQL('imprimir_prefechamento_mobile = :imprimir, id_usuario_pre = :idUsuarioPre,')
      .SQL('pre_fech_mobile_imp_interna = :impressaoInterna, ven_008 = :ven_008')
      .SQL('where ven_001 = :ven_001 and emp_001 = :emp_001')
      .ParamAsInteger('nro_pessoas', APreFechamento.numeroPessoas)
      .ParamAsInteger('nro_couvert_f', APreFechamento.numeroCouvertFeminino)
      .ParamAsInteger('nro_couvert_m', APreFechamento.numeroCouvertMasculino)
      .ParamAsDateTime('data', Now)
      .ParamAsInteger('idUsuario', APreFechamento.idUsuario)
      .ParamAsBoolean('imprimir', APreFechamento.imprimirPreFechamentoMobile)
      .ParamAsInteger('idUsuarioPre', APreFechamento.idUsuario)
      .ParamAsBoolean('impressaoInterna', APreFechamento.preFechamentoMobileImpressaoInterna)
      .ParamAsCurrency('ven_008', 0)
      .ParamAsInteger('emp_001', APreFechamento.idEmpresa)
      .ParamAsInteger('ven_001', APreFechamento.idVenda)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVenda.Select;
begin
  Query.SQL('select venda.emp_001, venda.ven_001,  venda.ven_004, venda.ven_008,')
    .SQL(' venda.ven_009, venda.dat_001_1, venda.cli_001, venda.total_pre,')
    .SQL(' venda.sit_001, venda.usu_001_1, venda.id_caixa_abertura, venda.terminal_abertura,')
    .SQL(' venda.ven_015, venda.ven_024, venda.ven_025, venda.ven_026, venda.ven_029, venda.ven_038,')
    .SQL(' venda.taxa_cartao_reter, venda.valor_entrada,')
    .SQL(' venda.nro_pessoas, venda.nro_couvert_f, venda.nro_couvert_m,')
    .SQL(' venda.numero_cupom, venda.usu_001_2,')
    .SQL(' venda.imprimir_prefechamento_mobile, venda.nome_mesa_comanda,')
    .SQL(' clientes.cli_002, clientes.cli_004')
    .SQL(' from venda')
    .SQL(' left join clientes on venda.cli_001 = clientes.cli_001 and venda.emp_001 = clientes.emp_001');

end;

procedure TAPIRPCheffDAOVenda.TransferirComanda(AIdVenda, ANumeroComanda: Integer);
begin
  StartTransaction;
  try
    Query.SQL('update venda set ven_026 = :numeroComanda')
      .SQL('  where emp_001 = :idEmpresa')
      .SQL('  and ven_001 = :idVenda')
      .ParamAsInteger('numeroComanda', ANumeroComanda)
      .ParamAsInteger('idEmpresa', FIdEmpresa)
      .ParamAsInteger('idVenda', AIdVenda)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVenda.TransferirMesa(AIdVenda, ANumeroMesa: Integer);
begin
  StartTransaction;
  try
    Query.SQL('update venda set ven_025 = :numeroMesa')
      .SQL('  where emp_001 = :idEmpresa')
      .SQL('  and ven_001 = :idVenda')
      .ParamAsInteger('numeroMesa', ANumeroMesa)
      .ParamAsInteger('idEmpresa', FIdEmpresa)
      .ParamAsInteger('idVenda', AIdVenda)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

end.

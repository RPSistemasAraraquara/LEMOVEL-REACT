unit APIRPCheff.DAO.VendaItem;

interface

uses
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Base,
  Data.DB,
  System.Math,
  System.Generics.Collections,
  System.SysUtils;

type

  TAPIRPCheffDAOVendaItem = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityVendaItem>)
  private
    procedure Select;
    procedure CarregarOpcionaisEmLote(AItens: TObjectList<TAPIRPCheffEntityVendaItem>);
    procedure GarantirControleLancamentoMobile;


  protected
    function DataSetToList(ADataSet: TDataSet): TObjectList<TAPIRPCheffEntityVendaItem>; override;
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityVendaItem; override;
  public
    procedure AtualizarItemImpresso(AIdVenda,AidNumeroItem: Integer; AFlagImpresso: Boolean = True);
    function UltimoNumeroItemLancado(AIdVenda: Integer): Integer;
    function UltimoItemFracionado(AIdVenda: Integer): Integer;
    function Listar(AIdVenda: Integer): TObjectList<TAPIRPCheffEntityVendaItem>; overload;
    function Listar(AIdVenda: Integer; ASituacao: TRPCheffSituacaoItem): TObjectList<TAPIRPCheffEntityVendaItem>; overload;
    function Listar(AIdVenda, ACodProduto: Integer; ASituacao: TRPCheffSituacaoItem = siOK): TObjectList<TAPIRPCheffEntityVendaItem>; overload;
    procedure GarantirPrecisaoQuantidadeDecimal;
    function Inserir(AVendaItem: TAPIRPCheffEntityVendaItem; APendenteImpressao: Boolean = True): Boolean;
    procedure LiberarImpressao(AIdEmpresa, AIdVenda: Integer);
    procedure Cancelar(ACancelamento: TAPIRPCheffEntityVendaItemCancelamento);
    function ListarVendasAgrupadosProdutos(AidVenda: Integer): TObjectList<TAPIRPCheffEntityVendaItem>;
    function ListarProdutosSomenteTaxaGarcom(AIdVenda: Integer): Currency;
    procedure TotalizarItensVenda(AIdVenda: Integer; out ATotalItens, ADesconto: Currency);
    procedure AplicarDescontoProporcional(AidVenda: Integer;ADesconto: Currency);
    procedure RatearTaxaGarcomPorItens(AidVenda: Integer);
    procedure CalcularMargemLucro(AidVenda: Integer);
    procedure AtualizarQuantidadePago(AIdVenda,AidNumeroItem: Integer;AQuantidadePaga,AValorPago:Currency);
  end;

implementation

{ TAPIRPCheffDAOVendaItem }

uses
  APIRPCheff.DAO.Factory;

var
  GQuantidadeDecimalPrecisionChecked: Boolean = False;
  GControleLancamentoMobileChecked: Boolean = False;
  GSchemaLock: TObject;


procedure TAPIRPCheffDAOVendaItem.GarantirPrecisaoQuantidadeDecimal;
var
  LDataSet    : TDataSet;
  LColumnName : string;
begin
  if GQuantidadeDecimalPrecisionChecked then
    Exit;

  TMonitor.Enter(GSchemaLock);
  try
    if GQuantidadeDecimalPrecisionChecked then
      Exit;

    LDataSet := Query.SQL('select column_name')
      .SQL('from information_schema.columns')
      .SQL('where table_schema = current_schema()')
      .SQL('and lower(table_name) = ''vendaitem''')
      .SQL('and lower(column_name) in (''ite_002'', ''quantidade_impressao'', ''qtd_paga_antec'')')
      .SQL('and data_type = ''numeric''')
      .SQL('and coalesce(numeric_scale, 0) < 3')
      .OpenDataSet;
    try
      LDataSet.First;
      while not LDataSet.Eof do
      begin
        LColumnName := LDataSet.FieldByName('column_name').AsString;
        if SameText(LColumnName, 'ite_002') or SameText(LColumnName, 'quantidade_impressao') or SameText(LColumnName, 'qtd_paga_antec') then
          Query.SQL('alter table vendaItem alter column %s type numeric(18,3)', [LColumnName]).ExecSQL;
        LDataSet.Next;
      end;
    finally
      FreeAndNil(LDataSet);
    end;

    GQuantidadeDecimalPrecisionChecked := True;
  finally
    TMonitor.Exit(GSchemaLock);
  end;
end;

procedure TAPIRPCheffDAOVendaItem.GarantirControleLancamentoMobile;
var
  LDataSet: TDataSet;
begin
  if GControleLancamentoMobileChecked then
    Exit;

  TMonitor.Enter(GSchemaLock);
  try
    if GControleLancamentoMobileChecked then
      Exit;

    LDataSet := Query.SQL('select column_name')
      .SQL('from information_schema.columns')
      .SQL('where table_schema = current_schema()')
      .SQL('and lower(table_name) = ''vendaitem''')
      .SQL('and lower(column_name) = ''id_lancamento_mobile''')
      .OpenDataSet;
    try
      if LDataSet.IsEmpty then
        Query.SQL('alter table vendaItem add column id_lancamento_mobile varchar(100)').ExecSQL;
    finally
      FreeAndNil(LDataSet);
    end;

    Query.SQL('create unique index if not exists ux_vendaitem_lanc_mobile')
      .SQL('on vendaItem (emp_001, ven_001, id_lancamento_mobile)')
      .ExecSQL;

    GControleLancamentoMobileChecked := True;
  finally
    TMonitor.Exit(GSchemaLock);
  end;
end;


function TAPIRPCheffDAOVendaItem.Inserir(AVendaItem: TAPIRPCheffEntityVendaItem; APendenteImpressao: Boolean = True): Boolean;
var
  LMobileLaunchId: string;
  LDataSet: TDataSet;
begin
  LMobileLaunchId := Trim(Copy(AVendaItem.mobileLaunchId, 1, 100));
  if LMobileLaunchId <> EmptyStr then
    GarantirControleLancamentoMobile;

  StartTransaction;
  try
    if LMobileLaunchId <> EmptyStr then
    begin
      LDataSet := Query.SQL('INSERT INTO vendaItem (')
        .SQL('  emp_001, ven_001, ite_001, mat_001, ite_002, ite_003, data_hora_lancamento,')
        .SQL('  ite_005, ite_006, sit_001, produtoimpresso, pendenteimpressao, ite_013, ite_014, gar_001,')
        .SQL('  desconto, acrescimo, tamanho, b_venda_tamanho, mesa_vinc,')
        .SQL('  b_gratis, item_fracionado, quantidade_impressao, terminal_impressao, lancamento_mobile, id_lancamento_mobile)')
        .SQL('VALUES (')
        .SQL('  :emp_001, :ven_001, :ite_001, :mat_001, :ite_002, :ite_003, :data_hora_lancamento,')
        .SQL('  :ite_005, :ite_006, :sit_001, :produtoimpresso, :pendenteimpressao, :ite_013, :ite_014, :gar_001,')
        .SQL('  :desconto, :acrescimo, :tamanho, :b_venda_tamanho, :mesa_vinc,')
        .SQL('  :b_gratis, :item_fracionado, :quantidade_impressao, :terminal_impressao, :lancamento_mobile, :id_lancamento_mobile)')
        .SQL('ON CONFLICT (emp_001, ven_001, id_lancamento_mobile) DO NOTHING')
        .SQL('RETURNING ite_001')
        .ParamAsInteger ('emp_001', AVendaItem.idEmpresa)
        .ParamAsInteger ('ven_001', AVendaItem.idVenda)
        .ParamAsInteger ('ite_001', AVendaItem.numeroItem)
        .ParamAsInteger ('mat_001', AVendaItem.idProduto)
        .ParamAsFloat('ite_002', AVendaItem.quantidade)
        .ParamAsCurrency('ite_003', AVendaItem.valorUnitario)
        .ParamAsDateTime('data_hora_lancamento', AVendaItem.dataLancamento)
        .ParamAsCurrency('ite_005', AVendaItem.valorTotal)
        .ParamAsString  ('ite_006', AVendaItem.observacao)
        .ParamAsCurrency('desconto', AVendaItem.desconto)
        .ParamAsCurrency('acrescimo', AVendaItem.acrescimo)
        .ParamAsInteger ('sit_001', AVendaItem.situacao.DBValue)
        .ParamAsBoolean ('produtoimpresso', False)
        .ParamAsBoolean ('pendenteimpressao', APendenteImpressao)
        .ParamAsInteger ('ite_013', AVendaItem.impressora1, True)
        .ParamAsInteger ('ite_014', AVendaItem.impressora2, True)
        .ParamAsInteger ('gar_001', AVendaItem.idGarcom)
        .ParamAsString  ('tamanho', AVendaItem.tamanho, True)
        .ParamAsBoolean ('b_venda_tamanho', AVendaItem.vendaPorTamanho)
        .ParamAsInteger ('mesa_vinc', AVendaItem.idMesaVinculada)
        .ParamAsBoolean ('b_gratis', AVendaItem.gratis)
        .ParamAsInteger ('item_fracionado', AVendaItem.itemFracionado, True)
        .ParamAsFloat('quantidade_impressao', AVendaItem.quantidade, True)
        .ParamAsString  ('terminal_impressao', AVendaItem.TerminalImpressao)
        .ParamAsBoolean ('lancamento_mobile', True)
        .ParamAsString  ('id_lancamento_mobile', LMobileLaunchId)
        .OpenDataSet;
      try
        Result := not LDataSet.IsEmpty;
      finally
        FreeAndNil(LDataSet);
      end;
    end
    else
    begin
      Query.SQL('INSERT INTO vendaItem (')
        .SQL('  emp_001, ven_001, ite_001, mat_001, ite_002, ite_003, data_hora_lancamento,')
        .SQL('  ite_005, ite_006, sit_001, produtoimpresso, pendenteimpressao, ite_013, ite_014, gar_001,')
        .SQL('  desconto, acrescimo, tamanho, b_venda_tamanho, mesa_vinc,')
        .SQL('  b_gratis, item_fracionado, quantidade_impressao, terminal_impressao, lancamento_mobile)')
        .SQL('VALUES (')
        .SQL('  :emp_001, :ven_001, :ite_001, :mat_001, :ite_002, :ite_003, :data_hora_lancamento,')
        .SQL('  :ite_005, :ite_006, :sit_001, :produtoimpresso, :pendenteimpressao, :ite_013, :ite_014, :gar_001,')
        .SQL('  :desconto, :acrescimo, :tamanho, :b_venda_tamanho, :mesa_vinc,')
        .SQL('  :b_gratis, :item_fracionado, :quantidade_impressao, :terminal_impressao, :lancamento_mobile)')
        .ParamAsInteger ('emp_001', AVendaItem.idEmpresa)
        .ParamAsInteger ('ven_001', AVendaItem.idVenda)
        .ParamAsInteger ('ite_001', AVendaItem.numeroItem)
        .ParamAsInteger ('mat_001', AVendaItem.idProduto)
        .ParamAsFloat('ite_002', AVendaItem.quantidade)
        .ParamAsCurrency('ite_003', AVendaItem.valorUnitario)
        .ParamAsDateTime('data_hora_lancamento', AVendaItem.dataLancamento)
        .ParamAsCurrency('ite_005', AVendaItem.valorTotal)
        .ParamAsString  ('ite_006', AVendaItem.observacao)
        .ParamAsCurrency('desconto', AVendaItem.desconto)
        .ParamAsCurrency('acrescimo', AVendaItem.acrescimo)
        .ParamAsInteger ('sit_001', AVendaItem.situacao.DBValue)
        .ParamAsBoolean ('produtoimpresso', False)
        .ParamAsBoolean ('pendenteimpressao', APendenteImpressao)
        .ParamAsInteger ('ite_013', AVendaItem.impressora1, True)
        .ParamAsInteger ('ite_014', AVendaItem.impressora2, True)
        .ParamAsInteger ('gar_001', AVendaItem.idGarcom)
        .ParamAsString  ('tamanho', AVendaItem.tamanho, True)
        .ParamAsBoolean ('b_venda_tamanho', AVendaItem.vendaPorTamanho)
        .ParamAsInteger ('mesa_vinc', AVendaItem.idMesaVinculada)
        .ParamAsBoolean ('b_gratis', AVendaItem.gratis)
        .ParamAsInteger ('item_fracionado', AVendaItem.itemFracionado, True)
        .ParamAsFloat('quantidade_impressao', AVendaItem.quantidade, True)
        .ParamAsString  ('terminal_impressao', AVendaItem.TerminalImpressao)
        .ParamAsBoolean ('lancamento_mobile', True)
        .ExecSQL;
      Result := True;
    end;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVendaItem.LiberarImpressao(AIdEmpresa, AIdVenda: Integer);
begin
  StartTransaction;
  try
    Query.SQL('UPDATE vendaItem SET pendenteimpressao = :pendenteimpressao')
      .SQL(' WHERE emp_001 = :emp_001 AND ven_001 = :ven_001')
      .SQL('   AND produtoimpresso = :produtoimpresso')
      .SQL('   AND pendenteimpressao = :pendente_atual')
      .ParamAsBoolean('pendenteimpressao', True)
      .ParamAsInteger('emp_001', AIdEmpresa)
      .ParamAsInteger('ven_001', AIdVenda)
      .ParamAsBoolean('produtoimpresso', False)
      .ParamAsBoolean('pendente_atual', False)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVendaItem.AtualizarQuantidadePago(AIdVenda,AidNumeroItem: Integer;AQuantidadePaga,AValorPago:Currency);
begin
  StartTransaction;
  try
    Query.SQL('update vendaitem                                     ')
    .SQL('   set valor_pago_antec   = :valor_pago_antec,            ')
    .SQL('   qtd_paga_antec = :qtd_paga_antec                       ')
    .SQL('   where emp_001 = :idEmpresa                             ')
    .SQL('   and ven_001 = :idVenda                                 ')
    .SQL('   and ite_001 =:ite_001                                  ')
    .ParamAsCurrency('valor_pago_antec', AValorPago)
    .ParamAsFloat('qtd_paga_antec', AQuantidadePaga)
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda)
     .ParamAsInteger('ite_001', AidNumeroItem)
    .ExecSQL;
    Commit;

  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVendaItem.AtualizarItemImpresso(AIdVenda,AidNumeroItem: Integer; AFlagImpresso: Boolean);
begin
  StartTransaction;
  try
    Query.SQL('update vendaitem                                   ')
    .SQL('   set produtoimpresso   = :produtoimpresso,            ')
    .SQL('   pendenteimpressao = :pendenteimpressao               ')
    .SQL('   where emp_001 = :idEmpresa                           ')
    .SQL('   and ven_001 = :idVenda and produtoimpresso = false   ')
    .SQL('   and ite_001 =:ite_001                                ')
    .ParamAsBoolean('produtoimpresso', AFlagImpresso)
    .ParamAsBoolean('pendenteimpressao', false)
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda)
     .ParamAsInteger('ite_001', AidNumeroItem)
    .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVendaItem.Cancelar(ACancelamento: TAPIRPCheffEntityVendaItemCancelamento);
begin
  StartTransaction;
  try
    Query.SQL('update vendaitem set sit_001 = 2, id_usuario_cancelamento = :idUsuario, ')
      .SQL('justificativa_cancelamento = :justificativa, b_imprime_canc_mobile = true, ')
      .SQL('data_cancelamento = :dataCancelamento')
      .SQL('where emp_001 = :idEmpresa')
      .SQL('and ven_001 = :idVenda')
      .SQL('and (ite_001 = :numeroItem or item_fracionado = :numeroItem)')
      .ParamAsInteger('idUsuario', ACancelamento.idUsuario)
      .ParamAsString('justificativa', ACancelamento.justificativa)
      .ParamAsInteger('idEmpresa', ACancelamento.idEmpresa)
      .ParamAsInteger('idVenda', ACancelamento.idVenda)
      .ParamAsInteger('numeroItem', ACancelamento.numeroItem)
      .ParamAsDateTime('dataCancelamento', ACancelamento.dataCancelamento)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

function TAPIRPCheffDAOVendaItem.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityVendaItem;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityVendaItem.Create;
    try
      Result.idEmpresa                      := ADataSet.FieldByName('emp_001').AsInteger;
      Result.idVenda                        := ADataSet.FieldByName('ven_001').AsInteger;
      Result.numeroItem                     := ADataSet.FieldByName('ite_001').AsInteger;
      Result.idProduto                      := ADataSet.FieldByName('mat_001').AsInteger;
      Result.idMesaVinculada                := ADataSet.FieldByName('mesa_vinc').AsInteger;
      Result.dataLancamento                 := ADataSet.FieldByName('data_hora_lancamento').AsDateTime;
      Result.quantidade                     := ADataSet.FieldByName('ite_002').AsCurrency;
      Result.valorUnitario                  := ADataSet.FieldByName('ite_003').AsCurrency;
      Result.valorTotal                     := ADataSet.FieldByName('ite_005').AsCurrency;
      Result.desconto                       := ADataSet.FieldByName('desconto').AsCurrency;
      Result.acrescimo                      := ADataSet.FieldByName('acrescimo').AsCurrency;
      Result.observacao                     := ADataSet.FieldByName('ite_006').AsString;
      Result.pendenteImpressao              := ADataSet.FieldByName('ProdutoImpresso').AsBoolean;
      Result.impressora1                    := ADataSet.FieldByName('ite_013').AsInteger;
      Result.impressora2                    := ADataSet.FieldByName('ite_014').AsInteger;
      Result.idGarcom                       := ADataSet.FieldByName('gar_001').AsInteger;
      Result.tamanho                        := ADataSet.FieldByName('tamanho').AsString;
      Result.vendaPorTamanho                := ADataSet.FieldByName('b_venda_tamanho').AsBoolean;
      Result.idUsuarioCancelamento          := ADataSet.FieldByName('id_usuario_cancelamento').AsInteger;
      Result.dataCancelamento               := ADataSet.FieldByName('data_cancelamento').AsDateTime;
      Result.justificativaCancelamento      := ADataSet.FieldByName('justificativa_cancelamento').AsString;
      Result.situacao.FromDBValue(ADataSet.FieldByName('sit_001').AsInteger);
      Result.gratis                         := ADataSet.FieldByName('b_gratis').AsBoolean;
      Result.itemFracionado                 := ADataSet.FieldByName('item_fracionado').AsInteger;
      Result.produtoIdCategoria             := ADataSet.FieldByName('cat_001').AsInteger;
      Result.produtoDescricao               := ADataSet.FieldByName('mat_003').AsString;
      Result.produtoCodReferencia           := ADataSet.FieldByName('mat_004').AsString;
      Result.produtoUtilizaCombo            := ADataSet.FieldByName('utiliza_combo').AsBoolean;
      Result.produtoIdSetor                 := ADataSet.FieldByName('id_setor').AsInteger;
      Result.ImprimirFichaIndividual        := ADataSet.FieldByName('b_ficha_individual').AsBoolean;
      Result.TerminalImpressao              := ADataSet.FieldByName('terminal_impressao').AsString;
      Result.QuantidadePagaAntecipado       := ADataSet.FieldByName('qtd_paga_antec').AsCurrency;
      Result.ValorPagoAntecipado            := ADataSet.FieldByName('valor_pago_antec').AsCurrency;
      Result.ValorTaxaServico               := ADataSet.FieldByName('rateiotaxagarcom').AsCurrency;
      Result.nomeGarcom                     := ADataSet.FieldByName('nomeGarcom').AsString;

      if Result.vendaPorTamanho then
      begin
        if Result.tamanho = 'P' then
          Result.descricaoTamanho := ADataSet.FieldByName('tamanho_p').AsString;
        if Result.tamanho = 'M' then
          Result.descricaoTamanho := ADataSet.FieldByName('tamanho_m').AsString;
        if Result.tamanho = 'G' then
          Result.descricaoTamanho := ADataSet.FieldByName('tamanho_g').AsString;
        if Result.tamanho = 'GG' then
          Result.descricaoTamanho := ADataSet.FieldByName('tamanho_gg').AsString;
        if Result.tamanho = 'EXTRA' then
          Result.descricaoTamanho := ADataSet.FieldByName('tamanho_extra').AsString;
      end;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffDAOVendaItem.CarregarOpcionaisEmLote(AItens: TObjectList<TAPIRPCheffEntityVendaItem>);
var
  I               : Integer;
  LIdVenda        : Integer;
  LIdEmpresa      : Integer;
  LMesmoContexto  : Boolean;
  LItem           : TAPIRPCheffEntityVendaItem;
  LItensPorNumero : TDictionary<Integer, TAPIRPCheffEntityVendaItem>;
  LOpcional       : TAPIRPCheffEntityVendaItemOpcional;
  LOpcionais      : TObjectList<TAPIRPCheffEntityVendaItemOpcional>;
  LCopia          : TAPIRPCheffEntityVendaItemOpcional;
begin
  if (not Assigned(AItens)) or (AItens.Count = 0) then
    Exit;

  LIdVenda := AItens[0].idVenda;
  LIdEmpresa := AItens[0].idEmpresa;
  LMesmoContexto := True;
  for I := 0 to Pred(AItens.Count) do
  begin
    if (AItens[I].idVenda <> LIdVenda) or (AItens[I].idEmpresa <> LIdEmpresa) then
    begin
      LMesmoContexto := False;
      Break;
    end;
  end;

  if not LMesmoContexto then
  begin
    for I := 0 to Pred(AItens.Count) do
      AItens[I].opcionais := TAPIRPCheffDAOFactory(FactoryDAO)
        .IdEmpresa(AItens[I].idEmpresa)
        .VendaItemOpcionalDAO
        .Listar(AItens[I].idVenda, AItens[I].numeroItem);
    Exit;
  end;

  LOpcionais := nil;
  LItensPorNumero := nil;
  try
    LOpcionais := TAPIRPCheffDAOFactory(FactoryDAO)
      .IdEmpresa(LIdEmpresa)
      .VendaItemOpcionalDAO
      .ListarTodosPorVenda(LIdVenda);
    LItensPorNumero := TDictionary<Integer, TAPIRPCheffEntityVendaItem>.Create;

    for I := 0 to Pred(AItens.Count) do
      LItensPorNumero.AddOrSetValue(AItens[I].numeroItem, AItens[I]);

    for LOpcional in LOpcionais do
      if LItensPorNumero.TryGetValue(LOpcional.idVendaItem, LItem) then
      begin
        LCopia := TAPIRPCheffEntityVendaItemOpcional.Create;
        try
          LCopia.Assign(LOpcional);
          LItem.opcionais.Add(LCopia);
        except
          LCopia.Free;
          raise;
        end;
      end;
  finally
    LItensPorNumero.Free;
    LOpcionais.Free;
  end;
end;

function TAPIRPCheffDAOVendaItem.DataSetToList(ADataSet: TDataSet): TObjectList<TAPIRPCheffEntityVendaItem>;
begin
  Result := inherited;
  CarregarOpcionaisEmLote(Result);
  TAPIRPCheffEntityVendaItem.SepararFracionados(Result);
end;

function TAPIRPCheffDAOVendaItem.Listar(AIdVenda, ACodProduto: Integer; ASituacao: TRPCheffSituacaoItem): TObjectList<TAPIRPCheffEntityVendaItem>;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL('where vendaItem.emp_001 = :idEmpresa')
    .SQL('and vendaItem.ven_001 = :idVenda')
    .SQL('and vendaItem.mat_001 = :idProduto')
    .SQL('and vendaItem.sit_001 = :situacao')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda)
    .ParamAsInteger('idProduto', ACodProduto)
    .ParamAsInteger('situacao', ASituacao.DBValue)
    .OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOVendaItem.ListarProdutosSomenteTaxaGarcom(AIdVenda: Integer):Currency;
var
  LDataSet : TDataSet;
begin
  Result:=0;
  LDataSet:=Query.SQL(' select coalesce(sum(ite_005),0) as ite_005	from vendaitem                                    ')
          .SQL(' join materiais on vendaitem.mat_001 = materiais.mat_001 and vendaitem.emp_001 = materiais.emp_001    ')
          .SQL(' where  not materiais.b_nao_taxa and vendaItem.ven_001 =:idVenda                                      ')
          .SQL(' and vendaitem.sit_001=4  and vendaitem.emp_001=:idEmpresa                                            ')
          .ParamAsInteger('idVenda',AIdVenda)
          .ParamAsInteger('idEmpresa',FIdEmpresa)
          .OpenDataSet;
    try
      Result:=LDataSet.FieldByName('ite_005').AsCurrency;
    finally
      FreeAndNil(LDataSet);
    end;
end;

procedure TAPIRPCheffDAOVendaItem.TotalizarItensVenda(AIdVenda: Integer; out ATotalItens,
  ADesconto: Currency);
var
  LDataSet: TDataSet;
begin
  ATotalItens := 0;
  ADesconto := 0;

  LDataSet := Query.SQL('select coalesce(sum(ite_005), 0) as total_itens,')
    .SQL('       coalesce(sum(desconto), 0) as desconto')
    .SQL('  from vendaitem')
    .SQL(' where emp_001 = :idEmpresa')
    .SQL('   and ven_001 = :idVenda')
    .SQL('   and sit_001 = 4')
    .ParamAsInteger('idVenda', AIdVenda)
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .OpenDataSet;
  try
    ATotalItens := LDataSet.FieldByName('total_itens').AsCurrency;
    ADesconto := LDataSet.FieldByName('desconto').AsCurrency;
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOVendaItem.Listar(AIdVenda: Integer): TObjectList<TAPIRPCheffEntityVendaItem>;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL('where vendaItem.emp_001 = :idEmpresa')
    .SQL('and vendaItem.ven_001 = :idVenda')
    .SQL('order by ite_001')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda)
    .OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOVendaItem.Listar(AIdVenda: Integer; ASituacao: TRPCheffSituacaoItem): TObjectList<TAPIRPCheffEntityVendaItem>;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL('where vendaItem.emp_001 = :idEmpresa')
    .SQL('and vendaItem.ven_001 = :idVenda')
    .SQL('and vendaItem.sit_001 = :situacao')
    .SQL('order by ite_001')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda)
    .ParamAsInteger('situacao', ASituacao.DBValue)
    .OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOVendaItem.ListarVendasAgrupadosProdutos(AidVenda: Integer): TObjectList<TAPIRPCheffEntityVendaItem>;
var
  LDataSet: TDataSet;
begin
  LDataSet := Query.SQL('SELECT vendaitem.emp_001, vendaitem.ven_001, MIN(vendaitem.ite_001) AS ite_001, vendaitem.mat_001,                  ')
    .SQL('  materiais.mat_003, materiais.mat_004, materiais.cat_001, materiais.mat_021, vendaitem.terminal_impressao,                        ')
    .SQL('  materiais.mat_022, materiais.utiliza_combo, materiais.id_setor,BOOL_OR(vendaitem.b_gratis) AS b_gratis,                          ')
    .SQL('  BOOL_OR(materiais.b_ficha_individual) AS b_ficha_individual,  materiais.tamanho_p, materiais.tamanho_m, materiais.tamanho_g,     ')
    .SQL('  materiais.tamanho_gg, materiais.tamanho_extra,MAX(vendaitem.data_hora_lancamento) AS data_hora_lancamento,                       ')
    .SQL('  MAX(vendaitem.mesa_vinc) AS mesa_vinc, (vendaitem.ite_006) AS ite_006,  (vendaitem.produtoimpresso) AS produtoimpresso,          ')
    .SQL('  (vendaitem.pendenteimpressao) AS pendenteimpressao, MAX(vendaitem.ite_013) AS ite_013,                                           ')
    .SQL('  MAX(vendaitem.ite_014) AS ite_014,MAX(vendaitem.gar_001) AS gar_001, MAX(vendaitem.sit_001) AS sit_001,                          ')
    .SQL('  MAX(vendaitem.id_usuario_cancelamento) AS id_usuario_cancelamento,MAX(vendaitem.data_cancelamento) AS data_cancelamento,         ')
    .SQL('  MAX(vendaitem.justificativa_cancelamento) AS justificativa_cancelamento, (vendaitem.tamanho) AS tamanho,                         ')
    .SQL('  BOOL_OR(vendaitem.b_venda_tamanho) AS b_venda_tamanho, MAX(vendaitem.item_fracionado) AS item_fracionado,                        ')
    .SQL('  BOOL_OR(vendaitem.b_entregue) AS b_entregue, COUNT(*) AS total_itens,                                                            ')
    .SQL('  SUM(CASE WHEN vendaitem.item_fracionado > 0 AND vendaitem.ite_002 = 0 AND vendaitem.ite_003 <> 0                                 ')
    .SQL('    THEN vendaitem.ite_005 / vendaitem.ite_003 ELSE vendaitem.ite_002 END) AS ite_002,                                             ')
    .SQL('  MIN(vendaitem.ite_003) AS ite_003, SUM(vendaitem.ite_005) AS ite_005, SUM(vendaitem.desconto) AS desconto,                       ')
    .SQL('  SUM(vendaitem.acrescimo) AS acrescimo, SUM(vendaitem.quantidade_impressao) AS quantidade_impressao,                              ')
    .SQL('  vendaitem.qtd_paga_antec, vendaitem.valor_pago_antec, vendaitem.rateiotaxagarcom,                                                ')
    .SQL('  MAX(usuarios.usu_002) as nomeGarcom                                                                                              ')
    .SQL('  FROM vendaItem                                                                                                                   ')
    .SQL('  JOIN materiais ON vendaitem.mat_001 = materiais.mat_001                                                                          ')
    .SQL('  AND vendaitem.emp_001 = materiais.emp_001                                                                                        ')
    .SQL('  LEFT JOIN usuarios ON usuarios.usu_001 = vendaitem.gar_001                                                                       ')
    .SQL('  WHERE vendaitem.emp_001 = :idEmpresa  and vendaitem.sit_001=4                                                                    ')
    .SQL('  AND vendaitem.ven_001 = :idVenda                                                                                                 ')
    .SQL('  GROUP BY vendaitem.emp_001, vendaitem.ven_001, vendaitem.mat_001,                                                                ')
    .SQL('  materiais.mat_003, materiais.mat_004, materiais.cat_001, vendaitem.terminal_impressao,                                           ')
    .SQL('  materiais.mat_021, materiais.mat_022, materiais.utiliza_combo,materiais.id_setor, materiais.tamanho_p,                           ')
    .SQL('  materiais.tamanho_m, materiais.tamanho_g,                                                                                        ')
    .SQL('  materiais.tamanho_gg, materiais.tamanho_extra, ite_006, produtoimpresso, pendenteimpressao, tamanho,                             ')
    .SQL('  vendaitem.qtd_paga_antec, vendaitem.valor_pago_antec,vendaitem.rateiotaxagarcom,                                                 ')
    .SQL('  CASE WHEN vendaitem.item_fracionado > 0 THEN vendaitem.item_fracionado ELSE 0 END,                                               ')
    .SQL('  CASE WHEN vendaitem.item_fracionado > 0 THEN vendaitem.ite_001 ELSE 0 END                                                        ')
    .SQL('  ORDER BY MIN(vendaitem.ite_001)                                                                                                  ')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idVenda', AidVenda)
    .OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

procedure TAPIRPCheffDAOVendaItem.Select;
begin
  Query.SQL('select vendaitem.emp_001, vendaitem.ven_001, vendaitem.ite_001, materiais.b_ficha_individual,        ')
    .SQL('  vendaitem.data_hora_lancamento, b_gratis, vendaitem.mesa_vinc,                                        ')
    .SQL('  vendaitem.ite_002, vendaitem.ite_003, vendaitem.ite_005, vendaitem.ite_006,                           ')
    .SQL('  vendaitem.produtoimpresso, vendaitem.pendenteimpressao, vendaitem.ite_013, vendaitem.ite_014,         ')
    .SQL('  vendaitem.gar_001, vendaitem.sit_001, vendaitem.desconto, vendaitem.acrescimo,                        ')
    .SQL('  vendaitem.id_usuario_cancelamento, vendaitem.data_cancelamento, vendaitem.justificativa_cancelamento, ')
    .SQL('  vendaitem.tamanho, vendaitem.b_venda_tamanho, vendaitem.item_fracionado,                              ')
    .SQL('  vendaitem.quantidade_impressao, vendaitem.b_entregue,                                                 ')
    .SQL('  vendaitem.mat_001, materiais.mat_003, materiais.mat_004, materiais.cat_001,                           ')
    .SQL('  materiais.mat_021, materiais.mat_022, materiais.utiliza_combo,                                        ')
    .SQL('  materiais.id_setor, materiais.tamanho_p, materiais.tamanho_m,                                         ')
    .SQL('  materiais.tamanho_g, materiais.tamanho_gg, materiais.tamanho_extra,vendaitem.terminal_impressao,      ')
    .SQL('  vendaitem.qtd_paga_antec, vendaitem.valor_pago_antec, vendaitem.rateiotaxagarcom,                     ')
    .SQL('  usuarios.usu_002 as nomeGarcom                                                                        ')
    .SQL('  from vendaItem                                                                                        ')
    .SQL('  join materiais on vendaitem.mat_001 = materiais.mat_001   and vendaitem.emp_001 = materiais.emp_001   ')
    .SQL('  left join usuarios on usuarios.usu_001 = vendaitem.gar_001                                            ');
end;

function TAPIRPCheffDAOVendaItem.UltimoItemFracionado(AIdVenda: Integer): Integer;
var
  LDataSet: TDataSet;
begin
  Query.SQL('select max(item_fracionado) as ultimo from vendaItem')
    .SQL('where emp_001 = :idEmpresa')
    .SQL('and ven_001 = :idVenda')
    .SQL('and item_fracionado > 0')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda);

  LDataSet := Query.OpenDataSet;
  try
    Result := LDataSet.FieldByName('ultimo').AsInteger;
  finally
    FreeAndNil(LDataSet);
  end;
end;

procedure TAPIRPCheffDAOVendaItem.AplicarDescontoProporcional(AidVenda:Integer;ADesconto:Currency);
begin
  StartTransaction;
  try
    Query.SQL('CALL aplicar_desconto_proporcional_vendaitem(:idVenda,:idEmpresa,:ADesconto)')
    .ParamAsInteger('idVenda', AIdVenda)
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsCurrency('ADesconto',ADesconto)
    .ExecSQL;
    Commit;
  except
   Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVendaItem.RatearTaxaGarcomPorItens(AidVenda:Integer);
begin
   StartTransaction;
  try
    Query.SQL('CALL RatearTaxaGarcomPorItens(:idVenda,:idEmpresa)')
    .ParamAsInteger('idVenda', AIdVenda)
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ExecSQL;
    Commit;
  except
   Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVendaItem.CalcularMargemLucro(AidVenda:Integer);
begin
   StartTransaction;
  try
    Query.SQL('CALL PROC_recalcular_margem_lucro(:idVenda,:idEmpresa)')
    .ParamAsInteger('idVenda', AIdVenda)
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ExecSQL;
    Commit;
  except
   Rollback;
    raise;
  end;
end;

function TAPIRPCheffDAOVendaItem.UltimoNumeroItemLancado(AIdVenda: Integer): Integer;
var
  LDataSet: TDataSet;
begin
  Query.SQL('select max(ite_001) as ultimo from vendaItem')
    .SQL('where emp_001 = :idEmpresa')
    .SQL('and ven_001 = :idVenda')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda);

  LDataSet := Query.OpenDataSet;
  try
    Result := LDataSet.FieldByName('ultimo').AsInteger;
  finally
    FreeAndNil(LDataSet);
  end;
end;

initialization
  GSchemaLock := TObject.Create;

finalization
  FreeAndNil(GSchemaLock);

end.

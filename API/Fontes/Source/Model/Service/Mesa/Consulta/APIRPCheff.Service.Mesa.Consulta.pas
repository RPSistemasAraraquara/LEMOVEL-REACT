unit APIRPCheff.Service.Mesa.Consulta;

interface

uses
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  APIRPCheff.Service.Venda.Consulta,
  System.DateUtils,
  System.SysUtils,
  System.Generics.Collections,
  System.Classes;

type
  TAPIRPCheffServiceMesaConsulta = class
  private
    FDAO                  : TAPIRPCheffDAOFactory;
    FServiceVendaConsulta : TAPIRPCheffServiceVendaConsulta;

    procedure CarregarVenda(AMesa: TAPIRPCheffEntityMesa);
    procedure CarregarVendasEmLote(AMesas: TObjectList<TAPIRPCheffEntityMesa>);
  public
    destructor Destroy; override;

    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceMesaConsulta;
    function Listar: TObjectList<TAPIRPCheffEntityMesa>;
    function ListarPorSituacao(ASituacao: TRPCheffSituacaoVenda): TObjectList<TAPIRPCheffEntityMesa>;
    function Consultar(AIdMesa: Integer): TAPIRPCheffEntityMesa;
  end;

implementation

{ TAPIRPCheffServiceMesaConsulta }


procedure TAPIRPCheffServiceMesaConsulta.CarregarVenda(AMesa: TAPIRPCheffEntityMesa);
begin
  if AMesa.idVenda > 0 then
  begin
    if not Assigned(FServiceVendaConsulta) then
    begin
      FreeAndNil(FServiceVendaConsulta);
      FServiceVendaConsulta := TAPIRPCheffServiceVendaConsulta.Create;
      FServiceVendaConsulta.DAO(FDAO);
    end;
    AMesa.venda := FServiceVendaConsulta.Buscar(AMesa.idVenda, False);
  end;
  if (AMesa.situacao = smReservada) and Assigned(AMesa.venda) then
    AMesa.venda.situacao := svReservada;
end;

// Performance: carrega as vendas de TODAS as mesas em 2 queries (antes eram
// 2 por mesa aberta - N+1 no GET /mesa). Mesmas entidades, mesmos valores:
// BuscarLote usa o mesmo Select do Buscar e SomarTaxaGarcomLote a mesma
// query da taxa agrupada; venda duplicada (juncao de mesas) ou ausente cai
// no CarregarVenda original.
procedure TAPIRPCheffServiceMesaConsulta.CarregarVendasEmLote(AMesas: TObjectList<TAPIRPCheffEntityMesa>);
var
  LIds: TArray<Integer>;
  LCount: Integer;
  LMesa: TAPIRPCheffEntityMesa;
  LVendas: TObjectList<TAPIRPCheffEntityVenda>;
  LVendaPorId: TDictionary<Integer, TAPIRPCheffEntityVenda>;
  LTaxas: TDictionary<Integer, Currency>;
  LVenda: TAPIRPCheffEntityVenda;
  LTaxa: Currency;
begin
  SetLength(LIds, AMesas.Count);
  LCount := 0;
  for LMesa in AMesas do
    if LMesa.idVenda > 0 then
    begin
      LIds[LCount] := LMesa.idVenda;
      Inc(LCount);
    end;
  SetLength(LIds, LCount);
  if LCount = 0 then
    Exit;

  if not Assigned(FServiceVendaConsulta) then
  begin
    FServiceVendaConsulta := TAPIRPCheffServiceVendaConsulta.Create;
    FServiceVendaConsulta.DAO(FDAO);
  end;

  LVendas := nil;
  LTaxas := nil;
  LVendaPorId := TDictionary<Integer, TAPIRPCheffEntityVenda>.Create;
  try
    LVendas := FDAO.VendaDAO.BuscarLote(LIds);
    // dicionario populado ANTES da query de taxa: se ela falhar, o finally
    // libera as entidades ja carregadas (a lista LVendas nao e dona delas)
    for LVenda in LVendas do
      LVendaPorId.AddOrSetValue(LVenda.idVenda, LVenda);

    LTaxas := FDAO.VendaItemDAO.SomarTaxaGarcomLote(LIds);

    for LMesa in AMesas do
    begin
      if LMesa.idVenda <= 0 then
      begin
        // paridade com o caminho antigo: mesa sem venda aberta ainda passa
        // pelo CarregarVenda (sem query) para propagar smReservada ->
        // svReservada na venda placeholder do constructor da mesa
        CarregarVenda(LMesa);
        Continue;
      end;

      if LVendaPorId.TryGetValue(LMesa.idVenda, LVenda) and Assigned(LVenda) then
      begin
        // posse transferida ANTES do calculo da taxa: se ele falhar, a mesa
        // (dona da venda) e liberada pelo except do chamador - sem leak
        LVendaPorId[LMesa.idVenda] := nil;
        LMesa.venda := LVenda;
        if not LTaxas.TryGetValue(LMesa.idVenda, LTaxa) then
          LTaxa := 0;
        FServiceVendaConsulta.AplicarValoresDeTaxasComValor(LMesa.venda, LTaxa);
        if (LMesa.situacao = smReservada) and Assigned(LMesa.venda) then
          LMesa.venda.situacao := svReservada;
      end
      else
        // venda nao veio no lote ou ja foi transferida p/ outra mesa (juncao):
        // caminho unitario original preserva o comportamento
        CarregarVenda(LMesa);
    end;
  finally
    for LVenda in LVendaPorId.Values do
      LVenda.Free;
    FreeAndNil(LVendaPorId);
    FreeAndNil(LTaxas);
    FreeAndNil(LVendas);
  end;
end;

function TAPIRPCheffServiceMesaConsulta.Consultar(AIdMesa: Integer): TAPIRPCheffEntityMesa;
begin
  Result := FDAO.MesaDAO.Busca(AIdMesa);
  try
    CarregarVenda(Result);
  except
    Result.Free;
    raise;
  end;
end;

function TAPIRPCheffServiceMesaConsulta.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceMesaConsulta;
begin
  Result := Self;
  FDAO := AValue;
end;

destructor TAPIRPCheffServiceMesaConsulta.Destroy;
begin
  FreeAndNil(FServiceVendaConsulta);
  inherited;
end;

//function TAPIRPCheffServiceMesaConsulta.Listar: TObjectList<TAPIRPCheffEntityMesa>;
//var
//  LMesa: TAPIRPCheffEntityMesa;
//begin
//  Result := FDAO.MesaDAO.List;
//  try
//    for LMesa in Result do
//      CarregarVenda(LMesa);
//  except
//    for LMesa in Result do
//      LMesa.Free;
//    FreeAndNil(Result);
//    raise;
//  end;
//end;

function TAPIRPCheffServiceMesaConsulta.Listar: TObjectList<TAPIRPCheffEntityMesa>;
begin
  Result := FDAO.MesaDAO.List;
  try
    CarregarVendasEmLote(Result);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TAPIRPCheffServiceMesaConsulta.ListarPorSituacao(ASituacao: TRPCheffSituacaoVenda): TObjectList<TAPIRPCheffEntityMesa>;
begin
  Result := FDAO.MesaDAO.ListarPorSituacaoVenda(ASituacao);
  try
    CarregarVendasEmLote(Result);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

end.

unit APIRPCheff.Controller.Venda;

interface

uses
  APIRPCheff.Controller.Base,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  Horse.GBSwagger.Registry,
  GBSwagger.Path.Attributes,
  System.JSON,
  GBSwagger.Validator.Interfaces,
  System.Generics.Collections,
  System.SysUtils;

type
  [SwagPath('empresa/{idEmpresa}/venda', 'Venda')]
  [SwagParamPath('idEmpresa', 'Id da empresa')]
  TAPIRPCheffControllerVenda = class(TAPIRPCheffControllerBase)
  private
    procedure ConsultarJSON;
    procedure ConsultarTextPlain;
    function TipoMaquinaPagamentoRequest: TRPTipoMaquinaPagamento;
    function UsaImpressaoDaMaquininha(AValue: TRPTipoMaquinaPagamento): Boolean;
    function BloquearImpressoraWindows(ATipoMaquina: TRPTipoMaquinaPagamento): Boolean;
    procedure ValidarCouvertNaoReduzido(ACouvert: TAPIRPCheffEntityVendaPatchCouvert);
  public
    [SwagGET('{idVenda}', 'Carregar Venda')]
    [SwagParamPath('idVenda', 'Id da Venda')]
    [SwagParamHeader('listarItens', 'Indica se busca tamb'#233'm os itens da venda')]
    [SwagParamHeader('impressaoInterna', 'Indica se deve imprimir localmente', 'false,true', False)]
    [SwagParamHeader('imprimirFichaIndividualProdutos', 'Indica se deve imprimir ficha individual dos produtos', 'false,true', False)]
    [SwagProduces('application/json')]
    [SwagProduces('text/plain')]
    [SwagResponse(200, TAPIRPCheffEntityVenda)]
    [SwagResponse(404)]
    procedure Consultar;

    [SwagPATCH('{idVenda}/couvert', 'Atualizar Couvert')]
    [SwagParamPath('idVenda', 'Id da Venda')]
    [SwagParamBody('couvert', TAPIRPCheffEntityVendaPatchCouvert)]
    [SwagResponse(202)]
    procedure AtualizarCouvert;

    [SwagPATCH('{idVenda}/preFechamento', 'PreFechamento da venda')]
    [SwagParamPath('idVenda', 'Id da Venda')]
    [SwagParamBody('preFechamento', TAPIRPCheffEntityVendaPatchPreFechamento)]
    [SwagProduces('text/plain')]
    [SwagResponse(202)]
    procedure ExecutarPreFechamento;

    [SwagPOST('{idVenda}/fechamento', 'Fechamento da venda')]
    [SwagParamPath('idVenda', 'Id da Venda')]
    [SwagParamBody('fechamento', TAPIRPCheffEntityVendaPostFechamento)]
    [SwagProduces('text/plain')]
    [SwagResponse(202)]
    procedure FecharVenda;

    [SwagPATCH('{idVenda}/nome', 'Atualizar Nome Mesa/Comanda')]
    [SwagParamPath('idVenda', 'Id da Venda')]
    [SwagParamBody('nomeMesaComanda', TAPIRPCheffEntityVendaPatchNomeMesaComanda)]
    [SwagResponse(202)]
    procedure AlterarNomeMesaComanda;

    [SwagGET('{idVenda}/pagamentoAntecipado', 'Listar pagamentos antecipados da venda')]
    [SwagParamPath('idVenda', 'Id da Venda')]
    [SwagResponse(200, TAPIRPCheffEntityVendaPagamentoAntecipado, True)]
    [SwagResponse(400)]
    procedure ListarPagamentosAntecipados;

    [SwagPOST('{idVenda}/pagamento', 'Registrar um pagamento parcial')]
    [SwagParamPath('idVenda', 'Id da Venda')]
    [SwagParamBody('pagamento', TAPIRPCheffEntityVendaPagamentoAntecipado)]
    [SwagResponse(202)]
    procedure RegistrarPagamentoParcial;

    [SwagPATCH('{idVenda}/reabertura', 'Reabrir mesa/comanda (voltar de pr'#233'-fechamento para pendente)')]
    [SwagParamPath('idVenda', 'Id da Venda')]
    [SwagResponse(202)]
    [SwagResponse(400)]
    procedure ReabrirMesaComanda;

    [SwagPOST('{idVenda}/juncao', 'Juntar mesas/comandas na venda destino')]
    [SwagParamPath('idVenda', 'Id da Venda destino')]
    [SwagResponse(204)]
    [SwagResponse(400)]
    procedure JuntarMesa;

  end;

implementation

uses
  System.Classes;

{ TAPIRPCheffControllerVenda }

procedure TAPIRPCheffControllerVenda.AlterarNomeMesaComanda;
var
  LPatch: TAPIRPCheffEntityVendaPatchNomeMesaComanda;
begin
  LPatch := Self.FromJSONObject<TAPIRPCheffEntityVendaPatchNomeMesaComanda>;
  try
    LPatch.idVenda := FRequest.Params.Field('idVenda').AsInteger;
    Controller.DAO.VendaDAO.AtualizarNomeMesaComanda(LPatch.idVenda, LPatch.nome);
    FResponse.Status(202);
  finally
    FreeAndNil(LPatch);
  end;
end;

procedure TAPIRPCheffControllerVenda.AtualizarCouvert;
var
  LCouvert: TAPIRPCheffEntityVendaPatchCouvert;
begin
  LCouvert := Self.FromJSONObject<TAPIRPCheffEntityVendaPatchCouvert>;
  try
    LCouvert.idEmpresa := FRequest.Params.Field('idEmpresa').AsInteger;
    LCouvert.idVenda := FRequest.Params.Field('idVenda').AsInteger;
    if (LCouvert.numeroPessoas < LCouvert.NumeroCouvert) then
      LCouvert.numeroPessoas := LCouvert.NumeroCouvert;

    ValidarCouvertNaoReduzido(LCouvert);
    Controller.DAO.VendaDAO.AtualizarCouvert(LCouvert);
    FResponse.Status(202);
  finally
    FreeAndNil(LCouvert);
  end;
end;

procedure TAPIRPCheffControllerVenda.ValidarCouvertNaoReduzido(
  ACouvert: TAPIRPCheffEntityVendaPatchCouvert);
var
  LVenda: TAPIRPCheffEntityVenda;
begin
  LVenda := Controller.DAO.VendaDAO.Buscar(ACouvert.idVenda);
  try
    if not Assigned(LVenda) then
    begin
      FResponse.Status(404);
      raise Exception.CreateFmt('Venda %d nao encontrada.', [ACouvert.idVenda]);
    end;

    if ACouvert.numeroCouvertMasculino < LVenda.numeroCouvertMasculino then
    begin
      FResponse.Status(409);
      raise Exception.CreateFmt(
        'Nao e permitido diminuir couvert masculino ja lancado. Quantidade atual: %d.',
        [LVenda.numeroCouvertMasculino]
      );
    end;

    if ACouvert.numeroCouvertFeminino < LVenda.numeroCouvertFeminino then
    begin
      FResponse.Status(409);
      raise Exception.CreateFmt(
        'Nao e permitido diminuir couvert feminino ja lancado. Quantidade atual: %d.',
        [LVenda.numeroCouvertFeminino]
      );
    end;
  finally
    FreeAndNil(LVenda);
  end;
end;

procedure TAPIRPCheffControllerVenda.Consultar;
var
  LAccept: string;
begin
  LAccept := FRequest.RawWebRequest.Accept.ToLower;
  if Pos('text/plain', LAccept) > 0 then
    ConsultarTextPlain
  else
    ConsultarJSON;
end;

procedure TAPIRPCheffControllerVenda.ConsultarJSON;
var
  LIdVenda: Integer;
  LIdEmpresa: Integer;
  LBuscarItens: Boolean;
  LVenda: TAPIRPCheffEntityVenda;
begin
  LBuscarItens  := FRequest.Headers.Field('listarItens').AsBoolean;
  LIdVenda      := FRequest.Params.Field('idVenda').AsInteger;
  LIdEmpresa    := FRequest.Params.Field('idEmpresa').AsInteger;
  LVenda        := Controller.IdEmpresa(LIdEmpresa).Service.VendaConsultaService.Buscar(LIdVenda, LBuscarItens);
  try
    Self.Response(LVenda);
  finally
    FreeAndNil(LVenda);
  end;
end;

procedure TAPIRPCheffControllerVenda.ConsultarTextPlain;
var
  LIdVenda: Integer;
  LIdEmpresa: Integer;
  LNumeroColunas: Integer;
  LImpressao: string;
  LTipoMaquina: TRPTipoMaquinaPagamento;
  LImprimir: Boolean;
  LImprimirFichaIndividualProdutos: Boolean;
  LStream: TStream;
begin
  if not FRequest.Params.ContainsKey('idVenda') then
    Exit;

  LIdVenda        := FRequest.Params.Field('idVenda').AsInteger;
  LIdEmpresa      := FRequest.Params.Field('idEmpresa').AsInteger;
  LNumeroColunas  := FRequest.Headers.Field('numeroColunas').AsInteger;
  LImprimir       := FRequest.Headers.Field('impressaoInterna').AsBoolean;
  LImprimirFichaIndividualProdutos := True;
  if FRequest.Headers.ContainsKey('imprimirFichaIndividualProdutos') then
    LImprimirFichaIndividualProdutos := FRequest.Headers.Field('imprimirFichaIndividualProdutos').AsBoolean;
  LTipoMaquina := TipoMaquinaPagamentoRequest;
  if BloquearImpressoraWindows(LTipoMaquina) then
    LImprimir := False;
  if LNumeroColunas <= 0 then
    LNumeroColunas := 48;
  LStream := Controller.IdEmpresa(LIdEmpresa).Service.VendaImpressaoService
    .IdEmpresa(LIdEmpresa)
    .IdVenda(LIdVenda)
    .NumeroColunas(LNumeroColunas)
    .Imprimir(LImprimir)
    .ImprimirFichaIndividualProdutos(LImprimirFichaIndividualProdutos)
    .TipoMaquina(LTipoMaquina)
    .Execute;
  try
    LImpressao := TStringStream(LStream).DataString;
    Self.FResponse.Send(LImpressao)
      .ContentType('text/plain; charset="UTF-8"');
  finally
    LStream.Free;
  end;
end;

procedure TAPIRPCheffControllerVenda.ExecutarPreFechamento;
var
  LPreFechamento: TAPIRPCheffEntityVendaPatchPreFechamento;
  LAccept: string;
  LTipoMaquina: TRPTipoMaquinaPagamento;
begin
  LAccept := FRequest.RawWebRequest.Accept.ToLower;
  LTipoMaquina := TipoMaquinaPagamentoRequest;
  LPreFechamento := Controller.Components.JSON
    .FromJSONObject<TAPIRPCheffEntityVendaPatchPreFechamento>(FRequest.Body);
  try
    LPreFechamento.idEmpresa := FRequest.Params.Field('idEmpresa').AsInteger;
    LPreFechamento.idVenda := FRequest.Params.Field('idVenda').AsInteger;
    if BloquearImpressoraWindows(LTipoMaquina) then
      LPreFechamento.preFechamentoMobileImpressaoInterna := False;
    if (LPreFechamento.numeroPessoas < LPreFechamento.NumeroCouvert) then
      LPreFechamento.numeroPessoas := LPreFechamento.NumeroCouvert;

    Controller.Service.VendaPreFechamentoService
      .Patch(LPreFechamento)
      .Execute;
    if Pos('text/plain', LAccept) > 0 then
      ConsultarTextPlain;
    FResponse.Status(202);
  finally
    try
      FreeAndNil(LPreFechamento);
    except
      on E: Exception do
      begin
      end;
    end;
  end;
end;

procedure TAPIRPCheffControllerVenda.FecharVenda;
var
  LIdVenda    : Integer;
  LIdUsuarioHeader: Integer;
  LFechamento : TAPIRPCheffEntityVendaPostFechamento;
  LAccept    : string;
  LTipoMaquina: TRPTipoMaquinaPagamento;
begin
  LAccept     := FRequest.RawWebRequest.Accept.ToLower;
  LTipoMaquina := TipoMaquinaPagamentoRequest;
  LIdVenda    := FRequest.Params.Field('idVenda').AsInteger;
  LFechamento := Controller.Components.JSON
    .FromJSONObject<TAPIRPCheffEntityVendaPostFechamento>(FRequest.Body);
  try
    LFechamento.idEmpresa := FRequest.Params.Field('idEmpresa').AsInteger;
    LFechamento.idVenda := LIdVenda;
    if BloquearImpressoraWindows(LTipoMaquina) then
      LFechamento.impressoraInterna := False;
    LIdUsuarioHeader := Self.IdUsuario;
    if LIdUsuarioHeader > 0 then
      LFechamento.idUsuario := LIdUsuarioHeader;

    Controller.Service.VendaFechamentoService
      .Fechamento(LFechamento)
      .Execute;

    if Pos('text/plain', LAccept) > 0 then
      ConsultarTextPlain;
    FResponse.Status(202);
  finally
    try
      FreeAndNil(LFechamento);
    except
      on E: Exception do
      begin
      end;
    end;
  end;
end;

procedure TAPIRPCheffControllerVenda.ListarPagamentosAntecipados;
var
  LIdEmpresa, LIdVenda: Integer;
  LPagamentos: TObjectList<TAPIRPCheffEntityVendaPagamentoAntecipado>;
begin
  LIdEmpresa := FRequest.Params.Field('idEmpresa').AsInteger;
  LIdVenda   := FRequest.Params.Field('idVenda').AsInteger;

  LPagamentos := Controller.DAO.IdEmpresa(LIdEmpresa).VendaPagamentoAntecipadoDAO.Listar(LIdVenda);

  try
    Self.Response<TAPIRPCheffEntityVendaPagamentoAntecipado>(LPagamentos);
  finally
    FreeAndNil(LPagamentos);
  end;
end;


procedure TAPIRPCheffControllerVenda.RegistrarPagamentoParcial;
var
  LPagamento: TAPIRPCheffEntityVendaPagamentoAntecipado;
  LBody: TJSONObject;
  LValue: TJSONValue;
begin
  LPagamento := Self.FromJSONObject<TAPIRPCheffEntityVendaPagamentoAntecipado>;
  try
    LBody := TJSONObject.ParseJSONValue(FRequest.Body) as TJSONObject;
    try
      if Assigned(LBody) then
      begin
        LValue := LBody.Values['idUsuarioLancamento'];
        if Assigned(LValue) then
          LPagamento.IdUsuarioLancamento := StrToIntDef(LValue.Value, LPagamento.IdUsuarioLancamento);

        if (LPagamento.IdUsuarioLancamento <= 0) then
        begin
          LValue := LBody.Values['idUsuario'];
          if Assigned(LValue) then
            LPagamento.IdUsuarioLancamento := StrToIntDef(LValue.Value, LPagamento.IdUsuarioLancamento);
        end;
      end;
    finally
      LBody.Free;
    end;

    LPagamento.idEmpresa := FRequest.Params.Field('idEmpresa').AsInteger;
    LPagamento.idVenda   := FRequest.Params.Field('idVenda').AsInteger;

    if (LPagamento.idEmpresa <= 0) then
      raise Exception.Create('Empresa inv'#225'lida.');
    if (LPagamento.idVenda <= 0) then
      raise Exception.Create('Venda inv'#225'lida.');
    if (LPagamento.idFormaPagamento <= 0) then
      raise Exception.Create('Forma de pagamento inv'#225'lida.');
    if (LPagamento.valor <= 0) then
      raise Exception.Create('Valor pago inv'#225'lido.');
    if (LPagamento.IdUsuarioLancamento <= 0) then
      raise Exception.Create('Usu'#225'rio inv'#225'lido para pagamento parcial.');

    Controller.Service.VendaPagamentoParcialService.PagamentoAntecipado(LPagamento).Execute;

    FResponse.Status(202);
  finally
    FreeAndNil(LPagamento);
  end;
end;

function TAPIRPCheffControllerVenda.TipoMaquinaPagamentoRequest: TRPTipoMaquinaPagamento;
begin
  Result := tmpNenhum;
  Result.FromString(FRequest.Headers.Field('tipoMaquina').AsString);
  if Result = tmpNenhum then
    Result.FromString(FRequest.Query.Field('tipoMaquina').AsString);
end;

function TAPIRPCheffControllerVenda.BloquearImpressoraWindows(
  ATipoMaquina: TRPTipoMaquinaPagamento): Boolean;
begin
  Result := UsaImpressaoDaMaquininha(ATipoMaquina);
end;

function TAPIRPCheffControllerVenda.UsaImpressaoDaMaquininha(
  AValue: TRPTipoMaquinaPagamento): Boolean;
begin
  Result := AValue in [tmpStone, tmpPlugPag, tmpCielo];
end;

procedure TAPIRPCheffControllerVenda.ReabrirMesaComanda;
var
  LIdVenda: Integer;
  LIdEmpresa: Integer;
begin
  LIdEmpresa := FRequest.Params.Field('idEmpresa').AsInteger;
  LIdVenda   := FRequest.Params.Field('idVenda').AsInteger;

  if (LIdVenda <= 0) then
    raise Exception.Create('Venda inv'#225'lida.');

  Controller.DAO.IdEmpresa(LIdEmpresa).VendaDAO.ReabrirMesaComanda(LIdVenda, LIdEmpresa);
  FResponse.Status(202).Send('{"message":"Mesa/comanda reaberta com sucesso"}');
end;

procedure TAPIRPCheffControllerVenda.JuntarMesa;
var
  LIdVendaDestino: Integer;
  LIdEmpresa: Integer;
  LBody: TJSONObject;
  LVendasOrigem: TJSONArray;
  I: Integer;
begin
  LIdEmpresa      := FRequest.Params.Field('idEmpresa').AsInteger;
  LIdVendaDestino := FRequest.Params.Field('idVenda').AsInteger;

  LBody := FRequest.Body<TJSONObject>;
  LVendasOrigem := LBody.GetValue<TJSONArray>('vendasOrigem');

  if (LVendasOrigem = nil) or (LVendasOrigem.Count = 0) then
    raise Exception.Create('Nenhuma venda de origem informada.');

  Controller.DAO.IdEmpresa(LIdEmpresa);

  Controller.Service.MesaJuncaoService
    .IdVendaDestino(LIdVendaDestino);

  for I := 0 to Pred(LVendasOrigem.Count) do
    Controller.Service.MesaJuncaoService
      .AddVendaOrigem(LVendasOrigem.Items[I].AsType<Integer>);

  Controller.Service.MesaJuncaoService.Execute;
  FResponse.Status(200).Send('{"message":"Mesas/comandas unidas com sucesso"}');
end;

initialization
  THorseGBSwaggerRegistry.RegisterPath(TAPIRPCheffControllerVenda);

end.

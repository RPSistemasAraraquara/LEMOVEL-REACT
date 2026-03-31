unit APIRPCheff.Entity.Types;

interface

uses
  System.Classes,
  System.SysUtils,
  System.TypInfo;

const
  SituacaoVendaNames = 'svNull,svDigitacao,svFinalizada,svCancelada,' +
    'svPendente,svAguardandoLiberacao,svReservada,svPreFechamento';

type
  EImpressaoException = class(Exception);

  TRPCheffSituacao = (sCancelado, sAtivo);

  TRPCheffSituacaoItem = (siOK, siCancelado);

  TRPCheffSituacaoMesa = (smDisponivel, smReservada);

  TRPCheffSituacaoVenda = (svNull, svDigitacao, svFinalizada, svCancelada,
    svPendente, svAguardandoLiberacao, svReservada, svPreFechamento);

  TRPCheffTipoCasaControle = (tccPosPago, tccPrePago);

  TRPCheffTipoDesconto = (tdValor, tdPercentual);

  TRPTipoMaquinaPagamento = (tmpNenhum, tmpVero, tmpStone, tmpPlugPag, tmpCielo);

  TRPCheffTipoOpcional = (toOpcional, toBorda);

  TRPCheffTipoVenda = (tvBalcao, tvComanda, tvMesa, tvDelivery, tvPdv);

  TEnumUtils<T> = class
  public
    class function EnumValue(AValue: string): Integer;
  end;

  TRPCheffSituacaoHelper = record helper for TRPCheffSituacao
  public
    function DBValue: Integer;
    procedure FromDBValue(AValue: Integer);
  end;

  TRPCheffSituacaoItemHelper = record helper for TRPCheffSituacaoItem
  public
    function DBValue: Integer;
    procedure FromDBValue(AValue: Integer);
  end;

  TRPCheffSituacaoMesaHelper = record helper for TRPCheffSituacaoMesa
  public
    function Description: string;
    procedure FromDBValue(AValue: Integer);
  end;

  TRPCheffSituacaoVendaHelper = record helper for TRPCheffSituacaoVenda
  public
    function Description: string;
    function DBValue: Integer;
    procedure FromDBValue(AValue: Integer);
  end;

  TRPCheffTipoDescontoHelper = record helper for TRPCheffTipoDesconto
  public
    procedure FromDBValue(AValue: Integer);
  end;

  TRPTipoMaquinaPagamentoHelper = record helper for TRPTipoMaquinaPagamento
  public
    procedure FromString(AValue: string);
  end;

  TRPCheffTipoOpcionalHelper = record helper for TRPCheffTipoOpcional
  public
    function DBValue: Integer;
    procedure FromDBValue(AValue: Integer);
  end;

  TRPCheffTipoVendaHelper = record helper for TRPCheffTipoVenda
  public
    function DBValue: string;
    procedure FromDBValue(AValue: string);
  end;

function BooleanToString(AValue: Boolean): string;
function StringToBoolean(AValue: string): Boolean;

implementation

function BooleanToString(AValue: Boolean): string;
begin
  Result := 'N';
  if AValue then
    Result := 'S';
end;

function StringToBoolean(AValue: string): Boolean;
begin
  Result := AValue.ToUpper = 'S';
end;

{ TRPCheffSituacaoMesaHelper }

function TRPCheffSituacaoMesaHelper.Description: string;
begin
  case Self of
    smDisponivel: Result := 'Dispon'#237'vel';
    smReservada: Result := 'Reservada';
  end;
end;

procedure TRPCheffSituacaoMesaHelper.FromDBValue(AValue: Integer);
begin
  if AValue = 4 then
    Self := smDisponivel
  else
  if AValue = 19 then
    Self := smReservada;
end;

{ TRPCheffSituacaoVendaHelper }

function TRPCheffSituacaoVendaHelper.DBValue: Integer;
begin
  Result := -1;
  case Self of
    svDigitacao: Result := 0;
    svFinalizada: Result := 1;
    svCancelada: Result := 2;
    svPendente: Result := 8;
    svAguardandoLiberacao: Result := 15;
    svReservada: Result := 19;
    svPreFechamento: Result := 21;
  end;
end;

function TRPCheffSituacaoVendaHelper.Description: string;
begin
  Result := EmptyStr;
  case Self of
    svDigitacao: Result := 'Digita'#231#227'o';
    svFinalizada: Result := 'Finalizada';
    svCancelada: Result := 'Cancelada';
    svPendente: Result := 'Pendente';
    svAguardandoLiberacao: Result := 'Aguardando Libera'#231#227'o';
    svReservada: Result := 'Reservada';
    svPreFechamento: Result := 'Pr'#233'-Fechamento';
  end;
end;

procedure TRPCheffSituacaoVendaHelper.FromDBValue(AValue: Integer);
begin
  if AValue = 0 then
    Self := svDigitacao
  else
  if AValue = 1 then
    Self := svFinalizada
  else
  if AValue = 2 then
    Self := svCancelada
  else
  if AValue = 8 then
    Self := svPendente
  else
  if AValue = 15 then
    Self := svAguardandoLiberacao
  else
  if AValue = 19 then
    Self := svReservada
  else
  if AValue = 21 then
    Self := svPreFechamento;
end;

{ TRPCheffTipoVendaHelper }

function TRPCheffTipoVendaHelper.DBValue: string;
begin
  case Self of
    tvBalcao: Result := 'B';
    tvComanda: Result := 'C';
    tvMesa: Result := 'M';
    tvDelivery: Result := 'D';
    tvPdv: Result := 'P';
  end;
end;

procedure TRPCheffTipoVendaHelper.FromDBValue(AValue: string);
begin
  if AValue = 'B' then
    Self := tvBalcao
  else
  if AValue = 'C' then
    Self := tvComanda
  else
  if AValue = 'D' then
    Self := tvDelivery
  else
  if AValue = 'M' then
    Self := tvMesa
  else
  if AValue = 'P' then
    Self := tvPdv;
end;

{ TRPCheffSituacaoHelper }

function TRPCheffSituacaoHelper.DBValue: Integer;
begin
  Result := 0;
  case Self of
    sCancelado: Result := 3;
    sAtivo: Result := 4;
  end;
end;

procedure TRPCheffSituacaoHelper.FromDBValue(AValue: Integer);
begin
  if AValue = 3 then
    Self := sCancelado
  else
  if AValue = 4 then
    Self := sAtivo;
end;

{ TRPCheffTipoOpcionalHelper }

function TRPCheffTipoOpcionalHelper.DBValue: Integer;
begin
  Result := 0;
  case Self of
    toOpcional: Result := 0;
    toBorda: Result := 1;
  end;
end;

procedure TRPCheffTipoOpcionalHelper.FromDBValue(AValue: Integer);
begin
  Self := toOpcional;
  if AValue = 1 then
    Self := toBorda;
end;

{ TRPCheffTipoDescontoHelper }

procedure TRPCheffTipoDescontoHelper.FromDBValue(AValue: Integer);
begin
  if AValue = 0 then
    Self := tdPercentual
  else
  if AValue = 1 then
    Self := tdValor;
end;

{ TRPCheffSituacaoItemHelper }

function TRPCheffSituacaoItemHelper.DBValue: Integer;
begin
  Result := 4;
  case Self of
    siOK: Result := 4;
    siCancelado: Result := 2;
  end;
end;

procedure TRPCheffSituacaoItemHelper.FromDBValue(AValue: Integer);
begin
  Self := siOK;
  if AValue = 2 then
    Self := siCancelado;
end;

{ TEnumUtils<T> }

class function TEnumUtils<T>.EnumValue(AValue: string): Integer;
begin
  Result := GetEnumValue(TypeInfo(T), AValue);
end;

{ TRPTipoMaquinaPagamentoHelper }

procedure TRPTipoMaquinaPagamentoHelper.FromString(AValue: string);
begin
  Self := tmpNenhum;
  if AValue = 'tmpVero' then
    Self := tmpVero
  else
  if AValue = 'tmpStone' then
    Self := tmpStone
  else
  if AValue = 'tmpPlugPag' then
    Self := tmpPlugPag
  else
  if AValue = 'tmpCielo' then
    Self := tmpCielo;
end;

end.

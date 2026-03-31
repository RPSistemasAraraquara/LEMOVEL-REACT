unit APIRPCheff.Entity.Promocao;

interface

uses
  APIRPCheff.Entity.Types,
  GBSwagger.Model.Attributes,
  System.SysUtils,
  System.DateUtils;

type
  TAPIRPCheffEntityPromocao = class
  private
    FidPromocao                  : Integer;
    FidEmpresa                   : Integer;
    FidProduto                   : Integer;
    FtipoDesconto                : TRPCheffTipoDesconto;
    FquintaFeira                 : Boolean;
    Fsabado                      : Boolean;
    FsegundaFeira                : Boolean;
    Fdomingo                     : Boolean;
    FtercaFeira                  : Boolean;
    FsextaFeira                  : Boolean;
    FquartaFeira                 : Boolean;
    FtipoMesa                    : Boolean;
    FtipoComanda                 : Boolean;
    FdescontoSegundaPadrao       : Currency;
    FdescontoSegundaTamanhoP     : Currency;
    FdescontoSegundaTamanhoM     : Currency;
    FdescontoSegundaTamanhoG     : Currency;
    FdescontoSegundaTamanhoGG    : Currency;
    FdescontoSegundaTamanhoExtra : Currency;
    FdescontoTercaTamanhoG       : Currency;
    FdescontoTercaPadrao         : Currency;
    FdescontoTercaTamanhoGG      : Currency;
    FdescontoTercaTamanhoP       : Currency;
    FdescontoTercaTamanhoExtra   : Currency;
    FdescontoTercaTamanhoM       : Currency;
    FdescontoQuartaTamanhoM      : Currency;
    FdescontoQuartaTamanhoG      : Currency;
    FdescontoQuartaPadrao        : Currency;
    FdescontoQuartaTamanhoGG     : Currency;
    FdescontoQuartaTamanhoP      : Currency;
    FdescontoQuartaTamanhoExtra  : Currency;
    FdescontoQuintaTamanhoExtra  : Currency;
    FdescontoQuintaTamanhoM      : Currency;
    FdescontoQuintaTamanhoG      : Currency;
    FdescontoQuintaPadrao        : Currency;
    FdescontoQuintaTamanhoGG     : Currency;
    FdescontoQuintaTamanhoP      : Currency;
    FdescontoSextaTamanhoM       : Currency;
    FdescontoSextaTamanhoG       : Currency;
    FdescontoSextaPadrao         : Currency;
    FdescontoSextaTamanhoGG      : Currency;
    FdescontoSextaTamanhoP       : Currency;
    FdescontoSextaTamanhoExtra   : Currency;
    FdescontoSabadoTamanhoExtra  : Currency;
    FdescontoSabadoTamanhoM      : Currency;
    FdescontoSabadoTamanhoG      : Currency;
    FdescontoSabadoPadrao        : Currency;
    FdescontoSabadoTamanhoGG     : Currency;
    FdescontoSabadoTamanhoP      : Currency;
    FdescontoDomingoPadrao       : Currency;
    FdescontoDomingoTamanhoGG    : Currency;
    FdescontoDomingoTamanhoP     : Currency;
    FdescontoDomingoTamanhoExtra : Currency;
    FdescontoDomingoTamanhoM     : Currency;
    FdescontoDomingoTamanhoG     : Currency;

    function DescontoPorTamanhoSegunda(ATamanho: string): Currency;
    function DescontoPorTamanhoTerca(ATamanho: string): Currency;
    function DescontoPorTamanhoQuarta(ATamanho: string): Currency;
    function DescontoPorTamanhoQuinta(ATamanho: string): Currency;
    function DescontoPorTamanhoSexta(ATamanho: string): Currency;
    function DescontoPorTamanhoSabado(ATamanho: string): Currency;
    function DescontoPorTamanhoDomingo(ATamanho: string): Currency;
  public
    function DiaDePromocao: Boolean;
    function ValorDesconto: Currency; overload;
    function ValorDesconto(ATamanho: string): Currency; overload;

    [SwagIgnore]
    property idPromocao: Integer read FidPromocao write FidPromocao;
    [SwagIgnore]
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;
    [SwagIgnore]
    property idProduto: Integer read FidProduto write FidProduto;

    property tipoDesconto: TRPCheffTipoDesconto read FtipoDesconto write FtipoDesconto;
    property segundaFeira: Boolean read FsegundaFeira write FsegundaFeira;
    property tercaFeira: Boolean read FtercaFeira write FtercaFeira;
    property quartaFeira: Boolean read FquartaFeira write FquartaFeira;
    property quintaFeira: Boolean read FquintaFeira write FquintaFeira;
    property sextaFeira: Boolean read FsextaFeira write FsextaFeira;
    property sabado: Boolean read Fsabado write Fsabado;
    property domingo: Boolean read Fdomingo write Fdomingo;
    property tipoMesa: Boolean read FtipoMesa write FtipoMesa;
    property tipoComanda: Boolean read FtipoComanda write FtipoComanda;
    property descontoSegundaPadrao: Currency read FdescontoSegundaPadrao write FdescontoSegundaPadrao;
    property descontoSegundaTamanhoP: Currency read FdescontoSegundaTamanhoP write FdescontoSegundaTamanhoP;
    property descontoSegundaTamanhoM: Currency read FdescontoSegundaTamanhoM write FdescontoSegundaTamanhoM;
    property descontoSegundaTamanhoG: Currency read FdescontoSegundaTamanhoG write FdescontoSegundaTamanhoG;
    property descontoSegundaTamanhoGG: Currency read FdescontoSegundaTamanhoGG write FdescontoSegundaTamanhoGG;
    property descontoSegundaTamanhoExtra: Currency read FdescontoSegundaTamanhoExtra write FdescontoSegundaTamanhoExtra;
    property descontoTercaPadrao: Currency read FdescontoTercaPadrao write FdescontoTercaPadrao;
    property descontoTercaTamanhoP: Currency read FdescontoTercaTamanhoP write FdescontoTercaTamanhoP;
    property descontoTercaTamanhoM: Currency read FdescontoTercaTamanhoM write FdescontoTercaTamanhoM;
    property descontoTercaTamanhoG: Currency read FdescontoTercaTamanhoG write FdescontoTercaTamanhoG;
    property descontoTercaTamanhoGG: Currency read FdescontoTercaTamanhoGG write FdescontoTercaTamanhoGG;
    property descontoTercaTamanhoExtra: Currency read FdescontoTercaTamanhoExtra write FdescontoTercaTamanhoExtra;
    property descontoQuartaPadrao: Currency read FdescontoQuartaPadrao write FdescontoQuartaPadrao;
    property descontoQuartaTamanhoP: Currency read FdescontoQuartaTamanhoP write FdescontoQuartaTamanhoP;
    property descontoQuartaTamanhoM: Currency read FdescontoQuartaTamanhoM write FdescontoQuartaTamanhoM;
    property descontoQuartaTamanhoG: Currency read FdescontoQuartaTamanhoG write FdescontoQuartaTamanhoG;
    property descontoQuartaTamanhoGG: Currency read FdescontoQuartaTamanhoGG write FdescontoQuartaTamanhoGG;
    property descontoQuartaTamanhoExtra: Currency read FdescontoQuartaTamanhoExtra write FdescontoQuartaTamanhoExtra;
    property descontoQuintaPadrao: Currency read FdescontoQuintaPadrao write FdescontoQuintaPadrao;
    property descontoQuintaTamanhoP: Currency read FdescontoQuintaTamanhoP write FdescontoQuintaTamanhoP;
    property descontoQuintaTamanhoM: Currency read FdescontoQuintaTamanhoM write FdescontoQuintaTamanhoM;
    property descontoQuintaTamanhoG: Currency read FdescontoQuintaTamanhoG write FdescontoQuintaTamanhoG;
    property descontoQuintaTamanhoGG: Currency read FdescontoQuintaTamanhoGG write FdescontoQuintaTamanhoGG;
    property descontoQuintaTamanhoExtra: Currency read FdescontoQuintaTamanhoExtra write FdescontoQuintaTamanhoExtra;
    property descontoSextaPadrao: Currency read FdescontoSextaPadrao write FdescontoSextaPadrao;
    property descontoSextaTamanhoP: Currency read FdescontoSextaTamanhoP write FdescontoSextaTamanhoP;
    property descontoSextaTamanhoM: Currency read FdescontoSextaTamanhoM write FdescontoSextaTamanhoM;
    property descontoSextaTamanhoG: Currency read FdescontoSextaTamanhoG write FdescontoSextaTamanhoG;
    property descontoSextaTamanhoGG: Currency read FdescontoSextaTamanhoGG write FdescontoSextaTamanhoGG;
    property descontoSextaTamanhoExtra: Currency read FdescontoSextaTamanhoExtra write FdescontoSextaTamanhoExtra;
    property descontoSabadoPadrao: Currency read FdescontoSabadoPadrao write FdescontoSabadoPadrao;
    property descontoSabadoTamanhoP: Currency read FdescontoSabadoTamanhoP write FdescontoSabadoTamanhoP;
    property descontoSabadoTamanhoM: Currency read FdescontoSabadoTamanhoM write FdescontoSabadoTamanhoM;
    property descontoSabadoTamanhoG: Currency read FdescontoSabadoTamanhoG write FdescontoSabadoTamanhoG;
    property descontoSabadoTamanhoGG: Currency read FdescontoSabadoTamanhoGG write FdescontoSabadoTamanhoGG;
    property descontoSabadoTamanhoExtra: Currency read FdescontoSabadoTamanhoExtra write FdescontoSabadoTamanhoExtra;
    property descontoDomingoPadrao: Currency read FdescontoDomingoPadrao write FdescontoDomingoPadrao;
    property descontoDomingoTamanhoP: Currency read FdescontoDomingoTamanhoP write FdescontoDomingoTamanhoP;
    property descontoDomingoTamanhoM: Currency read FdescontoDomingoTamanhoM write FdescontoDomingoTamanhoM;
    property descontoDomingoTamanhoG: Currency read FdescontoDomingoTamanhoG write FdescontoDomingoTamanhoG;
    property descontoDomingoTamanhoGG: Currency read FdescontoDomingoTamanhoGG write FdescontoDomingoTamanhoGG;
    property descontoDomingoTamanhoExtra: Currency read FdescontoDomingoTamanhoExtra write FdescontoDomingoTamanhoExtra;
  end;

implementation

{ TAPIRPCheffEntityPromocao }

function TAPIRPCheffEntityPromocao.DescontoPorTamanhoDomingo(ATamanho: string): Currency;
begin
  Result := 0;
  if ATamanho = 'P' then
    Result := FdescontoDomingoTamanhoP
  else
  if ATamanho = 'M' then
    Result := FdescontoDomingoTamanhoM
  else
  if ATamanho = 'G' then
    Result := FdescontoDomingoTamanhoG
  else
  if ATamanho = 'GG' then
    Result := FdescontoDomingoTamanhoGG
  else
  if ATamanho = 'E' then
    Result := FdescontoDomingoTamanhoExtra;
end;

function TAPIRPCheffEntityPromocao.DescontoPorTamanhoQuarta(ATamanho: string): Currency;
begin
  Result := 0;
  if ATamanho = 'P' then
    Result := FdescontoQuartaTamanhoP
  else
  if ATamanho = 'M' then
    Result := FdescontoQuartaTamanhoM
  else
  if ATamanho = 'G' then
    Result := FdescontoQuartaTamanhoG
  else
  if ATamanho = 'GG' then
    Result := FdescontoQuartaTamanhoGG
  else
  if ATamanho = 'E' then
    Result := FdescontoQuartaTamanhoExtra;
end;

function TAPIRPCheffEntityPromocao.DescontoPorTamanhoQuinta(ATamanho: string): Currency;
begin
  Result := 0;
  if ATamanho = 'P' then
    Result := FdescontoQuintaTamanhoP
  else
  if ATamanho = 'M' then
    Result := FdescontoQuintaTamanhoM
  else
  if ATamanho = 'G' then
    Result := FdescontoQuintaTamanhoG
  else
  if ATamanho = 'GG' then
    Result := FdescontoQuintaTamanhoGG
  else
  if ATamanho = 'E' then
    Result := FdescontoQuintaTamanhoExtra;
end;

function TAPIRPCheffEntityPromocao.DescontoPorTamanhoSabado(ATamanho: string): Currency;
begin
  Result := 0;
  if ATamanho = 'P' then
    Result := FdescontoSabadoTamanhoP
  else
  if ATamanho = 'M' then
    Result := FdescontoSabadoTamanhoM
  else
  if ATamanho = 'G' then
    Result := FdescontoSabadoTamanhoG
  else
  if ATamanho = 'GG' then
    Result := FdescontoSabadoTamanhoGG
  else
  if ATamanho = 'E' then
    Result := FdescontoSabadoTamanhoExtra;
end;

function TAPIRPCheffEntityPromocao.DescontoPorTamanhoSegunda(ATamanho: string): Currency;
begin
  Result := 0;
  if ATamanho = 'P' then
    Result := FdescontoSegundaTamanhoP
  else
  if ATamanho = 'M' then
    Result := FdescontoSegundaTamanhoM
  else
  if ATamanho = 'G' then
    Result := FdescontoSegundaTamanhoG
  else
  if ATamanho = 'GG' then
    Result := FdescontoSegundaTamanhoGG
  else
  if ATamanho = 'E' then
    Result := FdescontoSegundaTamanhoExtra;
end;

function TAPIRPCheffEntityPromocao.DescontoPorTamanhoSexta(ATamanho: string): Currency;
begin
  Result := 0;
  if ATamanho = 'P' then
    Result := FdescontoSextaTamanhoP
  else
  if ATamanho = 'M' then
    Result := FdescontoSextaTamanhoM
  else
  if ATamanho = 'G' then
    Result := FdescontoSextaTamanhoG
  else
  if ATamanho = 'GG' then
    Result := FdescontoSextaTamanhoGG
  else
  if ATamanho = 'E' then
    Result := FdescontoSextaTamanhoExtra;
end;

function TAPIRPCheffEntityPromocao.DescontoPorTamanhoTerca(ATamanho: string): Currency;
begin
  Result := 0;
  if ATamanho = 'P' then
    Result := FdescontoTercaTamanhoP
  else
  if ATamanho = 'M' then
    Result := FdescontoTercaTamanhoM
  else
  if ATamanho = 'G' then
    Result := FdescontoTercaTamanhoG
  else
  if ATamanho = 'GG' then
    Result := FdescontoTercaTamanhoGG
  else
  if ATamanho = 'E' then
    Result := FdescontoTercaTamanhoExtra;
end;

function TAPIRPCheffEntityPromocao.DiaDePromocao: Boolean;
var
  LDiaDeHoje: Integer;
begin
  Result := False;
  LDiaDeHoje := DayOfTheWeek(Now);
  case LDiaDeHoje of
    DayMonday: Result := FsegundaFeira;
    DayTuesday: Result := FtercaFeira;
    DayWednesday: Result := FquartaFeira;
    DayThursday: Result := FquintaFeira;
    DayFriday: Result := FsextaFeira;
    DaySaturday: Result := Fsabado;
    DaySunday: Result := Fdomingo;
  end;
end;

function TAPIRPCheffEntityPromocao.ValorDesconto(ATamanho: string): Currency;
var
  LDiaDeHoje: Integer;
begin
  Result := 0;
  if not DiaDePromocao then
    Exit;

  LDiaDeHoje := DayOfTheWeek(Now);
  case LDiaDeHoje of
    DayMonday: Result := DescontoPorTamanhoSegunda(ATamanho);
    DayTuesday: Result := DescontoPorTamanhoTerca(ATamanho);
    DayWednesday: Result := DescontoPorTamanhoQuarta(ATamanho);
    DayThursday: Result := DescontoPorTamanhoQuinta(ATamanho);
    DayFriday: Result := DescontoPorTamanhoSexta(ATamanho);
    DaySaturday: Result := DescontoPorTamanhoSabado(ATamanho);
    DaySunday: Result := DescontoPorTamanhoDomingo(ATamanho);
  end;
end;

function TAPIRPCheffEntityPromocao.ValorDesconto: Currency;
var
  LDiaDeHoje: Integer;
begin
  Result := 0;
  if not DiaDePromocao then
    Exit;

  LDiaDeHoje := DayOfTheWeek(Now);
  case LDiaDeHoje of
    DayMonday: Result := FdescontoSegundaPadrao;
    DayTuesday: Result := FdescontoTercaPadrao;
    DayWednesday: Result := FdescontoQuartaPadrao;
    DayThursday: Result := FdescontoQuintaPadrao;
    DayFriday: Result := FdescontoSextaPadrao;
    DaySaturday: Result := FdescontoSabadoPadrao;
    DaySunday: Result := FdescontoDomingoPadrao;
  end;
end;

end.

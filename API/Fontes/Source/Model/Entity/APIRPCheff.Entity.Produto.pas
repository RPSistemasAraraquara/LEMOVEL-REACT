unit APIRPCheff.Entity.Produto;

interface

uses
  APIRPCheff.Entity.Promocao,
  APIRPCheff.Entity.Opcional,
  System.DateUtils,
  System.SysUtils,
  System.Generics.Collections;

type
  TAPIRPCheffEntityProdutoHappyHour = class;

  TAPIRPCheffEntityProdutoRestricao = class;

  TAPIRPCheffEntityProduto = class
  private
    FidProduto                : Integer;
    FidEmpresa                : Integer;
    Fdescricao                : string;
    FcodReferencia            : string;
    FvalorTamanhoP            : Currency;
    FvalorTamanhoM            : Currency;
    FvalorTamanhoG            : Currency;
    FvalorTamanhoGG           : Currency;
    FvalorTamanhoExtra        : Currency;
    FvendaPorTamanho          : Boolean;
    FtamanhoPadrao            : string;
    FtamanhoP                 : string;
    FtamanhoM                 : string;
    FtamanhoG                 : string;
    FtamanhoGG                : string;
    FtamanhoExtra             : string;
    FvalorUnitario            : Currency;
    FcobrarTaxa               : Boolean;
    Fimpressora1              : Integer;
    Fimpressora2              : Integer;
    FidCategoria              : Integer;
    Fopcionais                : TObjectList<TAPIRPCheffEntityOpcional>;
    FhappyHourAtivar          : Boolean;
    FhappyHour                : TAPIRPCheffEntityProdutoHappyHour;
    FrestringirVenda          : Boolean;
    Frestricao                : TAPIRPCheffEntityProdutoRestricao;
    FpermiteFracao            : Boolean;
    FproximoGratis            : Boolean;
    FquantidadeProximoGratis  : Integer;
    FvalorTabela2             : Currency;
    FvalorAtacado             : Currency;
    Fpreco4                   : Currency;
    Fpreco5                   : Currency;
    Fpreco6                   : Currency;
    Fpreco7                   : Currency;
    Fpromocao                 : TAPIRPCheffEntityPromocao;
    FutilizaCombo             : Boolean;
    FidSetor                  : Integer;
    FusaQuantidadeDecimal     : Boolean;
    FImprimirFicha            : Boolean;
    FPermiteVendaAPP          : boolean;
    FCustoProduto             : Currency;
    FCustoComposicao          : Currency;
    Fimagem                   : string;
    FpossuiImagem             : Boolean;
    function GetValorVenda    : Currency;
    procedure SetOpcionais(const AValue: TObjectList<TAPIRPCheffEntityOpcional>);
    procedure SetPromocao(const AValue: TAPIRPCheffEntityPromocao);
    function GetPossuiPromocao: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function UsaHappyHour: Boolean;
    function VendaRestritaHoje: Boolean;
    function DiaRestricaoAtualDescricao: string;
    function Valor: Currency;
    function ValorPorTamanho(ATamanho: string): Currency;

    property idEmpresa               : Integer                                  read FidEmpresa                  write FidEmpresa;
    property idProduto               : Integer                                  read FidProduto                  write FidProduto;
    property idCategoria             : Integer                                  read FidCategoria                write FidCategoria;
    property descricao               : string                                   read Fdescricao                  write Fdescricao;

    property codReferencia           : string                                   read FcodReferencia              write FcodReferencia;
    property cobrarTaxa              : Boolean                                  read FcobrarTaxa                 write FcobrarTaxa;
    property valorTamanhoP           : Currency                                 read FvalorTamanhoP              write FvalorTamanhoP;
    property valorTamanhoM           : Currency                                 read FvalorTamanhoM              write FvalorTamanhoM;
    property valorTamanhoG           : Currency                                 read FvalorTamanhoG              write FvalorTamanhoG;
    property valorTamanhoGG          : Currency                                 read FvalorTamanhoGG             write FvalorTamanhoGG;
    property valorTamanhoExtra       : Currency                                 read FvalorTamanhoExtra          write FvalorTamanhoExtra;
    property vendaPorTamanho         : Boolean                                  read FvendaPorTamanho            write FvendaPorTamanho;
    property tamanhoPadrao           : string                                   read FtamanhoPadrao              write FtamanhoPadrao;
    property tamanhoP                : string                                   read FtamanhoP                   write FtamanhoP;
    property tamanhoM                : string                                   read FtamanhoM                   write FtamanhoM;
    property tamanhoG                : string                                   read FtamanhoG                   write FtamanhoG;
    property tamanhoGG               : string                                   read FtamanhoGG                  write FtamanhoGG;
    property tamanhoExtra            : string                                   read FtamanhoExtra               write FtamanhoExtra;
    property valorUnitario           : Currency                                 read FvalorUnitario              write FvalorUnitario;
    property valorTabela2            : Currency                                 read FvalorTabela2               write FvalorTabela2;
    property valorAtacado            : Currency                                 read FvalorAtacado               write FvalorAtacado;
    property preco4                  : Currency                                 read Fpreco4                     write Fpreco4;
    property preco5                  : Currency                                 read Fpreco5                     write Fpreco5;
    property preco6                  : Currency                                 read Fpreco6                     write Fpreco6;
    property preco7                  : Currency                                 read Fpreco7                     write Fpreco7;
    property valorVenda              : Currency                                 read GetValorVenda;
    property impressora1             : Integer                                  read Fimpressora1                write Fimpressora1;
    property impressora2             : Integer                                  read Fimpressora2                write Fimpressora2;
    property happyHourAtivar         : Boolean                                  read FhappyHourAtivar            write FhappyHourAtivar;
    property happyHour               : TAPIRPCheffEntityProdutoHappyHour        read FhappyHour                  write FhappyHour;
    property restringirVenda         : Boolean                                  read FrestringirVenda            write FrestringirVenda;
    property restricao               : TAPIRPCheffEntityProdutoRestricao        read Frestricao                  write Frestricao;
    property permiteFracao           : Boolean                                  read FpermiteFracao              write FpermiteFracao;
    property proximoGratis           : Boolean                                  read FproximoGratis              write FproximoGratis;
    property utilizaCombo            : Boolean                                  read FutilizaCombo               write FutilizaCombo;
    property idSetor                 : Integer                                  read FidSetor                    write FidSetor;
    property quantidadeProximoGratis : Integer                                  read FquantidadeProximoGratis    write FquantidadeProximoGratis;
    property usaQuantidadeDecimal    : Boolean                                  read FusaQuantidadeDecimal       write FusaQuantidadeDecimal;
    property possuiPromocao          : Boolean                                  read GetPossuiPromocao;
    property promocao                : TAPIRPCheffEntityPromocao                read Fpromocao                   write SetPromocao;
    property opcionais               : TObjectList<TAPIRPCheffEntityOpcional>   read Fopcionais                  write SetOpcionais;
    property ImprimirFicha           : Boolean                                  read FImprimirFicha              write FImprimirFicha;
    property PermiteVendaAPP         : boolean                                  read FPermiteVendaAPP            write FPermiteVendaAPP;
    property CustoProduto            : Currency                                 read FCustoProduto               write FCustoProduto;
    property CustoComposicao         : Currency                                 read FCustoComposicao            write FCustoComposicao;
    property imagem                  : string                                   read Fimagem                     write Fimagem;
    property possuiImagem            : Boolean                                  read FpossuiImagem               write FpossuiImagem;
  end;

  TAPIRPCheffEntityProdutoHappyHour = class
  private
    FsegundaFeira                   : Boolean;
    FtercaFeira                     : Boolean;
    FquartaFeira                    : Boolean;
    FquintaFeira                    : Boolean;
    FsextaFeira                     : Boolean;
    Fsabado                         : Boolean;
    Fdomingo                        : Boolean;
    FtipoMesa                       : Boolean;
    FtipoComanda                    : Boolean;
    FhoraInicial                    : TTime;
    FhoraFinal                      : TTime;
    Fvalor                          : Currency;
  public
    function HoraDeHappyHour: Boolean;
    property segundaFeira           : Boolean   read FsegundaFeira    write FsegundaFeira;
    property tercaFeira             : Boolean   read FtercaFeira      write FtercaFeira;
    property quartaFeira            : Boolean   read FquartaFeira     write FquartaFeira;
    property quintaFeira            : Boolean   read FquintaFeira     write FquintaFeira;
    property sextaFeira             : Boolean   read FsextaFeira      write FsextaFeira;
    property sabado                 : Boolean   read Fsabado          write Fsabado;
    property domingo                : Boolean   read Fdomingo         write Fdomingo;
    property tipoMesa               : Boolean   read FtipoMesa        write FtipoMesa;
    property tipoComanda            : Boolean   read FtipoComanda     write FtipoComanda;
    property horaInicial            : TTime     read FhoraInicial     write FhoraInicial;
    property horaFinal              : TTime     read FhoraFinal       write FhoraFinal;
    property valor                  : Currency  read Fvalor           write Fvalor;

  end;

  TAPIRPCheffEntityProdutoRestricao = class
  private
    FquintaFeira                    : Boolean;
    Fsabado                         : Boolean;
    FsegundaFeira                   : Boolean;
    Fdomingo                        : Boolean;
    FtercaFeira                     : Boolean;
    FsextaFeira                     : Boolean;
    FquartaFeira                    : Boolean;
  public
    property segundaFeira           : Boolean  read FsegundaFeira     write FsegundaFeira;
    property tercaFeira             : Boolean  read FtercaFeira       write FtercaFeira;
    property quartaFeira            : Boolean  read FquartaFeira      write FquartaFeira;
    property quintaFeira            : Boolean  read FquintaFeira      write FquintaFeira;
    property sextaFeira             : Boolean  read FsextaFeira       write FsextaFeira;
    property sabado                 : Boolean  read Fsabado           write Fsabado;
    property domingo                : Boolean  read Fdomingo          write Fdomingo;

  end;

implementation

{ TAPIRPCheffEntityProduto }

constructor TAPIRPCheffEntityProduto.Create;
begin
  FcobrarTaxa           := False;
  FhappyHour            := TAPIRPCheffEntityProdutoHappyHour.Create;
  Fopcionais            := TObjectList<TAPIRPCheffEntityOpcional>.Create;
  Fpromocao             := TAPIRPCheffEntityPromocao.Create;
  Frestricao            := TAPIRPCheffEntityProdutoRestricao.Create;
  FusaQuantidadeDecimal := False;
end;

destructor TAPIRPCheffEntityProduto.Destroy;
begin
  FreeAndNil(FhappyHour);
  FreeAndNil(Fopcionais);
  FreeAndNil(Fpromocao);
  FreeAndNil(Frestricao);
  inherited;
end;

function TAPIRPCheffEntityProduto.GetPossuiPromocao: Boolean;
begin
  Result := False;
  if Assigned(Fpromocao) then
  begin
    Result := (Fpromocao.segundaFeira) or (Fpromocao.tercaFeira) or (Fpromocao.quartaFeira) or
      (Fpromocao.quintaFeira) or (Fpromocao.sextaFeira) or (Fpromocao.sabado) or (Fpromocao.domingo);
  end;
end;

function TAPIRPCheffEntityProduto.GetValorVenda: Currency;
begin
  Result := FvalorUnitario;
  if FvendaPorTamanho then
  begin
    if FtamanhoPadrao = 'P' then
      Result := FvalorTamanhoP
    else
    if FtamanhoPadrao = 'M' then
      Result := FvalorTamanhoM
    else
    if FtamanhoPadrao = 'G' then
      Result := FvalorTamanhoG
    else
    if FtamanhoPadrao = 'GG' then
      Result := FvalorTamanhoGG
    else
    if FtamanhoPadrao = 'E' then
      Result := FvalorTamanhoExtra;
  end;
end;

procedure TAPIRPCheffEntityProduto.SetOpcionais(const AValue: TObjectList<TAPIRPCheffEntityOpcional>);
begin
  FreeAndNil(Fopcionais);
  Fopcionais := AValue;
end;

procedure TAPIRPCheffEntityProduto.SetPromocao(const AValue: TAPIRPCheffEntityPromocao);
begin
  FreeAndNil(Fpromocao);
  Fpromocao := AValue;
end;

function TAPIRPCheffEntityProduto.UsaHappyHour: Boolean;
begin
  Result := (FhappyHourAtivar) and (FhappyHour.HoraDeHappyHour);
end;

function TAPIRPCheffEntityProduto.DiaRestricaoAtualDescricao: string;
begin
  Result := 'hoje';
  case DayOfTheWeek(Now) of
    DayMonday    : Result := 'segunda-feira';
    DayTuesday   : Result := 'terca-feira';
    DayWednesday : Result := 'quarta-feira';
    DayThursday  : Result := 'quinta-feira';
    DayFriday    : Result := 'sexta-feira';
    DaySaturday  : Result := 'sabado';
    DaySunday    : Result := 'domingo';
  end;
end;

function TAPIRPCheffEntityProduto.VendaRestritaHoje: Boolean;
begin
  Result := False;
  if (not FrestringirVenda) or (not Assigned(Frestricao)) then
    Exit;

  case DayOfTheWeek(Now) of
    DayMonday    : Result := Frestricao.segundaFeira;
    DayTuesday   : Result := Frestricao.tercaFeira;
    DayWednesday : Result := Frestricao.quartaFeira;
    DayThursday  : Result := Frestricao.quintaFeira;
    DayFriday    : Result := Frestricao.sextaFeira;
    DaySaturday  : Result := Frestricao.sabado;
    DaySunday    : Result := Frestricao.domingo;
  end;
end;

function TAPIRPCheffEntityProduto.Valor: Currency;
begin
  Result := Self.valorVenda;
  if UsaHappyHour then
    Result := FhappyHour.valor;
end;

function TAPIRPCheffEntityProduto.ValorPorTamanho(ATamanho: string): Currency;
begin
  Result := FvalorTamanhoM;
  if ATamanho = 'P' then
    Result := FvalorTamanhoP
  else
  if ATamanho = 'M' then
    Result := FvalorTamanhoM
  else
  if ATamanho = 'G' then
    Result := FvalorTamanhoG
  else
  if ATamanho = 'GG' then
    Result := FvalorTamanhoGG
  else
  if ATamanho = 'E' then
    Result := FvalorTamanhoExtra;
end;

{ TAPIRPCheffEntityProdutoHappyHour }

function TAPIRPCheffEntityProdutoHappyHour.HoraDeHappyHour: Boolean;
var
  LDiaDeHoje     : Integer;
  LDiaDeHappyHour: Boolean;
  LHora          : TTime;
begin
  Result := False;
  LDiaDeHappyHour := False;
  LDiaDeHoje := DayOfTheWeek(Now);
  case LDiaDeHoje of
    DayMonday       : LDiaDeHappyHour := FsegundaFeira;
    DayTuesday      : LDiaDeHappyHour := FtercaFeira;
    DayWednesday    : LDiaDeHappyHour := FquartaFeira;
    DayThursday     : LDiaDeHappyHour := FquintaFeira;
    DayFriday       : LDiaDeHappyHour := FsextaFeira;
    DaySaturday     : LDiaDeHappyHour := Fsabado;
    DaySunday       : LDiaDeHappyHour := Fdomingo;
  end;

  if LDiaDeHappyHour then
  begin
    LHora := Now.GetTime;
    Result := (FhoraFinal >= LHora) and
      (FhoraInicial <= LHora);
  end;
end;

end.

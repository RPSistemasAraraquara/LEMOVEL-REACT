unit APIRPCheff.Service.Comanda.Abertura;

interface

uses
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.SysUtils;

type
  TAPIRPCheffServiceComandaAbertura = class
  private
    FDAO        : TAPIRPCheffDAOFactory;
    FAbertura   : TAPIRPCheffEntityVendaPostAbertura;
    FIdUsuario  : Integer;
    FUsaCatraca : Boolean;

    procedure AtribuirCaixa(AVenda: TAPIRPCheffEntityVenda);
    function BuscarComanda: TAPIRPCheffEntityComanda;
    procedure InserirVenda(AVenda: TAPIRPCheffEntityVenda);
    procedure InserirCatraca(AComanda: TAPIRPCheffEntityComanda);
    procedure ValidarDadosEmpresa;
  public
    constructor Create;

    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceComandaAbertura;
    function Abertura(AValue: TAPIRPCheffEntityVendaPostAbertura): TAPIRPCheffServiceComandaAbertura;
    function IdUsuario(AValue: Integer): TAPIRPCheffServiceComandaAbertura;
    function UsaCatraca(AValue: Boolean): TAPIRPCheffServiceComandaAbertura;
    function Execute: TAPIRPCheffEntityComanda;
  end;

implementation

{ TAPIRPCheffServiceComandaAbertura }

function TAPIRPCheffServiceComandaAbertura.Abertura(AValue: TAPIRPCheffEntityVendaPostAbertura): TAPIRPCheffServiceComandaAbertura;
begin
  Result := Self;
  FAbertura := AValue;
end;

procedure TAPIRPCheffServiceComandaAbertura.AtribuirCaixa(AVenda: TAPIRPCheffEntityVenda);
var
  LCaixa: TAPIRPCheffEntityCaixa;
begin
  LCaixa := FDAO.CaixaDAO.ProximoCaixaAberto;
  try
    if not Assigned(LCaixa) then
      raise Exception.Create('n'#227'o foi encontrado Caixa aberto.');
    AVenda.idCaixa := LCaixa.idCaixa;
  finally
    FreeAndNil(LCaixa);
  end;
end;

function TAPIRPCheffServiceComandaAbertura.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceComandaAbertura;
begin
  Result := Self;
  FDAO := AValue;
end;

function TAPIRPCheffServiceComandaAbertura.Execute: TAPIRPCheffEntityComanda;
begin
  ValidarDadosEmpresa;
  Result := BuscarComanda;
  try
    Result.venda := TAPIRPCheffEntityVenda.Create;
    Result.venda.idEmpresa := FAbertura.idEmpresa;
    Result.venda.numeroComanda := Result.numero.ToInteger;
    Result.venda.data := Now;
    Result.venda.dataAbertura := Result.venda.data;
    Result.venda.situacao := svPendente;
    Result.venda.idUsuario := FIdUsuario;
    Result.venda.tipoVenda := tvComanda;
    Result.venda.terminalAbertura := FAbertura.terminalAbertura;
    Result.venda.nomeMesaComanda := FAbertura.nomeMesaComanda;
    Result.venda.numeroMesa := 0;
    Result.venda.numeroPessoas := 1;

    AtribuirCaixa(Result.venda);
    FDAO.StartTransaction;
    try
      InserirVenda(Result.venda);
      InserirCatraca(Result);
      Result.idVenda := Result.venda.idVenda;
      FDAO.Commit;
    except
      FDAO.Rollback;
      raise;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TAPIRPCheffServiceComandaAbertura.IdUsuario(AValue: Integer): TAPIRPCheffServiceComandaAbertura;
begin
  Result := Self;
  FIdUsuario := AValue;
end;

procedure TAPIRPCheffServiceComandaAbertura.InserirCatraca(AComanda: TAPIRPCheffEntityComanda);
var
  LDAO: TAPIRPCheffDAOCatracaMobile;
  LCatraca: TAPIRPCheffEntityCatracaMobile;
begin
  if not FUsaCatraca then
    Exit;
  LDAO := FDAO.CatracaMobileDAO;
  LDAO.ManagerTransaction(False);
  LCatraca := TAPIRPCheffEntityCatracaMobile.Create;
  try
    LCatraca.idComanda := AComanda.idComanda;
    LCatraca.idEmpresa := FAbertura.idEmpresa;
    LCatraca.comando := 'C';
    LCatraca.data := Now;
    LDAO.Inserir(LCatraca);
  finally
    FreeAndNil(LCatraca);
  end;
end;

procedure TAPIRPCheffServiceComandaAbertura.InserirVenda(AVenda: TAPIRPCheffEntityVenda);
var
  LDAO: TAPIRPCheffDAOVenda;
begin
  LDAO := FDAO.VendaDAO;
  LDAO.ManagerTransaction(False);
  LDAO.Inserir(AVenda);
end;

function TAPIRPCheffServiceComandaAbertura.UsaCatraca(AValue: Boolean): TAPIRPCheffServiceComandaAbertura;
begin
  Result := Self;
  FUsaCatraca := AValue;
end;

procedure TAPIRPCheffServiceComandaAbertura.ValidarDadosEmpresa;
var
  LEmpresa: TAPIRPCheffEntityEmpresa;
begin
  FDAO.EmpresaDAO.IdEmpresa(FAbertura.idEmpresa);
  LEmpresa := FDAO.EmpresaDAO.Busca;
  try
    if not Assigned(LEmpresa) then
      raise Exception.Create('Empresa N'#227'o encontrada.');

    if LEmpresa.casaNoturna then
      raise Exception.Create('Imposs'#237'vel abrir venda no m'#243'dulo casa noturna.');
  finally
    FreeAndNil(LEmpresa);
  end;
end;

function TAPIRPCheffServiceComandaAbertura.BuscarComanda: TAPIRPCheffEntityComanda;
begin
  Result := FDAO.ComandaDAO.Busca(FAbertura.idMesaComanda);
  try
    if not Assigned(Result) then
      raise Exception.CreateFmt('Comanda %d N'#227'o encontrada.', [FAbertura.idMesaComanda]);

    if Result.idVenda > 0 then
      raise Exception.CreateFmt('Comanda %s N'#227'o est'#225' livre.', [Result.numero]);
  except
    Result.Free;
    raise;
  end;
end;

constructor TAPIRPCheffServiceComandaAbertura.Create;
begin
  FUsaCatraca := False;
end;

end.

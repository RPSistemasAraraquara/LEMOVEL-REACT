unit APIRPCheff.Service.Mesa.Abertura;

interface

uses
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.SysUtils;

type
  TAPIRPCheffServiceMesaAbertura = class
  private
    FDAO       : TAPIRPCheffDAOFactory;
    FAbertura  : TAPIRPCheffEntityVendaPostAbertura;
    FIdUsuario : Integer;

    procedure AtribuirCaixa(AVenda: TAPIRPCheffEntityVenda);
    function BuscarMesa: TAPIRPCheffEntityMesa;
    procedure VerificarSeEstaEmLimpeza(AMesa: TAPIRPCheffEntityMesa);
    procedure ValidarDadosEmpresa;
  public
    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceMesaAbertura;
    function Abertura(AValue: TAPIRPCheffEntityVendaPostAbertura): TAPIRPCheffServiceMesaAbertura;
    function IdUsuario(AValue: Integer): TAPIRPCheffServiceMesaAbertura;
    function Execute: TAPIRPCheffEntityMesa;
  end;

implementation

{ TAPIRPCheffServiceMesaAbertura }

function TAPIRPCheffServiceMesaAbertura.Abertura(AValue: TAPIRPCheffEntityVendaPostAbertura): TAPIRPCheffServiceMesaAbertura;
begin
  Result := Self;
  FAbertura := AValue;
end;

procedure TAPIRPCheffServiceMesaAbertura.AtribuirCaixa(AVenda: TAPIRPCheffEntityVenda);
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

function TAPIRPCheffServiceMesaAbertura.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceMesaAbertura;
begin
  Result := Self;
  FDAO := AValue;
end;

function TAPIRPCheffServiceMesaAbertura.Execute: TAPIRPCheffEntityMesa;
begin
  ValidarDadosEmpresa;
  Result := BuscarMesa;
  try
    VerificarSeEstaEmLimpeza(Result);
    Result.venda := TAPIRPCheffEntityVenda.Create;
    Result.venda.idEmpresa := FAbertura.idEmpresa;
    Result.venda.numeroMesa := Result.numero.ToInteger;
    Result.venda.data := Now;
    Result.venda.dataAbertura := Result.venda.data;
    Result.venda.situacao := svPendente;
    Result.venda.idUsuario := FIdUsuario;
    Result.venda.tipoVenda := tvMesa;
    Result.venda.terminalAbertura := FAbertura.terminalAbertura;
    Result.venda.nomeMesaComanda := FAbertura.nomeMesaComanda;
    Result.venda.numeroComanda := 0;
    Result.venda.numeroPessoas := 1;

    AtribuirCaixa(Result.venda);
    FDAO.VendaDAO.Inserir(Result.venda);
    Result.idVenda := Result.venda.idVenda;
  except
    Result.Free;
    raise;
  end;
end;

function TAPIRPCheffServiceMesaAbertura.IdUsuario(AValue: Integer): TAPIRPCheffServiceMesaAbertura;
begin
  Result := Self;
  FIdUsuario := AValue;
end;

procedure TAPIRPCheffServiceMesaAbertura.ValidarDadosEmpresa;
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

procedure TAPIRPCheffServiceMesaAbertura.VerificarSeEstaEmLimpeza(AMesa: TAPIRPCheffEntityMesa);
var
  LVenda: TAPIRPCheffEntityVenda;
begin
  LVenda := FDAO.VendaDAO.BuscarComMesaAguardandoLimpeza(AMesa.idMesa);
  try
    if Assigned(LVenda) then
      raise Exception.Create('Mesa encontra-se aguardando limpeza...');
  finally
    FreeAndNil(LVenda);
  end;
end;

function TAPIRPCheffServiceMesaAbertura.BuscarMesa: TAPIRPCheffEntityMesa;
begin
  Result := FDAO.MesaDAO.Busca(FAbertura.idMesaComanda);
  try
    if not Assigned(Result) then
      raise Exception.CreateFmt('Mesa %d N'#227'o encontrada.', [FAbertura.idMesaComanda]);

    if Result.idVenda > 0 then
      raise Exception.CreateFmt('Mesa %s N'#227'o est'#225' livre.', [Result.numero]);
  except
    Result.Free;
    raise;
  end;
end;

end.

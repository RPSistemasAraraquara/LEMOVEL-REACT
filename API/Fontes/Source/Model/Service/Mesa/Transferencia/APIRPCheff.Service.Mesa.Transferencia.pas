unit APIRPCheff.Service.Mesa.Transferencia;

interface

uses
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.SysUtils,
  System.Classes;

type
  TAPIRPCheffServiceMesaTransferencia = class
  private
    FDAO           : TAPIRPCheffDAOFactory;
    FIdMesaOrigem  : Integer;
    FIdMesaDestino : Integer;
    FMesaOrigem    : TAPIRPCheffEntityMesa;
    FMesaDestino   : TAPIRPCheffEntityMesa;

    procedure CarregarMesaOrigem;
    procedure CarregarMesaDestino;
    procedure Transferir;
  public
    destructor Destroy; override;

    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceMesaTransferencia;
    function IdMesaOrigem(AValue: Integer): TAPIRPCheffServiceMesaTransferencia;
    function IdMesaDestino(AValue: Integer): TAPIRPCheffServiceMesaTransferencia;
    procedure Execute;
  end;

implementation

{ TAPIRPCheffServiceMesaTransferencia }

procedure TAPIRPCheffServiceMesaTransferencia.CarregarMesaDestino;
begin
  FreeAndNil(FMesaDestino);
  FMesaDestino := FDAO.MesaDAO.Busca(FIdMesaDestino);
  if not Assigned(FMesaDestino) then
    raise Exception.CreateFmt('Mesa destino %d N'#227'o encontrada.', [FIdMesaDestino]);

  if FMesaDestino.idVenda > 0 then
    raise Exception.CreateFmt('Mesa destino %d possui venda em andamento.',
      [FIdMesaDestino]);
end;

procedure TAPIRPCheffServiceMesaTransferencia.CarregarMesaOrigem;
begin
  FreeAndNil(FMesaOrigem);
  FMesaOrigem := FDAO.MesaDAO.Busca(FIdMesaOrigem);
  if not Assigned(FMesaOrigem) then
    raise Exception.CreateFmt('Mesa origem %d N'#227'o encontrada.', [FIdMesaOrigem]);

  if FMesaOrigem.idVenda = 0 then
    raise Exception.CreateFmt('Mesa origem %d N'#227'o possui venda em aberto.', [FIdMesaOrigem]);

  FMesaOrigem.venda := FDAO.VendaDAO.Buscar(FMesaOrigem.idVenda);
  if FMesaOrigem.venda.situacao <> svPendente then
    raise Exception.CreateFmt('situa'#231#227'o da mesa origem est'#225' como %s. s'#243' '#224' poss'#237'vel transferir ' +
      'de mesas pendentes', [FMesaOrigem.venda.situacao.Description]);
end;

function TAPIRPCheffServiceMesaTransferencia.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceMesaTransferencia;
begin
  Result := Self;
  FDAO := AValue;
end;

destructor TAPIRPCheffServiceMesaTransferencia.Destroy;
begin
  FreeAndNil(FMesaOrigem);
  FreeAndNil(FMesaDestino);
  inherited;
end;

procedure TAPIRPCheffServiceMesaTransferencia.Execute;
begin
  CarregarMesaOrigem;
  CarregarMesaDestino;
  Transferir;
end;

function TAPIRPCheffServiceMesaTransferencia.IdMesaDestino(AValue: Integer): TAPIRPCheffServiceMesaTransferencia;
begin
  Result := Self;
  FIdMesaDestino := AValue;
end;

function TAPIRPCheffServiceMesaTransferencia.IdMesaOrigem(AValue: Integer): TAPIRPCheffServiceMesaTransferencia;
begin
  Result := Self;
  FIdMesaOrigem := AValue;
end;

procedure TAPIRPCheffServiceMesaTransferencia.Transferir;
begin
  FDAO.VendaDAO.TransferirMesa(FMesaOrigem.idVenda, FMesaDestino.numero.ToInteger);
end;

end.

unit APIRPCheff.Service.Comanda.Transferencia;

interface

uses
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.SysUtils,
  System.Classes;

type
  TAPIRPCheffServiceComandaTransferencia = class
  private
    FDAO: TAPIRPCheffDAOFactory;
    FIdComandaOrigem: Integer;
    FIdComandaDestino: Integer;
    FComandaOrigem: TAPIRPCheffEntityComanda;
    FComandaDestino: TAPIRPCheffEntityComanda;

    procedure CarregarComandaOrigem;
    procedure CarregarComandaDestino;
    procedure Transferir;
  public
    destructor Destroy; override;

    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceComandaTransferencia;
    function IdComandaOrigem(AValue: Integer): TAPIRPCheffServiceComandaTransferencia;
    function IdComandaDestino(AValue: Integer): TAPIRPCheffServiceComandaTransferencia;
    procedure Execute;
  end;

implementation

{ TAPIRPCheffServiceComandaTransferencia }

procedure TAPIRPCheffServiceComandaTransferencia.CarregarComandaDestino;
begin
  FreeAndNil(FComandaDestino);
  FComandaDestino := FDAO.ComandaDAO.Busca(FIdComandaDestino);
  if not Assigned(FComandaDestino) then
    raise Exception.CreateFmt('Comanda destino %d N'#227'o encontrada.', [FIdComandaDestino]);

  if FComandaDestino.idVenda > 0 then
    raise Exception.CreateFmt('Comanda destino %d possui venda em andamento.',
      [FIdComandaDestino]);
end;

procedure TAPIRPCheffServiceComandaTransferencia.CarregarComandaOrigem;
begin
  FreeAndNil(FComandaOrigem);
  FComandaOrigem := FDAO.ComandaDAO.Busca(FIdComandaOrigem);
  if not Assigned(FComandaOrigem) then
    raise Exception.CreateFmt('Comanda origem %d N'#227'o encontrada.', [FIdComandaOrigem]);

  if FComandaOrigem.idVenda = 0 then
    raise Exception.CreateFmt('Comanda origem %d N'#227'o possui venda em aberto.', [FIdComandaOrigem]);

  FComandaOrigem.venda := FDAO.VendaDAO.Buscar(FComandaOrigem.idVenda);
  if FComandaOrigem.venda.situacao <> svPendente then
    raise Exception.CreateFmt('situa'#231#227'o da comanda origem est'#225' como %s. s'#243' '#224' poss'#237'vel transferir ' +
      'de comandas pendentes', [FComandaOrigem.venda.situacao.Description]);
end;

function TAPIRPCheffServiceComandaTransferencia.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceComandaTransferencia;
begin
  Result := Self;
  FDAO := AValue;
end;

destructor TAPIRPCheffServiceComandaTransferencia.Destroy;
begin
  FreeAndNil(FComandaOrigem);
  FreeAndNil(FComandaDestino);
  inherited;
end;

procedure TAPIRPCheffServiceComandaTransferencia.Execute;
begin
  CarregarComandaOrigem;
  CarregarComandaDestino;
  Transferir;
end;

function TAPIRPCheffServiceComandaTransferencia.IdComandaDestino(AValue: Integer): TAPIRPCheffServiceComandaTransferencia;
begin
  Result := Self;
  FIdComandaDestino := AValue;
end;

function TAPIRPCheffServiceComandaTransferencia.IdComandaOrigem(AValue: Integer): TAPIRPCheffServiceComandaTransferencia;
begin
  Result := Self;
  FIdComandaOrigem := AValue;
end;

procedure TAPIRPCheffServiceComandaTransferencia.Transferir;
begin
  FDAO.VendaDAO.TransferirComanda(FComandaOrigem.idVenda, FComandaDestino.numero.ToInteger);
end;

end.

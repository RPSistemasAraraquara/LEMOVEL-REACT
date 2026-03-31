unit APIRPCheff.Service.Mesa.Juncao;

interface

uses
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TAPIRPCheffServiceMesaJuncao = class
  private
    FDAO              : TAPIRPCheffDAOFactory;
    FIdVendaDestino   : Integer;
    FIdVendasOrigem   : TList<Integer>;

    procedure ValidarVendaDestino;
    procedure ValidarVendasOrigem;
    procedure MoverItens(AIdVendaOrigem: Integer);
    procedure MoverPagamentos(AIdVendaOrigem: Integer);
    procedure FinalizarVendaOrigem(AIdVendaOrigem: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceMesaJuncao;
    function IdVendaDestino(AValue: Integer): TAPIRPCheffServiceMesaJuncao;
    function AddVendaOrigem(AValue: Integer): TAPIRPCheffServiceMesaJuncao;
    procedure Execute;
  end;

implementation

{ TAPIRPCheffServiceMesaJuncao }

constructor TAPIRPCheffServiceMesaJuncao.Create;
begin
  inherited;
  FIdVendasOrigem := TList<Integer>.Create;
end;

destructor TAPIRPCheffServiceMesaJuncao.Destroy;
begin
  FreeAndNil(FIdVendasOrigem);
  inherited;
end;

function TAPIRPCheffServiceMesaJuncao.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceMesaJuncao;
begin
  Result := Self;
  FDAO := AValue;
end;

function TAPIRPCheffServiceMesaJuncao.IdVendaDestino(AValue: Integer): TAPIRPCheffServiceMesaJuncao;
begin
  Result := Self;
  FIdVendaDestino := AValue;
end;

function TAPIRPCheffServiceMesaJuncao.AddVendaOrigem(AValue: Integer): TAPIRPCheffServiceMesaJuncao;
begin
  Result := Self;
  FIdVendasOrigem.Add(AValue);
end;

procedure TAPIRPCheffServiceMesaJuncao.ValidarVendaDestino;
var
  LVenda: TAPIRPCheffEntityVenda;
begin
  LVenda := FDAO.VendaDAO.Buscar(FIdVendaDestino);
  try
    if not Assigned(LVenda) then
      raise Exception.Create('Venda destino nao encontrada.');
    if not (LVenda.situacao in [svPendente, svPreFechamento]) then
      raise Exception.Create('A mesa/comanda de destino nao esta pendente. Nao e possivel juntar.');
  finally
    FreeAndNil(LVenda);
  end;
end;

procedure TAPIRPCheffServiceMesaJuncao.ValidarVendasOrigem;
var
  LIdVendaOrigem: Integer;
  LVenda: TAPIRPCheffEntityVenda;
begin
  for LIdVendaOrigem in FIdVendasOrigem do
  begin
    LVenda := FDAO.VendaDAO.Buscar(LIdVendaOrigem);
    try
      if not Assigned(LVenda) then
        raise Exception.Create('Uma das mesas/comandas selecionadas nao foi encontrada.');
      if LVenda.situacao <> svPendente then
        raise Exception.Create('Uma das mesas/comandas selecionadas nao esta pendente. Nao e possivel juntar.');
    finally
      FreeAndNil(LVenda);
    end;
  end;
end;

procedure TAPIRPCheffServiceMesaJuncao.MoverItens(AIdVendaOrigem: Integer);
begin
  FDAO.VendaDAO.JuntarItensVenda(AIdVendaOrigem, FIdVendaDestino);
end;

procedure TAPIRPCheffServiceMesaJuncao.MoverPagamentos(AIdVendaOrigem: Integer);
begin
  FDAO.VendaDAO.MoverPagamentosAntecipados(AIdVendaOrigem, FIdVendaDestino);
end;

procedure TAPIRPCheffServiceMesaJuncao.FinalizarVendaOrigem(AIdVendaOrigem: Integer);
begin
  FDAO.VendaDAO.DeletarVendaJuncao(AIdVendaOrigem);
end;

procedure TAPIRPCheffServiceMesaJuncao.Execute;
var
  LIdVendaOrigem: Integer;
begin
  if FIdVendasOrigem.Count = 0 then
    raise Exception.Create('Nenhuma mesa/comanda de origem selecionada.');

  ValidarVendaDestino;
  ValidarVendasOrigem;

  for LIdVendaOrigem in FIdVendasOrigem do
  begin
    MoverItens(LIdVendaOrigem);
    MoverPagamentos(LIdVendaOrigem);
    FinalizarVendaOrigem(LIdVendaOrigem);
  end;

  FDAO.VendaDAO.AtualizarTotalVenda(FDAO.IdEmpresa, FIdVendaDestino);
end;

end.

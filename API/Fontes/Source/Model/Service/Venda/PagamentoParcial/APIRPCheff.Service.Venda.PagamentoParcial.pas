unit APIRPCheff.Service.Venda.PagamentoParcial;

interface

uses
  APIRPCheff.DAO.Factory,
  APIRPCheff.Entity.Classes;

type

  TAPIRPCheffServiceVendaPagamentoParcial = class
  private
    FDAO                  : TAPIRPCheffDAOFactory;
    FPagamentoAntecipado     : TAPIRPCheffEntityVendaPagamentoAntecipado;
  public
    destructor Destroy; override;
    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaPagamentoParcial; overload;
    function DAO: TAPIRPCheffDAOFactory; overload;
    function PagamentoAntecipado(AValue: TAPIRPCheffEntityVendaPagamentoAntecipado): TAPIRPCheffServiceVendaPagamentoParcial; overload;
    function PagamentoAntecipado: TAPIRPCheffEntityVendaPagamentoAntecipado; overload;
    procedure Execute;
  end;

implementation

uses
  System.SysUtils,
  APIRPCheff.Service.Venda.Consulta,
  APIRPCheff.Context.Venda.PagamentoParcial,
  APIRPCheff.Service.Venda.PagamentoParcial.Command,
  APIRPCheff.Service.Venda.PagamentoParcial.Command.ProximoIdCaixaItem,
  APIRPCheff.Service.Venda.PagamentoParcial.Command.InserirCaixaItem,
  APIRPCheff.Service.Venda.PagamentoParcial.Command.InserirPagamentoAntecipados,
  APIRPCheff.Service.Venda.PagamentoParcial.Command.InserirPagamentoAntecipadoItens;

{ TAPIRPCheffServiceVendaPagamentoParcial }

function TAPIRPCheffServiceVendaPagamentoParcial.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaPagamentoParcial;
begin
  Result := Self;
  FDAO   := AValue;
end;

function TAPIRPCheffServiceVendaPagamentoParcial.DAO: TAPIRPCheffDAOFactory;
begin
  Result := FDAO;
end;

destructor TAPIRPCheffServiceVendaPagamentoParcial.Destroy;
begin
  inherited;
end;

procedure TAPIRPCheffServiceVendaPagamentoParcial.Execute;
var
  LInvoker            : TAPIRPCheffServiceVendaPagamentoParcialInvoker;
  LContext            : TAPIRPCheffContextVendaPagamentoParcial;
  LServiceConsultaVenda: TAPIRPCheffServiceVendaConsulta;
begin
  LContext := Default(TAPIRPCheffContextVendaPagamentoParcial);

  LServiceConsultaVenda := TAPIRPCheffServiceVendaConsulta.Create;
  try
    LServiceConsultaVenda.DAO(FDAO).AplicarTaxaServico(True);

    LContext.PagamentoAntecipado := FPagamentoAntecipado;
    LContext.Venda := nil;

    FDAO.VendaItemDAO.RatearTaxaGarcomPorItens(FPagamentoAntecipado.idVenda);
    LContext.Venda := LServiceConsultaVenda.Buscar(FPagamentoAntecipado.idVenda, True);

    try
      FPagamentoAntecipado.idCaixa := LContext.Venda.idCaixa;

      LInvoker := TAPIRPCheffServiceVendaPagamentoParcialInvoker.Create;
      try
        LInvoker
          .AddCommand(TAPIRPCheffServiceVendaPagamentoParcialCommandProximoIdCaixaItem.Create(Self))
          .AddCommand(TAPIRPCheffServiceVendaPagamentoParcialCommandInserirCaixaItem.Create(Self))
          .AddCommand(TAPIRPCheffServiceVendaPagamentoParcialCommandInserirPagamentoAntecipados.Create(Self))
          .AddCommand(TAPIRPCheffServiceVendaPagamentoParcialCommandInserirPagamentoAntecipadoItens.Create(Self))
          .Execute(@LContext);
      finally
        FreeAndNil(LInvoker);
      end;
    finally
      if Assigned(LContext.Venda) then
        LContext.Venda.Free;
    end;
  finally
    LServiceConsultaVenda.Free;
  end;
end;


function TAPIRPCheffServiceVendaPagamentoParcial.PagamentoAntecipado: TAPIRPCheffEntityVendaPagamentoAntecipado;
begin
 Result := FPagamentoAntecipado;
end;

function TAPIRPCheffServiceVendaPagamentoParcial.PagamentoAntecipado(AValue: TAPIRPCheffEntityVendaPagamentoAntecipado): TAPIRPCheffServiceVendaPagamentoParcial;
begin
  FPagamentoAntecipado := AValue;
  Result            := Self;
end;

end.

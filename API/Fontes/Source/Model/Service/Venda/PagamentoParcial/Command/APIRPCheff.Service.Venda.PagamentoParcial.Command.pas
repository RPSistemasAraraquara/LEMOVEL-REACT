unit APIRPCheff.Service.Venda.PagamentoParcial.Command;

interface

uses
  System.Generics.Collections,
  APIRPCheff.Service.Venda.PagamentoParcial,
  APIRPCheff.Context.Venda.PagamentoParcial;

type
  TAPIRPCheffServiceVendaPagamentoParcialCommand = class
  protected
    FParent: TAPIRPCheffServiceVendaPagamentoParcial;
  public
    constructor Create(AParent: TAPIRPCheffServiceVendaPagamentoParcial);

    procedure Execute(const AContext: PAPIRPCheffContextVendaPagamentoParcial); virtual; abstract;
  end;

  TAPIRPCheffServiceVendaPagamentoParcialInvoker = class
  private
    FCommands: TObjectList<TAPIRPCheffServiceVendaPagamentoParcialCommand>;
  public
    constructor Create;
    destructor Destroy; override;

    function AddCommand(AValue: TAPIRPCheffServiceVendaPagamentoParcialCommand): TAPIRPCheffServiceVendaPagamentoParcialInvoker;
    procedure Execute(const AContext: PAPIRPCheffContextVendaPagamentoParcial);
  end;

implementation

{ TAPIRPCheffServiceVendaPagamentoParcialCommand }

constructor TAPIRPCheffServiceVendaPagamentoParcialCommand.Create(AParent: TAPIRPCheffServiceVendaPagamentoParcial);
begin
  inherited Create;
  FParent := AParent;
end;

{ TAPIRPCheffServiceVendaPagamentoParcialInvoker }

function TAPIRPCheffServiceVendaPagamentoParcialInvoker.AddCommand(
  AValue: TAPIRPCheffServiceVendaPagamentoParcialCommand
): TAPIRPCheffServiceVendaPagamentoParcialInvoker;
begin
  Result := Self;
  FCommands.Add(AValue);
end;

constructor TAPIRPCheffServiceVendaPagamentoParcialInvoker.Create;
begin
  inherited Create;
  FCommands := TObjectList<TAPIRPCheffServiceVendaPagamentoParcialCommand>.Create(True);
end;

destructor TAPIRPCheffServiceVendaPagamentoParcialInvoker.Destroy;
begin
  FCommands.Free;
  inherited;
end;

procedure TAPIRPCheffServiceVendaPagamentoParcialInvoker.Execute(const AContext: PAPIRPCheffContextVendaPagamentoParcial);
var
  LCommand: TAPIRPCheffServiceVendaPagamentoParcialCommand;
begin
  for LCommand in FCommands do
    LCommand.Execute(AContext);
end;

end.


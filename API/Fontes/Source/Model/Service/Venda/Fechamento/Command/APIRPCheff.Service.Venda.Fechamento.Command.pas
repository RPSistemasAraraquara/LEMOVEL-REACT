unit APIRPCheff.Service.Venda.Fechamento.Command;

interface

uses
  System.SysUtils,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Service.Venda.Fechamento,
  System.Generics.Collections,
  APIRPCheff.Context.Venda.Fechamento;

type
  TAPIRPCheffServiceVendaFechamentoCommand = class
  protected
    FParent:  TAPIRPCheffServiceVendaFechamento;
    FContext: PAPIRPCheffContextVendaFechamento;
  public
    constructor Create(AParent: TAPIRPCheffServiceVendaFechamento; const AContext: PAPIRPCheffContextVendaFechamento);

    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); virtual; abstract;
  end;

  TAPIRPCheffServiceVendaFechamentoInvoker = class
  private
    FCommands: TObjectList<TAPIRPCheffServiceVendaFechamentoCommand>;
  public
    constructor Create;
    destructor Destroy; override;

    function AddCommand(AValue: TAPIRPCheffServiceVendaFechamentoCommand): TAPIRPCheffServiceVendaFechamentoInvoker;
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento);
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoInvoker }

function TAPIRPCheffServiceVendaFechamentoInvoker.AddCommand(AValue: TAPIRPCheffServiceVendaFechamentoCommand): TAPIRPCheffServiceVendaFechamentoInvoker;
begin
  Result := Self;
  FCommands.Add(AValue);
end;

constructor TAPIRPCheffServiceVendaFechamentoInvoker.Create;
begin
  FCommands := TObjectList<TAPIRPCheffServiceVendaFechamentoCommand>.Create;
end;

destructor TAPIRPCheffServiceVendaFechamentoInvoker.Destroy;
begin
  FreeAndNil(FCommands);
  inherited;
end;

procedure TAPIRPCheffServiceVendaFechamentoInvoker.Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LCommand: TAPIRPCheffServiceVendaFechamentoCommand;
  I: Integer;
begin
  for I := 0 to Pred(FCommands.Count) do
  begin
    LCommand := FCommands[I];
    LCommand.Execute(AFechamento);
  end;
end;

{ TAPIRPCheffServiceVendaFechamentoCommand }

constructor TAPIRPCheffServiceVendaFechamentoCommand.Create(AParent: TAPIRPCheffServiceVendaFechamento; const AContext: PAPIRPCheffContextVendaFechamento);
begin
  FParent  := AParent;
  FContext :=  AContext;
end;

end.

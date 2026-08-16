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

// Diagnostico do fechamento (Bin\fechamento.log); disponivel para os commands
// detalharem passos internos.
procedure LogFechamento(const AMensagem: string);

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SyncObjs;

var
  LogFechamentoLock: TCriticalSection;

// Registra cada comando em Bin\fechamento.log para identificar travamentos
// (thread fica "idle in transaction" sem SQL). Falha de log nunca derruba o
// fechamento.
procedure LogFechamento(const AMensagem: string);
begin
  try
    LogFechamentoLock.Enter;
    try
      TFile.AppendAllText(ExtractFilePath(ParamStr(0)) + 'fechamento.log',
        FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' [thread ' +
        IntToStr(TThread.Current.ThreadID) + '] ' + AMensagem + sLineBreak,
        TEncoding.ANSI);
    finally
      LogFechamentoLock.Leave;
    end;
  except
  end;
end;

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
    LogFechamento(Format('venda %d comando %d/%d %s inicio',
      [AFechamento.idVenda, I + 1, FCommands.Count, LCommand.ClassName]));
    LCommand.Execute(AFechamento);
    LogFechamento(Format('venda %d comando %d/%d %s fim',
      [AFechamento.idVenda, I + 1, FCommands.Count, LCommand.ClassName]));
  end;
end;

{ TAPIRPCheffServiceVendaFechamentoCommand }

constructor TAPIRPCheffServiceVendaFechamentoCommand.Create(AParent: TAPIRPCheffServiceVendaFechamento; const AContext: PAPIRPCheffContextVendaFechamento);
begin
  FParent  := AParent;
  FContext :=  AContext;
end;

initialization
  LogFechamentoLock := TCriticalSection.Create;

finalization
  LogFechamentoLock.Free;

end.

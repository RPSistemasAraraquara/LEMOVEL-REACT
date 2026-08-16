unit PoolManager;

interface

{
  By Carlos Modesto
  https://github.com/CarlosHe/pool-manager
}

uses
  System.SyncObjs,
  System.Generics.Collections,
  System.Classes,
  System.SysUtils;

type
  TPoolItem<T: class> = class
  private
    FMultiReadExclusiveWriteSynchronizer: TMultiReadExclusiveWriteSynchronizer;
    FInstance: T;
    FRefCount: Integer;
    FIdleTime: TDateTime;
    FInstanceOwner: Boolean;
  public
    function GetRefCount: Integer;
    function IsIdle(out AIdleTime: TDateTime): Boolean;
    function Acquire: T;
    // Aquisicao atomica: incrementa o RefCount SOMENTE se ainda houver vaga.
    // Usada pelo TryGetItem para que selecao e aquisicao sejam uma operacao
    // unica - sem isso, duas threads podem levar o mesmo item (mesma conexao).
    function TryAcquire(AMaxRefCount: Integer): Boolean;
    // Leitura da instancia SEM incrementar o RefCount (o item ja vem
    // adquirido do TryGetItem).
    function Instance: T;
    procedure Release;
    constructor Create(AInstance: T; const AInstanceOwner: Boolean = True);
    destructor Destroy; override;
  end;

  TPoolManager<T: class> = class(TThread)
  private
    { private declarations }
    FMultiReadExclusiveWriteSynchronizer: TMultiReadExclusiveWriteSynchronizer;
    FEvent: TEvent;
    FPoolItemList: TObjectList<TPoolItem<T>>;
    FMaxRefCountPerItem: Integer;
    FMaxIdleSeconds: Int64;
    FMinPoolCount: Integer;
  protected
    { protected declarations }
    procedure FreeInternalInternalInstances;
    procedure DoReleaseItems;
  public
    { public declarations }
    procedure DoGetInstance(var AInstance: T; var AInstanceOwner: Boolean); virtual; abstract;
    procedure SetMaxRefCountPerItem(AMaxRefCountPerItem: Integer);
    procedure SetMaxIdleSeconds(AMaxIdleSeconds: Int64);
    procedure SetMinPoolCount(AMinPoolCount: Integer);
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Execute; override;
    function TryGetItem: TPoolItem<T>;
  end;

implementation

uses
  System.DateUtils;

{ TPoolItem<T> }

function TPoolItem<T>.Acquire: T;
begin
  FMultiReadExclusiveWriteSynchronizer.BeginWrite;
  try
    TInterlocked.Increment(FRefCount);
    Result := FInstance;
  finally
    FMultiReadExclusiveWriteSynchronizer.EndWrite
  end;
end;

function TPoolItem<T>.TryAcquire(AMaxRefCount: Integer): Boolean;
begin
  FMultiReadExclusiveWriteSynchronizer.BeginWrite;
  try
    Result := FRefCount < AMaxRefCount;
    if Result then
      Inc(FRefCount);
  finally
    FMultiReadExclusiveWriteSynchronizer.EndWrite;
  end;
end;

function TPoolItem<T>.Instance: T;
begin
  FMultiReadExclusiveWriteSynchronizer.BeginRead;
  try
    Result := FInstance;
  finally
    FMultiReadExclusiveWriteSynchronizer.EndRead;
  end;
end;

constructor TPoolItem<T>.Create(AInstance: T; const AInstanceOwner: Boolean = True);
begin
  FMultiReadExclusiveWriteSynchronizer := TMultiReadExclusiveWriteSynchronizer.Create;
  FInstance := AInstance;
  FInstanceOwner := AInstanceOwner;
  FIdleTime := Now();
end;

destructor TPoolItem<T>.Destroy;
begin
  if FInstanceOwner then
    FInstance.Free;
  FMultiReadExclusiveWriteSynchronizer.Free;
  inherited;
end;

function TPoolItem<T>.GetRefCount: Integer;
begin
  FMultiReadExclusiveWriteSynchronizer.BeginRead;
  try
    Result := FRefCount;
  finally
    FMultiReadExclusiveWriteSynchronizer.EndRead;
  end;
end;

function TPoolItem<T>.IsIdle(out AIdleTime: TDateTime): Boolean;
begin
  FMultiReadExclusiveWriteSynchronizer.BeginRead;
  try
    Result := FRefCount = 0;
    if Result then
      AIdleTime := FIdleTime;
  finally
    FMultiReadExclusiveWriteSynchronizer.EndRead;
  end;
end;

procedure TPoolItem<T>.Release;
begin
  FMultiReadExclusiveWriteSynchronizer.BeginWrite;
  try
    if FRefCount > 0 then
      TInterlocked.Decrement(FRefCount);
    if FRefCount = 0 then
      FIdleTime := Now;
  finally
    FMultiReadExclusiveWriteSynchronizer.EndWrite;
  end;
end;

{ TPoolManager<T> }

function TPoolManager<T>.TryGetItem: TPoolItem<T>;
var
  I: Integer;
  LPoolItem: TPoolItem<T>;
  LInstance: T;
  LInstanceOwner: Boolean;
begin
  Result := nil;
  FMultiReadExclusiveWriteSynchronizer.BeginWrite;
  try
    for I := 0 to Pred(FPoolItemList.Count) do
    begin
      // Selecao + aquisicao ATOMICAS (TryAcquire incrementa o RefCount sob o
      // lock do item): sem isso duas threads levavam o MESMO item com
      // RefCount=0 e usavam a mesma conexao simultaneamente.
      if FPoolItemList.Items[I].TryAcquire(FMaxRefCountPerItem) then
      begin
        Result := FPoolItemList.Items[I];
        Break;
      end;
    end;
    if Result = nil then
    begin
      LInstance := nil;
      LInstanceOwner := False;
      // Sem try/finally aqui de proposito: se DoGetInstance falhar (banco
      // fora do ar), NENHUM item meio-construido pode entrar na lista -
      // um item com conexao nil envenenaria o pool ate reiniciar a API.
      DoGetInstance(LInstance, LInstanceOwner);
      if LInstance <> nil then
      begin
        LPoolItem := TPoolItem<T>.Create(LInstance, LInstanceOwner);
        LPoolItem.TryAcquire(FMaxRefCountPerItem);
        Result := LPoolItem;
        FPoolItemList.Add(LPoolItem);
      end;
    end;
  finally
    FMultiReadExclusiveWriteSynchronizer.EndWrite;
  end;
end;

procedure TPoolManager<T>.AfterConstruction;
begin
  inherited;
  FreeOnTerminate := False;
  FMinPoolCount := 0;
  FMaxRefCountPerItem := 1;
  FMaxIdleSeconds := 60;
  FEvent := TEvent.Create;
  FPoolItemList := TObjectList < TPoolItem < T >>.Create;
  FMultiReadExclusiveWriteSynchronizer := TMultiReadExclusiveWriteSynchronizer.Create;
end;

procedure TPoolManager<T>.BeforeDestruction;
begin
  Terminate;
  FEvent.SetEvent;
  WaitFor;
  FreeInternalInternalInstances;
  inherited;
end;

procedure TPoolManager<T>.DoReleaseItems;
var
  I: Integer;
  LIdleTime: TDateTime;
begin
  FMultiReadExclusiveWriteSynchronizer.BeginWrite;
  try
    for I := Pred(FPoolItemList.Count) downto 0 do
    begin
      if CheckTerminated then
        Break;
      if (FPoolItemList.Items[I].IsIdle(LIdleTime)) and (FPoolItemList.Count > FMinPoolCount) then
      begin
        if SecondsBetween(Now, LIdleTime) >= FMaxIdleSeconds then
        begin
          FPoolItemList.Delete(I);
        end;
      end;
    end;
  finally
    FMultiReadExclusiveWriteSynchronizer.EndWrite;
  end;
end;

procedure TPoolManager<T>.Execute;
var
  LWaitResult: TWaitResult;
begin
  inherited;
  while not CheckTerminated do
  begin
    try
      LWaitResult := FEvent.WaitFor(100);
      if CheckTerminated then
        Exit;
      if LWaitResult = wrTimeout then
        DoReleaseItems;
      if LWaitResult = wrSignaled then
        Break;
    except
      continue;
    end;
  end;
end;

procedure TPoolManager<T>.FreeInternalInternalInstances;
begin
  FPoolItemList.Free;
  FEvent.Free;
  FMultiReadExclusiveWriteSynchronizer.Free;
end;

procedure TPoolManager<T>.SetMaxIdleSeconds(AMaxIdleSeconds: Int64);
begin
  FMaxIdleSeconds := AMaxIdleSeconds;
end;

procedure TPoolManager<T>.SetMaxRefCountPerItem(AMaxRefCountPerItem: Integer);
begin
  FMaxRefCountPerItem := AMaxRefCountPerItem;
end;

procedure TPoolManager<T>.SetMinPoolCount(AMinPoolCount: Integer);
begin
  FMinPoolCount := AMinPoolCount;
end;

end.


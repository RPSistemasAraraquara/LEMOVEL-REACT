unit RPNFe.DAO.Base;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB,
  ADRConn.Model.Interfaces,
  ADRConn.DAO.Base,
  RPNFe.Components,
  RPNFe.Entity.Classes;

type
  TRPNFeDAOBase<T: class, constructor> = class(TInterfacedObject)
  private
    FComponents: TRPNFeComponents;
    FQuery: IADRQuery;
    FManagerTransaction: Boolean;
  protected
    function DataSetToList(ADataSet: TDataSet): TObjectList<T>;
    function DataSetToEntity(ADataSet: TDataSet): T; virtual;
    function OpenQueryToEntity: T;
    function OpenQueryToList: TObjectList<T>;

    function Query: IADRQuery;

    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;

    function ManagerTransaction: Boolean; overload;
  public
    constructor Create(AComponents: TRPNFeComponents);

    procedure ManagerTransaction(AValue: Boolean); overload;
  end;

implementation

{ TRPNFeDAOBase<T> }

procedure TRPNFeDAOBase<T>.Commit;
begin
  if FManagerTransaction then
    FComponents.Connection.GetConnection.Commit;
end;

constructor TRPNFeDAOBase<T>.Create(AComponents: TRPNFeComponents);
begin
  FComponents := AComponents;
end;

function TRPNFeDAOBase<T>.DataSetToEntity(ADataSet: TDataSet): T;
begin
  Result := nil;
end;

function TRPNFeDAOBase<T>.DataSetToList(ADataSet: TDataSet): TObjectList<T>;
begin
  Result := TObjectList<T>.Create;
  try
    ADataSet.First;
    while not ADataSet.Eof do
    begin
      Result.Add(DataSetToEntity(ADataSet));
      ADataSet.Next;
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TRPNFeDAOBase<T>.ManagerTransaction(AValue: Boolean);
begin
  FManagerTransaction := AValue;
end;

function TRPNFeDAOBase<T>.OpenQueryToEntity: T;
var
  LDataSet: TDataSet;
begin
  LDataSet := Query.OpenDataSet;
  try
    Result := DataSetToEntity(LDataSet);
  finally
    LDataSet.Free;
  end;
end;

function TRPNFeDAOBase<T>.OpenQueryToList: TObjectList<T>;
var
  LDataSet: TDataSet;
begin
  LDataSet := Query.OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    LDataSet.Free;
  end;
end;

function TRPNFeDAOBase<T>.Query: IADRQuery;
begin
  if not Assigned(FQuery) then
    FQuery := FComponents.Connection.GetQuery;
  Result := FQuery;
end;

function TRPNFeDAOBase<T>.ManagerTransaction: Boolean;
begin
  Result := FManagerTransaction;
end;

procedure TRPNFeDAOBase<T>.Rollback;
begin
  if FManagerTransaction then
    FComponents.Connection.GetConnection.Rollback;
end;

procedure TRPNFeDAOBase<T>.StartTransaction;
begin
  if FManagerTransaction then
    FComponents.Connection.GetConnection.StartTransaction;
end;

end.

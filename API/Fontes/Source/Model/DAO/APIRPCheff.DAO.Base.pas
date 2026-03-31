unit APIRPCheff.DAO.Base;

interface

uses
  ADRConn.Model.Interfaces,
  ADRConn.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils,
  System.Generics.Collections;

type
  TAPIRPCheffDAOBase<T: class, constructor> = class(TADRConnDAOBase)
  private
    FFactory: TObject;
  protected
    FIdEmpresa: Integer;

    function Query: IADRQuery;
    function FactoryDAO: TObject;

    function DataSetToList(ADataSet: TDataSet): TObjectList<T>; virtual;
    function DataSetToEntity(ADataSet: TDataSet): T; virtual; abstract;

    function ProximoId(AIdEmpresa: Integer; ATabela, ACampo: string; ACampoEmpresa: string = 'ed_empresa'): Integer;
  public
    constructor Create(AConnection: IADRConnection);
    destructor Destroy; override;

    function IdEmpresa(AValue: Integer): TAPIRPCheffDAOBase<T>;
    procedure ManagerTransaction(AValue: Boolean);
  end;

implementation

{ TAPIRPCheffDAOBase<T> }

uses
  APIRPCheff.DAO.Factory;

constructor TAPIRPCheffDAOBase<T>.Create(AConnection: IADRConnection);
begin
  inherited;
  FIdEmpresa := 1;
end;

function TAPIRPCheffDAOBase<T>.DataSetToList(ADataSet: TDataSet): TObjectList<T>;
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

destructor TAPIRPCheffDAOBase<T>.Destroy;
begin
  FreeAndNil(FFactory);
  inherited;
end;

function TAPIRPCheffDAOBase<T>.FactoryDAO: TObject;
begin
  if not Assigned(FFactory) then
  begin
    FFactory := TAPIRPCheffDAOFactory.Create(FConnection);
    TAPIRPCheffDAOFactory(FFactory).IdEmpresa(FIdEmpresa);
  end;
  Result := FFactory;
end;

function TAPIRPCheffDAOBase<T>.IdEmpresa(AValue: Integer): TAPIRPCheffDAOBase<T>;
begin
  Result := Self;
  FIdEmpresa := AValue;
end;

procedure TAPIRPCheffDAOBase<T>.ManagerTransaction(AValue: Boolean);
begin
  inherited ManagerTransaction(AValue);
end;

function TAPIRPCheffDAOBase<T>.ProximoId(AIdEmpresa: Integer; ATabela, ACampo: string; ACampoEmpresa: string = 'ed_empresa'): Integer;
begin
  Query.SQL('select (coalesce(max(%s),0) + 1) as proximoId ', [ACampo])
    .SQL('from %s where %s = :idEmpresa', [ATabela, ACampoEmpresa])
    .ParamAsInteger('idEmpresa', AIdEmpresa)
    .Open;

  Result := Query.DataSet.FieldByName('proximoId').AsInteger;
end;

function TAPIRPCheffDAOBase<T>.Query: IADRQuery;
begin
  Result := FQuery;
end;

end.

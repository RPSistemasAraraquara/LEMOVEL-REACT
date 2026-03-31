unit APIRPCheff.DAO.Categoria;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils,
  System.Generics.Collections;

type
  TAPIRPCheffDAOCategoria = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityCategoria>)
  private
    procedure SelectCategorias;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityCategoria; override;
  public
    function Lista: TObjectList<TAPIRPCheffEntityCategoria>;
  end;

implementation

{ TAPIRPCheffDAOCategoria }

function TAPIRPCheffDAOCategoria.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityCategoria;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityCategoria.Create;
    try
      Result.idCategoria := ADataSet.FieldByName('cat_001').AsInteger;
      Result.idEmpresa := ADataSet.FieldByName('emp_001').AsInteger;
      Result.descricao := ADataSet.FieldByName('cat_002').AsString;
      Result.PermiteVendaAPP:= ADataSet.FieldByName('b_exibir_mobile').AsBoolean;
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TAPIRPCheffDAOCategoria.Lista: TObjectList<TAPIRPCheffEntityCategoria>;
begin
  SelectCategorias;
  FQuery.SQL('where emp_001 = :idEmpresa')
    .SQL('and sit_001 = 4')
    .SQL('and b_exibir_mobile=true')
    .SQL('order by cat_002')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .Open;

  Result := DataSetToList(FQuery.DataSet);
end;

procedure TAPIRPCheffDAOCategoria.SelectCategorias;
begin
  FQuery.SQL('select emp_001, cat_001, cat_002,b_exibir_mobile from categoria');
end;

end.

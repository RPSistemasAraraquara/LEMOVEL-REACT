unit APIRPCheff.DAO.SetorEstoqueOpcional;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils;

type
  TAPIRPCheffDAOSetorEstoqueOpcional = class  (TAPIRPCheffDAOBase<TAPIRPCheffEntitySetorEstoqueOpcional>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet):TAPIRPCheffEntitySetorEstoqueOpcional;
  public
    procedure Inserir(AValue:TAPIRPCheffEntitySetorEstoqueOpcional);
    procedure Alterar(AValue:TAPIRPCheffEntitySetorEstoqueOpcional);
    function Buscar(AIdOpcional,AidSetor:Integer):TAPIRPCheffEntitySetorEstoqueOpcional;

  end;

implementation

{ TAPIRPCheffDAOSetorEstoqueOpcional }

procedure TAPIRPCheffDAOSetorEstoqueOpcional.Alterar(AValue: TAPIRPCheffEntitySetorEstoqueOpcional);
begin
  try
    Query.SQL('update setor_estoque_opcional set quantidade =:quantidade where id_opcional =:id_opcional and id_setor =:id_setor and id_empresa =:id_empresa')
    .ParamAsCurrency('quantidade', AValue.quantidade)
    .ParamAsInteger('id_opcional', AValue.idOpcional)
    .ParamAsInteger('id_setor', AValue.idSetor)
    .ParamAsInteger('id_empresa',1)
    .ExecSQL;
  except
    Rollback;
    raise;
  end;
end;

function TAPIRPCheffDAOSetorEstoqueOpcional.Buscar(AIdOpcional,AidSetor: Integer): TAPIRPCheffEntitySetorEstoqueOpcional;
var
LDataSet:TDataSet;
begin
  Select;
  LDataSet :=Query.SQL('where id_opcional =:id_opcional and id_setor =:id_setor and id_empresa =:id_empresa ')
  .ParamAsInteger('id_opcional', AIdOpcional)
  .ParamAsInteger('id_setor', AidSetor)
  .ParamAsInteger('id_empresa', FIdEmpresa)
  .OpenDataSet;
  try
    Result:=DataSetToEntity(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOSetorEstoqueOpcional.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntitySetorEstoqueOpcional;
begin
  Result :=nil;
  if ADataSet.RecordCount>0 then
  begin
    Result:=TAPIRPCheffEntitySetorEstoqueOpcional.Create;
    try
      Result.idOpcional       :=ADataSet.FieldByName('id_opcional').AsInteger;
      Result.idSetor          :=ADataSet.FieldByName('Id_setor').AsInteger;
      Result.idEmpresa        :=ADataSet.FieldByName('id_empresa').AsInteger;
      Result.quantidade       :=ADataSet.FieldByName('quantidade').AsCurrency;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffDAOSetorEstoqueOpcional.Inserir(AValue: TAPIRPCheffEntitySetorEstoqueOpcional);
begin
  try
    Query.SQL('insert into setor_estoque_opcional (               ')
      .SQL('  id_empresa, id_opcional, id_setor, quantidade)      ')
      .SQL('  values (                                            ')
      .SQL('  :id_empresa, :id_opcional, :id_setor, :quantidade)  ')
      .ParamAsCurrency('quantidade', AValue.quantidade)
      .ParamAsInteger('id_opcional', AValue.idOpcional)
      .ParamAsInteger('id_setor', AValue.idSetor)
      .ParamAsInteger('id_empresa', AValue.idEmpresa)
      .ExecSQL;
  except
    Rollback;
    raise
  end;
end;

procedure TAPIRPCheffDAOSetorEstoqueOpcional.Select;
begin
  Query.SQL('select id_opcional,id_setor,id_empresa, coalesce(quantidade,0)as quantidade from setor_estoque_opcional');
end;

end.

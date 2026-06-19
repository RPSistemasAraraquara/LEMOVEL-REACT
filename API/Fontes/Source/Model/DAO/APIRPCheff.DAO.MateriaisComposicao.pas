unit APIRPCheff.DAO.MateriaisComposicao;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.Generics.Collections,
  System.SysUtils;

type
  TAPIRPCheffDAOMateriaisComposicao = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityMateriaisComposicao>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityMateriaisComposicao; override;
  public
    function Listar(AIdMaterial: Integer): TObjectList<TAPIRPCheffEntityMateriaisComposicao>;
  end;

implementation

{ TAPIRPCheffDAOMateriaisComposicao }

function TAPIRPCheffDAOMateriaisComposicao.DataSetToEntity(
  ADataSet: TDataSet): TAPIRPCheffEntityMateriaisComposicao;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityMateriaisComposicao.Create;
    try
      Result.idEmpresa                       := ADataSet.FieldByName('id_empresa').AsInteger;
      Result.idMaterial                      := ADataSet.FieldByName('id_material').AsInteger;
      Result.idComposicao                    := ADataSet.FieldByName('id_composicao').AsInteger;
      Result.quantidade                      := ADataSet.FieldByName('quantidade').AsCurrency;
      Result.composicao.descricao            := ADataSet.FieldByName('descricao').AsString;
      Result.composicao.valorCusto           := ADataSet.FieldByName('valor_custo').AsCurrency;
      Result.composicao.estoqueMinimo        := ADataSet.FieldByName('estoque_minimo').AsCurrency;
      Result.composicao.rendimento           := ADataSet.FieldByName('rendimento').AsCurrency;
      Result.composicao.codigoRef            := ADataSet.FieldByName('codigo_ref').AsString;
      Result.composicao.idSetor              := ADataSet.FieldByName('id_setor').AsInteger;
      Result.composicao.baixarSetorPrincipal := ADataSet.FieldByName('b_baixar_setor_princ').AsBoolean;
      Result.composicao.idEmpresa            := Result.idEmpresa;
      Result.composicao.idComposicao         := Result.idComposicao;
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TAPIRPCheffDAOMateriaisComposicao.Listar(AIdMaterial: Integer): TObjectList<TAPIRPCheffEntityMateriaisComposicao>;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL('where materiais_composicao.id_empresa = :idEmpresa')
    .SQL('and materiais_composicao.id_material = :idMaterial')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idMaterial', AIdMaterial)
    .OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

procedure TAPIRPCheffDAOMateriaisComposicao.Select;
begin
  Query.SQL('select materiais_composicao.id_empresa, materiais_composicao.id_material,')
    .SQL('  materiais_composicao.quantidade, materiais_composicao.id_composicao,')
    .SQL('  composicao.descricao, composicao.valor_custo, composicao.estoque_minimo,')
    .SQL('  composicao.rendimento, composicao.codigo_ref, composicao.id_setor,')
    .SQL('  composicao.b_baixar_setor_princ, composicao.id_unidade, composicao.id_situacao')
    .SQL('from materiais_composicao')
    .SQL('join composicao on materiais_composicao.id_composicao = composicao.id_composicao')
    .SQL('  and materiais_composicao.id_empresa = composicao.id_empresa');
end;

end.

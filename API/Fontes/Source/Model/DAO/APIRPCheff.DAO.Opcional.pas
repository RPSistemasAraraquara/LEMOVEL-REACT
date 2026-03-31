unit APIRPCheff.DAO.Opcional;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  Data.DB,
  System.SysUtils,
  System.Generics.Collections;

type
  TAPIRPCheffDAOOpcional = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityOpcional>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityOpcional; override;
  public
    function Lista(AIdProduto: Integer): TObjectList<TAPIRPCheffEntityOpcional>; overload;
     function Buscar(AidProduto: Integer): TAPIRPCheffEntityOpcional;overload;
  end;

implementation

{ TAPIRPCheffDAOOpcional }

function TAPIRPCheffDAOOpcional.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityOpcional;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityOpcional.Create;
    try
      Result.idOpcional                 := ADataSet.FieldByName('id_opcional').AsInteger;
      Result.idEmpresa                  := ADataSet.FieldByName('id_empresa').AsInteger;
      Result.descricao                  := ADataSet.FieldByName('descricao').AsString;
      Result.valor                      := ADataSet.FieldByName('valor').AsCurrency;
      Result.opcionalP                  := ADataSet.FieldByName('opc_p').AsString;
      Result.opcionalM                  := ADataSet.FieldByName('opc_m').AsString;
      Result.opcionalG                  := ADataSet.FieldByName('opc_g').AsString;
      Result.opcionalGG                 := ADataSet.FieldByName('opc_gg').AsString;
      Result.opcionalExtra              := ADataSet.FieldByName('opc_extra').AsString;
      Result.valorOpcionalP             := ADataSet.FieldByName('valor_opc_p').AsCurrency;
      Result.valorOpcionalM             := ADataSet.FieldByName('valor_opc_m').AsCurrency;
      Result.valorOpcionalG             := ADataSet.FieldByName('valor_opc_g').AsCurrency;
      Result.valorOpcionalGG            := ADataSet.FieldByName('valor_opc_gg').AsCurrency;
      Result.valorOpcionalExtra         := ADataSet.FieldByName('valor_opc_extra').AsCurrency;
      Result.idsetor                    := ADataSet.FieldByName('id_setor').AsInteger;
      Result.ValorCusto                 := ADataSet.FieldByName('valor_custo').AsCurrency;
      Result.tipo.FromDBValue(ADataSet.FieldByName('tipo').AsInteger);
    except
      Result.Free;
      raise;
    end;
  end;
end;

function  TAPIRPCheffDAOOpcional.Buscar(AidProduto:Integer): TAPIRPCheffEntityOpcional;
var
  LDataSet: TDataSet;
begin
  Select;
  Query.SQL(' where id_opcional =:idProduto and id_empresa =:idEmpresa  ')
  .ParamAsInteger('idProduto', AIdProduto)
   .ParamAsInteger('idEmpresa', FIdEmpresa);
  LDataSet := Query.OpenDataSet;
  try
    Result := DataSetToEntity(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;


function TAPIRPCheffDAOOpcional.Lista(AIdProduto: Integer): TObjectList<TAPIRPCheffEntityOpcional>;
var
  LDataSet: TDataSet;
begin
  Select;
  Query.SQL('join materiais_opcional on opcional.id_opcional = materiais_opcional.id_opcional')
    .SQL('and opcional.id_empresa = materiais_opcional.id_empresa')
    .SQL('where opcional.id_empresa = :idEmpresa')
    .SQL('and materiais_opcional.id_material = :idProduto')
    .SQL('and opcional.id_situacao = 4')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idProduto', AIdProduto);
  LDataSet := Query.OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

procedure TAPIRPCheffDAOOpcional.Select;
begin
  Query.SQL('select opcional.id_opcional, opcional.id_empresa,opcional.valor_custo,  ')
    .SQL(' opcional.descricao, opcional.valor, opcional.opc_p,opcional.opc_m,        ')
    .SQL(' opcional.opc_g, opcional.opc_gg, opcional.opc_extra,opcional.id_setor,    ')
    .SQL(' opcional.valor_opc_p, opcional.valor_opc_m, opcional.valor_opc_g,         ')
    .SQL(' opcional.valor_opc_gg, opcional.valor_opc_extra,opcional.tipo             ')
    .SQL(' from opcional');
end;

end.

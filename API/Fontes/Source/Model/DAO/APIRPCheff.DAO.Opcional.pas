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
    procedure Select(const AIncludeProductId: Boolean = False);
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityOpcional; override;
  public
    function Lista(AIdProduto: Integer): TObjectList<TAPIRPCheffEntityOpcional>; overload;
    function ListaPorProdutos(const AIdsProduto: TArray<Integer>): TDictionary<Integer, TObjectList<TAPIRPCheffEntityOpcional>>;
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

function TAPIRPCheffDAOOpcional.ListaPorProdutos(
  const AIdsProduto: TArray<Integer>): TDictionary<Integer, TObjectList<TAPIRPCheffEntityOpcional>>;
var
  LDataSet: TDataSet;
  LIdProduto: Integer;
  LLista: TObjectList<TAPIRPCheffEntityOpcional>;
  LOpcional: TAPIRPCheffEntityOpcional;
  LPair: TPair<Integer, TObjectList<TAPIRPCheffEntityOpcional>>;
  LInClause: string;
  I: Integer;
begin
  Result := TDictionary<Integer, TObjectList<TAPIRPCheffEntityOpcional>>.Create;
  if Length(AIdsProduto) = 0 then
    Exit;

  LInClause := '';
  for I := Low(AIdsProduto) to High(AIdsProduto) do
  begin
    if LInClause <> '' then
      LInClause := LInClause + ', ';
    LInClause := LInClause + ':idProduto' + IntToStr(I);
  end;

  try
    Select(True);
    Query.SQL('join materiais_opcional on opcional.id_opcional = materiais_opcional.id_opcional')
      .SQL('and opcional.id_empresa = materiais_opcional.id_empresa')
      .SQL('where opcional.id_empresa = :idEmpresa')
      .SQL('and materiais_opcional.id_material in (' + LInClause + ')')
      .SQL('and opcional.id_situacao = 4')
      .ParamAsInteger('idEmpresa', FIdEmpresa);
    for I := Low(AIdsProduto) to High(AIdsProduto) do
      Query.ParamAsInteger('idProduto' + IntToStr(I), AIdsProduto[I]);

    LDataSet := Query.OpenDataSet;
    try
      LDataSet.First;
      while not LDataSet.Eof do
      begin
        LIdProduto := LDataSet.FieldByName('id_material_relacao').AsInteger;
        LOpcional := DataSetToEntity(LDataSet);
        if not Result.TryGetValue(LIdProduto, LLista) then
        begin
          LLista := TObjectList<TAPIRPCheffEntityOpcional>.Create(True);
          Result.Add(LIdProduto, LLista);
        end;

        LLista.Add(LOpcional);
        LDataSet.Next;
      end;
    finally
      FreeAndNil(LDataSet);
    end;
  except
    for LPair in Result do
      LPair.Value.Free;
    Result.Free;
    raise;
  end;
end;

procedure TAPIRPCheffDAOOpcional.Select(const AIncludeProductId: Boolean);
begin
  if AIncludeProductId then
    Query.SQL('select materiais_opcional.id_material as id_material_relacao, ')
  else
    Query.SQL('select ');

  Query.SQL(' opcional.id_opcional, opcional.id_empresa,opcional.valor_custo,  ')
    .SQL(' opcional.descricao, opcional.valor, opcional.opc_p,opcional.opc_m,        ')
    .SQL(' opcional.opc_g, opcional.opc_gg, opcional.opc_extra,opcional.id_setor,    ')
    .SQL(' opcional.valor_opc_p, opcional.valor_opc_m, opcional.valor_opc_g,         ')
    .SQL(' opcional.valor_opc_gg, opcional.valor_opc_extra,opcional.tipo             ')
    .SQL(' from opcional');
end;

end.

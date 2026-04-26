unit APIRPCheff.DAO.VendaItemOpcional;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils,
  System.Generics.Collections;

type
  TAPIRPCheffDAOVendaItemOpcional = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityVendaItemOpcional>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityVendaItemOpcional; override;
  public
    function Listar(AIdVenda, AIdVendaItem: Integer): TObjectList<TAPIRPCheffEntityVendaItemOpcional>;
    procedure Inserir(AVendaItemOpcional: TAPIRPCheffEntityVendaItemOpcional);
    function ListarAgrupadoPorProduto(AIdVenda,ANumeroItem: Integer): TObjectList<TAPIRPCheffEntityVendaItemOpcional>;
    function ListarPorVenda(AidVenda:Integer): TObjectList<TAPIRPCheffEntityVendaItemOpcional>;
    function ListarTodosPorVenda(AidVenda:Integer): TObjectList<TAPIRPCheffEntityVendaItemOpcional>;
  end;

implementation

{ TAPIRPCheffDAOVendaItemOpcional }

function TAPIRPCheffDAOVendaItemOpcional.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityVendaItemOpcional;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityVendaItemOpcional.Create;
    try
      Result.idVenda      := ADataSet.FieldByName('id_venda').AsInteger;
      Result.idEmpresa    := ADataSet.FieldByName('id_empresa').AsInteger;
      Result.idVendaItem  := ADataSet.FieldByName('id_vendaitem').AsInteger;
      Result.idOpcional   := ADataSet.FieldByName('id_opcional').AsInteger;
      Result.descricao    := ADataSet.FieldByName('descricao').AsString;
      Result.gratis       := ADataSet.FieldByName('gratis').AsBoolean;
      Result.valor        := ADataSet.FieldByName('valor').AsCurrency;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffDAOVendaItemOpcional.Inserir(AVendaItemOpcional: TAPIRPCheffEntityVendaItemOpcional);
begin
  StartTransaction;
  try
    Query.SQL('insert into vendaitemopcional (')
      .SQL('  id_venda, id_empresa, id_vendaitem, id_opcional,')
      .SQL('  gratis, valor)')
      .SQL('values (')
      .SQL('  :id_venda, :id_empresa, :id_vendaitem, :id_opcional,')
      .SQL('  :gratis, :valor)')
      .ParamAsInteger('id_venda', AVendaItemOpcional.idVenda)
      .ParamAsInteger('id_empresa', AVendaItemOpcional.idEmpresa)
      .ParamAsInteger('id_vendaitem', AVendaItemOpcional.idVendaItem)
      .ParamAsInteger('id_opcional', AVendaItemOpcional.idOpcional)
      .ParamAsBoolean('gratis', AVendaItemOpcional.gratis)
      .ParamAsCurrency('valor', AVendaItemOpcional.valor)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

function TAPIRPCheffDAOVendaItemOpcional.Listar(AIdVenda, AIdVendaItem: Integer): TObjectList<TAPIRPCheffEntityVendaItemOpcional>;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL('where vendaitemopcional.id_empresa = :idEmpresa')
    .SQL('and vendaitemopcional.id_venda = :idVenda')
    .SQL('and vendaitemopcional.id_vendaitem = :idVendaItem')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda)
    .ParamAsInteger('idVendaItem', AIdVendaItem)
    .OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOVendaItemOpcional.ListarPorVenda(AidVenda: Integer): TObjectList<TAPIRPCheffEntityVendaItemOpcional>;
var
  LDataSet: TDataSet;
begin
 Select;
  LDataSet := Query.SQL(' left join vendaitem  on vendaitem.ven_001 = vendaitemopcional.id_venda and vendaitem.emp_001 = vendaitemopcional.id_empresa ')
                   .SQL(' and vendaitem.ite_001 = vendaitemopcional.id_vendaitem                                                                      ')
                   .SQL(' where vendaitemopcional.id_venda =:idVenda and vendaitemopcional.id_empresa =:idEmpresa and vendaitem.sit_001 = 4         ')
                   .SQL(' order by vendaitemopcional.id_vendaitem')
                   .ParamAsInteger('idEmpresa', FIdEmpresa)
                   .ParamAsInteger('idVenda', AIdVenda)
                   .OpenDataSet;
   try
      Result:=DataSetToList(LDataSet);
   finally
    FreeAndNil(LDataSet);
   end;

end;

function TAPIRPCheffDAOVendaItemOpcional.ListarTodosPorVenda(AidVenda: Integer): TObjectList<TAPIRPCheffEntityVendaItemOpcional>;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL(' where vendaitemopcional.id_venda = :idVenda and vendaitemopcional.id_empresa = :idEmpresa ')
                   .SQL(' order by vendaitemopcional.id_vendaitem')
                   .ParamAsInteger('idEmpresa', FIdEmpresa)
                   .ParamAsInteger('idVenda', AIdVenda)
                   .OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;


function TAPIRPCheffDAOVendaItemOpcional.ListarAgrupadoPorProduto(AIdVenda, ANumeroItem: Integer): TObjectList<TAPIRPCheffEntityVendaItemOpcional>;
var
  LDataSet: TDataSet;
begin
  LDataSet :=
  Query.SQL('SELECT id_venda, id_empresa, id_vendaitem, id_opcional, gratis, descricao, valor, ord FROM               ')
       .SQL('  (SELECT vio.id_venda, vio.id_empresa, vio.id_vendaitem, vio.id_opcional, vio.gratis,                   ')
       .SQL('   CASE WHEN (vi.ite_002 - TRUNC(vi.ite_002) = 0) THEN                                                   ')
       .SQL('   CASE WHEN vio.gratis = FALSE THEN                                                                     ')
       .SQL('   CONCAT(''OPC: '', TRIM(TO_CHAR(vi.ite_002, ''99999990D'')), '' x '', o.descricao,                     ')
       .SQL('   '' (R$ '', TRIM(TO_CHAR(vio.valor * vi.ite_002, ''99999990D99'')), '')'')                             ')
       .SQL('  ELSE                                                                                                   ')
       .SQL('  CONCAT(''OPC: '', TRIM(TO_CHAR(vi.ite_002, ''99999990D'')), '' x '', o.descricao, '' (gr'#225'tis)'')       ')
       .SQL('  END                                                                                                    ')
       .SQL('  ELSE                                                                                                   ')
       .SQL('  CASE WHEN vio.gratis = FALSE THEN                                                                      ')
       .SQL('  CONCAT(''OPC: '', TRIM(TO_CHAR(vi.ite_002, ''99999990D999'')), '' x '', o.descricao,                   ')
       .SQL('  '' (R$ '', TRIM(TO_CHAR(vio.valor * vi.ite_002, ''99999990D99'')), '')'')                              ')
       .SQL('  ELSE                                                                                                   ')
       .SQL('  CONCAT(''OPC: '', TRIM(TO_CHAR(vi.ite_002, ''99999990D999'')), '' x '', o.descricao, '' (gr'#225'tis)'')    ')
       .SQL('  END                                                                                                    ')
       .SQL('  END AS descricao,                                                                                      ')
       .SQL('  vio.valor * vi.ite_002 AS valor,                                                                       ')
       .SQL('  CASE o.tipo WHEN 0 THEN 9 ELSE o.tipo END AS ord                                                       ')
       .SQL('  FROM vendaitemopcional vio                                                                             ')
       .SQL('  JOIN opcional o ON o.id_opcional = vio.id_opcional AND o.id_empresa = vio.id_empresa                   ')
       .SQL('  JOIN vendaitem vi ON vio.id_venda = vi.ven_001 AND vio.id_empresa = vi.emp_001 AND vio.id_vendaitem = vi.ite_001 ')
       .SQL('  WHERE vio.id_venda = :id_venda AND vio.id_empresa = :id_empresa AND vi.ite_001 = :id_vendaitem         ')
       .SQL('  UNION ALL                                                                                              ')
       .SQL('  SELECT ITE.VEN_001 AS id_venda, ITE.EMP_001 AS id_empresa, ITE.ITE_001 AS id_vendaitem,                ')
       .SQL('  0 AS id_opcional, FALSE AS gratis,                                                                     ')
       .SQL('  CONCAT(''OBS: '', ITE.ITE_006) AS descricao, 0.00 AS valor, 0 AS ord                                   ')
       .SQL('  FROM VENDAITEM ITE                                                                                     ')
       .SQL('  WHERE ITE.EMP_001 = :id_empresa AND ITE.VEN_001 = :id_venda AND ITE.ITE_001 = :id_vendaitem            ')
       .SQL('  AND NOT ITE.sit_001 IN (0,1,2,3) AND NOT (ITE.ITE_006 IS NULL OR ITE.ITE_006 = '''')                   ')
       .SQL('  ) sub ORDER BY id_vendaitem, ord, descricao')

       .ParamAsInteger('id_empresa', FIdEmpresa)
       .ParamAsInteger('id_venda', AIdVenda)
       .ParamAsInteger('id_vendaitem', ANumeroItem)
       .OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

procedure TAPIRPCheffDAOVendaItemOpcional.Select;
begin
  Query.SQL('select vendaitemopcional.id_venda, vendaitemopcional.id_empresa,                       ')
    .SQL(' vendaitemopcional.id_vendaitem, vendaitemopcional.id_opcional, vendaitemopcional.gratis, ')
    .SQL(' vendaitemopcional.valor, opcional.descricao                                              ')
    .SQL(' from vendaitemopcional                                                                   ')
    .SQL(' join opcional on vendaitemopcional.id_opcional = opcional.id_opcional                    ');
end;

end.

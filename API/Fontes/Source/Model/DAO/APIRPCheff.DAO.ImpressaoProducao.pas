unit APIRPCheff.DAO.ImpressaoProducao;

interface

uses

  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils,
  System.Generics.Collections;

  type
    TAPIRPCheffDAOImpressaoProducao = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityImpressaoProducao>)
   private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityImpressaoProducao; override;
  public
    procedure Inserir(AImpressaoProducao:TAPIRPCheffEntityImpressaoProducao);
    function Listar(AIDProduto,AidVenda:Integer):TObjectList<TAPIRPCheffEntityImpressaoProducao>;
  end;

implementation

{ TAPIRPCheffDAOImpressaoProducao }

function TAPIRPCheffDAOImpressaoProducao.DataSetToEntity( ADataSet: TDataSet): TAPIRPCheffEntityImpressaoProducao;
begin
  Result:=nil;
  if ADataSet.RecordCount>0 then
  begin
    Result                                         :=TAPIRPCheffEntityImpressaoProducao.Create;
    try
      Result.IdProduto                             := ADataSet.FieldByName('idproduto').AsInteger;
      Result.IdEmpresa                             := ADataSet.FieldByName('idempresa').AsInteger;
      Result.QtdeVendido                           := ADataSet.FieldByName('qtdevendido').AsFloat;
      Result.DescricaoProduto                      := ADataSet.FieldByName('descricaoproduto').AsString;
      Result.DataLancamento                        := ADataSet.FieldByName('datalancamento').AsDateTime;
      Result.ProdutoFoiImpresso                    := ADataSet.FieldByName('produtoimpresso').AsBoolean;
      Result.NomeGarcom                            := ADataSet.FieldByName('nomegarcom').AsString;
      Result.QuantidadeImpressao                   := ADataSet.FieldByName('quantidadeviaimpressao').AsInteger;
      Result.IdVenda                               := ADataSet.FieldByName('idvenda').AsInteger;
      Result.TipoVenda                             := ADataSet.FieldByName('TipoVenda').AsString;
      Result.ImpressoraInterna                     := ADataSet.FieldByName('impressorainterna').AsBoolean;
    except
      Result.Free;
      raise
    end;
  end;
end;

procedure TAPIRPCheffDAOImpressaoProducao.Inserir(AImpressaoProducao: TAPIRPCheffEntityImpressaoProducao);
begin
  StartTransaction;
  try
    Query.SQL('INSERT INTO impressaoproducao(                                                                                  ')
       .SQL('	idproduto, idempresa, qtdevendido, descricaoproduto, datalancamento, produtoimpresso,                            ')
       .SQL(' nomegarcom, idvenda, tipovenda, quantidadeviaimpressao,impressorainterna)                                        ')
       .SQL('	VALUES (	:idproduto, :idempresa, :qtdevendido, :descricaoproduto, :datalancamento,                              ')
       .SQL(' :produtoimpresso, :nomegarcom, :idvenda, :tipovenda, :quantidadeviaimpressao, :impressorainterna)                ')
       .ParamAsInteger('idproduto', AImpressaoProducao.IdProduto)
       .ParamAsInteger('idempresa', AImpressaoProducao.IdEmpresa)
       .ParamAsFloat('qtdevendido', AImpressaoProducao.QtdeVendido)
       .ParamAsString('descricaoproduto', AImpressaoProducao.DescricaoProduto)
       .ParamAsDateTime('datalancamento',AImpressaoProducao.DataLancamento)
       .ParamAsBoolean('produtoimpresso',AImpressaoProducao.ProdutoFoiImpresso)
       .ParamAsString('nomegarcom', AImpressaoProducao.NomeGarcom)
       .ParamAsInteger('idvenda', AImpressaoProducao.IdVenda)
       .ParamAsString('tipovenda', AImpressaoProducao.TipoVenda)
       .ParamAsInteger('quantidadeviaimpressao', AImpressaoProducao.QuantidadeImpressao)
       .ParamAsBoolean('impressorainterna', AImpressaoProducao.ImpressoraInterna)
       .ExecSQL;
       Commit;
  except
    Rollback;
    raise
  end;
end;

function TAPIRPCheffDAOImpressaoProducao.Listar(AIDProduto,AidVenda: Integer): TObjectList<TAPIRPCheffEntityImpressaoProducao>;
var
LDataset:TDataSet;
begin
  Select;
  LDataSet := Query.SQL(' where  idproduto =:idproduto and idvenda =:idvenda and idempresa =:idempresa')
  .ParamAsInteger('idproduto', AIDProduto)
  .ParamAsInteger('idvenda', AidVenda)
  .ParamAsInteger('idEmpresa', FIdEmpresa)
  .OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;

end;

procedure TAPIRPCheffDAOImpressaoProducao.Select;
begin
  Query.SQL('  SELECT idproduto, idempresa, qtdevendido, descricaoproduto, datalancamento, produtoimpresso,        ')
       .SQL('  nomegarcom, quantidadeviaimpressao ,idvenda,TipoVenda,impressorainterna                             ')
       .SQL('  FROM impressaoproducao                                                                              ');
end;

end.



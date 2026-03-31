unit APIRPCheff.DAO.CatracaMobile;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  System.SysUtils;

type
  TAPIRPCheffDAOCatracaMobile = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityCatracaMobile>)
  public
    procedure Inserir(ACatraca: TAPIRPCheffEntityCatracaMobile);
  end;

implementation

{ TAPIRPCheffDAOCatracaMobile }

procedure TAPIRPCheffDAOCatracaMobile.Inserir(ACatraca: TAPIRPCheffEntityCatracaMobile);
begin
  ACatraca.id := Self.ProximoId(ACatraca.idEmpresa, 'catraca_mobile', 'id', 'id_empresa');
  StartTransaction;
  try
    Query.SQL('insert into catraca_mobile (')
      .SQL('id, comanda, id_empresa, comando, data)')
      .SQL('values (')
      .SQL(':id, :comanda, :id_empresa, :comando, :data)')
      .ParamAsInteger('id', ACatraca.id)
      .ParamAsInteger('comanda', ACatraca.idComanda)
      .ParamAsInteger('id_empresa', ACatraca.idEmpresa)
      .ParamAsString('comando', ACatraca.comando)
      .ParamAsDateTime('data', ACatraca.data)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

end.

unit APIRPCheff.DAO.Usuario;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.Generics.Collections,
  System.SysUtils;

type
  TAPIRPCheffDAOUsuario = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityUsuario>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityUsuario; override;
  public
    function List: TObjectList<TAPIRPCheffEntityUsuario>;
    function Busca(ALogin: string): TAPIRPCheffEntityUsuario; overload;
    function Busca(ALogin, ASenha: string): TAPIRPCheffEntityUsuario; overload;
    function Busca(AIdUsuario: Integer): TAPIRPCheffEntityUsuario; overload;
  end;

implementation

{ TAPIRPCheffDAOUsuario }

function TAPIRPCheffDAOUsuario.Busca(ALogin, ASenha: string): TAPIRPCheffEntityUsuario;
begin
  Select;
  Query.SQL('where emp_001 = :idEmpresa')
    .SQL('and trim(upper(usu_003)) = trim(upper(:usuario))')
    .SQL('and usu_004 = :senha ')
    .SQL('and sit_001 = 4 and b_funcao_garcom')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsString('usuario', ALogin)
    .ParamAsString('senha', ASenha)
    .Open;
  Result := DataSetToEntity(Query.DataSet);
end;

function TAPIRPCheffDAOUsuario.Busca(AIdUsuario: Integer): TAPIRPCheffEntityUsuario;
begin
  Select;
  Query.SQL('where emp_001 = :idEmpresa')
    .SQL('and usu_001 = :idUsuario')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idUsuario', AIdUsuario)
    .Open;
  Result := DataSetToEntity(Query.DataSet);
end;

function TAPIRPCheffDAOUsuario.Busca(ALogin: string): TAPIRPCheffEntityUsuario;
begin
  Select;
  Query.SQL('where emp_001 = :idEmpresa')
    .SQL('and trim(upper(usu_003)) = trim(upper(:usuario))')
    .SQL('and sit_001 = 4')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsString('usuario', ALogin)
    .Open;
  Result := DataSetToEntity(Query.DataSet);
end;

function TAPIRPCheffDAOUsuario.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityUsuario;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityUsuario.Create;
    try
      Result.idUsuario                        := ADataSet.FieldByName('usu_001').AsInteger;
      Result.idEmpresa                        := ADataSet.FieldByName('emp_001').AsInteger;
      Result.nome                             := ADataSet.FieldByName('usu_002').AsString;
      Result.login                            := ADataSet.FieldByName('usu_003').AsString;
      Result.senha                            := ADataSet.FieldByName('usu_004').AsString;
      Result.transferenciaMesa                := ADataSet.FieldByName('b_transferencia_mesa').AsBoolean;
      Result.permiteCancelarItemMobile        := ADataSet.FieldByName('b_permite_canc_item_mobile').AsBoolean;
      Result.permitePreFechamentoMesaComanda  := ADataSet.FieldByName('b_permite_prefechamento_mesa_comanda').AsBoolean;
      Result.permiteFechamentoMesaComanda     := ADataSet.FieldByName('b_permite_fechamento_mesa_comanda').AsBoolean;
      Result.permiteAlterarTaxa10             := ADataSet.FieldByName('b_permite_alterar_taxa10').AsBoolean;
      Result.funcaoGarcom                     := ADataSet.FieldByName('b_funcao_garcom').AsBoolean;
      Result.descontoMaximo                   := ADataSet.FieldByName('desconto_max').AsCurrency;
      Result.PermiteJuntarMesaComanda         := ADataSet.FieldByName('b_permite_juntar_mesa_comanda').AsBoolean;
      Result.PermiteReabrirMesaComanda        := ADataSet.FieldByName('b_reabrir_mesa_comanda').AsBoolean;
      Result.PermitePagamentoParcial          := ADataSet.FieldByName('b_permite_pag_antecipado_mesa_comanda').AsBoolean;
      Result.PermiteDescontoFechamento        := ADataSet.FieldByName('b_permite_desconto_fechamento_mesa_comanda').AsBoolean;
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TAPIRPCheffDAOUsuario.List: TObjectList<TAPIRPCheffEntityUsuario>;
begin
  Select;
  Query.SQL('where emp_001 = :idEmpresa')
    .SQL('and sit_001 = 4 and b_funcao_garcom')
    .SQL('order by usu_002')
    .ParamAsInteger('idEmpresa', FIdEmpresa);
  Query.Open;
  Result := DataSetToList(Query.DataSet);
end;

procedure TAPIRPCheffDAOUsuario.Select;
begin
  Query.SQL('select usu_001, usu_002, emp_001, b_transferencia_mesa,b_permite_canc_item_mobile,usu_003,         ')
    .SQL('  b_permite_prefechamento_mesa_comanda,b_permite_fechamento_mesa_comanda,b_permite_alterar_taxa10,    ')
    .SQL('  usu_004, b_funcao_garcom, desconto_max,  b_permite_juntar_mesa_comanda, b_reabrir_mesa_comanda,     ')
    .SQL('  b_permite_pag_antecipado_mesa_comanda, b_permite_desconto_fechamento_mesa_comanda from usuarios     ');
end;

end.

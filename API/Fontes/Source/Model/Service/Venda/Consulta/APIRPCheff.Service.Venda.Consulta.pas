unit APIRPCheff.Service.Venda.Consulta;

interface

uses
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Generics.Collections,
  System.SysUtils,
  System.Classes;

type
  TAPIRPCheffServiceVendaConsulta = class
  private
    FConfiguracao       : TAPIRPCheffEntityConfiguracaoMesaComanda;
    FTipoConfiguracao   : TRPCheffTipoVenda;
    FDAO                : TAPIRPCheffDAOFactory;

    procedure CarregarConfiguracao(AVenda: TAPIRPCheffEntityVenda);
  public
    procedure AplicarValoresDeTaxas(AVenda: TAPIRPCheffEntityVenda);
    destructor Destroy; override;
    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaConsulta;
    function Buscar(AIdVenda: Integer; ABuscarItens: Boolean): TAPIRPCheffEntityVenda;
    function BuscarVendaItem(AIdVenda: Integer): TObjectList<TAPIRPCheffEntityVendaItem>;
  end;

implementation

{ TAPIRPCheffServiceVendaConsulta }

procedure TAPIRPCheffServiceVendaConsulta.AplicarValoresDeTaxas(AVenda: TAPIRPCheffEntityVenda);
begin
  CarregarConfiguracao(AVenda);
  if Assigned(FConfiguracao) then
  begin
    AVenda.valorCouvertMasculino := AVenda.numeroCouvertMasculino * FConfiguracao.valorCouvertMasculino;
    AVenda.valorCouvertFeminino := AVenda.numeroCouvertFeminino * FConfiguracao.valorCouvertFeminino;
  end;
end;

function TAPIRPCheffServiceVendaConsulta.Buscar(AIdVenda: Integer; ABuscarItens: Boolean): TAPIRPCheffEntityVenda;
begin
  Result := FDAO.VendaDAO.Buscar(AIdVenda);
  if not Assigned(Result) then
    Exit;
  try
    AplicarValoresDeTaxas(Result);
    if ABuscarItens then
    begin
      FreeAndNil(Result.itens);
      Result.itens := FDAO.VendaItemDAO.Listar(AIdVenda);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TAPIRPCheffServiceVendaConsulta.BuscarVendaItem(AIdVenda: Integer):TObjectList<TAPIRPCheffEntityVendaItem>;
begin
  Result := FDAO.VendaItemDAO.Listar(AIdVenda);
end;

procedure TAPIRPCheffServiceVendaConsulta.CarregarConfiguracao(AVenda: TAPIRPCheffEntityVenda);
begin
  if (not Assigned(FConfiguracao)) or (FConfiguracao.idEmpresa <> AVenda.idEmpresa) or
    (FTipoConfiguracao <> AVenda.tipoVenda) then
  begin
    FreeAndNil(FConfiguracao);
    FTipoConfiguracao := AVenda.tipoVenda;
    case AVenda.tipoVenda of
      tvComanda: FConfiguracao := FDAO.ConfiguracaoComandaDAO.Buscar(AVenda.idEmpresa);
      tvMesa: FConfiguracao := FDAO.ConfiguracaoMesaDAO.Buscar(AVenda.idEmpresa);
    end;
  end;
end;

function TAPIRPCheffServiceVendaConsulta.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaConsulta;
begin
  Result := Self;
  FDAO := AValue;
end;

destructor TAPIRPCheffServiceVendaConsulta.Destroy;
begin
 FreeAndNil(FConfiguracao);
  inherited;
end;

end.

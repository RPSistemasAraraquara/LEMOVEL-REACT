unit APIRPCheff.Service.Venda.Consulta;

interface

uses
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Math,
  System.Generics.Collections,
  System.SysUtils,
  System.Classes;

type
  TAPIRPCheffServiceVendaConsulta = class
  private
    FConfiguracao       : TAPIRPCheffEntityConfiguracaoMesaComanda;
    FAplicarTaxaServico : Boolean;
    FDAO                : TAPIRPCheffDAOFactory;

    procedure CarregarConfiguracao(AVenda: TAPIRPCheffEntityVenda);
    procedure AplicarValoresDeTaxas(AVenda: TAPIRPCheffEntityVenda);
  public
    constructor Create;
    destructor Destroy; override;
    procedure AplicarValoresDeTaxasComValor(AVenda: TAPIRPCheffEntityVenda; AValorTaxaGarcom: Currency);
    function AplicarTaxaServico(AValue: Boolean): TAPIRPCheffServiceVendaConsulta;
    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaConsulta;
    function Buscar(AIdVenda: Integer; ABuscarItens: Boolean): TAPIRPCheffEntityVenda;
    function BuscarVendaItem(AIdVenda: Integer): TObjectList<TAPIRPCheffEntityVendaItem>;
  end;

implementation

{ TAPIRPCheffServiceVendaConsulta }

function TAPIRPCheffServiceVendaConsulta.AplicarTaxaServico(AValue: Boolean): TAPIRPCheffServiceVendaConsulta;
begin
  Result := Self;
  FAplicarTaxaServico := AValue;
end;

procedure TAPIRPCheffServiceVendaConsulta.AplicarValoresDeTaxas(AVenda: TAPIRPCheffEntityVenda);
var
  LValorTaxaGarcom:Currency;
begin
  LValorTaxaGarcom:=0;
  CarregarConfiguracao(AVenda);
  if (Assigned(FConfiguracao)) and (FAplicarTaxaServico) and
     (FConfiguracao.utilizaTaxaServico) and (AVenda.itens.Count = 0) then
    LValorTaxaGarcom:=FDAO.VendaItemDAO.ListarProdutosSomenteTaxaGarcom(AVenda.idVenda);
  AplicarValoresDeTaxasComValor(AVenda, LValorTaxaGarcom);
end;

// Performance: mesma regra do AplicarValoresDeTaxas, mas com o somatorio da
// taxa ja resolvido pelo chamador (carga em lote do GET /mesa) - evita 1
// SELECT por venda. Couvert e formula do RoundTo identicos aos originais.
procedure TAPIRPCheffServiceVendaConsulta.AplicarValoresDeTaxasComValor(AVenda: TAPIRPCheffEntityVenda;
  AValorTaxaGarcom: Currency);
begin
  CarregarConfiguracao(AVenda);
  if Assigned(FConfiguracao) then
  begin
    AVenda.valorCouvertMasculino := AVenda.numeroCouvertMasculino * FConfiguracao.valorCouvertMasculino;
    AVenda.valorCouvertFeminino := AVenda.numeroCouvertFeminino * FConfiguracao.valorCouvertFeminino;

    if (FAplicarTaxaServico) and (FConfiguracao.utilizaTaxaServico) then
      AVenda.valorTaxaServico := RoundTo(AValorTaxaGarcom * FConfiguracao.percentualTaxaServico / 100 + MinDouble, -2);
  end;
end;


function TAPIRPCheffServiceVendaConsulta.Buscar(AIdVenda: Integer; ABuscarItens: Boolean): TAPIRPCheffEntityVenda;
begin
//  if not Assigned(Result) then
//    raise Exception.CreateFmt('Venda ID %d Não encontrada.', [AIdVenda]);

  Result := FDAO.VendaDAO.Buscar(AIdVenda);
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
  if (not Assigned(FConfiguracao)) or (FConfiguracao.idEmpresa <> AVenda.idEmpresa) then
  begin
    FreeAndNil(FConfiguracao);
    case AVenda.tipoVenda of
      tvComanda: FConfiguracao := FDAO.ConfiguracaoComandaDAO.Buscar(AVenda.idEmpresa);
      tvMesa: FConfiguracao := FDAO.ConfiguracaoMesaDAO.Buscar(AVenda.idEmpresa);
    end;
  end;
end;

constructor TAPIRPCheffServiceVendaConsulta.Create;
begin
  FAplicarTaxaServico := True;
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

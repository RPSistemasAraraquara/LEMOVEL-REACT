unit RPNFe.Service;

interface

uses
  RPNFe.DAO.Factory,
  RPNFe.Components,
  RPNFe.Service.Emissao,
  RPNFe.Service.Impressao;

type
  TRPNFeService = class
  private
    FComponents: TRPNFeComponents;
    FDAO: TRPNFeDAOFactory;

    FEmissaoService: TRPNFeServiceEmissao;
    FImpressaoService: TRPNFeServiceImpressao;
  public
    destructor Destroy; override;

    function Components(AValue: TRPNFeComponents): TRPNFeService;
    function DAO(AValue: TRPNFeDAOFactory): TRPNFeService;

    function EmissaoService: TRPNFeServiceEmissao;
    function ImpressaoService: TRPNFeServiceImpressao;
  end;

implementation

{ TRPNFeService }

uses
  RPNFe.Service.Emissao.Observer.SalvarDadosAutorizacao;

function TRPNFeService.Components(AValue: TRPNFeComponents): TRPNFeService;
begin
  Result := Self;
  FComponents := AValue;
end;

function TRPNFeService.DAO(AValue: TRPNFeDAOFactory): TRPNFeService;
begin
  Result := Self;
  FDAO := AValue;
end;

destructor TRPNFeService.Destroy;
begin
  FEmissaoService.Free;
  FImpressaoService.Free;
  inherited;
end;

function TRPNFeService.EmissaoService: TRPNFeServiceEmissao;
begin
  if not Assigned(FEmissaoService) then
  begin
    FEmissaoService := TRPNFeServiceEmissao.Create;
    FEmissaoService.DAO(FDAO)
      .Components(FComponents)
      .AddObserver(TRPNFeServiceEmissaoObserverSalvarDadosAutorizacao.Create(FEmissaoService));
  end;
  Result := FEmissaoService;
end;

function TRPNFeService.ImpressaoService: TRPNFeServiceImpressao;
begin
  if not Assigned(FImpressaoService) then
  begin
    FImpressaoService := TRPNFeServiceImpressao.Create;
    FImpressaoService.DAO(FDAO)
      .Components(FComponents);
  end;
  Result := FImpressaoService;
end;

end.

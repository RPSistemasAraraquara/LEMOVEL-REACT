unit APIRPCheff.Service.Venda.Impressao;

interface

uses
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.Components,
  APIRPCheff.DAO.Factory,
  APIRPCheff.Utils,
  System.SysUtils,
  System.Classes,
  System.StrUtils;

type
  TAPIRPCheffServiceVendaImpressao = class
  protected
    FComponents: TAPIRPCheffComponents;
    FDAO                       : TAPIRPCheffDAOFactory;
    FNumeroColunas             : Integer;
    FIdVenda                   : Integer;
    FIdEmpresa                 : Integer;
    FImprimirDecimais          : Boolean;
    FImprimirOpcionais         : Boolean;
    FUtilizaControleConsumacao : Boolean;
    FTipoMaquina               : TRPTipoMaquinaPagamento;
    FMensagemCouvert           : string;
    FImprimir                  : Boolean;
    FImprimirFichaIndividualProdutos: Boolean;

    function FormatarMoeda(AValor: Currency): string;
    function FormatarQuantidadeFracionada(AQuantidade, AValorUnitario, AValorTotal: Currency): string;
    function QuantidadeFichasIndividuais(AQuantidade: Currency): Integer;
    function UsaIntegracaoMaquininha(AEmpresa: TAPIRPCheffEntityEmpresa): Boolean;
    function PodeImprimirLocalmente(AEmpresa: TAPIRPCheffEntityEmpresa): Boolean;
    procedure Imprimir(AConteudo: string); overload;
    function CriarImpressaoStone: TAPIRPCheffServiceVendaImpressao;
    function CriarImpressaoPlugPag: TAPIRPCheffServiceVendaImpressao;
    function CriarImpressaoCielo: TAPIRPCheffServiceVendaImpressao;
  public
    constructor Create;

    function Components(AValue: TAPIRPCheffComponents): TAPIRPCheffServiceVendaImpressao;
    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaImpressao;
    function IdEmpresa(AValue: Integer): TAPIRPCheffServiceVendaImpressao;
    function IdVenda(AValue: Integer): TAPIRPCheffServiceVendaImpressao;
    function Imprimir(AValue: Boolean): TAPIRPCheffServiceVendaImpressao; overload;
    function ImprimirFichaIndividualProdutos(AValue: Boolean): TAPIRPCheffServiceVendaImpressao;
    function NumeroColunas(AValue: Integer): TAPIRPCheffServiceVendaImpressao;
    function TipoMaquina(AValue: TRPTipoMaquinaPagamento): TAPIRPCheffServiceVendaImpressao;
    function Execute: TStream; virtual;
  end;

implementation

{ TAPIRPCheffServiceVendaImpressao }

uses
  APIRPCheff.Service.Venda.ImpressaoSTONE,
{$IFNDEF LINUX}
  APIRPCheff.Service.Venda.ImpressaoSTONE.NFCe,
{$ENDIF}
  APIRPCheff.Service.Venda.ImpressaoPlugPag,
{$IFNDEF LINUX}
  APIRPCheff.Service.Venda.ImpressaoPlugPag.NFCe,
{$ENDIF}
  APIRPCheff.Service.Venda.ImpressaoCielo,
{$IFNDEF LINUX}
  APIRPCheff.Service.Venda.ImpressaoCielo.NFCe,
{$ENDIF}
  APIRPCheff.Service.Venda.Impressao32Colunas,
  APIRPCheff.Service.Venda.Impressao42Colunas,
  APIRPCheff.Service.Venda.Impressao48Colunas;

function TAPIRPCheffServiceVendaImpressao.FormatarMoeda(AValor: Currency): string;
begin
  Result := 'R$ ' + FormatFloat('0.00', AValor);
end;

function TAPIRPCheffServiceVendaImpressao.FormatarQuantidadeFracionada(
  AQuantidade, AValorUnitario, AValorTotal: Currency): string;
const
  TOLERANCIA = 0.01;
var
  LQuantidade: Currency;
  LDenominador: Integer;
begin
  LQuantidade := AQuantidade;
  if (LQuantidade <= 0) and (AValorUnitario <> 0) then
    LQuantidade := AValorTotal / AValorUnitario;

  for LDenominador := 2 to 10 do
    if Abs(Double(LQuantidade) - (1 / LDenominador)) < TOLERANCIA then
      Exit('1/' + LDenominador.ToString);

  Result := FormatFloat('0.###', LQuantidade);
end;

function TAPIRPCheffServiceVendaImpressao.Components(
  AValue: TAPIRPCheffComponents): TAPIRPCheffServiceVendaImpressao;
begin
  Result := Self;
  FComponents := AValue;
end;

constructor TAPIRPCheffServiceVendaImpressao.Create;
begin
  FTipoMaquina := tmpNenhum;
  FImprimirDecimais := True;
  FImprimirOpcionais := True;
  FUtilizaControleConsumacao := False;
  FImprimir := False;
  FImprimirFichaIndividualProdutos := True;
  FMensagemCouvert := 'COUVERT (+)';
end;

function TAPIRPCheffServiceVendaImpressao.CriarImpressaoCielo: TAPIRPCheffServiceVendaImpressao;
var
  LVenda: TAPIRPCheffEntityVenda;
begin
  LVenda := FDAO.VendaDAO.Buscar(FIdVenda);
  try
{$IFDEF LINUX}
    Result := TAPIRPCheffServiceVendaImpressaoCielo.Create;
{$ELSE}
    if LVenda.chaveEletronica.Trim.IsEmpty then
      Result := TAPIRPCheffServiceVendaImpressaoCielo.Create
    else
      Result := TAPIRPCheffServiceVendaImpressaCieloNFCe.Create;
{$ENDIF}
  finally
    LVenda.Free;
  end;
end;

function TAPIRPCheffServiceVendaImpressao.CriarImpressaoPlugPag: TAPIRPCheffServiceVendaImpressao;
var
  LVenda: TAPIRPCheffEntityVenda;
begin
  LVenda := FDAO.VendaDAO.Buscar(FIdVenda);
  try
{$IFDEF LINUX}
    Result := TAPIRPCheffServiceVendaImpressaoPlugPag.Create;
{$ELSE}
    if LVenda.chaveEletronica.Trim.IsEmpty then
      Result := TAPIRPCheffServiceVendaImpressaoPlugPag.Create
    else
      Result := TAPIRPCheffServiceVendaImpressaPlugPagNFCe.Create;
{$ENDIF}
  finally
    LVenda.Free;
  end;
end;

function TAPIRPCheffServiceVendaImpressao.CriarImpressaoStone: TAPIRPCheffServiceVendaImpressao;
var
  LVenda: TAPIRPCheffEntityVenda;
begin
  LVenda := FDAO.VendaDAO.Buscar(FIdVenda);
  try
{$IFDEF LINUX}
    Result := TAPIRPCheffServiceVendaImpressaoSTONE.Create;
{$ELSE}
    if LVenda.chaveEletronica.Trim.IsEmpty then
      Result := TAPIRPCheffServiceVendaImpressaoSTONE.Create
    else
      Result := TAPIRPCheffServiceVendaImpressaStoneNFCe.Create;
{$ENDIF}
  finally
    LVenda.Free;
  end;
end;

function TAPIRPCheffServiceVendaImpressao.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaImpressao;
begin
  Result := Self;
  FDAO := AValue;
end;

function TAPIRPCheffServiceVendaImpressao.Execute: TStream;
var
  LStrategy: TAPIRPCheffServiceVendaImpressao;
  LEmpresa: TAPIRPCheffEntityEmpresa;
begin
  LStrategy := nil;
  LEmpresa := FDAO.EmpresaDAO.Busca;
  try
    if FTipoMaquina = tmpNenhum then
    begin
      if FNumeroColunas = 32 then
        LStrategy := TAPIRPCheffServiceVendaImpressao32Colunas.Create
      else
      if FNumeroColunas = 42 then
        LStrategy := TAPIRPCheffServiceVendaImpressao42Colunas.Create
      else
      if FNumeroColunas = 48 then
        LStrategy := TAPIRPCheffServiceVendaImpressao48Colunas.Create;
    end
    else
    if Assigned(LEmpresa) and LEmpresa.utilizaIntegracaoStone and (FTipoMaquina = tmpStone) then
      LStrategy := CriarImpressaoStone
    else
    if Assigned(LEmpresa) and LEmpresa.utilizaIntegracaoPagBank and (FTipoMaquina = tmpPlugPag) then
      LStrategy := CriarImpressaoPlugPag
    else
    if Assigned(LEmpresa) and LEmpresa.utilizaIntegracaoCielo and (FTipoMaquina = tmpCielo) then
      LStrategy := CriarImpressaoCielo
    else
    if FNumeroColunas = 32 then
      LStrategy := TAPIRPCheffServiceVendaImpressao32Colunas.Create
    else
    if FNumeroColunas = 42 then
      LStrategy := TAPIRPCheffServiceVendaImpressao42Colunas.Create
    else
    if FNumeroColunas = 48 then
      LStrategy := TAPIRPCheffServiceVendaImpressao48Colunas.Create;

    if not Assigned(LStrategy) then
    begin
      Result := TStringStream.Create('', TEncoding.UTF8);
      Exit;
    end;

    LStrategy.IdVenda(FIdVenda)
      .IdEmpresa(FIdEmpresa)
      .Components(FComponents)
      .DAO(FDAO)
      .ImprimirFichaIndividualProdutos(FImprimirFichaIndividualProdutos);
    Result := LStrategy.Execute;
    if FImprimir and PodeImprimirLocalmente(LEmpresa) then
      Imprimir(TStringStream(Result).DataString);
  finally
    FreeAndNil(LStrategy);
    FreeAndNil(LEmpresa);
  end;
end;

function TAPIRPCheffServiceVendaImpressao.IdEmpresa(AValue: Integer): TAPIRPCheffServiceVendaImpressao;
begin
  Result := Self;
  FIdEmpresa := AValue;
end;

function TAPIRPCheffServiceVendaImpressao.IdVenda(AValue: Integer): TAPIRPCheffServiceVendaImpressao;
begin
  Result := Self;
  FIdVenda := AValue;
end;

procedure TAPIRPCheffServiceVendaImpressao.Imprimir(AConteudo: string);
var
  LComponents: TAPIRPCheffComponents;
begin
  LComponents := TAPIRPCheffComponents.Create;
  try
    try
      LComponents.Impressora.Imprimir(AConteudo);
    except
    end;
  finally
    FreeAndNil(LComponents);
  end;
end;

function TAPIRPCheffServiceVendaImpressao.PodeImprimirLocalmente(
  AEmpresa: TAPIRPCheffEntityEmpresa): Boolean;
begin
{$IFDEF LINUX}
  Exit(False);
{$ENDIF}
  Result := not UsaIntegracaoMaquininha(AEmpresa);
end;

function TAPIRPCheffServiceVendaImpressao.Imprimir(AValue: Boolean): TAPIRPCheffServiceVendaImpressao;
begin
  Result := Self;
  FImprimir := AValue;
end;

function TAPIRPCheffServiceVendaImpressao.ImprimirFichaIndividualProdutos(
  AValue: Boolean): TAPIRPCheffServiceVendaImpressao;
begin
  Result := Self;
  FImprimirFichaIndividualProdutos := AValue;
end;

function TAPIRPCheffServiceVendaImpressao.NumeroColunas(AValue: Integer): TAPIRPCheffServiceVendaImpressao;
begin
  Result := Self;
  FNumeroColunas := AValue;
end;

function TAPIRPCheffServiceVendaImpressao.QuantidadeFichasIndividuais(
  AQuantidade: Currency): Integer;
begin
  Result := Trunc(AQuantidade);
  if Result < 1 then
    Result := 1;
end;

function TAPIRPCheffServiceVendaImpressao.UsaIntegracaoMaquininha(
  AEmpresa: TAPIRPCheffEntityEmpresa): Boolean;
begin
  Result := FTipoMaquina in [tmpStone, tmpPlugPag, tmpCielo];
  if Result then
    Exit;

  Result := Assigned(AEmpresa) and (
    AEmpresa.utilizaIntegracaoStone
    or AEmpresa.utilizaIntegracaoPagBank
    or AEmpresa.utilizaIntegracaoCielo
  );
end;

function TAPIRPCheffServiceVendaImpressao.TipoMaquina(
  AValue: TRPTipoMaquinaPagamento): TAPIRPCheffServiceVendaImpressao;
begin
  Result := Self;
  FTipoMaquina := AValue;
end;

end.

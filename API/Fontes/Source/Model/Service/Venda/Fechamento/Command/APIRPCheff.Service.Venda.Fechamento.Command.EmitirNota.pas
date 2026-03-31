unit APIRPCheff.Service.Venda.Fechamento.Command.EmitirNota;

interface

uses
  System.Generics.Collections,
  System.Math,
  System.SysUtils,
  RPNFe.Entity.Classes,
  RPNFe.Components.Impressora.DanfeEscPos,
  APIRPCheff.Resources,
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory;

type
  TAPIRPCheffServiceVendaFechamentoCommandEmitirNota =
    class(TAPIRPCheffServiceVendaFechamentoCommand)
  private
    function DeveEmitirNota(const AFechamento: TAPIRPCheffEntityVendaPostFechamento): Boolean;
    procedure Imprimir(const ANota: TRPNFeEntityNFeNotaEletronica);
  public
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandEmitirNota }

function TAPIRPCheffServiceVendaFechamentoCommandEmitirNota.DeveEmitirNota(const AFechamento: TAPIRPCheffEntityVendaPostFechamento): Boolean;
var
  LPagamentos: TObjectList<TAPIRPCheffEntityFormaPagamento>;
begin
  Result := False;
  LPagamentos := FParent.DAO.FormaPagamentoDAO.ListarPagamentosDaVenda(AFechamento.idVenda);
  try
    for var LPagamento in LPagamentos do
    begin
      if LPagamento.emiteFiscal then
        Exit(True);
    end;
  finally
    LPagamentos.Free;
  end;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandEmitirNota.Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LNotaEletronica: TRPNFeEntityNFeNotaEletronica;
begin
  inherited;
  if DeveEmitirNota(AFechamento) then
  begin
    FParent.Components.RPNFe.Service.EmissaoService
      .Configuracao(APP_RESOURCES.NFE_XML_CONFIGURACAO)
      .IdVenda(FParent.Venda.idVenda);

    LNotaEletronica := FParent.Components.RPNFe.Service.EmissaoService.Execute;
    try
      try
        Imprimir(LNotaEletronica);
      except
      end;
    finally
      LNotaEletronica.Free;
    end;
  end;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandEmitirNota.Imprimir(const ANota: TRPNFeEntityNFeNotaEletronica);
begin
  try
    FParent.Components.RPNFe.Components.ImpressoraDanfeEscPos
      .Modelo(TACBrPosPrinterModelo(APP_RESOURCES.IMPRESSORA_MODELO))
      .PaginaDeCodigo(TACBrPosPaginaCodigo(APP_RESOURCES.IMPRESSORA_PAGINA_CODE))
      .Porta(APP_RESOURCES.IMPRESSORA_PORTA)
      .Colunas(APP_RESOURCES.IMPRESSORA_COLUNAS)
      .Espacos(APP_RESOURCES.IMPRESSORA_ESPACOS)
      .LinhasEntreCupons(APP_RESOURCES.IMPRESSORA_LINHAS_PULO);

    FParent.Components.RPNFe.Service.ImpressaoService
      .TipoDanfe(tdPosPrinter)
      .Xml(ANota.Xml)
      .Execute;
  except
    on E: Exception do
      raise EImpressaoException.Create(E.Message);
  end;
end;

end.

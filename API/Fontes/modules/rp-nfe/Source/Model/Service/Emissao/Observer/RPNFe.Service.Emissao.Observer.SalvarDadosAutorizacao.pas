unit RPNFe.Service.Emissao.Observer.SalvarDadosAutorizacao;

interface

uses
  System.SysUtils,
  RPNFe.Entity.Classes,
  RPNFe.Service.Emissao;

type
  TRPNFeServiceEmissaoObserverSalvarDadosAutorizacao = class(TRPNFeServiceEmissaoObserver)
  public
    procedure Execute(const ANotaEletronica: TRPNFeEntityNFeNotaEletronica); override;
  end;

implementation

{ TRPNFeServiceEmissaoObserverSalvarDadosAutorizacao }

procedure TRPNFeServiceEmissaoObserverSalvarDadosAutorizacao.Execute(
  const ANotaEletronica: TRPNFeEntityNFeNotaEletronica);
begin
  inherited;
  FParent.DAO.VendaDAO
    .AtualizarEmissao(FParent.Venda.Id, ANotaEletronica);

  // Marca a venda como NFC-e autorizada (VEN_SATSTATUS = 23), mesmo status que
  // o PDV desktop grava em encerravenda ao autorizar.
  FParent.DAO.EncerraVendaDAO
    .AtualizarStatusSAT(FParent.Venda.Id, 23);

  try
    DeleteFile(ANotaEletronica.XmlPath);
  except
  end;
end;

end.

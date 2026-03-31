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

  try
    DeleteFile(ANotaEletronica.XmlPath);
  except
  end;
end;

end.

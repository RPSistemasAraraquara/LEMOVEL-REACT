unit APIRPCheff.Service.Venda.Fechamento.Command.AtualizarCouvert;

interface

uses
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Math,
  System.SysUtils;

type
  TAPIRPCheffServiceVendaFechamentoCommandAtualizarCouvert =
    class(TAPIRPCheffServiceVendaFechamentoCommand)
  public
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandAtualizarCouvert }

procedure TAPIRPCheffServiceVendaFechamentoCommandAtualizarCouvert.Execute(
  AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LPatchCouvert: TAPIRPCheffEntityVendaPatchCouvert;
  LDAO: TAPIRPCheffDAOVenda;
  LVenda: TAPIRPCheffEntityVenda;
begin
  LVenda := FParent.Venda;
  LPatchCouvert := TAPIRPCheffEntityVendaPatchCouvert.Create;
  try
    LPatchCouvert.numeroCouvertFeminino := AFechamento.numeroCouvertFeminino;
    LPatchCouvert.numeroCouvertMasculino := AFechamento.numeroCouvertMasculino;
    LPatchCouvert.idEmpresa := AFechamento.idEmpresa;
    LPatchCouvert.idVenda := AFechamento.idVenda;
    LPatchCouvert.numeroPessoas := AFechamento.numeroCouvertFeminino +
      AFechamento.numeroCouvertMasculino;

    if LVenda.NumeroCouvert <> LPatchCouvert.numeroPessoas then
    begin
      LDAO := FParent.DAO.VendaDAO;
      LDAO.ManagerTransaction(False);
      LDAO.AtualizarCouvert(LPatchCouvert);
      LVenda.numeroPessoas := LPatchCouvert.numeroPessoas;
      LVenda.numeroCouvertMasculino := LPatchCouvert.numeroCouvertMasculino;
      LVenda.numeroCouvertFeminino := LPatchCouvert.numeroCouvertFeminino;
    end;

    if (FParent.ConfiguracaoMesa.utilizaCouvert) and
      (FParent.ConfiguracaoMesa.couvertObrigatorio) and
      (LVenda.NumeroCouvert <= 0) then
      raise Exception.Create('Obrigat'#243'rio informar o N'#195#353'MERO de couvert.');
  finally
    FreeAndNil(LPatchCouvert);
  end;
end;

end.

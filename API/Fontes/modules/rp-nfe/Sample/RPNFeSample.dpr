program RPNFeSample;

uses
  Vcl.Forms,
  RPNFe.View.Sample in 'RPNFe.View.Sample.pas' {Form1},
  RPNFe.Components.Connection in '..\Source\Model\Components\Connection\RPNFe.Components.Connection.pas',
  RPNFe.Components in '..\Source\Model\Components\RPNFe.Components.pas',
  RPNFe.Components.Emissor.ACBr in '..\Source\Model\Components\Emissor\RPNFe.Components.Emissor.ACBr.pas',
  RPNFe.Entity.Classes in '..\Source\Model\Entity\RPNFe.Entity.Classes.pas',
  RPNFe.DAO.Base in '..\Source\Model\DAO\RPNFe.DAO.Base.pas',
  RPNFe.DAO.Empresa in '..\Source\Model\DAO\RPNFe.DAO.Empresa.pas',
  RPNFe.DAO.Factory in '..\Source\Model\DAO\RPNFe.DAO.Factory.pas',
  RPNFe.DAO.VendaPagamento in '..\Source\Model\DAO\RPNFe.DAO.VendaPagamento.pas',
  RPNFe.DAO.IBPT in '..\Source\Model\DAO\RPNFe.DAO.IBPT.pas',
  RPNFe.DAO.VendaItem in '..\Source\Model\DAO\RPNFe.DAO.VendaItem.pas',
  RPNFe.DAO.ContaAReceber in '..\Source\Model\DAO\RPNFe.DAO.ContaAReceber.pas',
  RPNFe.DAO.Venda in '..\Source\Model\DAO\RPNFe.DAO.Venda.pas',
  RPNFe.Service.Emissao in '..\Source\Model\Service\Emissao\RPNFe.Service.Emissao.pas',
  RPNFe.Components.Log in '..\Source\Model\Components\Log\RPNFe.Components.Log.pas',
  RPNFe.Service.Emissao.Command.DadosIde in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.DadosIde.pas',
  RPNFe.Service.Emissao.Command.DadosEmit in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.DadosEmit.pas',
  RPNFe.Service.Emissao.Command.DadosDest in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.DadosDest.pas',
  RPNFe.Service in '..\Source\Model\Service\RPNFe.Service.pas',
  RPNFe.Service.Emissao.Command.Itens in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.Itens.pas',
  RPNFe.Service.Emissao.Command.ItensImpostoICMS in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.ItensImpostoICMS.pas',
  RPNFe.Service.Emissao.Command.ItensImpostoISSQN in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.ItensImpostoISSQN.pas',
  RPNFe.Service.Emissao.Command.ItensImpostoPIS in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.ItensImpostoPIS.pas',
  RPNFe.Service.Emissao.Command.ItensImpostoCOFINS in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.ItensImpostoCOFINS.pas',
  RPNFe.Service.Emissao.Command.ItensImpostoICMSUFDest in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.ItensImpostoICMSUFDest.pas',
  RPNFe.DAO.Aliquota in '..\Source\Model\DAO\RPNFe.DAO.Aliquota.pas',
  RPNFe.Service.Emissao.Command.ItensANP in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.ItensANP.pas',
  RPNFe.DAO.Estado in '..\Source\Model\DAO\RPNFe.DAO.Estado.pas',
  RPNFe.Service.Emissao.Command.Pagamentos in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.Pagamentos.pas',
  RPNFe.Service.Emissao.Command.Totais in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.Totais.pas',
  RPNFe.Service.Emissao.Command.ResponsavelTecnico in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.ResponsavelTecnico.pas',
  RPNFe.Service.Emissao.Command.AssinarXML in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.AssinarXML.pas',
  RPNFe.Controller in '..\Source\Controller\RPNFe.Controller.pas',
  RPNFe.Components.Arquivos in '..\Source\Model\Components\Arquivos\RPNFe.Components.Arquivos.pas',
  RPNFe.Service.Emissao.Command.EnviarNota in '..\Source\Model\Service\Emissao\Command\RPNFe.Service.Emissao.Command.EnviarNota.pas',
  RPNFe.DAO.EncerraVenda in '..\Source\Model\DAO\RPNFe.DAO.EncerraVenda.pas',
  RPNFe.DAO.Configuracao in '..\Source\Model\DAO\RPNFe.DAO.Configuracao.pas',
  RPNFe.Service.Emissao.Observer.SalvarDadosAutorizacao in '..\Source\Model\Service\Emissao\Observer\RPNFe.Service.Emissao.Observer.SalvarDadosAutorizacao.pas',
  RPNFe.Service.Impressao in '..\Source\Model\Service\Impressao\RPNFe.Service.Impressao.pas',
  RPNFe.Components.Impressora.DanfeEscPos in '..\Source\Model\Components\Impressora\RPNFe.Components.Impressora.DanfeEscPos.pas',
  RPNFe.Service.Impressao.EscPos in '..\Source\Model\Service\Impressao\RPNFe.Service.Impressao.EscPos.pas',
  RPNFe.Service.Impressao.FastReport in '..\Source\Model\Service\Impressao\RPNFe.Service.Impressao.FastReport.pas',
  ACBrNFeDANFEFRDM.Helper in '..\Source\Model\Components\Emissor\Helpers\ACBrNFeDANFEFRDM.Helper.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

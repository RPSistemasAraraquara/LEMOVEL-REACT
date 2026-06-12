unit APIRPCheff.Service.Venda.Fechamento.Command.GravarImpressao;

interface

uses
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Math,
  System.Generics.Collections,
  System.DateUtils,
  System.SysUtils;

type
  TAPIRPCheffServiceVendaFechamentoCommandGravarImpressao =
    class(TAPIRPCheffServiceVendaFechamentoCommand)
  private
    function PermiteImpressoraInterna: Boolean;
    procedure GravarImpressaoProducao(AItem: TAPIRPCheffEntityVendaItem);
  public
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandGravarImpressao }

procedure TAPIRPCheffServiceVendaFechamentoCommandGravarImpressao.Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LVenda: TAPIRPCheffEntityVenda;
  LEmpresa: TAPIRPCheffEntityEmpresa;
  LImpressaoProducaoDAO: TAPIRPCheffDAOImpressaoProducao;
begin
  LVenda := FParent.Venda;
  LEmpresa := FParent.Empresa;
  if not PermiteImpressoraInterna then
  begin
    LImpressaoProducaoDAO := FParent.DAO.ImpressaoProducaoDAO;
    LImpressaoProducaoDAO.ManagerTransaction(False);
    LImpressaoProducaoDAO.MarcarPendentesComoImpressos(AFechamento.idVenda);
    Exit;
  end;

  for var LItem in FParent.VendaItens do
  begin
    if LItem.ImprimirFichaIndividual then
    begin
       if (LVenda.tipoVenda.DBValue = 'M') and  LEmpresa.UtilizaFichaIndividualMesa then
       GravarImpressaoProducao(LItem)

      else if (LVenda.tipoVenda.DBValue = 'C') and LEmpresa.UtilizaFichaIndividualComanda then
        GravarImpressaoProducao(LItem);
    end;
  end;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandGravarImpressao.GravarImpressaoProducao(AItem: TAPIRPCheffEntityVendaItem);
var
  LImpressaoProducao: TAPIRPCheffEntityImpressaoProducao;
  LImpressaoProducaoDAO: TAPIRPCheffDAOImpressaoProducao;
  LGarcom: TAPIRPCheffEntityUsuario;
begin
  LImpressaoProducaoDAO := FParent.DAO.ImpressaoProducaoDAO;
  LImpressaoProducaoDAO.ManagerTransaction(False);
  LImpressaoProducao := TAPIRPCheffEntityImpressaoProducao.Create;
  try
    try
      LImpressaoProducao.IdEmpresa           := AItem.idEmpresa;
      LImpressaoProducao.IdProduto           := AItem.idProduto;
      LImpressaoProducao.QtdeVendido         := AItem.quantidade;
      LImpressaoProducao.DataLancamento      := Now;
      LImpressaoProducao.ProdutoFoiImpresso  := False;
      LImpressaoProducao.QuantidadeImpressao := 1;
      LImpressaoProducao.IdVenda             := AItem.idVenda;
      LImpressaoProducao.DescricaoProduto    := AItem.produtoDescricao + ' (' + AItem.descricaoTamanho + ')';
      LImpressaoProducao.ImpressoraInterna   := PermiteImpressoraInterna;
      LImpressaoProducao.NomeGarcom          := Trim(AItem.nomeGarcom);

      if (LImpressaoProducao.NomeGarcom = EmptyStr) and (AItem.idGarcom > 0) then
      begin
        LGarcom := FParent.DAO.UsuarioDAO.Busca(AItem.idGarcom);
        try
          if Assigned(LGarcom) then
            LImpressaoProducao.NomeGarcom := Trim(LGarcom.nome);
        finally
          FreeAndNil(LGarcom);
        end;
      end;

      LImpressaoProducaoDAO.Inserir(LImpressaoProducao);
    except
      on E: Exception do
        raise Exception.Create('Erro ao gravar impress'#227'o de PRODU'#199#195'O: ' + E.Message);
    end;
  finally
    FreeAndNil(LImpressaoProducao);
  end;
end;

function TAPIRPCheffServiceVendaFechamentoCommandGravarImpressao.PermiteImpressoraInterna: Boolean;
var
  LEmpresa: TAPIRPCheffEntityEmpresa;
begin
  Result := FParent.Fechamento.impressoraInterna;
  if not Result then
    Exit;

  LEmpresa := FParent.Empresa;
  if not Assigned(LEmpresa) then
    Exit;

  Result := not (
    LEmpresa.utilizaIntegracaoStone
    or LEmpresa.utilizaIntegracaoPagBank
    or LEmpresa.utilizaIntegracaoCielo
  );
end;

end.

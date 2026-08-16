unit APIRPCheff.Service.Venda.Fechamento.Command.InserirMovimentoEstoqueOpcional;

interface

uses
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Generics.Collections,
  System.SysUtils;
  // LogFechamento vem de APIRPCheff.Service.Venda.Fechamento.Command.

  type
  TAPIRPCheffServiceVendaFechamentoCommandInserirMovimentoEstoqueOpcional = class(TAPIRPCheffServiceVendaFechamentoCommand)
  private
    FVendaItem           :TAPIRPCheffEntityVendaItem;
    FFechamento          :TAPIRPCheffEntityVendaPostFechamento;
    FVendaItemOpcional   :TAPIRPCheffEntityVendaItemOpcional;
    FSetorEstoqueOpcional:TAPIRPCheffEntitySetorEstoqueOpcional;
    FQuantidadeAnterior  : Double;
    FQuantidadeVendida   : Double;
    FIdSetor             :integer;
    procedure InserirMovimentoEstoqueOpcional;
    procedure InserirMovimentoSetorEstoqueOpcional;

  public
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
    property QuantidadeAnterior: Double  read FQuantidadeAnterior write FQuantidadeAnterior;
    property IdSetor           : integer read FIdSetor            write FIdSetor;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandInserirMovimentoEstoqueOpcional }

procedure TAPIRPCheffServiceVendaFechamentoCommandInserirMovimentoEstoqueOpcional.Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LVendaItemOpcional : TObjectList<TAPIRPCheffEntityVendaItemOpcional>;
  I,J :Integer;
begin
  FFechamento := AFechamento;

  if FParent.VendaItens.Count = 0 then
    Exit;

  LogFechamento('  opcional: antes de ListarPorVenda');
  LVendaItemOpcional := FParent.DAO.VendaItemOpcionalDAO.ListarPorVenda(FParent.Venda.idVenda);
  LogFechamento(Format('  opcional: ListarPorVenda ok (%d opcionais)', [LVendaItemOpcional.Count]));
  try
    // Cada opcional baixa estoque UMA vez, com a quantidade do item DONO
    // (Venda.itens = lista NAO agrupada, numeroItem = ite_001 real). O laco
    // antigo item x opcional multiplicava a baixa: venda com 3 itens e 1
    // opcional baixava o estoque do opcional 3 vezes.
    for J :=0 to Pred(LVendaItemOpcional.Count) do
    begin
      FVendaItemOpcional := LVendaItemOpcional[J];

      FVendaItem := nil;
      for I := 0 to Pred(FParent.Venda.itens.Count) do
        if FParent.Venda.itens[I].numeroItem = FVendaItemOpcional.idVendaItem then
        begin
          FVendaItem := FParent.Venda.itens[I];
          Break;
        end;

      if not Assigned(FVendaItem) then
      begin
        LogFechamento(Format('  opcional: %d sem item dono (idVendaItem %d) - ignorado',
          [FVendaItemOpcional.idOpcional, FVendaItemOpcional.idVendaItem]));
        Continue;
      end;

      LogFechamento(Format('  opcional: %d (item dono %d) - setor inicio',
        [FVendaItemOpcional.idOpcional, FVendaItemOpcional.idVendaItem]));
      InserirMovimentoSetorEstoqueOpcional;
      LogFechamento(Format('  opcional: %d - movimento inicio', [FVendaItemOpcional.idOpcional]));
      InserirMovimentoEstoqueOpcional;
      LogFechamento(Format('  opcional: %d - fim', [FVendaItemOpcional.idOpcional]));
    end;
  finally
    FreeAndNil(LVendaItemOpcional);
  end;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandInserirMovimentoEstoqueOpcional.InserirMovimentoSetorEstoqueOpcional;
var
  LDAOOpcional: TAPIRPCheffDAOOpcional;
  LOpcional: TAPIRPCheffEntityOpcional;
  LDAOSetorEstoqueOpcional: TAPIRPCheffDAOSetorEstoqueOpcional;
  LSetorEstoqueOpcional: TAPIRPCheffEntitySetorEstoqueOpcional;
begin
  QuantidadeAnterior  := 0;
  IdSetor             := 0;

  LDAOOpcional := FParent.DAO.OpcionalDAO;
  LDAOOpcional.ManagerTransaction(False);
  LOpcional             := nil;
  LSetorEstoqueOpcional := nil;
  try
    LogFechamento(Format('  opcional: buscar opcional %d', [FVendaItemOpcional.idOpcional]));
    LOpcional := LDAOOpcional.Buscar(FVendaItemOpcional.idOpcional);
    LogFechamento('  opcional: buscar opcional ok');
    if Assigned(LOpcional) and (LOpcional.idOpcional > 0) then
    begin
      LDAOSetorEstoqueOpcional := FParent.DAO.SetorEstoqueOpcionalDAO;
      LDAOSetorEstoqueOpcional.ManagerTransaction(False);

      LogFechamento(Format('  opcional: buscar setorEstoque (opc %d setor %d)',
        [LOpcional.idOpcional, LOpcional.idSetor]));
      LSetorEstoqueOpcional := LDAOSetorEstoqueOpcional.Buscar(LOpcional.idOpcional, LOpcional.idSetor);
      LogFechamento('  opcional: buscar setorEstoque ok');
      if Assigned(LSetorEstoqueOpcional) then
      begin
        QuantidadeAnterior                := LSetorEstoqueOpcional.quantidade;
        IdSetor                           := LOpcional.idSetor;
        LSetorEstoqueOpcional.quantidade  := LSetorEstoqueOpcional.quantidade - 1 * FVendaItem.quantidade;
        LSetorEstoqueOpcional.idEmpresa   := FFechamento.idEmpresa;
        LDAOSetorEstoqueOpcional.Alterar(LSetorEstoqueOpcional);
      end
      else
      begin
        LSetorEstoqueOpcional := TAPIRPCheffEntitySetorEstoqueOpcional.Create;
        try
          QuantidadeAnterior := 0;
          IdSetor                           := LOpcional.idSetor;
          LSetorEstoqueOpcional.idOpcional  := LOpcional.idOpcional;
          LSetorEstoqueOpcional.idSetor     := LOpcional.idSetor;
          LSetorEstoqueOpcional.idEmpresa   := FFechamento.idEmpresa;
          LSetorEstoqueOpcional.quantidade := 1 * FVendaItem.quantidade;
          LDAOSetorEstoqueOpcional.Inserir(LSetorEstoqueOpcional);
        finally
          FreeAndNil(LSetorEstoqueOpcional);
        end;
      end;
    end;
  finally
    FreeAndNil(LOpcional);
    if Assigned(LSetorEstoqueOpcional) then
      FreeAndNil(LSetorEstoqueOpcional);
  end;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandInserirMovimentoEstoqueOpcional.InserirMovimentoEstoqueOpcional;
var
LDAO:TAPIRPCheffDAOMovimentoEstoqueOpcional;
LMovimentoEstoqueOpcional:TAPIRPCheffEntityMovimentoEstoqueOpcional;
begin

  LDAO :=FParent.DAO.MovimentoEstoqueOpcionalDAO;
  LDAO.ManagerTransaction(False);
  LMovimentoEstoqueOpcional  :=TAPIRPCheffEntityMovimentoEstoqueOpcional.Create;
  try
    LMovimentoEstoqueOpcional.idEmpresa         := FFechamento.idEmpresa;
    LMovimentoEstoqueOpcional.idOpcional        := FVendaItemOpcional.idOpcional;
    LMovimentoEstoqueOpcional.idVenda           := FVendaItemOpcional.idVenda;
    LMovimentoEstoqueOpcional.quantidade        := 1 * FVendaItem.quantidade;
    LMovimentoEstoqueOpcional.tipoMovimento     :='S';
    LMovimentoEstoqueOpcional.idUsuario         := FFechamento.idUsuario;
    LMovimentoEstoqueOpcional.observacao        := string.Empty;
    LMovimentoEstoqueOpcional.idVendaItem       := FVendaItemOpcional.idVendaItem;
    LMovimentoEstoqueOpcional.Data              := Now;
    LMovimentoEstoqueOpcional.valorCusto        := 0;
    LMovimentoEstoqueOpcional.valorVenda        := FVendaItemOpcional.valor;
    LMovimentoEstoqueOpcional.idFornecedor      := 0;
    LMovimentoEstoqueOpcional.idSetor           := IdSetor;
    LMovimentoEstoqueOpcional.idSetorDestino    := 0;
    LMovimentoEstoqueOpcional.QuantidadeAnterior:= QuantidadeAnterior;
    LDAO.Inserir(LMovimentoEstoqueOpcional);
  finally
   FreeAndNil(LMovimentoEstoqueOpcional);
  end;
end;

end.

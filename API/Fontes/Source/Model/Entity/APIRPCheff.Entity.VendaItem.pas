unit APIRPCheff.Entity.VendaItem;

interface

uses
  GBSwagger.Model.Attributes,
  APIRPCheff.Entity.Types,
  APIRPCheff.Entity.VendaItemOpcional,
  System.SysUtils,
  System.Math,
  System.Generics.Defaults,
  System.Generics.Collections;

type
  TAPIRPCheffEntityVendaItemFracao = class;



  TAPIRPCheffEntityVendaItem = class
  private
    FidEmpresa                 : Integer;
    FidVenda                   : Integer;
    FnumeroItem                : Integer;
    FidProduto                 : Integer;
    FvalorUnitario             : Currency;
    Fquantidade                : Currency;
    FvalorTotal                : Currency;
    Fdesconto                  : Currency;
    FidUsuarioCancelamento     : Integer;
    FdataLancamento            : TDateTime;
    Ftamanho                   : string;
    FvendaPorTamanho           : Boolean;
    Fobservacao                : string;
    Facrescimo                 : Currency;
    Fgratis                    : Boolean;
    FjustificativaCancelamento : string;
    FidGarcom                  : Integer;
    FdataCancelamento          : TDateTime;
    Fimpressora2               : Integer;
    Fimpressora1               : Integer;
    Fsituacao                  : TRPCheffSituacaoItem;
    FpendenteImpressao         : Boolean;
    FprodutoDescricao          : string;
    FprodutoCodReferencia      : string;
    FprodutoIdCategoria        : Integer;
    Fopcionais                 : TObjectList<TAPIRPCheffEntityVendaItemOpcional>;
    FprodutoUtilizaCombo       : Boolean;
    FprodutoIdSetor            : Integer;
    Ffracoes                   : TObjectList<TAPIRPCheffEntityVendaItemFracao>;
    FitemFracionado            : Integer;
    FidMesaVinculada           : Integer;
    FdescricaoTamanho          : string;
    FImprimirFichaIndividual   : Boolean;
    FTerminalImpressao         : string;
    FQuantidadePagaAntecipado  : Currency;
    FValorPagoAntecipado       : Currency;
    FValorTaxaServico          : Currency;
    FnomeGarcom                : string;
    procedure SetOpcionais(const AValue: TObjectList<TAPIRPCheffEntityVendaItemOpcional>);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TAPIRPCheffEntityVendaItem);

    class procedure SepararFracionados(AItens: TObjectList<TAPIRPCheffEntityVendaItem>);
    class function GetFracaoPrincipal(ALista: TObjectList<TAPIRPCheffEntityVendaItem>; ANumeroItemFracionado: Integer): TAPIRPCheffEntityVendaItem;

    function Fracionado: Boolean;
    function TotalFracoes: Currency;
    procedure AtualizaValorTotal;
    function TotalOpcionais: Currency;
    function QuantidadeFracaoPrincipal: Integer;

    [SwagIgnore]
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;

    [SwagProp(False, True)]
    property idVenda: Integer read FidVenda write FidVenda;

    [SwagProp(False, True)]
    property numeroItem: Integer read FnumeroItem write FnumeroItem;

    [SwagProp(False, True)]
    property itemFracionado: Integer read FitemFracionado write FitemFracionado;

    property idProduto: Integer read FidProduto write FidProduto;
    property idMesaVinculada: Integer read FidMesaVinculada write FidMesaVinculada;

    [SwagProp(False, True)]
    property produtoDescricao: string read FprodutoDescricao write FprodutoDescricao;

    [SwagProp(False, True)]
    property descricaoTamanho: string read FdescricaoTamanho write FdescricaoTamanho;

    [SwagProp(False, True)]
    property produtoCodReferencia: string read FprodutoCodReferencia write FprodutoCodReferencia;

    [SwagProp(False, True)]
    property produtoIdCategoria: Integer read FprodutoIdCategoria write FprodutoIdCategoria;

    [SwagProp(False, True)]
    property produtoUtilizaCombo: Boolean read FprodutoUtilizaCombo write FprodutoUtilizaCombo;

    [SwagProp(False, True)]
    property produtoIdSetor: Integer read FprodutoIdSetor write FprodutoIdSetor;

    property dataLancamento: TDateTime read FdataLancamento write FdataLancamento;
    property valorUnitario: Currency read FvalorUnitario write FvalorUnitario;
    property quantidade: Currency read Fquantidade write Fquantidade;
    property valorTotal: Currency read FvalorTotal write FvalorTotal;
    property desconto: Currency read Fdesconto write Fdesconto;
    property acrescimo: Currency read Facrescimo write Facrescimo;
    property observacao: string read Fobservacao write Fobservacao;
    property vendaPorTamanho: Boolean read FvendaPorTamanho write FvendaPorTamanho;
    property tamanho: string read Ftamanho write Ftamanho;
    property gratis: Boolean read Fgratis write Fgratis;
    property opcionais: TObjectList<TAPIRPCheffEntityVendaItemOpcional> read Fopcionais write SetOpcionais;
    property fracoes: TObjectList<TAPIRPCheffEntityVendaItemFracao> read Ffracoes write Ffracoes;
    property ImprimirFichaIndividual: Boolean read fImprimirFichaIndividual write FImprimirFichaIndividual;
    property TerminalImpressao: string read FTerminalImpressao write FTerminalImpressao;
    property QuantidadePagaAntecipado: Currency read FQuantidadePagaAntecipado write FQuantidadePagaAntecipado;
    property ValorPagoAntecipado: Currency read FValorPagoAntecipado write FValorPagoAntecipado;
    property ValorTaxaServico: Currency read FValorTaxaServico write FValorTaxaServico;

    [SwagProp(False, True)]
    property situacao: TRPCheffSituacaoItem read Fsituacao write Fsituacao;

    [SwagProp(False, True)]
    property pendenteImpressao: Boolean read FpendenteImpressao write FpendenteImpressao;

    [SwagProp(False, True)]
    property impressora1: Integer read Fimpressora1 write Fimpressora1;

    [SwagProp(False, True)]
    property impressora2: Integer read Fimpressora2 write Fimpressora2;

    [SwagProp(False, True)]
    property idGarcom: Integer read FidGarcom write FidGarcom;

    [SwagProp(False, True)]
    property idUsuarioCancelamento: Integer read FidUsuarioCancelamento write FidUsuarioCancelamento;

    [SwagProp(False, True)]
    property justificativaCancelamento: string read FjustificativaCancelamento write FjustificativaCancelamento;

    [SwagProp(False, True)]
    property dataCancelamento: TDateTime read FdataCancelamento write FdataCancelamento;

    [SwagProp(False, True)]
    property nomeGarcom: string read FnomeGarcom write FnomeGarcom;
  end;

  TAPIRPCheffEntityVendaItemFracao = class
  private
    FidProduto: Integer;
    FprodutoDescricao: string;
    Fquantidade: Currency;
    FvalorUnitario: Currency;
    FvalorTotal: Currency;
    FnumeroItem: Integer;
    Fobservacao: string;
    Fopcionais: TObjectList<TAPIRPCheffEntityVendaItemOpcional>;
    Facrescimo: Currency;
    FDescricaoTamanho: string;
    procedure SetOpcionais(const AValue: TObjectList<TAPIRPCheffEntityVendaItemOpcional>);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TAPIRPCheffEntityVendaItemFracao);

    property idProduto: Integer read FidProduto write FidProduto;
    property numeroItem: Integer read FnumeroItem write FnumeroItem;
    property produtoDescricao: string read FprodutoDescricao write FprodutoDescricao;
    property quantidade: Currency read Fquantidade write Fquantidade;
    property valorUnitario: Currency read FvalorUnitario write FvalorUnitario;
    property acrescimo: Currency read Facrescimo write Facrescimo;
    property valorTotal: Currency read FvalorTotal write FvalorTotal;
    property observacao: string read Fobservacao write Fobservacao;
    property DescricaoTamanho: string read FDescricaoTamanho write FDescricaoTamanho;
    property opcionais: TObjectList<TAPIRPCheffEntityVendaItemOpcional> read Fopcionais write SetOpcionais;
  end;

  TAPIRPCheffEntityVendaItemCancelamento = class
  private
    FidEmpresa: Integer;
    FidVenda: Integer;
    FnumeroItem: Integer;
    FidUsuario: Integer;
    Fjustificativa: string;
    FdataCancelamento: TDateTime;
  public
    constructor Create;

    property idEmpresa: Integer read FidEmpresa write FidEmpresa;
    property idVenda: Integer read FidVenda write FidVenda;
    property numeroItem: Integer read FnumeroItem write FnumeroItem;
    property idUsuario: Integer read FidUsuario write FidUsuario;
    property justificativa: string read Fjustificativa write Fjustificativa;
    property dataCancelamento: TDateTime read FdataCancelamento write FdataCancelamento;
  end;

implementation

{ TAPIRPCheffEntityVendaItem }

procedure TAPIRPCheffEntityVendaItem.Assign(ASource: TAPIRPCheffEntityVendaItem);
var
  LOpcional: TAPIRPCheffEntityVendaItemOpcional;
  LFracao: TAPIRPCheffEntityVendaItemFracao;
begin
  Self.FidEmpresa                 := ASource.idEmpresa;
  Self.FidVenda                   := ASource.idVenda;
  Self.FnumeroItem                := ASource.numeroItem;
  Self.FidProduto                 := ASource.idProduto;
  Self.FvalorUnitario             := ASource.valorUnitario;
  Self.Fquantidade                := ASource.quantidade;
  Self.FvalorTotal                := ASource.valorTotal;
  Self.Fdesconto                  := ASource.desconto;
  Self.FidUsuarioCancelamento     := ASource.idUsuarioCancelamento;
  Self.FdataLancamento            := ASource.dataLancamento;
  Self.Ftamanho                   := ASource.tamanho;
  Self.FvendaPorTamanho           := ASource.vendaPorTamanho;
  Self.Fobservacao                := ASource.observacao;
  Self.Facrescimo                 := ASource.acrescimo;
  Self.Fgratis                    := ASource.gratis;
  Self.FjustificativaCancelamento := ASource.justificativaCancelamento;
  Self.FidGarcom                  := ASource.idGarcom;
  Self.FdataCancelamento          := ASource.dataCancelamento;
  Self.Fimpressora1               := ASource.impressora1;
  Self.Fimpressora2               := ASource.impressora2;
  Self.Fsituacao                  := ASource.situacao;
  Self.FpendenteImpressao         := ASource.pendenteImpressao;
  Self.FprodutoDescricao          := ASource.produtoDescricao;
  Self.FprodutoCodReferencia      := ASource.produtoCodReferencia;
  Self.FprodutoIdCategoria        := ASource.FprodutoIdCategoria;
  Self.FprodutoUtilizaCombo       := ASource.produtoUtilizaCombo;
  Self.FprodutoIdSetor            := ASource.produtoIdSetor;
  Self.FitemFracionado            := ASource.itemFracionado;
  Self.FTerminalImpressao         :=ASource.TerminalImpressao;
  Self.FnomeGarcom                := ASource.nomeGarcom;

  for LOpcional in ASource.opcionais do
  begin
    Self.opcionais.Add(TAPIRPCheffEntityVendaItemOpcional.Create);
    Self.opcionais.Last.Assign(LOpcional);
  end;

  for LFracao in ASource.fracoes do
  begin
    Self.fracoes.Add(TAPIRPCheffEntityVendaItemFracao.Create);
    Self.fracoes.Last.Assign(LFracao);
  end;
end;

procedure TAPIRPCheffEntityVendaItem.AtualizaValorTotal;
begin
  FvalorTotal := (FvalorUnitario * Fquantidade);
  FvalorTotal := SimpleRoundTo(FvalorTotal + Facrescimo - Fdesconto, -2);
end;

constructor TAPIRPCheffEntityVendaItem.Create;
begin
  Fopcionais := TObjectList<TAPIRPCheffEntityVendaItemOpcional>.Create;
  Ffracoes := TObjectList<TAPIRPCheffEntityVendaItemFracao>.Create;
  FvendaPorTamanho := False;
  Ftamanho := 'M';
  Fsituacao := siOK;
  FpendenteImpressao := True;
  FprodutoUtilizaCombo := False;
  Fgratis := False;
end;

destructor TAPIRPCheffEntityVendaItem.Destroy;
begin
  FreeAndNil(Fopcionais);
  FreeAndNil(Ffracoes);
  inherited;
end;

function TAPIRPCheffEntityVendaItem.Fracionado: Boolean;
begin
  Result := FitemFracionado > 0;
end;

class function TAPIRPCheffEntityVendaItem.GetFracaoPrincipal(ALista: TObjectList<TAPIRPCheffEntityVendaItem>;
  ANumeroItemFracionado: Integer): TAPIRPCheffEntityVendaItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Pred(ALista.Count) do
    if ALista[I].itemFracionado = ANumeroItemFracionado then
      Exit(ALista[I]);
end;

function TAPIRPCheffEntityVendaItem.QuantidadeFracaoPrincipal: Integer;
var
  LTotalFracoes: Integer;
  I: Integer;
begin
  LTotalFracoes := 0;
  for I := 0 to Pred(Ffracoes.Count) do
    Inc(LTotalFracoes);
  Result := 4 - LTotalFracoes;
end;

class procedure TAPIRPCheffEntityVendaItem.SepararFracionados(AItens: TObjectList<TAPIRPCheffEntityVendaItem>);
var
  I: Integer;
  LItem: TAPIRPCheffEntityVendaItem;
  LFracaoPrincipal: TAPIRPCheffEntityVendaItem;
begin
  for I := Pred(AItens.Count) downto 0 do
  begin
    LItem := AItens[I];
    if LItem.Fracionado then
    begin
      LFracaoPrincipal := GetFracaoPrincipal(AItens, LItem.itemFracionado);

      begin
        LFracaoPrincipal.fracoes.Add(TAPIRPCheffEntityVendaItemFracao.Create);
        LFracaoPrincipal.fracoes.Last.idProduto := LItem.idProduto;
        LFracaoPrincipal.fracoes.Last.numeroItem := LItem.numeroItem;
        LFracaoPrincipal.fracoes.Last.produtoDescricao := LItem.produtoDescricao;
        LFracaoPrincipal.fracoes.Last.quantidade := LItem.quantidade;
        LFracaoPrincipal.fracoes.Last.valorUnitario := LItem.valorUnitario;
        LFracaoPrincipal.fracoes.Last.valorTotal := LItem.valorTotal;
        LFracaoPrincipal.fracoes.Last.observacao := LItem.observacao;
        LFracaoPrincipal.fracoes.Last.DescricaoTamanho:=LItem.descricaoTamanho;

        for var LOpcional in LItem.opcionais do
        begin
          LFracaoPrincipal.fracoes.Last.opcionais.Add(TAPIRPCheffEntityVendaItemOpcional.Create);
          LFracaoPrincipal.fracoes.Last.opcionais.Last.Assign(LOpcional);
        end;

        if LFracaoPrincipal.numeroItem <> LItem.numeroItem then
        begin
          AItens.Extract(LItem);
          LItem.Free;
        end;

        if LFracaoPrincipal.fracoes.Count > 1 then
          LFracaoPrincipal.fracoes.Sort(TComparer<TAPIRPCheffEntityVendaItemFracao>.Construct(
            function(const ALeft, ARight: TAPIRPCheffEntityVendaItemFracao): Integer
            begin
              if ALeft.numeroItem = ARight.numeroItem then
                Result := 0
              else if ALeft.numeroItem < ARight.numeroItem then
                Result := -1
              else
                Result := 1;
            end));
      end;
    end;
  end;
end;

procedure TAPIRPCheffEntityVendaItem.SetOpcionais(const AValue: TObjectList<TAPIRPCheffEntityVendaItemOpcional>);
begin
  FreeAndNil(Fopcionais);
  Fopcionais := AValue;
end;

function TAPIRPCheffEntityVendaItem.TotalFracoes: Currency;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Pred(Ffracoes.Count) do
    Result := Result + Ffracoes.Items[I].valorTotal;
end;

function TAPIRPCheffEntityVendaItem.TotalOpcionais: Currency;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Pred(Fopcionais.Count) do
    Result := Result + (Fopcionais[I].valor * Fquantidade);
end;

{ TAPIRPCheffEntityVendaItemFracao }

procedure TAPIRPCheffEntityVendaItemFracao.Assign(ASource: TAPIRPCheffEntityVendaItemFracao);
begin
  Self.idProduto := ASource.idProduto;
  Self.produtoDescricao := ASource.produtoDescricao;
  Self.quantidade := ASource.quantidade;
  Self.valorUnitario := ASource.valorUnitario;
  Self.valorTotal := ASource.valorTotal;
  Self.acrescimo := ASource.acrescimo;
  Self.numeroItem := ASource.numeroItem;
  Self.observacao := ASource.observacao;
  Self.DescricaoTamanho:=ASource.DescricaoTamanho;

  for var LOpcional in ASource.opcionais do
  begin
    Self.opcionais.Add(TAPIRPCheffEntityVendaItemOpcional.Create);
    Self.opcionais.Last.Assign(LOpcional);
  end;
end;

constructor TAPIRPCheffEntityVendaItemFracao.Create;
begin
  Fopcionais := TObjectList<TAPIRPCheffEntityVendaItemOpcional>.Create;
end;

destructor TAPIRPCheffEntityVendaItemFracao.Destroy;
begin
  FreeAndNil(Fopcionais);
  inherited;
end;

procedure TAPIRPCheffEntityVendaItemFracao.SetOpcionais(const AValue: TObjectList<TAPIRPCheffEntityVendaItemOpcional>);
begin
  FreeAndNil(Fopcionais);
  Fopcionais := AValue;
end;

{ TAPIRPCheffEntityVendaItemCancelamento }

constructor TAPIRPCheffEntityVendaItemCancelamento.Create;
begin
  FdataCancelamento := Now;
end;

end.

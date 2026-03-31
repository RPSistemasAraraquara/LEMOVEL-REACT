unit APIRPCheff.Entity.ImpressaoProducao;

interface

uses
  System.SysUtils;

type
  TAPIRPCheffEntityImpressaoProducao = class
  private
    FIdProduto           : Integer;
    FQtdeVendido         : double;
    FDescricaoProduto    : String;
    FDataLancamento      : TDateTime;
    FProdutoFoiImpresso  : Boolean;
    FNomeGarcom          : string;
    FQuantidadeImpressao : Integer;
    FIdEmpresa           : Integer;
    FIdVenda             : Integer;
    FTipoVenda           : String;
    FImpressoraInterna   : Boolean;

  public
    property IdProduto             : Integer read FIdProduto                           write FIdProduto;
    property IdEmpresa           : Integer read FIdEmpresa write FIdEmpresa;
    property QtdeVendido         : double read FQtdeVendido                        write FQtdeVendido;
    property DescricaoProduto    : String read FDescricaoProduto              write FDescricaoProduto;
    property DataLancamento      : TDateTime read FDataLancamento               write FDataLancamento;
    property ProdutoFoiImpresso  : Boolean read FProdutoFoiImpresso         write FProdutoFoiImpresso;
    property NomeGarcom          : string read FNomeGarcom                          write FNomeGarcom;
    property QuantidadeImpressao : Integer read FQuantidadeImpressao       write FQuantidadeImpressao;
    property IdVenda             : Integer read FIdVenda write FIdVenda;
    property TipoVenda           : String read FTipoVenda write FTipoVenda;
    property ImpressoraInterna   : Boolean read FImpressoraInterna write FImpressoraInterna;

  end;

implementation

end.

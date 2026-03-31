unit APIRPCheff.Entity.MovimentoEstoqueComposicao;

interface

type
  TAPIRPCheffEntityMovimentoEstoqueComposicao = class
  private
    FidEmpresa          : Integer;
    FidComposicao       : Integer;
    Fquantidade         : Currency;
    FidUsuario          : Integer;
    Fobservacao         : string;
    FtipoMovimento      : string;
    Fdata               : TDateTime;
    FidFornecedor       : Integer;
    FvalorVenda         : Currency;
    FvalorCusto         : Currency;
    FidVenda            : Integer;
    FidVendaItem        : Integer;
    FidSetor            : Integer;
    FidSetorDestino     : Integer;
  public
    property idEmpresa        : Integer     read FidEmpresa         write FidEmpresa;
    property idComposicao     : Integer     read FidComposicao      write FidComposicao;
    property quantidade       : Currency    read Fquantidade        write Fquantidade;
    property idUsuario        : Integer     read FidUsuario         write FidUsuario;
    property observacao       : string      read Fobservacao        write Fobservacao;
    property tipoMovimento    : string      read FtipoMovimento     write FtipoMovimento;
    property data             : TDateTime   read Fdata              write Fdata;
    property idFornecedor     : Integer     read FidFornecedor      write FidFornecedor;
    property valorVenda       : Currency    read FvalorVenda        write FvalorVenda;
    property valorCusto       : Currency    read FvalorCusto        write FvalorCusto;
    property idVenda          : Integer     read FidVenda           write FidVenda;
    property idVendaItem      : Integer     read FidVendaItem       write FidVendaItem;
    property idSetor          : Integer     read FidSetor           write FidSetor;
    property idSetorDestino   : Integer     read FidSetorDestino    write FidSetorDestino;
  end;

implementation

end.

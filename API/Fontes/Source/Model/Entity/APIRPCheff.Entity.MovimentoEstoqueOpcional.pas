unit APIRPCheff.Entity.MovimentoEstoqueOpcional;

interface

type
  TAPIRPCheffEntityMovimentoEstoqueOpcional = class
  private
    FidEmpresa          : Integer;
    FidOpcional         : Integer;
    FidVenda            : Integer;
    Fquantidade         : Currency;
    FtipoMovimento      : string;
    FidUsuario          : Integer;
    Fobservacao         : string;
    FidVendaItem        : Integer;
    Fdata               : TDateTime;
    FvalorCusto         : Currency;
    FvalorVenda         : Currency;
    FidFornecedor       : Integer;
    FidSetor            : Integer;
    FidSetorDestino     : Integer;
    FQuantidadeAnterior : Double;

  public
    property idEmpresa            : Integer     read FidEmpresa             write FidEmpresa;
    property idOpcional           : Integer     read FidOpcional            write FidOpcional;
    property idVenda              : Integer     read FidVenda               write FidVenda;
    property quantidade           : Currency    read Fquantidade            write Fquantidade;
    property tipoMovimento        : string      read FtipoMovimento         write FtipoMovimento;
    property idUsuario            : Integer     read FidUsuario             write FidUsuario;
    property observacao           : string      read Fobservacao            write Fobservacao;
    property idVendaItem          : Integer     read FidVendaItem           write FidVendaItem;
    property data                 : TDateTime   read Fdata                  write Fdata;
    property valorCusto           : Currency    read FvalorCusto            write FvalorCusto;
    property valorVenda           : Currency    read FvalorVenda            write FvalorVenda;
    property idFornecedor         : Integer     read FidFornecedor          write FidFornecedor;
    property idSetor              : Integer     read FidSetor               write FidSetor;
    property idSetorDestino       : Integer     read FidSetorDestino        write FidSetorDestino;
    property QuantidadeAnterior   : Double      read FQuantidadeAnterior    write FQuantidadeAnterior;

  end;

implementation




end.

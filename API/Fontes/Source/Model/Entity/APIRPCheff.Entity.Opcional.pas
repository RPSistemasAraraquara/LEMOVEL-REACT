unit APIRPCheff.Entity.Opcional;

interface

uses
  APIRPCheff.Entity.Types;

type
  TAPIRPCheffEntityOpcional = class
  private
    FidOpcional           : Integer;
    FidEmpresa            : Integer;
    Fdescricao            : string;
    Fvalor                : Currency;
    FopcionalP            : string;
    FopcionalM            : string;
    FopcionalG            : string;
    FopcionalGG           : string;
    FopcionalExtra        : string;
    FvalorOpcionalP       : Currency;
    FvalorOpcionalM       : Currency;
    FvalorOpcionalG       : Currency;
    FvalorOpcionalGG      : Currency;
    FvalorOpcionalExtra   : Currency;
    Ftipo                 : TRPCheffTipoOpcional;
    Fidsetor              : Integer;
    FValorCusto           : Currency;
  public
    property idOpcional         : Integer                read FidOpcional         write FidOpcional;
    property idEmpresa          : Integer                read FidEmpresa          write FidEmpresa;
    property descricao          : string                 read Fdescricao          write Fdescricao;
    property valor              : Currency               read Fvalor              write Fvalor;
    property opcionalP          : string                 read FopcionalP          write FopcionalP;
    property opcionalM          : string                 read FopcionalM          write FopcionalM;
    property opcionalG          : string                 read FopcionalG          write FopcionalG;
    property opcionalGG         : string                 read FopcionalGG         write FopcionalGG;
    property opcionalExtra      : string                 read FopcionalExtra      write FopcionalExtra;
    property valorOpcionalP     : Currency               read FvalorOpcionalP     write FvalorOpcionalP;
    property valorOpcionalM     : Currency               read FvalorOpcionalM     write FvalorOpcionalM;
    property valorOpcionalG     : Currency               read FvalorOpcionalG     write FvalorOpcionalG;
    property valorOpcionalGG    : Currency               read FvalorOpcionalGG    write FvalorOpcionalGG;
    property valorOpcionalExtra : Currency               read FvalorOpcionalExtra write FvalorOpcionalExtra;
    property tipo               : TRPCheffTipoOpcional   read Ftipo               write Ftipo;
    property idsetor            : Integer                read Fidsetor            write Fidsetor;
    property ValorCusto         : Currency               read FValorCusto         write FValorCusto;
  end;

implementation

end.

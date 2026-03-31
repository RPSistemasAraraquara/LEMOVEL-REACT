unit APIRPCheff.Entity.Usuario;

interface

type
  TAPIRPCheffEntityLogin = class
  private
    Flogin: string;
    Fsenha: string;
  public
    property login: string read Flogin write Flogin;
    property senha: string read Fsenha write Fsenha;
  end;

  TAPIRPCheffEntityUsuario = class
  private
    FidUsuario                       : Integer;
    Fnome                            : string;
    Flogin                           : string;
    Fsenha                           : string;
    FtransferenciaMesa               : Boolean;
    FpermiteCancelarItemMobile       : Boolean;
    FpermitePreFechamentoMesaComanda : Boolean;
    FpermiteFechamentoMesaComanda    : Boolean;
    FpermiteAlterarTaxa10            : Boolean;
    FfuncaoGarcom                    : Boolean;
    FidEmpresa                       : Integer;
    FdescontoMaximo                  : Currency;
    FPermiteJuntarMesaComanda        : Boolean;
    FPermiteReabrirMesaComanda       : Boolean;
    FPermitePagamentoParcial         : Boolean;
    FPermiteDescontoFechamento       : Boolean;
  public
    constructor Create;

    property idUsuario                      : Integer   read FidUsuario                       write FidUsuario;
    property idEmpresa                      : Integer   read FidEmpresa                       write FidEmpresa;
    property nome                           : string    read Fnome                            write Fnome;
    property login                          : string    read Flogin                           write Flogin;
    property senha                          : string    read Fsenha                           write Fsenha;
    property transferenciaMesa              : Boolean   read FtransferenciaMesa               write FtransferenciaMesa;
    property permiteCancelarItemMobile      : Boolean   read FpermiteCancelarItemMobile       write FpermiteCancelarItemMobile;
    property permitePreFechamentoMesaComanda: Boolean   read FpermitePreFechamentoMesaComanda write FpermitePreFechamentoMesaComanda;
    property permiteFechamentoMesaComanda   : Boolean   read FpermiteFechamentoMesaComanda    write FpermiteFechamentoMesaComanda;
    property permiteAlterarTaxa10           : Boolean   read FpermiteAlterarTaxa10            write FpermiteAlterarTaxa10;
    property funcaoGarcom                   : Boolean   read FfuncaoGarcom                    write FfuncaoGarcom;
    property descontoMaximo                 : Currency  read FdescontoMaximo                  write FdescontoMaximo;
    property PermiteJuntarMesaComanda       : Boolean   read FPermiteJuntarMesaComanda        write FPermiteJuntarMesaComanda;
    property PermiteReabrirMesaComanda      : Boolean   read FPermiteReabrirMesaComanda       write FPermiteReabrirMesaComanda;
    property PermitePagamentoParcial        : Boolean   read FPermitePagamentoParcial         write FPermitePagamentoParcial;
    property PermiteDescontoFechamento      : Boolean   read FPermiteDescontoFechamento       write FPermiteDescontoFechamento;
  end;

implementation

{ TAPIRPCheffEntityUsuario }

constructor TAPIRPCheffEntityUsuario.Create;
begin
  FtransferenciaMesa               := False;
  FpermiteCancelarItemMobile       := False;
  FpermitePreFechamentoMesaComanda := False;
  FpermiteFechamentoMesaComanda    := False;
  FpermiteAlterarTaxa10            := False;
  FfuncaoGarcom                    := True;
  FPermiteJuntarMesaComanda        := False;
  FPermiteReabrirMesaComanda       := False;
  FPermitePagamentoParcial         := False;
  FPermiteDescontoFechamento       := False;
end;

end.

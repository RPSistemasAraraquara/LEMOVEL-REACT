unit APIRPCheff.Entity.Empresa;

interface

uses
  APIRPCheff.Entity.Types;

type
  TAPIRPCheffEntityEmpresa = class
  private
    FidEmpresa                           : Integer;
    Fnome                                : string;
    FcasaNoturna                         : Boolean;
    FtaxaAdicionalMesa                   : Boolean;
    FcouvertMesa                         : Boolean;
    FcouvertObrigatorioMesa              : Boolean;
    FconsumacaoMesa                      : Boolean;
    FvalorCouvertMasculinoMesa           : Currency;
    FvalorCouvertFemininoMesa            : Currency;
    FconsumacaoMinimaMesa                : Currency;
    FtaxaAdicionalComanda                : Boolean;
    FcouvertComanda                      : Boolean;
    FcouvertObrigatorioComanda           : Boolean;
    FvalorCouvertMasculinoComanda        : Currency;
    FvalorCouvertFemininoComanda         : Currency;
    FconsumacaoComanda                   : Boolean;
    FconsumacaoMinimaComanda             : Currency;
    FpermiteTrocoTodasAsFormas           : Boolean;
    FatualizaCustoMaterialComposicao     : Boolean;
    FconsideraRedimentoEntradaComposicao : Boolean;
    Fendereco                            : string;
    Fnumero                              : string;
    FtelefonePrincipal                   : Integer;
    Ftelefone                            : string;
    Fcelular                             : string;
    FcasaControle                        : TRPCheffTipoCasaControle;
    FutilizaRPMovel                      : Boolean;
    FutilizaIntegracaoStone              : Boolean;
    FUtilizaFichaIndividualMesa          : Boolean;
    FUtilizaFichaIndividualComanda       : Boolean;
    FutilizaIntegracaoCielo: Boolean;
    FutilizaIntegracaoPagBank: Boolean;
  public
    constructor Create;

    property idEmpresa: Integer                           read FidEmpresa                               write FidEmpresa;
    property nome: string                                 read Fnome                                    write Fnome;
    property endereco: string                             read Fendereco                                write Fendereco;
    property numero: string                               read Fnumero                                  write Fnumero;
    property telefonePrincipal: Integer                   read FtelefonePrincipal                       write FtelefonePrincipal;
    property telefone: string                             read Ftelefone                                write Ftelefone;
    property celular: string                              read Fcelular                                 write Fcelular;
    property casaNoturna: Boolean                         read FcasaNoturna                             write FcasaNoturna;
    property casaControle: TRPCheffTipoCasaControle       read FcasaControle                            write FcasaControle;
    property taxaAdicionalMesa: Boolean                   read FtaxaAdicionalMesa                       write FtaxaAdicionalMesa;
    property couvertMesa: Boolean                         read FcouvertMesa                             write FcouvertMesa;
    property couvertObrigatorioMesa: Boolean              read FcouvertObrigatorioMesa                  write FcouvertObrigatorioMesa;
    property valorCouvertMasculinoMesa: Currency          read FvalorCouvertMasculinoMesa               write FvalorCouvertMasculinoMesa;
    property valorCouvertFemininoMesa: Currency           read FvalorCouvertFemininoMesa                write FvalorCouvertFemininoMesa;
    property consumacaoMesa: Boolean                      read FconsumacaoMesa                          write FconsumacaoMesa;
    property consumacaoMinimaMesa: Currency               read FconsumacaoMinimaMesa                    write FconsumacaoMinimaMesa;
    property taxaAdicionalComanda: Boolean                read FtaxaAdicionalComanda                    write FtaxaAdicionalComanda;
    property couvertComanda: Boolean                      read FcouvertComanda                          write FcouvertComanda;
    property couvertObrigatorioComanda: Boolean           read FcouvertObrigatorioComanda               write FcouvertObrigatorioComanda;
    property valorCouvertMasculinoComanda: Currency       read FvalorCouvertMasculinoComanda            write FvalorCouvertMasculinoComanda;
    property valorCouvertFemininoComanda: Currency        read FvalorCouvertFemininoComanda             write FvalorCouvertFemininoComanda;
    property consumacaoComanda: Boolean                   read FconsumacaoComanda                       write FconsumacaoComanda;
    property consumacaoMinimaComanda: Currency            read FconsumacaoMinimaComanda                 write FconsumacaoMinimaComanda;
    property permiteTrocoTodasAsFormas: Boolean           read FpermiteTrocoTodasAsFormas               write FpermiteTrocoTodasAsFormas;
    property atualizaCustoMaterialComposicao: Boolean     read FatualizaCustoMaterialComposicao         write FatualizaCustoMaterialComposicao;
    property consideraRedimentoEntradaComposicao: Boolean read FconsideraRedimentoEntradaComposicao     write FconsideraRedimentoEntradaComposicao;
    property utilizaRPMovel: Boolean                      read FutilizaRPMovel                          write FutilizaRPMovel;
    property utilizaIntegracaoStone: Boolean              read FutilizaIntegracaoStone                  write FutilizaIntegracaoStone;
    property UtilizaFichaIndividualMesa: Boolean          read FUtilizaFichaIndividualMesa              write FUtilizaFichaIndividualMesa;
    property UtilizaFichaIndividualComanda: Boolean       read FUtilizaFichaIndividualComanda           write FUtilizaFichaIndividualComanda;
    property utilizaIntegracaoCielo: Boolean              read FutilizaIntegracaoCielo                  write FutilizaIntegracaoCielo;
    property utilizaIntegracaoPagBank: Boolean            read FutilizaIntegracaoPagBank                write FutilizaIntegracaoPagBank;
  end;

implementation

{ TAPIRPCheffEntityEmpresa }

constructor TAPIRPCheffEntityEmpresa.Create;
begin
  FcasaNoturna               := False;
  FtaxaAdicionalMesa         := False;
  FcouvertMesa               := False;
  FcouvertObrigatorioMesa    := False;
  FconsumacaoMesa            := False;
  FtaxaAdicionalComanda      := False;
  FcouvertComanda            := False;
  FcouvertObrigatorioComanda := False;
  FconsumacaoComanda         := False;
  FpermiteTrocoTodasAsFormas := False;
  FutilizaIntegracaoCielo    := False;
  FutilizaIntegracaoPagBank  := False;
end;

end.

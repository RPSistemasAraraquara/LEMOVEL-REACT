unit APIRPCheff.Entity.Configuracao;

interface

type
  TAPIRPCheffEntityConfiguracaoMesaComanda = class
  private
    FidEmpresa                 : Integer;
    FtempoConsumo              : Integer;
    FutilizaTaxaServico        : Boolean;
    FpercentualTaxaServico     : Currency;
    FutilizaCouvert            : Boolean;
    FcouvertObrigatorio        : Boolean;
    FvalorCouvertMasculino     : Currency;
    FvalorCouvertFeminino      : Currency;
    FutilizaConsumacaoMinima   : Boolean;
    FconsumacaoMinima          : Currency;
    FpermiteTrocoTodasAsFormas : Boolean;
  public
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;
    property tempoConsumo: Integer read FtempoConsumo write FtempoConsumo;
    property utilizaTaxaServico: Boolean read FutilizaTaxaServico write FutilizaTaxaServico;
    property percentualTaxaServico: Currency read FpercentualTaxaServico write FpercentualTaxaServico;
    property utilizaCouvert: Boolean read FutilizaCouvert write FutilizaCouvert;
    property couvertObrigatorio: Boolean read FcouvertObrigatorio write FcouvertObrigatorio;
    property valorCouvertMasculino: Currency read FvalorCouvertMasculino write FvalorCouvertMasculino;
    property valorCouvertFeminino: Currency read FvalorCouvertFeminino write FvalorCouvertFeminino;
    property utilizaConsumacaoMinima: Boolean read FutilizaConsumacaoMinima write FutilizaConsumacaoMinima;
    property consumacaoMinima: Currency read FconsumacaoMinima write FconsumacaoMinima;
    property permiteTrocoTodasAsFormas: Boolean read FpermiteTrocoTodasAsFormas write FpermiteTrocoTodasAsFormas;
  end;

  TAPIRPCheffEntityConfiguracaoComanda = class(TAPIRPCheffEntityConfiguracaoMesaComanda)
  end;

  TAPIRPCheffEntityConfiguracaoMesa = class(TAPIRPCheffEntityConfiguracaoMesaComanda)
  end;

implementation

end.

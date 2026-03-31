unit APIRPCheff.Entity.Venda.PagamentoAntecipadoItens;

interface

uses
 System.SysUtils;

 type
 TAPIRPCheffEntityVendaPagamentoAntecipadoItens = class

 private
    FId             : Integer;
    FIdEmpresa      : Integer;
    FNumeroItem     : Integer;
    FIdMaterial     : Integer;
    FQuantidadePaga : Currency;
    FValorPago      : Currency;
    FUnitario       : Currency;


 public
    property Id             : Integer   read FId              write FId;
    property IdEmpresa      : Integer   read FIdEmpresa       write FIdEmpresa;
    property NumeroItem     : Integer   read FNumeroItem      write FNumeroItem;
    property IdMaterial     : Integer   read FIdMaterial      write FIdMaterial;
    property QuantidadePaga : Currency  read FQuantidadePaga  write FQuantidadePaga;
    property ValorPago      : Currency  read FValorPago       write FValorPago;
    property Unitario       : Currency  read FUnitario        write FUnitario;


 end;


implementation

end.

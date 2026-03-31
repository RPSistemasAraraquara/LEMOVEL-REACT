unit APIRPCheff.Context.Venda.PagamentoParcial;

interface

uses
  System.Generics.Collections,
  APIRPCheff.Entity.Classes;

type

  PAPIRPCheffContextVendaPagamentoParcial = ^TAPIRPCheffContextVendaPagamentoParcial;

  TAPIRPCheffContextVendaPagamentoParcial = record
    PagamentoAntecipado: TAPIRPCheffEntityVendaPagamentoAntecipado;
    Venda: TAPIRPCheffEntityVenda;
  end;

implementation

end.

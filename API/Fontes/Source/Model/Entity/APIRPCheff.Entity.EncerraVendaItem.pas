unit APIRPCheff.Entity.EncerraVendaItem;

interface

uses
  System.SysUtils,
  APIRPCheff.Entity.FormaPagamento;

type
  TAPIRPCheffEntityEncerraVendaItem = class
  private
    FidEmpresa         : Integer;
    FidEncerraVenda : Integer;
    FnumeroItem     : Integer;
    Fvalor          : Currency;
    FidFormaPgto    : Integer;
    FtrocoDinheiro  : Currency;
    FnovaVenda      : Boolean;
    FformaPagamento : TAPIRPCheffEntityFormaPagamento;
  public
    constructor Create;
    destructor Destroy; override;

    function ValorPago: Currency;

    property idEmpresa      : Integer                              read FidEmpresa           write FidEmpresa;
    property idEncerraVenda : Integer                              read FidEncerraVenda write FidEncerraVenda;
    property numeroItem     : Integer                              read FnumeroItem         write FnumeroItem;
    property valor          : Currency                             read Fvalor                  write Fvalor;
    property idFormaPgto    : Integer                              read FidFormaPgto       write FidFormaPgto;
    property trocoDinheiro  : Currency                             read FtrocoDinheiro  write FtrocoDinheiro;
    property novaVenda      : Boolean                              read FnovaVenda           write FnovaVenda;
    property formaPagamento : TAPIRPCheffEntityFormaPagamento      read FformaPagamento;
  end;

implementation

{ TAPIRPCheffEntityEncerraVendaItem }

constructor TAPIRPCheffEntityEncerraVendaItem.Create;
begin
  FformaPagamento := TAPIRPCheffEntityFormaPagamento.Create;
end;

destructor TAPIRPCheffEntityEncerraVendaItem.Destroy;
begin
  FreeAndNil(FformaPagamento);
  inherited;
end;

function TAPIRPCheffEntityEncerraVendaItem.ValorPago: Currency;
begin
  Result := Fvalor + FtrocoDinheiro;
end;

end.

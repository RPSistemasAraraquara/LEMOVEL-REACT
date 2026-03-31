unit APIRPCheff.Service.Venda.ImpressaoSTONE.NFCe;

interface

uses
  System.SysUtils,
  System.Classes,
  System.NetEncoding,
  System.JSON,
  RPNFe.Entity.Classes,
  APIRPCheff.Service.Venda.Impressao;

type
  TAPIRPCheffServiceVendaImpressaStoneNFCe = class(TAPIRPCheffServiceVendaImpressao)
  private
    function GetCupom: string;
  public
    function Execute: TStream; override;
  end;

implementation

{ TAPIRPCheffServiceVendaImpressaStoneNFCe }

function TAPIRPCheffServiceVendaImpressaStoneNFCe.Execute: TStream;
var
  LCupom64: string;
  LJSON: TJSONObject;
  LJSONArray: TJSONArray;
begin
  LCupom64 := GetCupom;
  LJSONArray := TJSONArray.Create;
  try
    LJSON := TJSONObject.Create;
    LJSONArray.Add(LJSON);
    LJSON.AddPair('type', 'image')
      .AddPair('imagePath', LCupom64);

    Result := TStringStream.Create(LJSONArray.ToString, TEncoding.UTF8)
  finally
    LJSONArray.Free;
  end;
end;

function TAPIRPCheffServiceVendaImpressaStoneNFCe.GetCupom: string;
var
  LStream: TMemoryStream;
  LStringStream: TStringStream;
begin
  LStream := FComponents.RPNFe.Service.ImpressaoService
    .IdVenda(FIdVenda)
    .TipoDanfe(tdImage)
    .Execute;
  try
    LStringStream := TStringStream.Create(EmptyStr);
    try
      TNetEncoding.Base64.Encode(LStream, LStringStream);
      Result := LStringStream.DataString;
    finally
      LStringStream.Free;
    end;
  finally
    LStream.Free;
  end;
end;

end.

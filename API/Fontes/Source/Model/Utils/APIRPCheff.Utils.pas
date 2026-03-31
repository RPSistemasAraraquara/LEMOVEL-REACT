unit APIRPCheff.Utils;

interface

uses
  System.SysUtils,
  System.Classes,
  System.StrUtils;

function AcertaTexto(const ATexto, ADirecao: string; const AQuantidade: Integer;
  ACaracterPreenchimento: string = ' '): string;
function QuebraLinhaItemCupom(ATextoItem: string; ALarguraAjuste: integer;
  ATextoAnterior: string = ''; ATextoPosterior: string = ''): string;
function ReplicarCaracter(const ACaracter: string; const AQuantidade: Integer): string;

implementation

function AcertaTexto(const ATexto, ADirecao: string; const AQuantidade: Integer;
  ACaracterPreenchimento: string = ' '): string;
var
  AQuantidadeDireita: Integer;
  AQuantidadeEspacos: Integer;
begin
  Result := ATexto;
  if ADirecao = 'E' then
    Result := ATexto + ReplicarCaracter(ACaracterPreenchimento, AQuantidade - Length(ATexto))
  else
  if ADirecao = 'D' then
    Result := ReplicarCaracter(ACaracterPreenchimento, AQuantidade - Length(ATexto)) + ATexto
  else
  if ADirecao = 'C' then
  begin
    AQuantidadeEspacos := AQuantidade - Length(ATexto);
    AQuantidadeDireita := AQuantidadeEspacos div 2;

    Result := ReplicarCaracter(ACaracterPreenchimento, AQuantidadeDireita) + ATexto +
      ReplicarCaracter(ACaracterPreenchimento, AQuantidadeEspacos - AQuantidadeDireita);
  end;

  Result := Copy(Result, 1, AQuantidade);
end;

function QuebraLinhaItemCupom(ATextoItem: string; ALarguraAjuste: Integer;
  ATextoAnterior: string = ''; ATextoPosterior: string = ''): string;
var
  LLarguraAnterior: Integer;
  LLarguraPosterior: Integer;
  LLarguraItem: Integer;
  LPosicao: Integer;
  LStrFinal: string;
  LStrAux: string;
begin
  LLarguraAnterior := Length(ATextoAnterior) ;
  LLarguraPosterior := Length(ATextoPosterior) ;
  LLarguraItem := Length(ATextoItem) ;

  //monta a primeira linha
  LStrFinal :=  ATextoAnterior + AcertaTexto(Copy(ATextoItem, 0, ALarguraAjuste), 'E', ALarguraAjuste) + ATextoPosterior;
  //se o tamanho for maior, quebra o texto do item...
  if Length(ATextoItem) > ALarguraAjuste then
  begin
    LPosicao := ALarguraAjuste + 1;
    while LPosicao < LLarguraItem do
    begin
      LStrAux := sLineBreak + ReplicarCaracter(' ', LLarguraAnterior) +
        AcertaTexto(Copy(ATextoItem, LPosicao, ALarguraAjuste), 'E', ALarguraAjuste) +
        ReplicarCaracter(' ', LLarguraPosterior);
      LPosicao := LPosicao + ALarguraAjuste;
      LStrFinal := LStrFinal + LStrAux;
    end;
  end;
  Result := LStrFinal;
end;

function ReplicarCaracter(const ACaracter: string; const AQuantidade: Integer): string;
var
  LPrimeiraLetra: Char;
begin
  try
    LPrimeiraLetra := ACaracter[1];
  except
    LPrimeiraLetra := #0;
  end;
  Result := StringOfChar(LPrimeiraLetra, AQuantidade);
end;

end.

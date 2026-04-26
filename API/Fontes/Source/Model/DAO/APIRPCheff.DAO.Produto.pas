unit APIRPCheff.DAO.Produto;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TAPIRPCheffDAOProduto = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityProduto>)
  private
    FExibirImagem: Boolean;
    procedure CarregarRelacionamentos(AProdutos: TObjectList<TAPIRPCheffEntityProduto>);
    procedure SelectProdutos;
    function CompactarImagemJpeg(const ABytes: TBytes): TMemoryStream;
    function CompactarImagemBase64(const ABytes: TBytes): string;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityProduto; override;
  public
    function ExibirImagem(AValue: Boolean): TAPIRPCheffDAOProduto;
    function BuscarImagem(AIdProduto: Integer): TMemoryStream;
    function Buscar(AIdProduto: Integer): TAPIRPCheffEntityProduto;
    function Lista: TObjectList<TAPIRPCheffEntityProduto>; overload;
    function Lista(AIdCategoria: Integer): TObjectList<TAPIRPCheffEntityProduto>; overload;
  end;

implementation

{ TAPIRPCheffDAOProduto }

uses
  APIRPCheff.DAO.Factory,
  System.Math,
  System.NetEncoding,
  Vcl.Graphics,
  Vcl.Imaging.jpeg,
  Vcl.Imaging.pngimage,
  Vcl.Imaging.GIFImg;


function TAPIRPCheffDAOProduto.ExibirImagem(AValue: Boolean): TAPIRPCheffDAOProduto;
begin
  FExibirImagem := AValue;
  Result := Self;
end;

function TAPIRPCheffDAOProduto.CompactarImagemJpeg(const ABytes: TBytes): TMemoryStream;
const
  MAX_DIMENSION = 220;
  JPEG_QUALITY = 60;
var
  LInputStream: TBytesStream;
  LGraphic: TGraphic;
  LBitmap: TBitmap;
  LJpeg: TJPEGImage;
  LOutputStream: TMemoryStream;
  LScale: Double;
  LTargetWidth: Integer;
  LTargetHeight: Integer;
  function CriarGraphic: TGraphic;
  begin
    Result := nil;

    if Length(ABytes) < 2 then
      Exit;

    if (Length(ABytes) >= 8) and
       (ABytes[0] = $89) and
       (ABytes[1] = $50) and
       (ABytes[2] = $4E) and
       (ABytes[3] = $47) then
      Exit(TPngImage.Create);

    if (Length(ABytes) >= 3) and
       (ABytes[0] = $FF) and
       (ABytes[1] = $D8) and
       (ABytes[2] = $FF) then
      Exit(TJPEGImage.Create);

    if (Length(ABytes) >= 4) and
       (ABytes[0] = Ord('G')) and
       (ABytes[1] = Ord('I')) and
       (ABytes[2] = Ord('F')) and
       (ABytes[3] = Ord('8')) then
      Exit(TGIFImage.Create);

    if (ABytes[0] = Ord('B')) and (ABytes[1] = Ord('M')) then
      Exit(TBitmap.Create);
  end;
begin
  Result := nil;

  if Length(ABytes) = 0 then
    Exit;

  LInputStream := TBytesStream.Create(ABytes);
  LGraphic := CriarGraphic;
  LBitmap := TBitmap.Create;
  LJpeg := TJPEGImage.Create;
  LOutputStream := TMemoryStream.Create;
  try
    if not Assigned(LGraphic) then
      Exit;

    try
      LGraphic.LoadFromStream(LInputStream);
    except
      Exit;
    end;

    if (LGraphic.Width <= 0) or (LGraphic.Height <= 0) then
      Exit;

    LScale := Min(1, Min(MAX_DIMENSION / LGraphic.Width, MAX_DIMENSION / LGraphic.Height));
    LTargetWidth := Max(1, Round(LGraphic.Width * LScale));
    LTargetHeight := Max(1, Round(LGraphic.Height * LScale));

    LBitmap.SetSize(LTargetWidth, LTargetHeight);
    LBitmap.PixelFormat := pf24bit;
    LBitmap.Canvas.Brush.Color := clWhite;
    LBitmap.Canvas.FillRect(Rect(0, 0, LTargetWidth, LTargetHeight));
    LBitmap.Canvas.StretchDraw(Rect(0, 0, LTargetWidth, LTargetHeight), LGraphic);

    LJpeg.Assign(LBitmap);
    LJpeg.CompressionQuality := JPEG_QUALITY;
    LJpeg.Compress;
    LJpeg.SaveToStream(LOutputStream);
    LOutputStream.Position := 0;
    Result := LOutputStream;
    LOutputStream := nil;
  finally
    LOutputStream.Free;
    LJpeg.Free;
    LBitmap.Free;
    LGraphic.Free;
    LInputStream.Free;
  end;
end;


function TAPIRPCheffDAOProduto.CompactarImagemBase64(const ABytes: TBytes): string;
var
  LOutputStream: TMemoryStream;
  LEncodedBytes: TBytes;
begin
  Result := '';
  LOutputStream := CompactarImagemJpeg(ABytes);
  try
    if not Assigned(LOutputStream) then
      Exit;

    if LOutputStream.Size <= 0 then
      Exit;

    SetLength(LEncodedBytes, LOutputStream.Size);
    LOutputStream.Position := 0;
    if LOutputStream.Size > 0 then
      LOutputStream.ReadBuffer(LEncodedBytes[0], LOutputStream.Size);

    Result := 'data:image/jpeg;base64,' + TNetEncoding.Base64.EncodeBytesToString(LEncodedBytes);
  finally
    LOutputStream.Free;
  end;
end;

function TAPIRPCheffDAOProduto.BuscarImagem(AIdProduto: Integer): TMemoryStream;
begin
  Result := nil;
  FQuery.SQL('select imagem_db')
    .SQL('from materiais')
    .SQL('where emp_001 = :idEmpresa')
    .SQL('and mat_001 = :idProduto')
    .SQL('and sit_001 = 4')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idProduto', AIdProduto)
    .Open;

  if (not FQuery.DataSet.IsEmpty) and (not FQuery.DataSet.FieldByName('imagem_db').IsNull) then
    Result := CompactarImagemJpeg(FQuery.DataSet.FieldByName('imagem_db').AsBytes);
end;

function TAPIRPCheffDAOProduto.Buscar(AIdProduto: Integer): TAPIRPCheffEntityProduto;
begin
  SelectProdutos;
  FQuery.SQL('where emp_001 = :idEmpresa')
    .SQL('and mat_001 = :idProduto')
    .SQL('and sit_001 = 4')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idProduto', AIdProduto)
    .Open;
  Result := DataSetToEntity(FQuery.DataSet);
  if Assigned(Result) then
  begin
    Result.promocao := TAPIRPCheffDAOFactory(FactoryDAO)
      .IdEmpresa(FIdEmpresa)
      .PromocaoDAO.Buscar(Result.idProduto);
    Result.opcionais := TAPIRPCheffDAOFactory(FactoryDAO)
      .IdEmpresa(FIdEmpresa)
      .OpcionalDAO.Lista(Result.idProduto);
  end;
end;

procedure TAPIRPCheffDAOProduto.CarregarRelacionamentos(AProdutos: TObjectList<TAPIRPCheffEntityProduto>);
var
  LOpcionaisPorProduto: TDictionary<Integer, TObjectList<TAPIRPCheffEntityOpcional>>;
  LPromocoesPorProduto: TDictionary<Integer, TAPIRPCheffEntityPromocao>;
  LProduto: TAPIRPCheffEntityProduto;
  LIdsProduto: TArray<Integer>;
  LListaOpcional: TObjectList<TAPIRPCheffEntityOpcional>;
  LPromocao: TAPIRPCheffEntityPromocao;
  LPairOpcional: TPair<Integer, TObjectList<TAPIRPCheffEntityOpcional>>;
  LPairPromocao: TPair<Integer, TAPIRPCheffEntityPromocao>;
  I: Integer;
begin
  if (not Assigned(AProdutos)) or (AProdutos.Count = 0) then
    Exit;

  SetLength(LIdsProduto, AProdutos.Count);
  for I := 0 to Pred(AProdutos.Count) do
    LIdsProduto[I] := AProdutos[I].idProduto;

  LOpcionaisPorProduto := TAPIRPCheffDAOFactory(FactoryDAO)
    .IdEmpresa(FIdEmpresa)
    .OpcionalDAO.ListaPorProdutos(LIdsProduto);
  LPromocoesPorProduto := TAPIRPCheffDAOFactory(FactoryDAO)
    .IdEmpresa(FIdEmpresa)
    .PromocaoDAO.ListaPorProdutos(LIdsProduto);
  try
    for LProduto in AProdutos do
    begin
      if LOpcionaisPorProduto.TryGetValue(LProduto.idProduto, LListaOpcional) then
      begin
        LProduto.opcionais := LListaOpcional;
        LOpcionaisPorProduto.Remove(LProduto.idProduto);
      end;

      if LPromocoesPorProduto.TryGetValue(LProduto.idProduto, LPromocao) then
      begin
        LProduto.promocao := LPromocao;
        LPromocoesPorProduto.Remove(LProduto.idProduto);
      end;
    end;

    for LPairOpcional in LOpcionaisPorProduto do
      LPairOpcional.Value.Free;
    for LPairPromocao in LPromocoesPorProduto do
      LPairPromocao.Value.Free;
  finally
    LOpcionaisPorProduto.Free;
    LPromocoesPorProduto.Free;
  end;
end;

function TAPIRPCheffDAOProduto.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityProduto;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityProduto.Create;
    try
      Result.idEmpresa                         := ADataSet.FieldByName('emp_001').AsInteger;
      Result.idProduto                         := ADataSet.FieldByName('mat_001').AsInteger;
      Result.idCategoria                       := ADataSet.FieldByName('cat_001').AsInteger;
      Result.descricao                         := ADataSet.FieldByName('mat_003').AsString;
      Result.codReferencia                     := ADataSet.FieldByName('mat_004').AsString;
      Result.valorUnitario                     := ADataSet.FieldByName('mat_008').AsCurrency;
      Result.valorTabela2                      := ADataSet.FieldByName('valor_tabela2').AsCurrency;
      Result.valorAtacado                      := ADataSet.FieldByName('valor_atacado').AsCurrency;
      Result.preco4                            := ADataSet.FieldByName('preco4').AsCurrency;
      Result.preco5                            := ADataSet.FieldByName('preco5').AsCurrency;
      Result.preco6                            := ADataSet.FieldByName('preco6').AsCurrency;
      Result.preco7                            := ADataSet.FieldByName('preco7').AsCurrency;
      Result.valorTamanhoP                     := ADataSet.FieldByName('valor_tam_p').AsCurrency;
      Result.valorTamanhoM                     := ADataSet.FieldByName('valor_tam_m').AsCurrency;
      Result.valorTamanhoG                     := ADataSet.FieldByName('valor_tam_g').AsCurrency;
      Result.valorTamanhoGG                    := ADataSet.FieldByName('valor_tam_gg').AsCurrency;
      Result.valorTamanhoExtra                 := ADataSet.FieldByName('valor_tam_extra').AsCurrency;
      Result.vendaPorTamanho                   := ADataSet.FieldByName('b_venda_tamanho').AsBoolean;
      Result.tamanhoPadrao                     := ADataSet.FieldByName('tamanho_padrao').AsString;
      Result.tamanhoP                          := ADataSet.FieldByName('tamanho_p').AsString;
      Result.tamanhoM                          := ADataSet.FieldByName('tamanho_m').AsString;
      Result.tamanhoG                          := ADataSet.FieldByName('tamanho_g').AsString;
      Result.tamanhoGG                         := ADataSet.FieldByName('tamanho_gg').AsString;
      Result.tamanhoExtra                      := ADataSet.FieldByName('tamanho_extra').AsString;
      Result.cobrarTaxa                        := not ADataSet.FieldByName('b_nao_taxa').AsBoolean;
      Result.impressora1                       := ADataSet.FieldByName('mat_021').AsInteger;
      Result.impressora2                       := ADataSet.FieldByName('mat_022').AsInteger;
      Result.permiteFracao                     := ADataSet.FieldByName('b_permite_frac').AsBoolean;
      Result.proximoGratis                     := ADataSet.FieldByName('b_proximogratis').AsBoolean;
      Result.quantidadeProximoGratis           := ADataSet.FieldByName('qtdeproximogratis').AsInteger;
      Result.usaQuantidadeDecimal              := ADataSet.FieldByName('usaQuantidadeDecimal').AsBoolean;
      Result.utilizaCombo                      := ADataSet.FieldByName('utiliza_combo').AsBoolean;
      Result.idSetor                           := ADataSet.FieldByName('id_setor').AsInteger;
      Result.happyHourAtivar                   := ADataSet.FieldByName('hh_ativar').AsBoolean;
      Result.happyHour.segundaFeira            := ADataSet.FieldByName('hh_dia_seg').AsBoolean;
      Result.happyHour.tercaFeira              := ADataSet.FieldByName('hh_dia_ter').AsBoolean;
      Result.happyHour.quartaFeira             := ADataSet.FieldByName('hh_dia_qua').AsBoolean;
      Result.happyHour.quintaFeira             := ADataSet.FieldByName('hh_dia_qui').AsBoolean;
      Result.happyHour.sextaFeira              := ADataSet.FieldByName('hh_dia_sex').AsBoolean;
      Result.happyHour.sabado                  := ADataSet.FieldByName('hh_dia_sab').AsBoolean;
      Result.happyHour.domingo                 := ADataSet.FieldByName('hh_dia_dom').AsBoolean;
      Result.happyHour.tipoMesa                := ADataSet.FieldByName('hh_tipo_mesa').AsBoolean;
      Result.happyHour.tipoComanda             := ADataSet.FieldByName('hh_tipo_comanda').AsBoolean;
      Result.happyHour.horaInicial             := ADataSet.FieldByName('hh_inicial').AsDateTime;
      Result.happyHour.horaFinal               := ADataSet.FieldByName('hh_final').AsDateTime;
      Result.happyHour.valor                   := ADataSet.FieldByName('hh_valor').AsCurrency;
      Result.restringirVenda                   := ADataSet.FieldByName('b_restricao').AsBoolean;
      Result.restricao.segundaFeira            := ADataSet.FieldByName('nao_dia_seg').AsBoolean;
      Result.restricao.tercaFeira              := ADataSet.FieldByName('nao_dia_ter').AsBoolean;
      Result.restricao.quartaFeira             := ADataSet.FieldByName('nao_dia_qua').AsBoolean;
      Result.restricao.quintaFeira             := ADataSet.FieldByName('nao_dia_qui').AsBoolean;
      Result.restricao.sextaFeira              := ADataSet.FieldByName('nao_dia_sex').AsBoolean;
      Result.restricao.sabado                  := ADataSet.FieldByName('nao_dia_sab').AsBoolean;
      Result.restricao.domingo                 := ADataSet.FieldByName('nao_dia_dom').AsBoolean;
      Result.ImprimirFicha                     := ADataSet.FieldByName('b_ficha_individual').AsBoolean;
      Result.PermiteVendaAPP                   := ADataSet.FieldByName('b_venda_mobile').AsBoolean;
      Result.CustoProduto                      := ADataSet.FieldByName('mat_012').AsCurrency;
      Result.CustoComposicao                   := ADataSet.FieldByName('mat_006').AsCurrency;
      Result.possuiImagem                      := ADataSet.FieldByName('possui_imagem').AsBoolean;
      if FExibirImagem and (not ADataSet.FieldByName('imagem_db').IsNull) then
        Result.imagem                          := CompactarImagemBase64(ADataSet.FieldByName('imagem_db').AsBytes);
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TAPIRPCheffDAOProduto.Lista: TObjectList<TAPIRPCheffEntityProduto>;
begin
  SelectProdutos;
  FQuery.SQL('where emp_001 = :idEmpresa')
    .SQL('and sit_001 = 4')
    .SQL('and b_venda_mobile = true')
    .SQL('order by mat_003')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .Open;
  Result := DataSetToList(FQuery.DataSet);
  CarregarRelacionamentos(Result);
end;

function TAPIRPCheffDAOProduto.Lista(AIdCategoria: Integer): TObjectList<TAPIRPCheffEntityProduto>;
begin
  SelectProdutos;
  FQuery.SQL('where emp_001 = :idEmpresa')
    .SQL('and cat_001 = :idCategoria')
    .SQL('and sit_001 = 4')
    .SQL('and b_venda_mobile = true')
    .SQL('order by mat_003')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idCategoria', AIdCategoria)
    .Open;
  Result := DataSetToList(FQuery.DataSet);
  CarregarRelacionamentos(Result);
end;

procedure TAPIRPCheffDAOProduto.SelectProdutos;
begin
  FQuery.SQL('select mat_001, mat_003, mat_004, emp_001, mat_008, b_venda_tamanho,                       ')
    .SQL('valor_tam_p, valor_tam_m, valor_tam_g, valor_tam_gg, valor_tam_extra,                          ')
    .SQL('tamanho_padrao, tamanho_p, tamanho_m, tamanho_g, tamanho_gg, tamanho_extra,                    ')
    .SQL('cat_001, b_nao_taxa, mat_021, mat_022, utiliza_combo, id_setor,                                ')
    .SQL('hh_ativar, hh_dia_seg, hh_dia_ter, hh_dia_qua, hh_dia_qui, hh_dia_sex,                         ')
    .SQL('hh_dia_sab, hh_dia_dom, hh_tipo_mesa, hh_tipo_comanda,                                         ')
    .SQL('hh_inicial, hh_final, hh_valor,                                                                ')
    .SQL('b_restricao, nao_dia_seg, nao_dia_ter, nao_dia_qua, nao_dia_qui, nao_dia_sex,                  ')
    .SQL('nao_dia_sab, nao_dia_dom,                                                                      ')
    .SQL('b_permite_frac, b_proximogratis, qtdeproximogratis, usaQuantidadeDecimal,                      ')
    .SQL('valor_tabela2, valor_atacado, preco4, preco5, preco6, preco7,b_ficha_individual,b_venda_mobile, ')
    .SQL('mat_012, mat_006, case when imagem_db is not null then true else false end as possui_imagem');
  if FExibirImagem then
    FQuery.SQL(', imagem_db');
  FQuery.SQL('from materiais');
end;

end.

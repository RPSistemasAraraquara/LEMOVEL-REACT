unit ACBrNFeDANFEFRDM.Helper;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  frxExportImage,
  ACBrUtil.Strings,
  ACBrUtil.FilesIO,
  ACBrNFe,
  ACBrNFe.Classes,
  ACBrNFeNotasFiscais,
  ACBrDFeDANFeReport,
  ACBrNFeDANFEFR,
  ACBrNFeDANFEFRDM;

type
  TACBrNFeFRClassHelper = class helper for TACBrNFeFRClass
  public
    function ImprimirDANFEImage(ANFE: TNFe = nil): TMemoryStream;
  end;

  TACBrNFeDANFEFRHelper = class helper for TACBrNFeDANFEFR
  private
    function GetDMDanfe: TACBrNFeFRClass;
  public
    function ImprimirDANFEImage(NFE: TNFe = nil): TMemoryStream;
  end;

  TNotasFiscaisHelper = class helper for TNotasFiscais
  public
    function ImprimirImage: TMemoryStream;
  end;

  TObjectHelper = class helper for TObject
  public
    function GetField(const AFieldName: string): TRttiField;
    procedure InvokeMethod(const AMethodName: string);
  end;

implementation

{ TACBrNFeFRClassHelper }

function TACBrNFeFRClassHelper.ImprimirDANFEImage(ANFE: TNFe): TMemoryStream;
var
  LExportImage: TfrxJPEGExport;
  LFile: string;
  I : Integer;
begin
  LExportImage := TfrxJPEGExport.Create(nil);
  try
    LExportImage.ShowProgress := False;
    LExportImage.ShowDialog := False;
    LExportImage.Resolution := 96;
    for I := 1 to TACBrNFe(DANFEClassOwner.ACBrNFe).NotasFiscais.Count do
    begin
      DANFEClassOwner.FIndexImpressaoIndividual := I;
      if PrepareReport(ANFE) then
      begin
        Result := TMemoryStream.Create;
        try
          LExportImage.FileName := ExtractFilePath(GetModuleName(HInstance)) + OnlyNumber(NFe.infNFe.ID) + '-nfe';

          ForceDirectories(ExtractFileDir(LExportImage.FileName));

          frxReport.Export(LExportImage);

          LFile := LExportImage.FileName + '.1.jpg';
          Result.LoadFromFile(LFile);
          Result.Position := 0;
          DeleteFile(LFile);
        except
          Result.Free;
          raise;
        end;
      end;
    end;
  finally
    LExportImage.Free;
  end;
end;

{ TACBrNFeDANFEFRHelper }

function TACBrNFeDANFEFRHelper.GetDMDanfe: TACBrNFeFRClass;
var
  LField: TRttiField;
begin
  LField := Self.GetField('FdmDanfe');
  Result := TACBrNFeFRClass(LField.GetValue(Self).AsObject);
end;

function TACBrNFeDANFEFRHelper.ImprimirDANFEImage(NFE: TNFe): TMemoryStream;
var
  LDanfe: TACBrNFeFRClass;
begin
  LDanfe := GetDMDanfe;
  Result := LDanfe.ImprimirDANFEImage(nil);
end;

{ TNotasFiscaisHelper }

function TNotasFiscaisHelper.ImprimirImage: TMemoryStream;
var
  LACBr: TComponent;
begin
//  Self.InvokeMethod('VerificarDANFE');
  LACBr := TComponent(GetField('FACBrNFe').GetValue(Self).AsObject);
  Result := TACBrNFeDANFEFR(TACBrNFe(LACBr).DANFE).ImprimirDANFEImage;
end;

{ TObjectHelper }

function TObjectHelper.GetField(const AFieldName: string): TRttiField;
var
  LContext: TRttiContext;
  LType: TRttiType;
begin
  LContext := TRttiContext.Create;
  try
    LType := LContext.GetType(Self.ClassType);
    Result := LType.GetField(AFieldName);
  finally
    LContext.Free;
  end;
end;

procedure TObjectHelper.InvokeMethod(const AMethodName: string);
var
  LContext: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
begin
  LContext := TRttiContext.Create;
  try
    LType := LContext.GetType(Self.ClassType);
    LMethod := LType.GetMethod(AMethodName);
    LMethod.Invoke(Self, []);
  finally
    LContext.Free;
  end;
end;

end.

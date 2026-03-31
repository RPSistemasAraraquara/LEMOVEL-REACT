unit RpError.Exception;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.DateUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.DBCtrls,
  Winapi.Tlhelp32,
  System.Types,
  Winapi.Windows,
  System.Win.Registry,
  Vcl.Imaging.jpeg,
  FastMMMemLeakMonitor, RpError.FormError;

type
  TRpLogError = class
  strict private
    FFile: TStringList;
    FPrintFormAtivo: string;
    FLogProcess: boolean;
    function GetFileLogName: string;
    function LogProgramasAtivos: string;
    function MemoriaUtilizada: string;
    function ObterNomeUsuario: string;
    function ObterVersaoWindows: string;
    function GetPrintFormAtivo: string;
    function WindowsUpTime: string;
  public
    procedure LogException(Sender: TObject; E: Exception);
    constructor Create;
    destructor Destroy; override;
    property LogProcess: boolean read FLogProcess write FLogProcess;
  end;

  TRpOnExceptionHandler = class
  public
    class procedure OnException(Sender: TObject; E: Exception);
  end;

implementation

{ TRpLogError }

constructor TRpLogError.Create;
begin
  FFile := TStringList.Create;
  FLogProcess := True;
end;

destructor TRpLogError.Destroy;
begin
  FFile.Free;
  inherited;
end;

function TRpLogError.GetFileLogName: string;
var
  lLocalPath, lFileName: string;
begin
  lFileName:= 'Dia' + DayOf(Now).ToString + '_' +FormatDateTime('hhnnss',now)+'_'+ExtractFileName(ParamStr(0));
  lFileName:= ChangeFileExt(ExtractFileName(lFileName), '.log');
  lLocalPath:= TPath.Combine(ExtractFilePath(ParamStr(0)), 'LocalLog');
  lLocalPath:= TPath.Combine(lLocalPath, 'Ano_' + YearOf(Now).ToString);
  lLocalPath:= TPath.Combine(lLocalPath, 'Mes_' + MonthOf(Now).ToString);
  ForceDirectories(lLocalPath);
  Result:= TPath.Combine(lLocalPath, lFileName);
end;

function TRpLogError.WindowsUpTime: string;
var
  lCount, lDays, lMin, lHours, lSeconds: Longint;
begin
  lCount := GetTickCount();
  lCount := lCount div 1000;
  lDays  := lCount div (24 * 3600);
  if lDays > 0 then
    lCount := lCount - (24 * 3600 * lDays);
  lHours := lCount div 3600;
  if lHours > 0 then
    lCount := lCount - (3600 * lHours);
  lMin := lCount div 60;
  lSeconds := lCount Mod 60;
  Result :=
    IntToStr(lDays) + ' dias '    + IntToStr(lHours  ) + ' horas ' +
    IntToStr(lMin ) + ' minutos ' + IntToStr(lSeconds) +' segundos ';
end;

function TRpLogError.LogProgramasAtivos: string;
const
  PROCESS_TERMINATE = $0001;
var
  lCount: Integer;
  lListaProcessos: TStringList;
  lContinueLoop: Boolean;
  lSnapshotHandle: THandle;
  lProcessEntry32: TProcessEntry32;
begin
  lListaProcessos:= TStringList.Create;
  try
    lSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    lProcessEntry32.dwSize := sizeof(lProcessEntry32);
    lContinueLoop := Process32First(lSnapshotHandle, lProcessEntry32);
    while Integer(lContinueLoop) <> 0 do
    begin
      if lListaProcessos.IndexOf(lProcessEntry32.szExeFile) = -1 then
        lListaProcessos.Add(lProcessEntry32.szExeFile);
      lContinueLoop := Process32Next(lSnapshotHandle, lProcessEntry32);
    end;
    CloseHandle(lSnapshotHandle);

    lListaProcessos.Sort;
    for lCount := 0 to Pred(lListaProcessos.Count) do
    begin
      Result:= Result + ' ' + '[' + lListaProcessos.Strings[lCount] + ']';
      if (lCount mod 10) = 0 then
        Result:= Result + sLineBreak;
    end;
  finally
    lListaProcessos.Free;
  end;
end;

function TRpLogError.ObterNomeUsuario: string;
var
  lSize: DWord;
begin
  lSize := 1024;
  SetLength(Result, lSize);
  GetUserName(PChar(Result), lSize);
  SetLength(Result, lSize - 1);
end;

function TRpLogError.ObterVersaoWindows: string;
var
  lNome,
  lVersao,
  lCurrentBuild: String;
  lReg: TRegistry;
begin
  lReg := TRegistry.Create;
  try
    lReg.Access  := KEY_READ;
    lReg.RootKey := HKEY_LOCAL_MACHINE;
    lReg.OpenKey('\SOFTWARE\Microsoft\Windows NT\CurrentVersion\', true);
    lNome         := lReg.ReadString('ProductName');
    lVersao       := lReg.ReadString('CurrentVersion');
    lCurrentBuild := lReg.ReadString('CurrentBuild');

    Result := lNome + ' - ' + lVersao + ' - ' + lCurrentBuild;
  finally
    lReg.Free;
  end;
end;

function TRpLogError.GetPrintFormAtivo: string;
begin
  if FPrintFormAtivo <> '' then
    Exit(FPrintFormAtivo);

  Result:= ExtractFilePath(GetFileLogName);
  Result:= TPath.Combine(Result, FormatDateTime('hhmmssnn', Now) + '.jpg');
  var lImage:= Screen.ActiveForm.GetFormImage;
  try
    lImage.SaveToFile(Result);
  finally
    FreeAndNil(lImage);
  end;
end;

function TRpLogError.MemoriaUtilizada: string;
var
  lMemoryManagerState: TMemoryManagerState;
  lBytes: Integer;
  lI: Integer;
begin
  lBytes := 0;
  {$WARN SYMBOL_PLATFORM OFF}
  GetMemoryManagerState(lMemoryManagerState);

  for lI := 0 to High(lMemoryManagerState.SmallBlockTypeStates) do
    Inc(lBytes, lMemoryManagerState.SmallBlockTypeStates[lI].AllocatedBlockCount * lMemoryManagerState.SmallBlockTypeStates[lI].UseableBlockSize);

  Inc(lBytes, lMemoryManagerState.TotalAllocatedMediumBlockSize);
  Inc(lBytes, lMemoryManagerState.TotalAllocatedLargeBlockSize);
  Result:= FormatFloat('0.00', (lBytes / 1024)/1024) + ' MB';
end;

procedure TRpLogError.LogException(Sender: TObject; E: Exception);
begin
  FFile.Add('+----------------------------------------------------------+');
  FFile.Add('exce'#231#227'o no sistema encontrada   ' + DateTimeToStr(Now));
  FFile.Add('===================================================');
  FFile.Add('Classe exce'#231#227'o...........: ' + E.ClassName);
  if Screen.ActiveForm <> nil then
  begin
    FFile.Add('Formul'#225'rio...............: ' + Screen.ActiveForm.Name);
    FFile.Add('t'#237'tulo do Formul'#225'rio.....: ' + Screen.ActiveForm.Caption);
    FFile.Add('Print do Form Ativo......: ' + GetPrintFormAtivo);
  end;
  FFile.Add('Unit.....................: ' + Sender.UnitName);
  if Screen.ActiveControl <> nil then
  begin
    FFile.Add('Controle Visual..........: ' + Screen.ActiveControl.Name);
  end;
  FFile.Add('Mensagem.................: ' + E.Message);
  FFile.Add('Aplicativo...............: ' + ParamStr(0));
  FFile.Add('Data/Hora do Aplicativo..: ' + DateTimeToStr(FileDateToDateTime(FileAge(ParamStr(0)))));
  FFile.Add('mem'#243'ria Utilizada........: ' + MemoriaUtilizada);
  FFile.Add('usu'#225'rio do Windows.......: ' + ObterNomeUsuario);
  FFile.Add('vers'#227'o Windows...........: ' + ObterVersaoWindows);
  FFile.Add('Tempo do Windows Ativo...: ' + WindowsUpTime);
  if FLogProcess then
    FFile.Add('Processos Rodando........: ' + LogProgramasAtivos);
  FFile.Add('+----------------------------------------------------------+');

  FFile.SaveToFile(GetFileLogName);

  var lFormError := TFormError.Create(nil);
  try
    lFormError.lblError.Caption := E.Message;
    lFormError.memDetails.Text := FFile.Text;
    lFormError.ShowModal;
  finally
    FreeAndNil(lFormError);
  end;
end;

{ TRpOnExceptionHandler }

class procedure TRpOnExceptionHandler.OnException(Sender: TObject; E: Exception);
begin
  var lRpError := TRpLogError.Create;
  try
    lRpError.LogException(Sender, E);
  finally
    lRpError.Free;
  end;
end;



end.


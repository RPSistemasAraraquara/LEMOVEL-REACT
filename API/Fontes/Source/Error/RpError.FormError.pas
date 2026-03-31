unit RpError.FormError;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ShellAPI,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls;

type
  TFormError = class(TForm)
    memDetails: TMemo;
    pnlButton: TPanel;
    btnOK: TButton;
    pnlTitulo: TPanel;
    imgError: TImage;
    lblError: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormError: TFormError;

implementation

{$R *.dfm}

end.

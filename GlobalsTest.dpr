program GlobalsTest;

uses
  Vcl.Forms,
  fmMain in 'fmMain.pas' {Form4},
  uGlobal in 'uGlobal.pas',
  uRTTIHelper in 'uRTTIHelper.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm4, Form4);
  Application.Run;
end.

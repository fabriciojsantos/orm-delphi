program Project1;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  DM in 'DM.pas' {D: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TD, D);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

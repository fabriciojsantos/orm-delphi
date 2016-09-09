unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    btnSave: TButton;
    btnUpdate: TButton;
    btnFind: TButton;
    Memo1: TMemo;
    Memo2: TMemo;
    Label1: TLabel;
    btnSpExec: TButton;
    procedure Button1Click(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnUpdateClick(Sender: TObject);
    procedure btnFindClick(Sender: TObject);
    procedure btnSpExecClick(Sender: TObject);
  private
    { Private declarations }

    procedure LogSQL;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses entidade.Cliente,
     entidade.Cliente.Endereco,
     entidade.sp.Cliente,
     DM;

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
   If not D.Connection.Connect('connection.ini') Then
      ShowMessage('Não conectado'+ sLineBreak + D.Connection.Error);
end;

procedure TForm1.LogSQL;
begin
   If FileExists('log.sql') Then
      Memo2.Lines.LoadFromFile('log.sql');
end;

procedure TForm1.btnSaveClick(Sender: TObject);
var C : TCliente;
    E : TClienteEndereco;
begin
   Memo1.Clear;

   C := TCliente.Create;
   C.Nome := 'Test (Save) ORM Delphi '+ DateTimeToStr(Now);
   D.Session.Save(C);
   Memo1.Lines.Add('TCliente: ID' + C.ID.ToString);

   D.Session.Commit;

   C := TCliente.Create;
   C.Nome := 'Test (Save) ORM Delphi '+ DateTimeToStr(Now);

   C.Enderecos.Add(TClienteEndereco.Create);
   C.Enderecos.Last.Logradouro := 'Logradouro '+ C.Nome;
   C.Enderecos.Last.Numero     := FormatDateTime('ss',Now);
   C.Enderecos.Last.Bairro     := 'Bairro' + C.Nome;

   C.Enderecos.Add(TClienteEndereco.Create);
   C.Enderecos.Last.Logradouro := 'Logradouro '+ C.Nome;
   C.Enderecos.Last.Numero     := FormatDateTime('ss',Now);
   C.Enderecos.Last.Bairro     := 'Bairro' + C.Nome;

   C.Enderecos.Add(TClienteEndereco.Create);
   C.Enderecos.Last.Logradouro := 'Logradouro '+ C.Nome;
   C.Enderecos.Last.Numero     := FormatDateTime('ss',Now);
   C.Enderecos.Last.Bairro     := 'Bairro' + C.Nome;

   D.Session.Save(C);
   Memo1.Lines.Add('TCliente: ID' + C.ID.ToString);
   For E in C.Enderecos Do
       Memo1.Lines.Add('TClienteEndereco: ID' + C.ID.ToString +' DataHora: '+ DateTimeToStr(C.Data));

   D.Session.Commit;

   LogSQL;
end;

procedure TForm1.btnSpExecClick(Sender: TObject);
var SP : TSPCliente;
begin
   Memo1.Clear;

   SP := TSPCliente.Create;
   SP.ID := 3;
   D.Session.Execute(SP);

   Memo1.Lines.Add(SP.ClassName +': return' + SP.Nome);

   LogSQL;
end;

procedure TForm1.btnUpdateClick(Sender: TObject);
var L : TObjectList<TCliente>;
    C : TCliente;
    E : TClienteEndereco;
begin
   L := D.Session.FindAll<TCliente>;

   Memo1.Clear;
   For C in L Do
   Begin
      C.Nome := 'Test (Update) ORM Delphi '+ DateTimeToStr(Now);
      For E in C.Enderecos Do
         E.Logradouro := 'Logradouro '+ C.Nome;
   End;

   D.Session.SaveAll<TCliente>(L);
   D.Session.Commit;

   btnFind.Click;
end;

procedure TForm1.btnFindClick(Sender: TObject);
var L : TObjectList<TCliente>;
    C : TCliente;
    E : TClienteEndereco;
begin
   L := D.Session.FindAll<TCliente>;
   Try
     For C in L Do
     Begin
        Memo1.Lines.Add('ID: '+ C.ID.ToString + sLineBreak +' Data: '+ DateToStr(C.Data)+ sLineBreak +' Nome: '+ C.Nome);
        For E in C.Enderecos Do
           Memo1.Lines.Add(E.Logradouro +','+ E.Numero +','+ E.Bairro);
        Memo1.Lines.Add(StringOfChar('-',30));
     End;
   Finally
     FreeAndNil(L);
   End;


   LogSQL;
end;

end.

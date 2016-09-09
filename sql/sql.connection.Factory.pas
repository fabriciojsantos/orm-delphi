unit sql.connection.Factory;

interface

uses System.SysUtils,
     sql.consts, sql.connection,
     Forms;

    function ConnectionFactory(Connect : TSQLConnect; Section : String = 'BANCO DE DADOS'; FileName : TFileName = 'connection.ini') : TDBConnection;

implementation

uses sql.connection.FireDac,
     sql.connection.DBExpress{,
     sql.connection.DataSnap};

function ConnectionFactory(Connect : TSQLConnect; Section : String; FileName : TFileName) : TDBConnection;
begin
   Result := nil;
   Case Connect Of
      sqlcDBX   : Result := TSQLConnectionDBX.Create;
      sqlcFD    : Result := TSQLConnectionFD.Create;
      //sqlcDSnap : Result := TSQLConnectionDataSnap.Create;
   End;

   If Assigned(Result) Then
      Result.Connect(FileName,Section);
end;


end.

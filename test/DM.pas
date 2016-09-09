unit DM;

interface

uses
  System.SysUtils, System.Classes,
  sql.Consts,
  sql.connection,
  sql.connection.Factory,
  orm.Session;

type
  TD = class(TDataModule)
  private
    { Private declarations }
    FConnection : TDBConnection;

    function GetConnection : TDBConnection;
    function GetSession : TSession;

  public
    { Public declarations }

    property Connection : TDBConnection   Read GetConnection;
    property Session    : TSession        Read GetSession;
  end;

var
  D: TD;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

function TD.GetConnection: TDBConnection;
begin
   If not Assigned(FConnection) Then
      FConnection := ConnectionFactory(TSQLConnect.sqlcDBX);
      //FConnection := ConnectionFactory(TSQLConnect.sqlcFD);
   Result := FConnection;
end;

function TD.GetSession: TSession;
begin
   If not Assigned(orm.Session.Session) Then
      orm.Session.Session := TSession.Create(Connection);
   Result := orm.Session.Session;
end;

end.

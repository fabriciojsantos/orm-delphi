unit sql.connection;

interface

uses System.Classes, System.SysUtils, System.IniFiles, System.Generics.Collections,
     Data.DB, Data.DBXCommon, {$IFNDEF FMX} MidasLib, {$ENDIF}
     sql.consts;

type
   TDataBase = Class
   private
     FServer   : String;
     FPort     : Integer;
     FDataBase : String;
     FUser     : String;
     FPassword : String;
     FDialect  : Integer;
     FFilterPC1: String;
   public
     property Server   : String  Read FServer    Write FServer;
     property Port     : Integer Read FPort      Write FPort;
     property DataBase : String  Read FDataBase  Write FDataBase;
     property User     : String  Read FUser      Write FUser;
     property Password : String  Read FPassword  Write FPassword;
     property Dialect  : Integer Read FDialect   Write FDialect;
     property FilterPC1: String  Read FFilterPC1 Write FFilterPC1;
   End;

   TDBConnection = Class
   private
     FSQL       : TSQL;
     FDataBase  : TDataBase;
     FError     : String;
     FLog       : Boolean;

     function GetDataBase : TDataBase;
   protected
     FDataSet    : TObjectList<TDataSet>;
     FSQLCurrent : String;

     procedure ClearLog;
     procedure AddLog(Value : String); Overload;
     procedure AddLog(Value : TStrings); Overload;
   public
     property SQL        : TSQL      Read FSQL      Write FSQL;
     property DataBase   : TDataBase Read GetDataBase;
     property Error      : String    Read FError    Write FError;
     property Log        : Boolean   Read FLog      Write FLog;
     property SQLCurrent : String    Read FSQLCurrent;

     constructor Create; Virtual;
     destructor  Destroy; Override;
   public
     function  Connect(Value : TFileName; Section : String = 'BANCO DE DADOS') : Boolean; Overload;
     function  Connect : Boolean; Overload; Virtual; Abstract;
     procedure Disconnect; Virtual; Abstract;
     function  Connected : Boolean; Virtual;

     function IsStart(Transact : Integer = 1)  : Boolean; Virtual; Abstract;
     function Start(Transact : Integer = 1)    : Boolean; Virtual; Abstract;
     function Commit(Transact : Integer = 1)   : Boolean; Virtual; Abstract;
     function Rollback(Transact : Integer = 1) : Boolean; Virtual; Abstract;

     function ExecuteScript(Value : TStrings; OnProgress : TOnProgress) : Boolean; Overload; Virtual; Abstract;

     function Execute(Value : String) : Boolean; Overload; Virtual; Abstract;
     function Execute(Value : TStrings) : Boolean; Overload; Virtual; Abstract;
     function Execute(Value : TStrings; Blobs : TList<TBlobData>) : Boolean; Overload; Virtual; Abstract;

     function Exec(Value : String) : Boolean; Overload;
     function Exec(Value : TStrings) : Boolean; Overload;
     function Exec(Value : TStrings; Blobs : TList<TBlobData>) : Boolean; Overload;

     function Open(Value : String) : TDataSet; Overload; Virtual; Abstract;
     function Open(Value : TStrings) : TDataSet; Overload; Virtual; Abstract;
     function Open(Value : TStrings; Blobs : TList<TBlobData>) : TDataSet; Overload; Virtual; Abstract;
     procedure Open(DataSet : TDataSet; Value : String); Overload; Virtual; Abstract;
     function Open(Value : String; const Params : Array Of Const) : TDataSet; Overload;

     procedure Open(var Value : TDataSet; SQL : String; const Params : Array Of Const); Overload;

     function OpenQry(Value : String) : TDataSet; Overload; Virtual; Abstract;

     function OpenExec(Value : String) : TDataSet; Overload; Virtual; Abstract;
     function OpenExec(Value : TStrings) : TDataSet; Overload; Virtual; Abstract;
     function OpenExec(Value : TStrings; Blobs : TList<TBlobData>) : TDataSet; Overload; Virtual; Abstract;

     function IsEmpty(Value : String) : Boolean; Overload;
     function IsEmpty(Value : String; const Params : Array Of Const) : Boolean; Overload;

     function IsCount(var Field1 : Variant; Value : String) : Integer; Overload;
     function IsCount(var Field1 : Variant; Value : String; const Params : Array Of Const) : Integer; Overload;

     procedure CloseDataSet;
     procedure DataSetFree(var Value : TDataSet); Overload;

     function  GetGenerator(Name : String) : Integer;
     function  GetDateTime : TDateTime;
     function  GetDate : TDate;
     function  GetTime : TTime;

     procedure SortIndex(Value : TDataSet; AscFields : String = ''; DescFields : String = ''); Virtual; Abstract;
   End;

implementation

{ TDBConnection }

constructor TDBConnection.Create;
begin
   FDataBase := TDataBase.Create;
   FDataSet  := TObjectList<TDataSet>.Create;
   FError    := '';
   FLog      := False;
   ClearLog;
end;

procedure TDBConnection.DataSetFree(var Value: TDataSet);
var I : Integer;
begin
   I := FDataSet.IndexOf(Value);
   Try
     If (I > -1) Then
        FDataSet.Delete(I)
     Else
        FreeAndNil(Value);
   Except
   End;
   Value := nil;
   FDataSet.TrimExcess;
end;

destructor TDBConnection.Destroy;
begin
   CloseDataSet;
   Rollback;
   Disconnect;
   FreeAndNil(FDataBase);
   FreeAndNil(FDataSet);
   If Assigned(FSQL) Then
      FreeAndNil(FSQL);
   inherited;
end;

function TDBConnection.Exec(Value: String): Boolean;
begin
   Try
     Result := Execute(Value);
     Commit;
   Except
     Rollback;
   End;
end;

function TDBConnection.Exec(Value: TStrings): Boolean;
begin
   Try
     Result := Execute(Value);
     Commit;
   Except
     Rollback;
   End;
end;

function TDBConnection.Exec(Value: TStrings; Blobs: TList<TBlobData>): Boolean;
begin
   Try
     Result := Execute(Value,Blobs);
     Commit;
   Except
     Rollback;
   End;
end;

function TDBConnection.GetDataBase: TDataBase;
begin
   If not Assigned(FDataBase) Then
      FDataBase := TDataBase.Create;
   Result := FDataBase;
end;

function TDBConnection.GetDate : TDate;
var DS : TDataSet;
begin
   Result := 0;
   DS := Open( SQL.SQLGetDate );
   Try
     Result := DS.FieldByName('V').AsDateTime;
   Finally
     DataSetFree(DS);
   End;
end;

function TDBConnection.GetDateTime : TDateTime;
var DS : TDataSet;
begin
   Result := 0;
   DS := Open( SQL.SQLGetDateTime );
   Try
     Result := DS.FieldByName('V').AsDateTime;
   Finally
     DataSetFree(DS);
   End;
end;

function TDBConnection.GetGenerator(Name: String): Integer;
var DS : TDataSet;
begin
   Result := 0;
   DS := Open( SQL.SQLGetGenerator(Name) );
   Try
     Result := DS.FieldByName('V').AsInteger;
   Finally
     DataSetFree(DS);
   End;
end;

function TDBConnection.GetTime : TTime;
var DS : TDataSet;
begin
   Result := 0;
   DS := Open( SQL.SQLGetTime );
   Try
     Result := DS.FieldByName('V').AsDateTime;
   Finally
     DataSetFree(DS);
   End;
end;

function TDBConnection.IsEmpty(Value: String): Boolean;
var DS : TDataSet;
begin
   Try
     DS := OpenQry(Value);
     Result := DS.IsEmpty;
   Finally
     DataSetFree(DS);
   End;
end;

function TDBConnection.IsCount(var Field1 : Variant; Value: String): Integer;
var DS : TDataSet;
begin
   Try
     DS := Open(Value);
     Field1 := DS.Fields[0].Value;
     Result := DS.RecordCount;
   Finally
     DataSetFree(DS);
   End;
end;

function TDBConnection.IsCount(var Field1 : Variant; Value: String;
  const Params: array of Const): Integer;
begin
   Result := IsCount(Field1,Format(Value,Params));
end;

function TDBConnection.IsEmpty(Value: String;
  const Params: array of Const): Boolean;
begin
   Result := IsEmpty(Format(Value,Params));
end;

procedure TDBConnection.Open(var Value : TDataSet; SQL : String;
  const Params: array of Const);
begin
   If not Assigned(Value) Then
      Value := Open(SQL,Params)
   Else
      Open(Value,Format(SQL,Params));
end;

function TDBConnection.Open(Value: String;
  const Params: array of Const): TDataSet;
begin
   Result := Open(Format(Value,Params));
end;

procedure TDBConnection.AddLog(Value: String);
var S : TStrings;
begin
   FSQLCurrent := Value;
   If not FLog Then
      Exit;

   S := TStringList.Create;
   Try
     If FileExists('log.sql') Then
        S.LoadFromFile('log.sql');
     S.Add('');
     S.Add(FormatDateTime('dd/mm/yyyy hh:nn:ss.zzzz',Now) +'|'+ StringOfChar('-',20));
     S.Add(Value);
     S.Add('');
     S.SaveToFile('log.sql');
   Finally
     FreeAndNil(S);
   End;
end;

procedure TDBConnection.AddLog(Value: TStrings);
var S : TStrings;
begin
   If not FLog Then
      Exit;

   S := TStringList.Create;
   Try
     If FileExists('log.sql') Then
        S.LoadFromFile('log.sql');
     S.Add('');
     S.Add(FormatDateTime('dd/mm/yyyy hh:nn:ss.zzzz',Now) +'|'+ StringOfChar('-',20));
     S.AddStrings(Value);
     S.Add('');
     S.SaveToFile('log.sql');
   Finally
     FreeAndNil(S);
   End;
end;

procedure TDBConnection.ClearLog;
var S : TStrings;
begin
   If not FileExists('log.sql') Then
      Exit;

   FLog := True;
   S := TStringList.Create;
   Try
     S.LoadFromFile('log.sql');
     S.Clear;
     S.SaveToFile('log.sql');
   Finally
     FreeAndNil(S);
   End;
end;

procedure TDBConnection.CloseDataSet;
var D : TDataSet;
begin
   For D in FDataSet Do
     D.Close;

   FDataSet.Clear;
end;

function TDBConnection.Connect(Value: TFileName; Section : String): Boolean;
var F : TIniFile;
begin
   If ExtractFileDir(Value).IsEmpty Then
      Value := ExtractFilePath(GetModuleName(0)) + Value;

   F := TIniFile.Create(Value);
   Try
     FSQL := TSQL.Factory( StringToSQLDB( F.ReadString(Section,'TYPE',SQLDBToString(dbFirebird)) ) );

     DataBase.Server := F.ReadString(Section ,'SERVER','localhost');
     If (Section = 'DATASNAP') Then
     Begin
        DataBase.Port      := F.ReadInteger(Section,'PORT',211);
        DataBase.User      := '';
        DataBase.Password  := '';
        DataBase.FilterPC1 := '';
     End Else
     Begin
        DataBase.DataBase  := F.ReadString(Section ,'DATABASE','');
        DataBase.Port      := F.ReadInteger(Section,'PORT'    ,3050);
        DataBase.User      := F.ReadString(Section ,'USER'    ,'SYSDBA');
        DataBase.Password  := F.ReadString(Section ,'PASSWORD','masterkey');
        DataBase.Dialect   := F.ReadInteger(Section,'DIALECT' ,3);
     End;

     If (Section <> 'DATASNAP') And not F.ValueExists(Section,'TYPE') Then
        F.WriteString(Section ,'TYPE',SQLDBToString(FSQL.SQLDB));

     If not F.ValueExists(Section,'SERVER') Then
        F.WriteString(Section ,'SERVER', DataBase.Server);

     If (Section <> 'DATASNAP') And not F.ValueExists(Section,'DATABASE') Then
        F.WriteString(Section ,'DATABASE', DataBase.DataBase);

     If not F.ValueExists(Section,'PORT') Then
        F.WriteInteger(Section,'PORT' , DataBase.Port);

     If (Section <> 'DATASNAP') And not F.ValueExists(Section,'USER') Then
        F.WriteString(Section ,'USER', DataBase.User);

     If (Section <> 'DATASNAP') And not F.ValueExists(Section,'PASSWORD') Then
        F.WriteString(Section ,'PASSWORD', DataBase.Password);

     If (Section <> 'DATASNAP') And not F.ValueExists(Section,'DIALECT') Then
        F.WriteInteger(Section,'DIALECT', DataBase.Dialect);
   Finally
     FreeAndNil(F);
   End;

   Result := Connect;
end;

function TDBConnection.Connected: Boolean;
begin
   Result := False;
end;

end.

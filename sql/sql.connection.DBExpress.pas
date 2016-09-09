unit sql.connection.DBExpress;

interface

uses System.Classes, System.SysUtils,
     Generics.Collections,
     Data.DB, Data.SqlExpr, Data.FMTBcd, Data.DBXCommon, SimpleDS, Datasnap.DBClient,
     Data.DBXFirebird, Data.DBXMySQL, Data.DBXMsSQL, Data.DBXOracle,
     sql.consts, sql.connection;

type
   TSQLConnectionDBX = Class(TDBConnection)
   private
      FConnection : TSQLConnection;
      FTransact   : TTransactionDesc;
      FDBXReaders : TObjectList<TDBXReader>;

      function FactorySDS : TSimpleDataSet;
      function FactoryQry : TSQLQuery;

   public
      constructor Create; Override;
      destructor  Destroy; Override;

      function  Connect : Boolean; Override;
      procedure Disconnect; Override;
      function  Connected : Boolean; Override;

      function IsStart(Transact : Integer = 1)  : Boolean; Override;
      function Start(Transact : Integer = 1)    : Boolean; Override;
      function Commit(Transact : Integer = 1)   : Boolean; Override;
      function Rollback(Transact : Integer = 1) : Boolean; Override;

      function ExecuteScript(Value : TStrings; OnProgress : TOnProgress) : Boolean; Override;

      function Execute(Value : String) : Boolean; Override;
      function Execute(Value : TStrings) : Boolean; Override;
      function Execute(Value : TStrings; Blobs : TList<TBlobData>) : Boolean; Override;

      function Open(Value : String) : TDataSet; Override;
      function Open(Value : TStrings) : TDataSet; Override;
      function Open(Value : TStrings; Blobs : TList<TBlobData>) : TDataSet; Override;
      procedure Open(DataSet : TDataSet; Value : String); Override;

      function OpenQry(Value : String) : TDataSet; Override;

      function OpenExec(Value : String) : TDataSet; Override;
      function OpenExec(Value : TStrings) : TDataSet; Override;
      function OpenExec(Value : TStrings; Blobs : TList<TBlobData>) : TDataSet; Override;

      procedure SortIndex(Value : TDataSet; AscFields, DescFields : String); Override;
   End;

implementation

{ TSQLConnectionDBX }

function TSQLConnectionDBX.Commit(Transact : Integer): Boolean;
begin
   Result := IsStart;
   Try
     If Result Then
        FConnection.Commit(FTransact);
     Result := True;
   Except On E:Exception Do
     Begin
        Error  := E.Message;
        Result := False;
     End;
   End;
end;

function TSQLConnectionDBX.Connect: Boolean;

     procedure SetFirebird;
     begin
        With FConnection Do
        begin
           DriverName     := 'Firebird';
           ConnectionName := 'FBConnection';
           VendorLib      := 'fbclient.dll';
           Params.Values[TDBXPropertyNames.HostName]    := DataBase.Server + '/'+ FormatFloat('0',DataBase.Port);
           //Params.Values[TDBXPropertyNames.Port]        := FormatFloat('0',DataBase.Port);
           Params.Values[TDBXPropertyNames.Database]    := DataBase.DataBase;
           Params.Values[TDBXPropertyNames.UserName]    := DataBase.User;
           Params.Values[TDBXPropertyNames.Password]    := DataBase.Password;
           Params.Values['SQLDialect']                  := FormatFloat('0',DataBase.Dialect);

           //Params.Values[TDBXPropertyNames.ErrorResourceFile] := 'C:\bti\sqlerro.txt';
        end;
     end;

     procedure SetSQLServer;
     begin
        With FConnection Do
        begin
           DriverName     := 'MSSQL';
           ConnectionName := 'MSSQLConnection';
           Params.Values[TDBXPropertyNames.HostName] := DataBase.Server;
           Params.Values[TDBXPropertyNames.Port]     := FormatFloat('0',DataBase.Port);
           Params.Values[TDBXPropertyNames.Database] := DataBase.DataBase;
           Params.Values[TDBXPropertyNames.UserName] := DataBase.User;
           Params.Values[TDBXPropertyNames.Password] := DataBase.Password;
        end;
     end;

     procedure SetMySQL;
     begin
        With FConnection Do
        begin
           DriverName     := 'MySQL';
           ConnectionName := 'MySQLConnection';
           LibraryName    := 'dbxmys.dll';
           VendorLib      := 'LIBMYSQL.dll';
           Params.Values[TDBXPropertyNames.DriverName] := 'MySQL';
           Params.Values[TDBXPropertyNames.HostName]   := DataBase.Server;
           Params.Values[TDBXPropertyNames.Port]       := FormatFloat('0',DataBase.Port);
           Params.Values[TDBXPropertyNames.Database]   := DataBase.DataBase;
           Params.Values[TDBXPropertyNames.UserName]   := DataBase.User;
           Params.Values[TDBXPropertyNames.Password]   := DataBase.Password;
        end;
     end;

     procedure SetOracle;
     begin
        With FConnection Do
        begin

        end;
     end;

begin
   Result := False;
   FConnection.LoginPrompt := False;
   Try
      Case SQL.SQLDB Of
         dbFirebird : SetFirebird;
         dbSQLServer: SetSQLServer;
         dbMySQL    : SetMySQL;
         dbOracle   : SetOracle;
      End;
   Finally
      Try
        FConnection.LoginPrompt := False;
        FConnection.Connected   := True;
        Result := FConnection.Connected;
      Except On E : Exception Do
        Error := E.Message;
      End;
   End;
end;

constructor TSQLConnectionDBX.Create;
begin
   inherited;
   FDBXReaders := TObjectList<TDBXReader>.Create;
   FConnection := TSQLConnection.Create(nil);

   FTransact.TransactionID  := 1;
   FTransact.IsolationLevel := xilREADCOMMITTED;
end;

destructor TSQLConnectionDBX.Destroy;
begin
   inherited;
   FreeAndNil(FDBXReaders);
   FreeAndNil(FConnection);
end;

procedure TSQLConnectionDBX.Disconnect;
begin
   inherited;
   Try
     FConnection.Close;
   Except
   End;
end;

function TSQLConnectionDBX.Execute(Value: TStrings;
  Blobs: TList<TBlobData>): Boolean;
var Qry : TSQLQuery;
    S : String;
    I : Integer;
begin
   AddLog(Value);

   Error := '';
   Try
     Qry := FactoryQry;

     For S in Value Do
     Begin
        If S.IsEmpty Then
           Continue;

        Qry.Close;
        Qry.SQL.Clear;
        Qry.SQL.Text := S;
        For I := 0 To (Qry.Params.Count - 1) Do
           Qry.Params[I].SetBlobData(Pointer(Blobs[I]),High(Blobs[I]));

        Try
          Start;
          Qry.ExecSQL;
          Result := True;
        Except On E:Exception Do
          Begin
             Result := False;
             Error  := E.Message + '('+ S +')';
             AddLog(Error);
          End;
        End;
     End;
   Finally
     FreeAndNil(Qry);
   End;
end;

function TSQLConnectionDBX.ExecuteScript(Value: TStrings; OnProgress : TOnProgress): Boolean;
var I, C : Integer;

    function IsContains(Values : Array Of String; Value : String) : Boolean;
    var X : Integer;
    Begin
       Result := False;
       For X := Low(Values) To High(Values) Do
          If Value.Contains(Values[X]) Then
             Exit(True);
    End;

    procedure DoOnProgress(Index, Max : Integer; Mens: String);
    begin
       If Assigned(OnProgress) Then
          OnProgress(Index,Max,Mens);
    end;

begin
   Result := True;
   Try
     Disconnect;
     If (not Connect) Then
        Exit(False);

     C := 0;
     For I := 0 To (Value.Count - 1) Do
     Begin
        DoOnProgress(I,Value.Count - 1,'Executando Script');
        If not Execute(Value[I]) Then
        Begin
           DoOnProgress(I,Value.Count - 1,'Erro ao executar Script');
           Exit(False);
        End;

        If not IsContains(['trigger','alter','drop','create','view'],LowerCase(Value[I])) Then
        Begin
           Inc(C);
           If (C <= 1000) Then
              Continue;
        End;

        C := 0;
        If (not Commit) Then
        Begin
           DoOnProgress(I,Value.Count - 1,'Erro ao Gravar no Banco de dados (Commit)');
           Exit(False);
        End;
     End;

     If (C > 0) And (not Commit) Then
     Begin
        DoOnProgress(I,Value.Count - 1,'Erro ao Gravar no Banco de dados (Commit)');
        Exit(False);
     End;
   Finally
     Value.Clear;
   End;
end;

function TSQLConnectionDBX.Execute(Value: TStrings): Boolean;
var S : String;
begin
   Result := False;
   For S in Value Do
      Result := Execute(S);
end;

function TSQLConnectionDBX.Execute(Value: String): Boolean;
var Qry : TSQLQuery;
begin
   AddLog(Value);

   Error := '';
   Try
     Qry := FactoryQry;
     Qry.SQL.Text := Value;
     Try
       Start;
       If (Trim(Value) <> '') Then
          Qry.ExecSQL(True);
       Result := True;
     Except On E:Exception Do
       Begin
          Result := False;
          Error  := E.Message + '('+ Value +')';
          AddLog(Error);
       End;
     End;
   Finally
     Qry.Close;
     FreeAndNil(Qry);
   End;
end;

function TSQLConnectionDBX.FactoryQry: TSQLQuery;
begin
   Result := TSQLQuery.Create(FConnection);
   Result.SQLConnection := FConnection;
   Result.Close;
end;

function TSQLConnectionDBX.FactorySDS: TSimpleDataSet;
begin
   Result := TSimpleDataSet.Create(FConnection);
   Result.Connection := FConnection;
   Result.Close;
end;

function TSQLConnectionDBX.IsStart(Transact : Integer): Boolean;
begin
   Result := FConnection.InTransaction;
end;

function TSQLConnectionDBX.Open(Value: TStrings): TDataSet;
var S : String;
begin
   Result := nil;
   For S in Value Do
      Result := Open(S);
end;

function TSQLConnectionDBX.OpenExec(Value: String): TDataSet;
var Qry : TSQLQuery;
begin
   AddLog(Value);

   Qry := FactoryQry;
   Try
     Qry.SQL.Text := Value;
     Qry.Open;
   Finally
     Result := Qry;
     FDataSet.Add(Result);
   End;
end;

function TSQLConnectionDBX.OpenExec(Value: TStrings): TDataSet;
var S : String;
begin
   Result := nil;
   For S in Value Do
      Result := OpenExec(S);
end;

function TSQLConnectionDBX.Open(Value: String): TDataSet;
var SDS : TSimpleDataSet;
begin
   AddLog(Value);

   SDS    := FactorySDS;
   Result := SDS;
   Try
     SDS.DataSet.CommandText := '';
     SDS.DataSet.CommandText := Value;
     SDS.Open;
   Finally
     FDataSet.Add(Result);
   End;
end;

function TSQLConnectionDBX.Connected: Boolean;
begin
   Result := (FConnection.Connected) And (FConnection.ConnectionState <> csStateClosed);
end;

function TSQLConnectionDBX.Rollback(Transact : Integer): Boolean;
begin
   Result := IsStart(Transact);
   Try
     If Result Then
        FConnection.Rollback(FTransact);
     Result := True;
   Except
     Result := False;
   End;
end;

procedure TSQLConnectionDBX.SortIndex(Value: TDataSet; AscFields, DescFields : String);
begin
   inherited;
   If (Value is TCustomClientDataSet) Then
   Begin
      With TClientDataSet(Value) Do
      Begin
         If IndexName <> '' Then
            DeleteIndex(IndexName);

         IndexName := '';
         IndexDefs.Clear;
         AddIndex('_index',AscFields,[],DescFields);

         IndexName := '_index';
      End;
   End;
end;

function TSQLConnectionDBX.Start(Transact : Integer): Boolean;
begin
   Result := IsStart;
   Try
     If not Result Then
        FConnection.StartTransaction(FTransact);
     Result := True;
   Except
     Result := False;
   End;
end;

procedure TSQLConnectionDBX.Open(DataSet: TDataSet; Value: String);
var SDS : TSimpleDataSet;
begin
   AddLog(Value);

   SDS := TSimpleDataSet(DataSet);
   SDS.DisableControls;
   SDS.Close;
   Try
     Try
       SDS.IndexName := '';
       SDS.IndexDefs.Clear;
     Except
     End;

     SDS.DataSet.CommandText := '';
     SDS.DataSet.CommandText := Value;
     SDS.Open;
   Finally
     SDS.EnableControls;
   End;
end;

function TSQLConnectionDBX.Open(Value: TStrings;
  Blobs: TList<TBlobData>): TDataSet;
var SDS : TSimpleDataSet;
    S : String;
    I : Integer;
begin
   AddLog(Value);

   Error  := '';
   SDS    := FactorySDS;
   Result := SDS;
   SDS.DisableControls;
   Try
     For S in Value Do
     Begin
        If S.IsEmpty Then
           Continue;

        Try
          SDS.Close;
          SDS.DataSet.CommandText := '';
          SDS.DataSet.CommandText := S;

          For I := 0 To (SDS.DataSet.Params.Count - 1) Do
             SDS.DataSet.Params[I].SetBlobData(Pointer(Blobs[I]),High(Blobs[I]));

          SDS.Open;
        Except On E:Exception Do
          Begin
             Error := E.Message + '('+ S +')';
             AddLog(Error);
          End;
        End;
     End;
   Finally
     SDS.EnableControls;
     FDataSet.Add(Result);
   End;
end;

function TSQLConnectionDBX.OpenExec(Value: TStrings;
  Blobs: TList<TBlobData>): TDataSet;
var Qry : TSQLQuery;
    S : String;
    I : Integer;
begin
   AddLog(Value);

   Error := '';
   Qry   := FactoryQry;
   Try
     For S in Value Do
     Begin
        If S.IsEmpty Then
           Continue;

        Qry.Close;
        Qry.SQL.Clear;
        Qry.SQL.Text := S;
        For I := 0 To (Qry.Params.Count - 1) Do
           Qry.Params[I].SetBlobData(TValueBuffer(Blobs[I]),High(Blobs[I]));

        Try
          Start;
          Qry.Open;
        Except On E:Exception Do
          Begin
             Qry.Close;
             Error := E.Message + '('+ S +')';
             AddLog(Error);
          End;
        End;
     End;
   Finally
     Result := Qry;
     FDataSet.Add(Result)
   End;
end;

function TSQLConnectionDBX.OpenQry(Value: String): TDataSet;
var Qry : TSQLQuery;
begin
   AddLog(Value);

   Qry    := FactoryQry;
   Result := Qry;
   Try
     Qry.SQL.Text := Value;
     Qry.Open;
   Finally
     FDataSet.Add(Result);
   End;
end;

end.

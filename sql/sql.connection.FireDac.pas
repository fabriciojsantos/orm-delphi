unit sql.connection.FireDac;

interface

uses System.Classes, System.SysUtils, System.Generics.Collections,
     FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
     FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
     FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
     FireDAC.Comp.ScriptCommands, FireDAC.Stan.Util, FireDAC.Comp.Script,
     FireDAC.DApt, FireDAC.Phys.IBBase, FireDAC.Comp.Client,
     FireDAC.VCLUI.Wait, FireDAC.Comp.UI,
     FireDAC.Comp.DataSet, FireDAC.Stan.Consts,
     Data.DB, Data.DBXCommon,
     sql.consts, sql.connection;

type TFDScriptOutputKind = {$IFDEF VER280}TFDScriptOuputKind{$ELSE}TFDScriptOutputKind{$ENDIF};

type
   TSQLConnectionFD = Class(TDBConnection)
   private
      FDriverLink : TFDPhysDriverLink;
      FConnection : TFDConnection;
      FTransact   : TFDTransaction;
      FDBXReaders : TObjectList<TDBXReader>;
      FOnProgress : TOnProgress;

      function FactoryQry : TFDQuery;

      procedure DoOnProgress(Sender : TObject);
      procedure DoOnConsolePut(AEngine: TFDScript; const AMessage: String; AKind: TFDScriptOutputKind);
   public
      Constructor Create; Override;
      Destructor  Destroy; Override;

      function SQLGetMetaData(Kind : TFDPhysMetaInfoKind; Name : String = '') : TDataSet;

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

function TSQLConnectionFD.Commit(Transact : Integer): Boolean;
begin
   Result := IsStart;
   Try
     If Result Then
        FConnection.Commit;
     Result := True;
   Except On E:Exception Do
     Begin
        Error  := E.Message;
        Result := False;
     End;
   End;
end;

function TSQLConnectionFD.Connect: Boolean;

     procedure SetFirebird;
     begin
        With FConnection Do
        Begin
           ConnectionName := '';
           DriverName     := 'FB';
           Params.Values[S_FD_ConnParam_Common_DriverID] := 'FB';
           Params.Values[S_FD_ConnParam_ADS_Protocol]    := 'TCPIP';
           Params.Values[S_FD_ConnParam_Common_Server]   := DataBase.Server;
           Params.Values[S_FD_ConnParam_Common_Database] := DataBase.DataBase;
           Params.Values[S_FD_ConnParam_Common_Port]     := FormatFloat('0',DataBase.Port);
           Params.Values[S_FD_ConnParam_Common_UserName] := DataBase.User;
           Params.Values[S_FD_ConnParam_Common_Password] := DataBase.Password;
           Params.Values[S_FD_ConnParam_IB_SQLDialect]   := FormatFloat('0',DataBase.Dialect);
        End;

        FDriverLink := TFDPhysFBDriverLink.Create(FConnection);
        FDriverLink.VendorLib := 'fbclient.dll';
     end;

     procedure SetSQLServer;
     begin
        With FConnection Do
        begin
           {DriverName     := 'MSSQL';
           ConnectionName := 'MSSQLConnection';
           Params.Values[TDBXPropertyNames.HostName] := DataBase.Server;
           Params.Values[TDBXPropertyNames.Database] := DataBase.DataBase;
           Params.Values[TDBXPropertyNames.UserName] := DataBase.User;
           Params.Values[TDBXPropertyNames.Password] := DataBase.Password;
           Params.Values[TDBXPropertyNames.ErrorResourceFile] := 'C:\bti\sqlerro.txt';}
        end;
     end;

     procedure SetMySQL;
     begin
        With FConnection Do
        begin
           {DriverName     := 'MySQL';
           ConnectionName := 'MySQLConnection';
           LibraryName    := 'dbxmys.dll';
           VendorLib      := 'LIBMYSQL.dll';
           Params.Values[TDBXPropertyNames.DriverName] := 'MySQL';
           Params.Values[TDBXPropertyNames.HostName]   := DataBase.Server;
           Params.Values[TDBXPropertyNames.Database]   := DataBase.DataBase;
           Params.Values[TDBXPropertyNames.UserName]   := DataBase.User;
           Params.Values[TDBXPropertyNames.Password]   := DataBase.Password;
           Params.Values[TDBXPropertyNames.ErrorResourceFile] := 'C:\bti\sqlerro.txt';}
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
   FConnection.Connected   := False;
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

constructor TSQLConnectionFD.Create;
begin
   inherited;
   FDBXReaders := TObjectList<TDBXReader>.Create;
   FConnection := TFDConnection.Create(nil);
   FTransact   := TFDTransaction.Create(FConnection);

   //FTransact.TransactionID  := 1;
   FTransact.Options.Isolation := xiReadCommitted;
   FConnection.ResourceOptions.SilentMode := True;
end;

destructor TSQLConnectionFD.Destroy;
begin
   inherited;
   FreeAndNil(FDBXReaders);
   FreeAndNil(FTransact);
   FreeAndNil(FConnection);
end;

procedure TSQLConnectionFD.Disconnect;
begin
   inherited;
   Try
     FConnection.Close;
   Except
   End;
end;

procedure TSQLConnectionFD.DoOnConsolePut(AEngine: TFDScript;
  const AMessage: String; AKind: TFDScriptOutputKind);
begin
   If (AKind in [TFDScriptOutputKind.soEcho]) Then
      FSQLCurrent := AMessage
   Else If (AKind in [TFDScriptOutputKind.soError]) Then
      Error := AMessage;
end;

procedure TSQLConnectionFD.DoOnProgress(Sender: TObject);
begin
   If Assigned(FOnProgress) Then
      FOnProgress(TFDScript(Sender).TotalJobDone,TFDScript(Sender).TotalJobSize,'Executando Script');
end;

function TSQLConnectionFD.Execute(Value: TStrings;
  Blobs: TList<TBlobData>): Boolean;
var Qry : TFDQuery;
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
        Begin
           Qry.Params[I].DataType := ftBlob;
           Qry.Params[I].SetData(Pointer(Blobs[I]),High(Blobs[I]));
        End;

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

function TSQLConnectionFD.ExecuteScript(Value: TStrings;
  OnProgress: TOnProgress): Boolean;
var S : TFDScript;
    I : Integer;
begin
   FOnProgress := OnProgress;
   S := TFDScript.Create(FConnection);
   Try
     S.Connection := FConnection;
     S.ScriptOptions.CommandSeparator := '^';

     For I := 0 To (Value.Count - 1) Do
        Value[I] := Value[I] + S.ScriptOptions.CommandSeparator;

     S.ScriptOptions.EchoCommandTrim := 0;

     S.OnConsolePut := DoOnConsolePut;
     S.OnProgress   := DoOnProgress;
     S.ExecuteScript(Value);
     Result := S.ExecuteAll And (S.TotalErrors = 0);
   Finally
     If Result Then
        FConnection.Commit
     Else
        FConnection.Rollback;
     FreeAndNil(S);
   End;
end;

function TSQLConnectionFD.Execute(Value: TStrings): Boolean;
var S : String;
begin
   Result := False;
   For S in Value Do
      Result := Execute(S);
end;

function TSQLConnectionFD.Execute(Value: String): Boolean;
var Qry : TFDQuery;
begin
   AddLog(Value);

   Error := '';
   Try
     Qry := FactoryQry;
     Qry.SQL.Clear;
     Qry.SQL.Text := Value;
     Try
       Start;
       If (Trim(Value) <> '') Then
          Qry.ExecSQL;
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

function TSQLConnectionFD.FactoryQry: TFDQuery;
begin
   Result := TFDQuery.Create(FConnection);
   Result.Connection    := FConnection;
   Result.CachedUpdates := True;
   Result.Close;
end;

function TSQLConnectionFD.IsStart(Transact : Integer): Boolean;
begin
   Result := FConnection.InTransaction;
end;

function TSQLConnectionFD.Open(Value: TStrings): TDataSet;
var S : String;
begin
   Result := nil;
   For S in Value Do
      Result := Open(S);
end;

function TSQLConnectionFD.OpenExec(Value: String): TDataSet;
var Qry : TFDQuery;
begin
   AddLog(Value);

   Qry := FactoryQry;
   Try
     Qry.SQL.Clear;
     Qry.SQL.Text := Value;
     Qry.Open;
   Finally
     Result := Qry;
     FDataSet.Add(Result);
   End;
end;

function TSQLConnectionFD.OpenExec(Value: TStrings): TDataSet;
var S : String;
begin
   Result := nil;
   For S in Value Do
      Result := OpenExec(S);
end;

function TSQLConnectionFD.Open(Value: String): TDataSet;
var Qry : TFDQuery;
begin
   AddLog(Value);

   Qry    := FactoryQry;
   Result := Qry;
   Try
     Qry.SQL.Clear;
     Qry.SQL.Text := Value;
     Qry.Open;
   Finally
     FDataSet.Add(Result);
   End;
end;

function TSQLConnectionFD.Connected: Boolean;
begin
   Result := (FConnection.Connected) {And FConnection.CheckActive};
end;

function TSQLConnectionFD.Rollback(Transact : Integer): Boolean;
begin
   Result := IsStart(Transact);
   Try
     If Result Then
        FConnection.Rollback;
     Result := True;
   Except
     Result := False;
   End;
end;

procedure TSQLConnectionFD.SortIndex(Value: TDataSet; AscFields, DescFields : String);
begin
   inherited;
   If (Value is TFDDataSet) Then
   Begin
      With TFDDataSet(Value) Do
      Begin
         If IndexName <> '' Then
            DeleteIndex(IndexName);

         IndexName := '';
         IndexDefs.Clear;
         Indexes.Clear;
         AddIndex('_index',AscFields,'',[],DescFields);

         IndexName := '_index';
      End;
   End;
end;

function TSQLConnectionFD.SQLGetMetaData(Kind: TFDPhysMetaInfoKind;
  Name: String): TDataSet;
var Inf : TFDMetaInfoQuery;
begin
  Inf := TFDMetaInfoQuery.Create(nil);
  Inf.Connection   := FConnection;
  Inf.MetaInfoKind := Kind;
  Inf.ObjectName   := Name;
  Inf.Open;

  Result := Inf;
end;

function TSQLConnectionFD.Start(Transact : Integer): Boolean;
begin
   Result := IsStart;
   Try
     If not Result Then
        FConnection.StartTransaction;
     Result := True;
   Except
     Result := False;
   End;
end;

procedure TSQLConnectionFD.Open(DataSet: TDataSet; Value: String);
var Qry : TFDQuery;
begin
   AddLog(Value);

   Qry := TFDQuery(DataSet);
   Qry.DisableControls;
   Qry.Close;
   Try
     Try
       Qry.IndexName := '';
       Qry.IndexDefs.Clear;
     Except
     End;

     Qry.SQL.Clear;
     Qry.SQL.Text := Value;
     Qry.Open;
   Finally
     Qry.EnableControls;
   End;
end;

function TSQLConnectionFD.Open(Value: TStrings;
  Blobs: TList<TBlobData>): TDataSet;
var Qry : TFDQuery;
    S : String;
    I : Integer;
begin
   AddLog(Value);

   Error  := '';
   Qry    := FactoryQry;
   Result := Qry;
   Qry.DisableControls;
   Try
     For S in Value Do
     Begin
        If S.IsEmpty Then
           Continue;

        Try
          Qry.Close;
          Qry.SQL.Clear;
          Qry.SQL.Text := S;

          For I := 0 To (Qry.Params.Count - 1) Do
          Begin
             Qry.Params[I].DataType := ftBlob;
             Qry.Params[I].SetData(Pointer(Blobs[I]),High(Blobs[I]));
          End;

          Qry.Open;
        Except On E:Exception Do
          Begin
             Error := E.Message + '('+ S +')';
             AddLog(Error);
          End;
        End;
     End;
   Finally
     Qry.EnableControls;
     FDataSet.Add(Result);
   End;
end;

function TSQLConnectionFD.OpenExec(Value: TStrings;
  Blobs: TList<TBlobData>): TDataSet;
var Qry : TFDQuery;
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
        Begin
           Qry.Params[I].DataType := ftBlob;
           Qry.Params[I].SetData(Pointer(Blobs[I]),High(Blobs[I]));
        End;

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

function TSQLConnectionFD.OpenQry(Value: String): TDataSet;
var Qry : TFDQuery;
begin
   AddLog(Value);

   Qry    := FactoryQry;
   Result := Qry;
   Try
     Qry.SQL.Clear;
     Qry.SQL.Text := Value;
     Qry.Open;
   Finally
     FDataSet.Add(Result);
   End;
end;

end.

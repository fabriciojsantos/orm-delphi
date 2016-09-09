unit sql.connection.DataSnap;

interface

uses System.Classes, System.SysUtils,
     Generics.Collections,
     DBXCompressionFilter, Data.DBXCommon, Data.DBXDataSnap, Datasnap.DBClient,
     Data.DB, Data.SqlExpr, Data.FMTBcd,
     IPPeerClient,
     sql.Consts, sql.connection,
     DataSnap.Client.Proxy.DataBase;

type
   TDataSetHack = Class(Data.DB.TDataSet);

type
   TSQLConnectionDataSnap = Class(TDBConnection)
   private
      FConnection : TSQLConnection;
      FServer     : TDSDataBase;
   public
      Constructor Create; Override;
      Destructor  Destroy; Override;

      property Connection : TSQLConnection Read FConnection;

      function  Connect : Boolean; Override;
      procedure Disconnect; Override;
      function  Connected : Boolean; Override;

      function IsStart(Transact : Integer = 1)  : Boolean; Override;
      function Start(Transact : Integer = 1)    : Boolean; Override;
      function Commit(Transact : Integer = 1)   : Boolean; Override;
      function Rollback(Transact : Integer = 1) : Boolean; Override;

      function ExecuteScript(Value : TStrings; OnProgress : TOnProgress) : Boolean; Override;

      function Execute(Value : String) : Boolean; Overload; Override;
      function Execute(Value : TStrings) : Boolean; Overload; Override;
      function Execute(Value : TStrings; Blobs : TList<TBlobData>) : Boolean; Overload; Override;

      function Open(Value : String) : TDataSet; Overload; Override;
      function Open(Value : TStrings) : TDataSet; Overload; Override;
      function Open(Value : TStrings; Blobs : TList<TBlobData>) : TDataSet; Overload; Override;

      function OpenQry(Value : String) : TDataSet; Overload; Override;

      function OpenExec(Value : String) : TDataSet; Overload; Override;
      function OpenExec(Value : TStrings) : TDataSet; Overload; Override;
      function OpenExec(Value : TStrings; Blobs : TList<TBlobData>) : TDataSet; Overload; Override;
   End;

implementation

{ TSQLConnectionDataSnap }

function TSQLConnectionDataSnap.Commit(Transact: Integer): Boolean;
begin
   Result := FServer.Commit(Transact);
end;

function TSQLConnectionDataSnap.Connect: Boolean;
begin
   Result := False;
   FConnection.LoginPrompt := False;
   Try
      With FConnection Do
      begin
         DriverName     := 'DataSnap';
         ConnectionName := 'DataSnapCONNECTION';
         Params.Clear;
         Params.Values[TDBXPropertyNames.DriverName] := 'DataSnap';
         Params.Values[TDBXPropertyNames.HostName]   := DataBase.Server;
         Params.Values[TDBXPropertyNames.Port]       := FormatFloat('0',DataBase.Port);
         Params.Values[TDBXPropertyNames.UserName]   := DataBase.User;
         Params.Values[TDBXPropertyNames.Password]   := DataBase.Password;
         Params.Values[TDBXPropertyNames.Filters]    := '{"ZLibCompression":{"CompressMoreThan":"1024"}}';
         //If not DataBase.FilterPC1.IsEmpty Then
         //   Params.Values[TDBXPropertyNames.Filters] := '{"ZLibCompression":{"CompressMoreThan":"1024"},"PC1":{"Key":"'+ DataBase.FilterPC1 +'"}}';
      end;
   Finally
      Try
        FConnection.LoginPrompt := False;
        FConnection.Connected   := True;
        Result := FConnection.Connected;

        If Assigned(FServer) Then
           FreeAndNil(FServer);

        If Result Then
           FServer := TDSDataBase.Create(FConnection.DBXConnection);
      Except On E : Exception Do
        Error := E.Message;
      End;
   End;
end;

constructor TSQLConnectionDataSnap.Create;
begin
   inherited;
   FConnection := TSQLConnection.Create(nil);
end;

destructor TSQLConnectionDataSnap.Destroy;
begin
   inherited;
   FreeAndNil(FConnection);
   If Assigned(FServer) Then
      FreeAndNil(FServer);
end;

procedure TSQLConnectionDataSnap.Disconnect;
begin
   inherited;
   Try
     FConnection.Close;
   Except
   End;
end;

function TSQLConnectionDataSnap.Execute(Value: TStrings;
  Blobs: TList<TBlobData>): Boolean;
begin
   Result := FServer.Execute(Value,Blobs);
end;

function TSQLConnectionDataSnap.ExecuteScript(Value: TStrings;
  OnProgress: TOnProgress): Boolean;
begin
   Result := False;
end;

function TSQLConnectionDataSnap.Execute(Value: TStrings): Boolean;
begin
   Result := FServer.Execute(Value);
end;

function TSQLConnectionDataSnap.Execute(Value: String): Boolean;
begin
   Result := FServer.Execute(Value);
end;

function TSQLConnectionDataSnap.IsStart(Transact: Integer): Boolean;
begin
   Result := FServer.IsStart(Transact);
end;

function TSQLConnectionDataSnap.Open(Value: TStrings;
  Blobs: TList<TBlobData>): TDataSet;
begin
   Result := FServer.Open(Value,Blobs);
end;

function TSQLConnectionDataSnap.Open(Value: TStrings): TDataSet;
begin
   Result := FServer.Open(Value);
end;

function TSQLConnectionDataSnap.Open(Value: String): TDataSet;
begin
   Result := FServer.Open(Value);
end;

function TSQLConnectionDataSnap.OpenExec(Value: TStrings): TDataSet;
begin
   Result := FServer.OpenExec(Value);
end;

function TSQLConnectionDataSnap.OpenExec(Value: TStrings;
  Blobs: TList<TBlobData>): TDataSet;
begin
   Result := FServer.OpenExec(Value,Blobs);
end;

function TSQLConnectionDataSnap.OpenExec(Value: String): TDataSet;
begin
   Result := FServer.OpenExec(Value);
end;

function TSQLConnectionDataSnap.OpenQry(Value: String): TDataSet;
begin
   Result := FServer.OpenQry(Value);
end;

function TSQLConnectionDataSnap.Rollback(Transact: Integer): Boolean;
begin
   Result := FServer.Rollback(Transact);
end;

function TSQLConnectionDataSnap.Start(Transact: Integer): Boolean;
begin
   Result := FServer.Start(Transact);
end;

function TSQLConnectionDataSnap.Connected: Boolean;
begin
   Result := (FConnection.Connected) And (FConnection.ConnectionState <> csStateClosed);
end;

end.

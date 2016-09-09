unit orm.session;

interface

uses System.SysUtils, System.Variants,
     System.Generics.Collections, System.Generics.Defaults,
     Data.DB,
     orm.engine,
     orm.attributes.objects,
     orm.where,
     sql.consts,
     sql.utils,
     sql.connection;

type
   TSession = Class
   Private
     FCache      : TCache;
     FConnection : TDBConnection;

     function OnSQLEvent(Events : TSQLEvents; Mode : TSQLDBMode; var DataSet : TDataSet) : Boolean;
   Public
     constructor Create(Value : TDBConnection);
     destructor  Destroy; Override;

     property Connection : TDBConnection Read FConnection;

     function Start(Transact : Integer = 1) : Boolean;
     function Commit(Transact : Integer = 1) : Boolean;
     function Rollback(Transact : Integer = 1) : Boolean;

     procedure CommitRollback(Value : Boolean);

     function Save(Value : TObject) : Boolean; Overload;
     function Save(Value : TObjectList<TObject>) : Boolean; Overload;
     function SaveAll<T : Class>(Value : TObjectList<T>) : Boolean; Overload;

     function Delete(Value : TObject) : Boolean; Overload;
     function Delete(Value : TObjectList<TObject>) : Boolean; Overload;

     function Refresh(Value : TObject) : Boolean; Overload;
     function Refresh(Values : Array Of TObject) : Boolean; Overload;

     function Execute(Value : TObject) : Boolean; Overload;
     function Execute(Values : Array Of TObject) : Boolean; Overload;

     function FindUpdate(Value : TObject; ID : Variant) : Boolean; Overload;
     function FindUpdate(Value : TObject; ID : Variant; Where : String) : Boolean; Overload;
     function FindUpdate(Value : TObject; ID : Variant; Where : TWhere) : Boolean; Overload;

     function Find<T : Class>(Value : Variant) : T; Overload;
     function Find<T : Class>(Value : TWhere) : T; Overload;

     function FindAll<T : Class>(Where : String = ''; OrderBy : String = ''; GroupBy : String = '') : TObjectList<T>; Overload;
     function FindAll<T : Class>(Where : TWhere; OrderBy : String = ''; GroupBy : String = '') : TObjectList<T>; Overload;

     function Find(ClassName : String; ID : Variant) : TObject; Overload;
     function FindAll(ClassName : String; Value : TObjectList<TObject>; Where : String = ''; OrderBy : String = ''; GroupBy : String = '') : Boolean; Overload;
   End;

var Session : TSession;

implementation

uses orm.objects.utils;

{ TSession }

function TSession.Commit(Transact : Integer) : Boolean;
begin
   Result := True;
   If FConnection.IsStart(Transact) Then
      Result := FConnection.Commit(Transact);
end;

procedure TSession.CommitRollback(Value: Boolean);
begin
   If Value Then Commit Else Rollback;
end;

constructor TSession.Create(Value : TDBConnection);
begin
   FConnection := Value;
   FCache      := TCache.Create;
end;

function TSession.Delete(Value: TObject) : Boolean;
begin
   Start;
   Result := TEngine.Add(FConnection.SQL,nil,dbDelete,OnSQLEvent,FCache,Value);
end;

function TSession.Delete(Value: TObjectList<TObject>): Boolean;
var O : TObject;
begin
   Result := True;
   For O in Value Do
      If Assigned(O) Then
         If O.ClassName.Contains('TObjectList<') Then
            Result := Result And Delete(TObjectList<TObject>(O))
         Else
            Result := Result And Delete(O);
end;

destructor TSession.Destroy;
begin
   FreeAndNil(FCache);
   inherited;
end;

function TSession.Execute(Values: array of TObject): Boolean;
var V : TObject;
begin
   Result := True;
   For V in Values Do
      Result := Result And (not Session.Execute(V));
end;

function TSession.Execute(Value: TObjecT) : Boolean;
begin
   Start;
   Result := TEngine.Add(FConnection.SQL,nil,dbExecute,OnSQLEvent,FCache,Value);
end;

function TSession.FindUpdate(Value: TObject; ID: Variant; Where : String): Boolean;
var A : TEngine;
    C : TClass;
begin
   //Result := False;
   Clear(Value);
   C := Value.ClassType;
   Try
     A := TEngine.Create(dbSelect,OnSQLEvent,FCache,C,Value);
     If (Where <> '') And (ID <> 0) Then
        A.Where := Format(A.KeyField,[SQLFormat(ID,0)]) +' AND '+ Where
     Else If (Where <> '')  Then
        A.Where := Where
     Else
        A.Where := Format(A.KeyField,[SQLFormat(ID,0)]);
     Result := A.Execute;
   Finally
     FreeAndNil(A);
   End;
end;

function TSession.Find(ClassName: String; ID: Variant): TObject;
var A : TEngine;
    C : TClass;
begin
   C := GetClass(ClassName);
   Result := Factory(C);

   A := TEngine.Create(dbSelect,OnSQLEvent,FCache,C,Result);
   Try
     A.Where := Format(A.KeyField,[SQLFormat(ID,0)]);
     A.Execute;
   Finally
     FreeAndNil(A);
   End;
end;

function TSession.Find<T>(Value: TWhere): T;
var A : TEngine;
    C : TClass;
    L : TObjectList<T>;
begin
   Result := nil;
   C := T;

   A := TEngine.Create(dbSelect,OnSQLEvent,FCache,C,Result);
   Try
     L := FindAll<T>(Value);
     Try
       If Assigned(L) And (L.Count > 0) Then
          Result := L.Extract(L.First);
     Finally
       FreeAndNil(L);
     End;
   Finally
     FreeAndNil(A);
   End;
end;

function TSession.Find<T>(Value: Variant): T;
var A : TEngine;
    C : TClass;
    L : TObjectList<T>;
begin
   Result := nil;
   C := T;
   A := TEngine.Create(dbSelect,OnSQLEvent,FCache,C,Result);
   Try
     L := FindAll<T>(Format(A.KeyField,[SQLFormat(Value,0)]));
     Try
       If Assigned(L) And (L.Count > 0) Then
          Result := L.Extract(L.First);
     Finally
       FreeAndNil(L);
     End;
   Finally
     FreeAndNil(A);
   End;
end;

function TSession.FindAll(ClassName : String; Value : TObjectList<TObject>; Where, OrderBy,
  GroupBy: String): Boolean;
var A : TEngine;
    C : TClass;
begin
   C := GetClass(ClassName) ;
   A := TEngine.Create(dbSelect,OnSQLEvent,FCache,C,TObjectList<TObject>(Value));
   Try
     A.Where   := Where;
     A.OrderBy := OrderBy;
     A.GroupBy := GroupBy;
     A.SQL     := FConnection.SQL;
     Result    := A.Execute;
   Finally
     FreeAndNil(A);
   End;
   Value.TrimExcess;
end;

function TSession.FindAll<T>(Where: TWhere; OrderBy,
  GroupBy: String): TObjectList<T>;
begin
   Result := FindAll<T>(Where.ToString,OrderBy,GroupBy);
end;

function TSession.FindUpdate(Value: TObject; ID: Variant): Boolean;
begin
   Result := FindUpdate(Value,ID,'');
end;

function TSession.FindUpdate(Value: TObject; ID: Variant;
  Where: TWhere): Boolean;
begin
   Result := FindUpdate(Value,ID,Where.ToString);
end;

function TSession.FindAll<T>(Where, OrderBy, GroupBy : String) : TObjectList<T>;
var A : TEngine;
    C : TClass;
begin
   C := T;
   Result := TObjectList<T>.Create;

   A := TEngine.Create(dbSelect,OnSQLEvent,FCache,C,TObjectList<TObject>(Result));
   Try
     A.Where   := Where;
     A.OrderBy := OrderBy;
     A.GroupBy := GroupBy;
     A.SQL     := FConnection.SQL;
     A.Execute;
   Finally
     FreeAndNil(A);
   End;
   Result.TrimExcess;
end;

function TSession.OnSQLEvent(Events : TSQLEvents; Mode: TSQLDBMode; var DataSet: TDataSet) : Boolean;
begin
   DataSet := nil;
   If not Assigned(Events) Then
      Exit;

   Case Mode Of
      dbDelete,
      dbExecute :
          If (Events.SQL[0].Contains('returning') Or Events.SQL[0].Contains('select')) Then
             DataSet := FConnection.Open(Events.SQL,Events.Blobs)
          Else
             FConnection.Execute(Events.SQL,Events.Blobs);

      dbInsert,
      dbUpdate :
          DataSet := FConnection.OpenExec(Events.SQL,Events.Blobs);

      dbSelect,
      dbRefresh :
          DataSet := FConnection.Open(Events.SQL,Events.Blobs);
   End;
   FreeAndNil(Events);
   Result := FConnection.Error.IsEmpty;
end;

function TSession.Refresh(Value: TObject) : Boolean;
begin
   Result := TEngine.Add(FConnection.SQL,nil,dbRefresh,OnSQLEvent,FCache,Value);
end;

function TSession.Refresh(Values: array of TObject): Boolean;
var V : TObject;
begin
   Result := True;
   For V in Values Do
      Result := Result And (not Session.Refresh(V));
end;

function TSession.Rollback(Transact : Integer) : Boolean;
begin
   Result := True;
   If FConnection.IsStart(Transact) Then
      Result := FConnection.Rollback(Transact);
end;

function TSession.Save(Value: TObject) : Boolean;
begin
   Start;
   Result := TEngine.Add(FConnection.SQL,nil,dbInsert,OnSQLEvent,FCache,Value);
end;

function TSession.Save(Value: TObjectList<TObject>): Boolean;
var O : TObject;
begin
   Result := True;
   For O in Value Do
      If Assigned(O) Then
         If O.ClassName.Contains('TObjectList<') Then
            Result := Result And Save(TObjectList<TObject>(O))
         Else
            Try
              Result := Result And Save(O);
            Except
              Result := False;
            End;
end;

function TSession.SaveAll<T>(Value: TObjectList<T>): Boolean;
var V : T;
begin
   Result := True;
   For V in Value Do
      Result := Result And Save(V);
end;

function TSession.Start(Transact : Integer) : Boolean;
begin
   Result := FConnection.Start(Transact);
end;

end.

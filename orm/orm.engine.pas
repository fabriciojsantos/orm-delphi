unit orm.engine;

interface

//{$DEFINE CODESITE}

uses {$IFDEF CODESITE}CodeSiteLogging,{$ENDIF}
     System.SysUtils, System.Classes, System.Variants,
     System.Rtti, System.TypInfo, System.Generics.Collections,
     Data.DB, Data.SqlTimSt,
     sql.consts,
     sql.utils,
     orm.attributes.types,
     orm.attributes.objects,
     orm.lazyload,
     orm.objects.utils;

type TSQLEvent = function (Events : TSQLEvents; Mode : TSQLDBMode; var DataSet : TDataSet) : Boolean of object;

type
   TEngine = Class
   Private
     FSQLEvent   : TSQLEvent;
     FSQLMode    : TSQLDBMode;
     FDataSet    : TDataSet;
     FWhere      : String;
     FOrderBy    : String;
     FGroupBy    : String;
     FSQL        : TSQL;
     FClass      : TClass;
     FObject     : TObject;
     FOwner      : TObject;
     FOwnerField : String;
     FCache      : TCache;
     FCacheData  : TCacheData;

     function Insert(Value : TDBObject) : TSQLEvents;
     function Update(Value : TDBObject) : TSQLEvents;
     function Delete(Value : TDBObject) : TSQLEvents;
     function Select(Value : TDBObject) : TSQLEvents; Overload;
     procedure Select(var Alias : Integer; Value : TDBObject; Keys, Fields, Joins : TList<String>); Overload;
     function Refresh(Value : TDBObject) : TSQLEvents;
     function Execute(Value : TDBObject) : TSQLEvents; Overload;

     function Command : TSQLEvents;

     procedure GetValues(Value : TObject); Overload;
     procedure GetValues(Value : TObject; DBObject : TDBObject); Overload;

     procedure SetValues(ValueTypes : TFieldTypes; ValueObject : TObject; DataSet : TDataSet); Overload;
     procedure SetValues(ValueTypes : TFieldTypes; ValueObject : TObject; DataSet : TDataSet; DBObject : TDBObject; ValueKey : Variant); Overload;

     procedure UpdateFields(DS : TDataSet; Value : TDBObject);

     function  GetFieldName(DS : TDataSet; Alias : String; Field : String) : String; Overload;
     function  GetFieldName(DS : TDataSet; C : TClass; Field : String) : String; Overload;

     function  AliasToAlias(Alias : TAlias; Value : String) : String;

     function DoOnSQLEvent : Boolean;

     procedure Notification(Value : TObject; DataSet : TDataSet; DBObject : TDBObject = nil; FieldKey : String = ''); Overload;
     procedure Notification(Value : TObject; FieldKey : String = ''); Overload;

   Public
     Constructor Create(M : TSQLDBMode; E : TSQLEvent; Cache : TCache; C : TClass; O : TObject); Overload;
     Destructor  Destroy; Override;

     class function Add(S : TSQL; DS : TDataSet; M : TSQLDBMode; E : TSQLEvent; Cache : TCache; O : TObject) : Boolean; Overload;
     class function Add(Owner : TObject; OwnerField : String; S : TSQL; DS : TDataSet; M : TSQLDBMode; E : TSQLEvent; Cache : TCache; O : TObject) : Boolean; Overload;

     property Where       : String   Read FWhere      Write FWhere;
     property OrderBy     : String   Read FOrderBy    Write FOrderBy;
     property GroupBy     : String   Read FGroupBy    Write FGroupBy;
     property SQL         : TSQL     Read FSQL        Write FSQL;
     property DataSet     : TDataSet Read FDataSet    Write FDataSet;
     property Owner       : TObject  Read FOwner      Write FOwner;
     property OwnerField  : String   Read FOwnerField Write FOwnerField;

     function KeyField : String;
     function Execute : Boolean; Overload;
   End;

implementation

{ TEngine }

class function TEngine.Add(S: TSQL; DS: TDataSet; M: TSQLDBMode; E: TSQLEvent;
  Cache : TCache; O: TObject) : Boolean;
var A : TEngine;
begin
   Result := True;
   A := TEngine.Create(M,E,Cache,O.ClassType,O);
   Try
     A.SQL     := S;
     A.DataSet := DS;
     Result    := A.Execute;
   Finally
     FreeAndNil(A);
   End;
end;

class function TEngine.Add(Owner: TObject; OwnerField : String; S: TSQL; DS: TDataSet; M: TSQLDBMode;
  E: TSQLEvent; Cache : TCache; O: TObject) : Boolean;
var A : TEngine;
begin
   Result := True;
   A := TEngine.Create(M,E,Cache,O.ClassType,O);
   Try
     A.SQL        := S;
     A.DataSet    := DS;
     A.Owner      := Owner;
     A.OwnerField := OwnerField;
     Result       := A.Execute;
   Finally
     FreeAndNil(A);
   End;
end;

function TEngine.Command: TSQLEvents;
var DBObject : TDBObject;
begin
   Result   := nil;
   DBObject := TAObject.Add(FClass,FCache);
   If not Assigned(DBObject) Then
      Exit;

   If (FSQLMode in [dbInsert,dbUpdate,dbRefresh,dbDelete,dbExecute]) Then
   Begin
      GetValues(FObject);
      If (FSQLMode in [dbInsert,dbUpdate]) Then
      Begin
         If (DBObject.OType in [TObjectType.otStoredProc]) Then
            FSQLMode := dbExecute
         Else If (not TAObject.IsKeyEmpty(FObject,FCache)) Then
            FSQLMode := dbUpdate
         Else
            FSQLMode := dbInsert;
      End;
   End;

   Result := nil;
   Case FSQLMode Of
      dbInsert  : Result := Insert(DBObject);
      dbUpdate  : Result := Update(DBObject);
      dbDelete  : Result := Delete(DBObject);
      dbSelect  : Result := Select(DBObject);
      dbRefresh : Result := Refresh(DBObject);
      dbExecute : Result := Execute(DBObject);
   End;
end;

constructor TEngine.Create(M : TSQLDBMode; E : TSQLEvent; Cache : TCache; C : TClass; O: TObject);
begin
   FSQLMode   := M;
   FSQLEvent  := E;
   FCache     := Cache;
   FClass     := C;
   FObject    := O;
   FCacheData := TCacheData.Create;
end;

function TEngine.Delete(Value : TDBObject) : TSQLEvents;
var F : TDBField;
    SKeys : TStringBuilder;
begin
   Result := TSQLEvents.Create;

   SKeys  := TStringBuilder.Create;
   Try
     For F in Value.Fields Do
        If (ftPrimaryKey in F.FieldTypes) Then
           SKeys.Append('('+ F.Name +' = '+ SQLFormat(F.TypeInfo,F.Value,F.Size,not (ftNotNull in F.FieldTypes)) +') and ');

     If (SKeys.Length = 0) Then
        Result.SQL.Add(Format(SQLDelete,[Value.Name]))
     Else
     Begin
        SKeys.Remove(SKeys.Length - 5,5);
        Result.SQL.Add(Format(SQLDelete + SQLWhere,[Value.Name,SKeys.ToString]))
     End;
   Finally
     FreeAndNil(SKeys);
   End;
end;

destructor TEngine.Destroy;
begin
   FreeAndNil(FCacheData);
   inherited;
end;

function TEngine.DoOnSQLEvent : Boolean;
begin
   Result := False;
   If Assigned(FSQLEvent) And (not Assigned(FDataSet)) Then
      Result := FSQLEvent(Command,FSQLMode,FDataSet);
end;

function TEngine.Execute(Value: TDBObject): TSQLEvents;
var SFields, SParams : TStringBuilder;
    SQL : String;

    procedure GetFields(V : TDBObject);
    var F : TDBField;
        C : TDBObject;
    Begin
       For F in V.Fields Do
         If not (ptInPut in F.ParamTypes) Then
            SFields.AppendLine( F.Name +',' )
         Else If not F.IsBytes Then
            SParams.Append(SQLFormat(F.TypeInfo,F.Value,F.Size,not (ftNotNull in F.FieldTypes)) +',')
         Else
         Begin
            SParams.Append(' :'+ F.Name +',');
            Result.Blobs.Add(F.Bytes);
         End;

       For C in V.Childs Do
          GetFields(C);
    End;

begin
   Result  := TSQLEvents.Create;

   SFields := TStringBuilder.Create;
   SParams := TStringBuilder.Create;
   Try
     GetFields(Value);

     If (SParams.Length <> 0) Then
        SParams.Remove(SParams.Length - 1,1);

     If (SFields.Length <> 0) Then
        SFields.Remove(SFields.Length - 1 - Length(sLineBreak),1 + Length(sLineBreak));

     SQL := SQLProcedure;
     If (SParams.Length <> 0) then
        SQL := SQLProcedure +'(%s)';

     If (SFields.Length = 0) then
        SQL := Format(SQL,[Value.Name,SParams.ToString])
     Else
        SQL := Format(SQLProcedureOpen,[SFields.ToString,Value.Name,SParams.ToString]);

     Result.SQL.Add(SQL);
   Finally
     FreeAndNil(SParams);
     FreeAndNil(SFields);
   End;
end;

function TEngine.Execute : Boolean;
var B : TBookmark;
begin
   Result := False;
   Try
     Result := DoOnSQLEvent;
     If not (Result And Assigned(FDataSet) And (not FDataSet.IsEmpty)) Then
        Exit;

     B := FDataSet.GetBookmark;
     Try
       Case FSQLMode Of
          dbSelect,
          dbExecute :
              Begin
                 If (Pos('List<',FObject.ClassName) = 0) Then
                    SetValues([],FObject,FDataSet)
                 Else
                 Begin
                    While (not FDataSet.Eof) Do
                    Begin
                       Notification(FObject,FDataSet);
                       FDataSet.Next;
                    End;
                 End;
              End;
          dbInsert  : SetValues([ftPrimaryKey,ftAuto,ftReadOnly],FObject,FDataSet);
          dbUpdate  : SetValues([ftAuto,ftReadOnly],FObject,FDataSet);
          dbRefresh : SetValues([],FObject,FDataSet);
       End;
     Finally
       FDataSet.GotoBookmark(B);
     End;
   Except On E:Exception Do
     Begin
        raise Exception.Create(E.Message);
     End;
   End;
end;

function TEngine.GetFieldName(DS : TDataSet; Alias, Field: String): String;
begin
   Result := '';
   If Assigned(DS.FindField(FSQL.SQLFieldAlias(Alias,Field))) Then
      Result := FSQL.SQLFieldAlias(Alias,Field)
   Else If Assigned(DS.FindField(Field)) Then
      Result := Field;
end;

function TEngine.GetFieldName(DS: TDataSet; C: TClass; Field: String): String;
var DBObject : TDBObject;
begin
   Result   := '';
   DBObject := TAObject.Add(C,FCache);
   If Assigned(DS.FindField(FSQL.SQLFieldAlias(DBObject.Alias,Field))) Then
      Result := FSQL.SQLFieldAlias(DBObject.Alias,Field)
   Else If Assigned(DS.FindField(Field)) Then
      Result := Field;
end;

procedure TEngine.GetValues(Value: TObject; DBObject: TDBObject);
var C : TRttiContext;
    Y : TRttiType;
    F : TRttiField;
    P : TRttiProperty;
    O : TObject;
    I : TDBObject;
    AF : TDBField;

    function IsNotification(FieldName : String) : Boolean;
    var Table : TDBTable;
        I : Integer;
    Begin
       Result := False;
       If not (DBObject is TDBTable) Then
          Exit(False);

       Table := TDBTable(DBObject);
       For I := 0 To (Table.Foreign.Count - 1) Do
          If (Table.Foreign[I].FieldName = FieldName) Then
             Exit((mInsert in Table.Foreign[I].Modifys) Or
                  (mUpdate in Table.Foreign[I].Modifys));
    End;

begin
   C := TRttiContext.Create;
   Try
     Try
       Y := C.GetType(Value.ClassType);
       For AF in DBObject.Fields Do
       Begin
          AF.Value := null;
          AF.SetBytes(nil);

          If (FSQLMode in [dbDelete]) And (not (ftPrimaryKey in AF.FieldTypes)) Then
             Continue;

          If (AF.FieldName <> '') Then
          Begin
             F := Y.GetField(AF.FieldName);
             If not Assigned(F) Then
                Continue;

             {$IFDEF CODESITE}
             CodeSite.Send('GetValues:'+ Value.ClassName +'|Name = '+ DBObject.Name + '|Alias = '+ DBObject.Alias +
                            '|FieldName = '+ AF.FieldName +'|Name = '+ AF.Name +'|Value = '+ VarToStr(AF.Value));
             {$ENDIF}

             AF.TypeInfo := F.GetValue(Value).TypeInfo;
             If (F.FieldType.TypeKind <> tkClass) Then
             Begin
                AF.Value := F.GetValue(Value).AsVariant;
                Continue;
             End;

             If F.FieldType.AsInstance.MetaclassType.InheritsFrom(TStream) Then
                AF.SetStream(TStream(F.GetValue(Value).AsObject))
             Else
             Begin
                O := F.GetValue(Value).AsObject;
                If (Pos('TLazyLoad',F.FieldType.AsInstance.MetaclassType.ClassName) > 0) Then
                Begin
                   If TLazyLoad<TObject>(F.GetValue(Value).AsObject).IsNull Then
                      Continue;
                   O := TLazyLoad<TObject>(F.GetValue(Value).AsObject).GetObject;
                End;

                AF.TypeInfo := System.TypeInfo(Integer);
                AF.Value    := TAObject.GetKey(O,FCache);
                If SQLValueEmpty(AF.Value) Then
                Begin
                   AF.Value := null;
                   If IsNotification(AF.FieldName) Then
                   Begin
                      Notification(F.GetValue(Value).AsObject);
                      AF.Value := TAObject.GetKey(F.GetValue(Value).AsObject,FCache);
                   End;
                End;
             End;
          End Else If (AF.PropertyName <> '') Then
          Begin
             P := Y.GetProperty(AF.PropertyName);
             If not Assigned(P) Then
                Continue;

             AF.TypeInfo := P.GetValue(Value).TypeInfo;
             If (P.PropertyType.TypeKind <> tkClass) Then
             Begin
                AF.Value := P.GetValue(Value).AsVariant;
                Continue;
             End;

             If P.PropertyType.AsInstance.MetaclassType.InheritsFrom(TStream) Then
                AF.SetStream(TStream(P.GetValue(Value).AsObject))
             Else
             Begin
                O := P.GetValue(Value).AsObject;
                If (Pos('TLazyLoad',P.PropertyType.AsInstance.MetaclassType.ClassName) > 0) Then
                Begin
                   If TLazyLoad<TObject>(P.GetValue(Value).AsObject).IsNull Then
                      Continue;
                   O := TLazyLoad<TObject>(P.GetValue(Value).AsObject).GetObject;
                End;

                AF.TypeInfo := System.TypeInfo(Integer);
                AF.Value    := TAObject.GetKey(O,FCache);
                If SQLValueEmpty(AF.Value) Then
                Begin
                   AF.Value := null;
                   If IsNotification(AF.FieldName) Then
                   Begin
                      Notification(P.GetValue(Value).AsObject);
                      AF.Value := TAObject.GetKey(P.GetValue(Value).AsObject,FCache);
                   End;
                End;
             End;
          End;
       End;

       For I in DBObject.Childs Do
       Begin
          O := nil;
          Case I.ParentType Of
             TParentType.ptField :
             Begin
                F := Y.GetField(I.Parent);
                If (not Assigned(F)) Or (F.FieldType.TypeKind <> tkClass) Or
                   F.FieldType.AsInstance.MetaclassType.InheritsFrom(TStream) Then
                   Continue;

                O := F.GetValue(Value).AsObject;
             End;
             TParentType.ptUnknow :
             Begin
                P := Y.GetProperty(I.Parent);
                If (not Assigned(P)) Or (P.PropertyType.TypeKind <> tkClass) Or
                   P.PropertyType.AsInstance.MetaclassType.InheritsFrom(TStream) Then
                   Continue;

                O := P.GetValue(Value).AsObject;
             End;
          End;

          If Assigned(O) Then
             GetValues(O,I);
       End;
     Finally
       C.Free;
     End;
   Except On E:Exception Do
     raise Exception.Create(E.Message +'|'+ F.Name);
   End;
end;

procedure TEngine.GetValues(Value : TObject);
begin
   GetValues(Value,TAObject.Add(Value.ClassType,FCache));
end;

function TEngine.Insert(Value : TDBObject) : TSQLEvents;
var S : TStrings;
    SKeys, SFields, SValues : TStringBuilder;

    procedure GetFields(V : TDBObject);
    var F : TDBField;
        C : TDBObject;
    Begin
       For F in V.Fields Do
          If (not (ftInsertOnly in F.FieldTypes)) And ((ftPrimaryKey in F.FieldTypes) Or (ftAuto in F.FieldTypes) Or (ftReadOnly in F.FieldTypes)) Then
             SKeys.Append(F.Name +' , ')
          Else If not (ftUpdateOnly in F.FieldTypes) Then
          Begin
             SFields.Append(F.Name +' , ');

             If (not FOwnerField.IsEmpty) And (FOwnerField = F.Name) Then
                SValues.Append(SQLFormat(System.TypeInfo(Integer),TAObject.GetKey(FOwner,FCache),-1) +' , ')
             Else If not F.IsBytes Then
                SValues.Append(SQLFormat(F.TypeInfo,F.Value,F.Size,not (ftNotNull in F.FieldTypes)) +' , ')
             Else
             Begin
                SValues.Append(' :'+ F.Name +' , ');
                Result.Blobs.Add(F.Bytes);
             End;
          End;

       For C in V.Childs Do
          GetFields(C);
    End;

begin
   Result   := TSQLEvents.Create;

   SKeys    := TStringBuilder.Create;
   SFields  := TStringBuilder.Create;
   SValues  := TStringBuilder.Create;
   Try
     GetFields(Value);

     If (not FOwnerField.IsEmpty) And (not SFields.ToString.Contains(FOwnerField +' ')) Then
     Begin
        SFields.Append(FOwnerField +' , ');
        SValues.Append(SQLFormat(System.TypeInfo(Integer),TAObject.GetKey(FOwner,FCache),-1) +' , ');
     End;

     If (SKeys.Length <> 0) Then
        SKeys.Remove(SKeys.Length - 3,3);

     If (SFields.Length <> 0) Then
        SFields.Remove(SFields.Length - 3,3);

     If (SValues.Length <> 0) Then
        SValues.Remove(SValues.Length - 3,3);

     S := FSQL.SQLInsert(Value.Name,SFields.ToString,SValues.ToString,SKeys.ToString);
     Try
       Result.SQL.AddStrings(S);
     Finally
       FreeAndNil(S);
     End;
   Finally
     FreeAndNil(SKeys);
     FreeAndNil(SFields);
     FreeAndNil(SValues);
   End;
end;

function TEngine.KeyField : String;
var AF : TDBField;
    DBObject : TDBObject;
begin
   Result   := '';
   DBObject := TAObject.Add(FClass,FCache);
   If not Assigned(DBObject) Then
      Exit;

   For AF in DBObject.Fields Do
      If (ftPrimaryKey in AF.FieldTypes) Then
         Exit('('+ DBObject.Name +'.'+ AF.Name +' = %s)');
end;

procedure TEngine.Notification(Value: TObject; FieldKey : String);
var O : TObject;
begin
   If not Assigned(Value) Then
      Exit;

   If (Pos('List<',Value.ClassName) <= 0) Then
   Begin
      If not FieldKey.IsEmpty Then
         TEngine.Add(FObject,FieldKey,FSQL,nil,FSQLMode,FSQLEvent,FCache,Value)
      Else
         TEngine.Add(FSQL,nil,FSQLMode,FSQLEvent,FCache,Value);
   End Else
   Begin
      For O in TObjectList<TObject>(Value) Do
         TEngine.Add(FObject,FieldKey,FSQL,nil,FSQLMode,FSQLEvent,FCache,O);
   End;
end;

procedure TEngine.Notification(Value: TObject; DataSet: TDataSet; DBObject : TDBObject; FieldKey : String);
var C : TClass;
    L : TObjectList<TObject>;
    K : Variant;
    FK : String;
begin
   If not Assigned(Value) Then
      Exit;

   If (not Value.ClassName.Contains('List<')) Then
   Begin
      If Assigned(DBObject) Then
         SetValues([],Value,DataSet,DBObject,null)
      Else
         SetValues([],Value,DataSet);
   End Else
   Begin
      C := GetClass(Value.ClassType);
      If (not FieldKey.IsEmpty) Then
      Begin
         FK := GetFieldName(FDataSet,Value.ClassType,FieldKey);
         If FDataSet.FieldByName(FK).IsNull Then
            Exit;
      End;

      L := TObjectList<TObject>(Value);
      If (L.Count = 0) Or FieldKey.IsEmpty Then
         L.Add(Factory(C))
      Else
      Begin
         K := TAObject.GetKey(L.Last,FK,FCache);
         If (K <> DataSet.FieldByName(FK).Value) Then
            L.Add(Factory(C));
      End;
      SetValues([],L.Last,DataSet);
   End;
end;

function TEngine.Refresh(Value : TDBObject) : TSQLEvents;
var F : TDBField;
    SKeys : TStringBuilder;
begin
   Result := TSQLEvents.Create;
   SKeys  := TStringBuilder.Create;
   Try
     Value.Alias := 'A';
     For F in Value.Fields Do
        If (ftPrimaryKey in F.FieldTypes) Then
           SKeys.Append( '('+ Value.Alias +'.'+ F.Name +' = '+ SQLFormat(F.TypeInfo,F.Value,F.Size,not (ftNotNull in F.FieldTypes)) +') and ' );

     If (SKeys.Length <> 0) Then
        SKeys.Remove(SKeys.Length - 5,5);

     FWhere := SKeys.ToString;
     Result := Select(Value);
   Finally
     FreeAndNil(SKeys);
   End;
end;

function TEngine.Select(Value : TDBObject) : TSQLEvents;
var SQL : TStringBuilder;
    S   : String;
    K, F, J: TList<String>;
    Alias  : Integer;
    ATable : TDBTable;
begin
   Alias  := 64;
   Result := TSQLEvents.Create;

   SQL := TStringBuilder.Create;
   K   := TList<String>.Create;
   F   := TList<String>.Create;
   J   := TList<String>.Create;
   Try
     ATable := TDBTable(Value);

     Select(Alias,ATable,K,F,J);

     SQL.Clear;
     For S in F Do
        SQL.AppendLine(S +',');

     If (SQL.Length <> 0) Then
        SQL.Remove(SQL.Length - 1 - Length(sLineBreak), 1 + Length(sLineBreak) );

     S := SQL.ToString;

     SQL.Clear;
     SQL.Append(Format(SQLSelect,[S,ATable.Name +' '+ ATable.Alias]));

     //Joins
     For S in J Do
       SQL.AppendLine(S);

     //Order
     If FOrderBy.IsEmpty Then
     Begin
        FOrderBy := '';
        For S in K Do
           FOrderBy := FOrderBy + S +','+ sLineBreak;
        FOrderBy := FOrderBy.Trim.Remove(FOrderBy.Length - 1 - Length(sLineBreak));
     End;

     If (not Where.IsEmpty) Then
        SQL.AppendLine(Format(SQLWhere,[AliasToAlias(ATable,Where)]));

     If (not FGroupBy.IsEmpty) Then
        SQL.AppendLine(Format(SQLOrderBy,[AliasToAlias(ATable,FGroupBy)]));

     If (not FOrderBy.IsEmpty) Then
        SQL.AppendLine(Format(SQLOrderBy,[AliasToAlias(ATable,FOrderBy)]));

     Result.SQL.Add(SQL.ToString);
   Finally
     FreeAndNil(SQL);
     FreeAndNil(K);
     FreeAndNil(F);
     FreeAndNil(J);
   End;
end;

procedure TEngine.Select(var Alias: Integer; Value: TDBObject; Keys, Fields,
  Joins: TList<String>);
var S : TStringBuilder;
    IndexJ : Integer;

    function GetAlias(A : Integer) : String;
    const S = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    begin
        Result := S[(A Mod 26)];
        If (A >= 26) Then
        Begin
           Result := S[(A Div 26)] + S[(A Mod 26) + 1];
           If (Result = 'AS') Then Result := 'A1';
           If (Result = 'AT') Then Result := 'A2';
        End;
    end;

    procedure GetFields(V : TDBObject);
    var F : TDBField;
        C : TDBObject;
    Begin
       For F in V.Fields Do
       Begin
          Try
            If (ftPrimaryKey in F.FieldTypes) Then
               Keys.Add(FSQL.SQLField(V.Alias,F.Name));
            Fields.Add(FSQL.SQLFieldAsAlias(V.Alias,F.Name));
          Except
          End;
       End;

       For C in V.Childs Do
       Begin
          C.Alias := V.Alias;
          GetFields(C);
       End;
    End;

    procedure GetForeign(V : TDBObject);
    var F : TDBField;
        C : TDBObject;
        J : TDBForeign;
        I : Integer;
        R : String;
        FV : TFieldValue;
        FK : TDBTable;
    Begin
       For J in TDBTable(V).Foreign Do
       Begin
          If (J.Load = lLazy) Then
             Continue;

          FK := TDBTable(TAObject.Add(J.AClass,FCache));

          Select(Alias,FK,Keys,Fields,Joins);

          J.Name  := FK.Name;
          J.Alias := FK.Alias;

          If (J.Keys.Count > 0) Then
             For FV in J.Keys Do
                Fields.Add(FSQL.SQLFieldAsAlias(FK.Alias,FV.Name));

          For F in FK.Fields Do
             If (ftPrimaryKey in F.FieldTypes) And (J.Keys.Count = 0) Then
             Begin
                J.Keys.Add(TFieldValue.Create(F.Name.Remove(30),null));
                Break;
             End;

          S.Clear;
          For I := 0 To (J.Keys.Count - 1) Do
             S := S.Append(Format('(%s = %s) and ',[ FSQL.SQLField(FK.Alias,J.Keys[I].Name),
                                                     FSQL.SQLField(Value.Alias,J.SubKeys[I].Name)]) );
          If (S.Length <> 0) Then
             S := S.Remove(S.Length - 5,5);

          R := S.ToString;
          Case J.Join Of
             jLeft  : R := Format(SQLLeftJoin  + ' %s %s on (%s) ',[FK.Name,FK.Alias,S.ToString]);
             jInner : R := Format(SQLInnerJoin + ' %s %s on (%s) ',[FK.Name,FK.Alias,S.ToString]);
             jRight : R := Format(SQLRightJoin + ' %s %s on (%s) ',[FK.Name,FK.Alias,S.ToString]);
          End;
          Joins.Insert(IndexJ,R);

          Inc(IndexJ);
       End;

       For C in V.Childs Do
          GetForeign(C);
    End;

begin
   Inc(Alias);
   IndexJ := Joins.Count;
   If (Value.OType <> otView) Or (Value.Alias.IsEmpty) Then
      Value.Alias := GetAlias(Alias - 64);

   GetFields(Value);

   If not (Value is TDBTable) Then
      Exit;

   S := TStringBuilder.Create;
   Try
     GetForeign(Value);
   Finally
     FreeAndNil(S);
   End;
end;

procedure TEngine.SetValues(ValueTypes: TFieldTypes; ValueObject: TObject;
  DataSet: TDataSet; DBObject: TDBObject; ValueKey : Variant);
var C : TRttiContext;
    Y : TRttiType;
    F : TRttiField;
    P : TRttiProperty;
    T : TFieldType;
    AF : TDBField;
    AJ : TDBForeign;
    I  : TDBObject;
    FindTypes : Boolean;
    O  : TObject;
    FK : String;
    VK, VKJ : Variant;
    S  : TStream;

    procedure SetLazyLoad(Value : TObject; Key : Variant; Field : String);
    var _C : TRttiContext;
        _T : TRttiType;
        _F : TRttiField;
    Begin
       _C := TRttiContext.Create;
       Try
         _T := _C.GetType(Value.ClassType);
         For _F in _T.GetFields Do
            If (_F.Name = 'FLoad') Then
               _F.SetValue(Value,False)
            Else If (_F.Name = 'FField') And (not Field.IsEmpty) Then
               _F.SetValue(Value,'A.' + Field)
            Else If (_F.Name = 'FKey') And not ((Key = Unassigned) Or (Key = Null)) Then
               _F.SetValue(Value,Integer(Key));
       Finally
         _C.Free;
       End;
    End;

    function GetKeyLazyLoad(C : TClass; Value : String) : String;
    var J : TDBForeign;
    Begin
       Result := Value;
       For J in TDBTable(DBObject).Foreign Do
          If (J.AClass = C) And (J.Keys.Count > 0) Then
          Begin
             J.IsColumn := True;
             Exit(J.Keys.First.Name);
          End;
    End;

begin
   VK := ValueKey;
   O  := nil;

   C := TRttiContext.Create;
   Try
     Try
       Y := C.GetType(ValueObject.ClassType);
       For AF in DBObject.Fields Do
       Begin
          FindTypes := ([] = ValueTypes);
          If not FindTypes Then
             For T in ValueTypes Do
                If (T in AF.FieldTypes) Then
                Begin
                   FindTypes := True;
                   Break;
                End;

          If not FindTypes Then
             Continue;

          O := nil;
          If (not AF.FieldName.IsEmpty) Then
          Begin
             F := Y.GetField(AF.FieldName);
             If not Assigned(F) Then
                Continue;

             If (ftPrimaryKey in AF.FieldTypes) Then
             Begin
                VK := AF.Value;
                If (VK = null) Then
                   Exit;
             End;

             {$IFDEF CODESITE}
             CodeSite.Send('SetValues|'+ ValueObject.ClassName +'|Name = '+ DBObject.Name + '|Alias = '+ DBObject.Alias +
                           '|FieldName = '+ AF.FieldName +'|Name = '+ AF.Name +'|Value = '+ VarToStr(AF.Value));
             {$ENDIF}

             Case F.FieldType.TypeKind Of
                tkInt64,
                tkInteger     : F.SetValue(ValueObject,AF.AsInteger);

                tkFloat       : If (F.GetValue(ValueObject).TypeInfo = TypeInfo(TDateTime)) Then
                                   F.SetValue(ValueObject,AF.AsDateTime)
                                Else If (F.GetValue(ValueObject).TypeInfo = TypeInfo(TDate)) Then
                                   F.SetValue(ValueObject,AF.AsDate)
                                Else If (F.GetValue(ValueObject).TypeInfo = TypeInfo(TTime)) Then
                                   F.SetValue(ValueObject,AF.AsTime)
                                Else If (F.GetValue(ValueObject).TypeInfo = TypeInfo(Extended)) Then
                                   F.SetValue(ValueObject,AF.AsExtended)
                                Else
                                   F.SetValue(ValueObject,AF.AsExtended);

                tkEnumeration : If (F.GetValue(ValueObject).TypeInfo = TypeInfo(Boolean)) Then
                                Begin
                                   If (AF.Size = 1) Then
                                      F.SetValue(ValueObject,(AF.AsString = 'S'))
                                   Else
                                      F.SetValue(ValueObject,(AF.AsInteger = 1));
                                End Else
                                   F.SetValue(ValueObject,TValue.FromOrdinal(F.GetValue(ValueObject).TypeInfo,AF.AsInteger));

                tkChar,   tkWChar,
                tkString, tkLString,
                tkWString,
                tkUString     : F.SetValue(ValueObject,AF.AsString);

                tkVariant     : F.SetValue(ValueObject,TValue.FromVariant(AF.Value));

                tkClass       :
                  Begin
                     If (Pos('TLazyLoad',F.FieldType.AsInstance.MetaclassType.ClassName) > 0) Then
                     Begin
                        SetLazyLoad(F.GetValue(ValueObject).AsObject,AF.Value,
                                    GetKeyLazyLoad(F.FieldType.AsInstance.MetaclassType,FK));
                        Continue;
                     End Else If (F.FieldType.AsInstance.MetaclassType.InheritsFrom(TStream)) Then
                     Begin
                        O := F.GetValue(ValueObject).AsObject;
                        If not Assigned(O) Then
                           O := Factory(F.FieldType.AsInstance.MetaclassType);
                        S := TStream(O);
                        S.WriteData(AF.Bytes,High(AF.Bytes));
                        F.SetValue(ValueObject,S);
                        Continue;
                     End Else If ((F.FieldType.IsInstance) And (F.GetValue(ValueObject).IsObject) And (F.GetValue(ValueObject).AsObject <> nil)) Then
                     Begin
                        If Assigned(DBObject.ChildsIndexOf(F.Name)) Then
                           Continue;
                        O := F.GetValue(ValueObject).AsObject;
                     End Else
                     Begin
                        O := Factory(F.FieldType.AsInstance.MetaclassType);
                        F.SetValue(ValueObject,O);
                     End;

                     Case FSQLMode Of
                        dbInsert : Notification(O);
                        dbSelect : Notification(O,DataSet);
                     End;
                  End;
             End;
          End Else If (not AF.PropertyName.IsEmpty) Then
          Begin
             P := Y.GetProperty(AF.PropertyName);
             If not Assigned(P) Then
                Continue;

             If (ftPrimaryKey in AF.FieldTypes) Then
             Begin
                VK := AF.Value;
                If (VK = null) Then
                   Exit;
             End;

             Case P.PropertyType.TypeKind Of
                tkInt64,
                tkInteger     : P.SetValue(ValueObject,AF.AsInteger);

                tkFloat       : If (P.GetValue(ValueObject).TypeInfo = TypeInfo(TDateTime)) Then
                                   P.SetValue(ValueObject,AF.AsDateTime)
                                Else If (P.GetValue(ValueObject).TypeInfo = TypeInfo(TDate)) Then
                                   P.SetValue(ValueObject,AF.AsDate)
                                Else If (P.GetValue(ValueObject).TypeInfo = TypeInfo(TTime)) Then
                                   P.SetValue(ValueObject,AF.AsTime)
                                Else If (P.GetValue(ValueObject).TypeInfo = TypeInfo(Extended)) Then
                                   P.SetValue(ValueObject,AF.AsExtended)
                                Else
                                   P.SetValue(ValueObject,AF.AsExtended);

                tkEnumeration : If (P.GetValue(ValueObject).TypeInfo = TypeInfo(Boolean)) Then
                                Begin
                                   If (AF.Size = 1) Then
                                      P.SetValue(ValueObject,(AF.AsString = 'S'))
                                   Else
                                      P.SetValue(ValueObject,(AF.AsInteger = 1));
                                End Else
                                   P.SetValue(ValueObject,TValue.FromOrdinal(P.GetValue(ValueObject).TypeInfo,AF.AsInteger));

                tkChar,   tkWChar,
                tkString, tkLString,
                tkWString,
                tkUString     : P.SetValue(ValueObject,AF.AsString);

                tkVariant     : P.SetValue(ValueObject,TValue.FromVariant(AF.Value));

                tkClass       :
                  Begin
                     If (Pos('TLazyLoad',P.PropertyType.AsInstance.MetaclassType.ClassName) > 0) Then
                     Begin
                        {FK := '';
                        If (Pos('List<',F.FieldType.AsInstance.MetaclassType.ClassName) > 0) Then
                            FK := AF.Name;}
                        SetLazyLoad(P.GetValue(ValueObject).AsObject,AF.Value,
                                    GetKeyLazyLoad(P.PropertyType.AsInstance.MetaclassType,AF.Name));
                        Continue;
                     End Else If (P.PropertyType.AsInstance.MetaclassType.InheritsFrom(TStream)) Then
                     Begin
                        O := P.GetValue(ValueObject).AsObject;
                        If not Assigned(O) Then
                        Begin
                           O := Factory(P.PropertyType.AsInstance.MetaclassType);
                           F.SetValue(ValueObject,O);
                        End;
                        S := TStream(O);
                        S.WriteData(AF.Bytes,High(AF.Bytes));
                     End Else If ((P.PropertyType.IsInstance) And (P.GetValue(ValueObject).IsObject) And (P.GetValue(ValueObject).AsObject <> nil)) Then
                     Begin
                        If Assigned(DBObject.ChildsIndexOf(P.Name)) Then
                           Continue;
                        O := P.GetValue(ValueObject).AsObject
                     End Else
                     Begin
                        O := Factory(P.PropertyType.AsInstance.MetaclassType);
                        P.SetValue(ValueObject,O);
                     End;

                     Case FSQLMode Of
                        dbInsert : Notification(O);
                        dbSelect : Notification(O,DataSet);
                     End;
                  End;
             End;
          End;
       End;

       For I in DBObject.Childs Do
       Begin
          O := nil;
          {$IFDEF CODESITE}
          CodeSite.Send('Child:'+ I.AClass.ClassName +'|Name: '+ I.Name +'|Alias: '+ I.Alias);
          {$ENDIF}
          Case I.ParentType Of
             TParentType.ptField :
             Begin
                F := Y.GetField(I.Parent);
                If (not Assigned(F)) Or (F.FieldType.TypeKind <> tkClass) Or
                   F.FieldType.AsInstance.MetaclassType.InheritsFrom(TStream) Then
                   Continue;

                O := F.GetValue(ValueObject).AsObject;
             End;
             TParentType.ptUnknow :
             Begin
                P := Y.GetProperty(I.Parent);
                If (not Assigned(P)) Or (P.PropertyType.TypeKind <> tkClass) Or
                   P.PropertyType.AsInstance.MetaclassType.InheritsFrom(TStream) Then
                   Continue;

                O := P.GetValue(ValueObject).AsObject;
             End;
          End;

          If Assigned(O) Then
             SetValues(ValueTypes,O,DataSet,I,VK);
       End;

       If not (DBObject is TDBTable) Then
          Exit;

       For AJ in TDBTable(DBObject).Foreign Do
       Begin
          {$IFDEF CODESITE}
          CodeSite.Send('Foreign:'+ AJ.AClass.ClassName +'|Name: '+AJ.Name+'*'+AJ.Alias +
                         '|Field:'+ AJ.FieldName+'/'+AJ.PropertyName);
          {$ENDIF}
          O   := nil;
          I   := nil;
          FK  := '';
          VKJ := VK;
          If (AJ.Keys.Count > 0) Then
             FK := AJ.Keys.First.Name;

          TAObject.Add(AJ.AClass,FCache,AJ.Alias);

          If (not AJ.FieldName.IsEmpty) Then
          Begin
             F := Y.GetField(AJ.FieldName);
             If (not Assigned(F)) Or (F.FieldType.TypeKind <> tkClass) Then
                Continue;

             If (Pos('TLazyLoad',F.FieldType.AsInstance.MetaclassType.ClassName) > 0) Then
             Begin
                If (AJ.Keys.Count = 0) And (AJ.SubKeys.Count > 0) Then
                Begin
                   //FK  := AJ.SubKeys.First.Name;
                   VKJ := AJ.SubKeys.First.Value;
                End;

                If not AJ.IsColumn Then
                   SetLazyLoad(F.GetValue(ValueObject).AsObject,VKJ,FK);

                If (FSQLMode in [dbSelect,dbRefresh]) Or
                   ((FSQLMode in [dbInsert]) And TLazyLoad<TObject>(F.GetValue(ValueObject).AsObject).IsNull) Then
                   Continue;

                O := TLazyLoad<TObject>(F.GetValue(ValueObject).AsObject).GetObject;

                If (AJ.Modifys = []) Then
                   AJ.Modifys := AJ.Modifys + [mInsert,mUpdate];
             End Else If ((F.FieldType.IsInstance) And (F.GetValue(ValueObject).IsObject) And (F.GetValue(ValueObject).AsObject <> nil)) Then
             Begin
                I := DBObject.ChildsIndexOf(F.Name);
                O := F.GetValue(ValueObject).AsObject;
             End Else
             Begin
                O := Factory(F.FieldType.AsInstance.MetaclassType);
                F.SetValue(ValueObject,O);
             End;

             If (FSQLMode in [dbSelect,dbRefresh]) Or
                (((mInsert in AJ.Modifys) And (FSQLMode = dbInsert)) Or
                 ((mUpdate in AJ.Modifys) And (FSQLMode = dbUpdate)) Or
                 ((mDelete in AJ.Modifys) And (FSQLMode = dbDelete)) ) Then
             Begin
                Case FSQLMode Of
                   dbInsert,
                   dbUpdate,
                   dbDelete : Notification(O,FK);
                   dbSelect : Notification(O,DataSet,I,FK);
                End;
             End;

          End Else If (not AJ.PropertyName.IsEmpty) Then
          Begin
             P := Y.GetProperty(AJ.PropertyName);
             If (not Assigned(P)) Or (P.PropertyType.TypeKind <> tkClass) Then
                Continue;

             If (Pos('TLazyLoad',P.PropertyType.AsInstance.MetaclassType.ClassName) > 0) Then
             Begin
                If (AJ.Keys.Count = 0) And (AJ.SubKeys.Count > 0) Then
                Begin
                   //FK  := AJ.SubKeys.First.Name;
                   VKJ := AJ.SubKeys.First.Value;
                End;

                If not AJ.IsColumn Then
                   SetLazyLoad(P.GetValue(ValueObject).AsObject,VKJ,FK);

                If (FSQLMode in [dbSelect,dbRefresh]) Or
                   ((FSQLMode in [dbInsert]) And TLazyLoad<TObject>(P.GetValue(ValueObject).AsObject).IsNull) Then
                   Continue;

                O := TLazyLoad<TObject>(P.GetValue(ValueObject).AsObject).GetObject;

                If (AJ.Modifys = []) Then
                   AJ.Modifys := AJ.Modifys + [mInsert,mUpdate];
             End Else If ((P.PropertyType.IsInstance) And (P.GetValue(ValueObject).IsObject) And (P.GetValue(ValueObject).AsObject <> nil)) Then
             Begin
                I := DBObject.ChildsIndexOf(F.Name);
                O := P.GetValue(ValueObject).AsObject;
             End Else
             Begin
                O := Factory(P.PropertyType.AsInstance.MetaclassType);
                P.SetValue(ValueObject,O);
             End;

             If (FSQLMode in [dbSelect,dbRefresh]) Or
                (((mInsert in AJ.Modifys) And (FSQLMode = dbInsert)) Or
                 ((mUpdate in AJ.Modifys) And (FSQLMode = dbUpdate)) Or
                 ((mDelete in AJ.Modifys) And (FSQLMode = dbDelete)) ) Then
             Begin
                Case FSQLMode Of
                   dbInsert,
                   dbUpdate,
                   dbDelete : Notification(O,FK);
                   dbSelect : Notification(O,DataSet,I,FK);
                End;
             End;
          End;
       End;
     Finally
       C.Free;
     End;
   Except On E:Exception Do
     raise Exception.Create(ValueObject.ClassName +'|'+ DBObject.AClass.ClassName +'|'+ AF.Name +'\n'+ E.Message);
   End
end;

procedure TEngine.UpdateFields(DS : TDataSet; Value : TDBObject);

    procedure SetValue(FieldName : String; F : TDBField);
    var dsField : TField;
    Begin
       dsField := DS.FindField(FieldName);
       If not Assigned(dsField) Then
          Exit;

       If not dsField.IsBlob Then
          F.Value := dsField.Value
       Else If (dsField.DataType = ftMemo) Then
          F.Value := dsField.Value
       Else
       Begin
          F.SetBytes(nil);
          F.SetBytes(dsField.AsBytes);
       End;
    End;

    procedure SetFields(V : TDBObject);
    var F : TDBField;
        C : TDBObject;
        J : TDBForeign;
        FV : TFieldValue;
        dsField : TField;

        O : TObject;
        L : TObjectList<TObject>;
    Begin
       If not Assigned(V) Then
          Exit;

       For F in V.Fields Do
          If (FSQLMode in [dbSelect,dbRefresh]) Then
             SetValue(FSQL.SQLFieldAlias(V.Alias,F.Name),F)
          Else If (FSQLMode in [dbInsert,dbUpdate,dbExecute]) And
                  ( (ftPrimaryKey in F.FieldTypes) Or (ftAuto in F.FieldTypes) Or
                    (ftReadOnly in F.FieldTypes) Or (ftInsertOnly in F.FieldTypes) Or
                    (ptOutPut in F.ParamTypes) Or (F.FieldTypes = []) ) Then
             SetValue(F.Name,F);

       For C in V.Childs Do
          If (C.OType <> otView) Then
             SetFields(C)
          Else
          Begin
             //Stored Procedure com Select (View) Melhorar implementacao
             O := orm.objects.utils.GetField(C.Parent,FObject).AsObject;
             L := TObjectList<TObject>(O);
             While (not DS.Eof) Do
             Begin
                L.Add(Factory(C.AClass));
                SetFields(C);
                SetValues([],L.Last,DS,C,null);
                DS.Next;
             End;
          End;

       If (not (V is TDBTable)) Or (not (FSQLMode in [dbInsert,dbSelect,dbRefresh])) Then
          Exit;

       For J in TDBTable(V).Foreign Do
       Begin
          For FV in J.Keys Do
          Begin
             dsField := DS.FindField(FSQL.SQLFieldAlias(V.Alias,FV.Name));
             If Assigned(dsField) Then
                FV.Value := dsField.Value;
          End;

          For FV in J.SubKeys Do
          Begin
             dsField := DS.FindField(FSQL.SQLFieldAlias(V.Alias,FV.Name));
             If Assigned(dsField) Then
                FV.Value := dsField.Value;
          End;
       End;
    End;

begin
   SetFields(Value);
end;

function TEngine.AliasToAlias(Alias : TAlias; Value: String): String;
var AJ : TDBForeign;
begin
   Result := Value;
   Result := StringReplace(Result,Alias.Name +'.',Alias.Alias +'.',[rfReplaceAll]);

   If (Alias is TDBTable) Then
     For AJ in TDBTable(Alias).Foreign Do
        Result := StringReplace(Result,AJ.Name +'.',AJ.Alias +'.',[rfReplaceAll]);
end;

procedure TEngine.SetValues(ValueTypes : TFieldTypes; ValueObject : TObject; DataSet : TDataSet);
var DBObject : TDBObject;
     dsField : TField;
Begin
   DBObject := TAObject.Add(ValueObject.ClassType,FCache);
   If not Assigned(DBObject) Then
      Exit;

   dsField  := DataSet.FindField(FSQL.SQLFieldAlias(DBObject.Alias,'ID'));
   If Assigned(dsField) And (dsField.AsInteger > 0) And
      FCacheData.Cache(dsField.AsString,ValueObject) Then
      Exit;

   UpdateFields(DataSet,DBObject);
   SetValues(ValueTypes,ValueObject,DataSet,DBObject,null);
end;

function TEngine.Update(Value : TDBObject) : TSQLEvents;
var S : TStrings;
    SKeys, SFields, SFieldsAuto : TStringBuilder;

    procedure GetFields(V : TDBObject);
    var F : TDBField;
        C : TDBObject;
    Begin
       For F in V.Fields Do
          If (ftInsertOnly in F.FieldTypes) Then
             Continue
          Else If (ftPrimaryKey in F.FieldTypes) And (not F.Value <> Null) Then
          Begin
             SKeys.Append('('+ F.Name +' = '+ SQLFormat(F.TypeInfo,F.Value,F.Size,not (ftNotNull in F.FieldTypes)) +') and ');
             SFieldsAuto.Append(F.Name + ' , ')
          End Else If ((ftAuto in F.FieldTypes) Or (ftReadOnly in F.FieldTypes)) Then
          Begin
             SFieldsAuto.Append(F.Name + ' , ');
             If (not (ftReadOnly in F.FieldTypes)) Then
                SFields.Append(F.Name +' = '+ SQLFormat(F.TypeInfo,F.Value,F.Size,not (ftNotNull in F.FieldTypes)) +' , ');
          End Else If F.IsBytes Then
          Begin
             SFields.Append(F.Name + ' = :'+ F.Name +' , ');
             Result.Blobs.Add(F.Bytes);
          End Else
             SFields.Append(F.Name +' = '+ SQLFormat(F.TypeInfo,F.Value,F.Size,not (ftNotNull in F.FieldTypes)) +' , ');

       For C in V.Childs Do
          GetFields(C);
    End;

begin
   Result := TSQLEvents.Create;

   SKeys       := TStringBuilder.Create;
   SFields     := TStringBuilder.Create;
   SFieldsAuto := TStringBuilder.Create;
   Try
     GetFields(Value);

     If (SKeys.Length <> 0) Then
        SKeys.Remove(SKeys.Length - 5,5);

     If (SFields.Length <> 0) Then
        SFields.Remove(SFields.Length - 3,3);

     If (SFieldsAuto.Length <> 0) Then
        SFieldsAuto.Remove(SFieldsAuto.Length - 3,3);

     S := FSQL.SQLUpdate(Value.Name,SFields.ToString,SKeys.ToString,SFieldsAuto.ToString);
     Try
       Result.SQL.AddStrings(S);
     Finally
       FreeAndNil(S);
     End;
   Finally
     FreeAndNil(SKeys);
     FreeAndNil(SFields);
     FreeAndNil(SFieldsAuto);
   End;
end;

end.




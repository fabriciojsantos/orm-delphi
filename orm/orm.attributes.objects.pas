unit orm.attributes.objects;

interface

uses System.SysUtils, System.Classes, System.Rtti, System.TypInfo,
     System.Variants, System.Generics.Collections, System.Generics.Defaults,
     Data.DB,
     orm.attributes.types;

type
   TFieldValue = Class
   Private
     FName  : String;
     FValue : Variant;
   Public
     Constructor Create(ValueName : String; ValueValue : Variant);

     property Name  : String  Read FName  Write FName;
     property Value : Variant Read FValue Write FValue;
   End;

   TAlias = class
   Private
     FName   : String;
     FAlias  : String;
     FAClass : TClass;
     FOType  : TObjectType;
     procedure SetAlias(Value : String);
   Protected
     Constructor Created; Overload; Virtual;
     Constructor Create(ValueOType : TObjectType; ValueName, ValueALias : String; ValueClass : TClass); Overload;
   Public
     property OType   : TObjectType Read FOType;
     property Name    : String      Read FName    Write FName;
     property Alias   : String      Read FAlias   Write SetAlias;
     property AClass  : TClass      Read FAClass  Write FAClass;
   end;

   TDBField = Class(TAlias)
   Private
     FTypeInfo       : PTypeInfo;
     FProperty       : String;
     FField          : String;
     FValue          : Variant;
     FDefault        : Variant;
     FSize           : Integer;
     FFieldTypes     : TFieldTypes;
     FParamTypes     : TParamTypes;
     FBytes          : TBytes;
   Public
     Constructor Create(ValueName, ValueAlias : String; ValueSize : Integer;
                        ValueDefault : Variant; ValueField, ValueProperty : String;
                        FTypes : TFieldTypes; PTypes : TParamTypes);

     property TypeInfo           : PTypeInfo   Read FTypeInfo        Write FTypeInfo;
     property PropertyName       : String      Read FProperty        Write FProperty;
     property FieldName          : String      Read FField           Write FField;
     property Value              : Variant     Read FValue           Write FValue;
     property Default            : Variant     Read FDefault         Write FDefault;
     property Size               : Integer     Read FSize            Write FSize;
     property FieldTypes         : TFieldTypes Read FFieldTypes      Write FFieldTypes;
     property ParamTypes         : TParamTypes Read FParamTypes      Write FParamTypes;
     property Bytes              : TBytes      Read FBytes;

     procedure SetStream(Value : TStream);
     procedure SetBytes(Value : TBytes);

     function AsInteger  : Int64;
     function AsString   : String;
     function AsExtended : Extended;
     function AsDateTime : TDateTime;
     function AsDate     : TDate;
     function AsTime     : TTime;
     function IsBytes    : Boolean;
   End;

   TDBForeign = Class(TAlias)
   Private
     FIsColumn: Boolean;
     FProperty: String;
     FField   : String;
     FJoin    : TJoin;
     FLoad    : TLoad;
     FModifys : TModifys;
     FKeys    : TObjectList<TFieldValue>;
     FSubKeys : TObjectList<TFieldValue>;
   Public
     Constructor Create(ValueField, ValueProperty : String; ValueJoin : TJoin; ValueLoad : TLoad; ValueModifys : TModifys; ValueKeys, ValueSubKeys : TList<String>; ValueClass : TClass);
     Destructor  Destroy; Override;

     property IsColumn     : Boolean           Read FIsColumn  Write FIsColumn;
     property PropertyName : String            Read FProperty  Write FProperty;
     property FieldName    : String            Read FField     Write FField;
     property Join         : TJoin             Read FJoin      Write FJoin;
     property Load         : TLoad             Read FLoad      Write FLoad;
     property Modifys      : TModifys          Read FModifys   Write FModifys;
     property Keys         : TObjectList<TFieldValue> Read FKeys;
     property SubKeys      : TObjectList<TFieldValue> Read FSubKeys;
   End;

   TDBObject = Class(TAlias)
   Private
     FParent     : String;
     FParentType : TParentType;

     FFields     : TObjectList<TDBField>;
     FChilds     : TObjectList<TDBObject>;
   Protected
     Constructor Created; Override;
   Public
     Destructor  Destroy; Override;

     property Parent     : String                 Read FParent;
     property ParentType : TParentType            Read FParentType;
     property Fields     : TObjectList<TDBField>  Read FFields;
     property Childs     : TObjectList<TDBObject> Read FChilds;

     function FieldIndexOf(Name : String) : Integer;
     function ChildsIndexOf(FieldParent : String) : TDBObject;
   End;

   TDBTable = Class(TDBObject)
   Private
     FForeign   : TObjectList<TDBForeign>;
   Public
     Constructor Create(ValueName, ValueAlias : String; ValueClass : TClass; ValueParent : String; ValueParentType : TParentType); Overload;
     Destructor  Destroy; Override;

     property Foreign : TObjectList<TDBForeign> Read FForeign;
   End;

   TDBView = Class(TDBObject)
   Private
     FChilds : TObjectList<TDBObject>;
   Public
     Constructor Create(ValueName, ValueAlias : String; ValueClass : TClass; ValueParent : String; ValueParentType : TParentType); Overload;
     Destructor Destroy; Override;

     property Childs  : TObjectList<TDBObject>  Read FChilds;
   End;

   TDBStoredProcedure = Class(TDBObject)
   Public
     Constructor Create(ValueName : String; ValueClass : TClass); Overload;
   End;

   TDBFunction = Class(TDBObject)
   Public
     Constructor Create(ValueName : String; ValueClass : TClass); Overload;
   End;

   TCache = Class(TDictionary<TClass,TDBObject>)
   Private
      procedure ValueNotify(Sender: TObject; const Item: TDBObject; Action: TCollectionNotification);
   Public
      Constructor Create;
   End;

   TCacheData = Class(TDictionary<String,TObject>)
   Public
      function Cache(Key : String; Value : TObject) : Boolean;
   End;

   TAObject = Class
   Private
     FAClass  : TClass;
     FObject  : TObject;
     FCache   : TCache;

     procedure GetAttributes(Value : TClass); Overload;
     procedure GetAttributes(ValueClass : TClass; Value : TDBObject); Overload;

     procedure SetObject(Value : TObject);
     procedure SetClassT(Value : TClass);
   Public
     Constructor Create(O : TObject; Cache : TCache); Overload;
     Constructor Create(C : TClass; Cache : TCache); Overload;
     Destructor  Destroy; Override;

     property AClass   : TClass    Read FAClass   Write SetClassT;
     property Value    : TObject   Read FObject   Write SetObject;

     Class function Add(C : TClass; Cache : TCache; Alias : String = '') : TDBObject; Overload;

     Class function IsKeyEmpty(Value : TObject; Cache : TCache) : Boolean;

     Class function GetKey(Value : TObject; var FieldKey : String; Cache : TCache) : Variant; Overload;
     Class function GetKey(Value : TObject; Cache : TCache) : Variant; Overload;
   End;

implementation

uses orm.attributes, orm.objects.utils;

{ TAForeign }

constructor TDBForeign.Create(ValueField, ValueProperty : String; ValueJoin : TJoin; ValueLoad : TLoad; ValueModifys : TModifys; ValueKeys, ValueSubKeys : TList<String>; ValueClass : TClass);
var S : String;
begin
   inherited Create(otForeign,'','',ValueClass);

   FIsColumn := False;
   FField    := ValueField;
   FProperty := ValueProperty;
   FJoin     := ValueJoin;
   FLoad     := ValueLoad;
   FModifys  := ValueModifys;
   FKeys     := TObjectList<TFieldValue>.Create;
   FSubKeys  := TObjectList<TFieldValue>.Create;
   For S in ValueKeys Do
      If not S.IsEmpty Then
         FKeys.Add(TFieldValue.Create(S,null));

   For S in ValueSubKeys Do
     If not S.IsEmpty Then
        FSubKeys.Add(TFieldValue.Create(S,null));
end;

destructor TDBForeign.Destroy;
begin
   FreeAndNil(FKeys);
   FreeAndNil(FSubKeys);
   inherited;
end;

{ TATable }

function TDBObject.ChildsIndexOf(FieldParent: String): TDBObject;
var C : TDBObject;
begin
   Result := nil;
   If (FChilds.Count = 0) Then
       Exit;

   For C in FChilds Do
      If (C.Parent = FieldParent) Then
         Result := C;
end;

constructor TDBObject.Created;
begin
   inherited;
   FFields := TObjectList<TDBField>.Create;
   FChilds := TObjectList<TDBObject>.Create;
end;

destructor TDBObject.Destroy;
begin
   FreeAndNil(FFields);
   FreeAndNil(FChilds);
   inherited;
end;

function TDBObject.FieldIndexOf(Name: String): Integer;
var I : Integer;
begin
   Result := -1;
   For I := 0 To (Fields.Count - 1) Do
      If (CompareStr(Fields[I].Name,Name) = 0) Then
         Exit(I);
end;

{ TATable }

constructor TDBTable.Create(ValueName, ValueAlias : String; ValueClass : TClass; ValueParent : String; ValueParentType : TParentType);
begin
   inherited Create(otTable,ValueName,ValueAlias,ValueClass);
   FForeign    := TObjectList<TDBForeign>.Create;
   FParent     := ValueParent;
   FParentType := ValueParentType;
end;

destructor TDBTable.Destroy;
begin
   FreeAndNil(FForeign);
   inherited;
end;

{ TAObject }

Class function TAObject.Add(C : TClass; Cache : TCache; Alias : String) : TDBObject;
var A : TAObject;
begin
   Result := nil;

   C := GetClass(C);
   Try
     If Assigned(Cache) And Cache.ContainsKey(C) Then
        Exit(Cache[C]);

     A := TAObject.Create(C,Cache);
     Try
     Finally
       FreeAndNil(A);
     End;

     If Assigned(Cache) And Cache.ContainsKey(C) Then
        Exit(Cache[C]);
   Finally
     If Assigned(Result) And (not Alias.IsEmpty) Then
        Result.Alias := Alias;
   End;
end;

constructor TAObject.Create(C: TClass; Cache : TCache);
begin
   FCache := Cache;
   AClass := C;
end;

destructor TAObject.Destroy;
begin
   inherited;
end;

constructor TAObject.Create(O : TObject; Cache : TCache);
begin
   FCache := Cache;
   Value  := O;
end;

procedure TAObject.GetAttributes(Value : TClass);
var C  : TRttiContext;
    Y  : TRttiType;
    A  : TCustomAttribute;
    DB : TDBObject;
    Index : Integer;
begin
   If Assigned(FCache) And FCache.ContainsKey(Value) Then
      Exit;

   DB := nil;
   C  := TRttiContext.Create;
   Try
     Y := C.GetType(Value);

     For A in Y.GetAttributes Do
        If (A is Table) Then
           DB := TDBTable.Create(Table(A).Name,Table(A).Alias,AClass,'',ptUnknow)
        Else If (A is View) Then
           DB := TDBView.Create(View(A).Name,View(A).Alias,AClass,'',ptUnknow)
        Else If (A is StoredProcedure) Then
           DB := TDBStoredProcedure.Create(StoredProcedure(A).Name,AClass)
        Else If (A is FunctionDB) Then
           DB := TDBFunction.Create(FunctionDB(A).Name,AClass);

     If not Assigned(DB) Then
        Exit;

     DB.AClass := AClass;
     If Assigned(FCache) Then
        FCache.Add(AClass,DB);

     GetAttributes(AClass,DB);
   Finally
     C.Free;
   End;
end;

procedure TAObject.GetAttributes(ValueClass : TClass; Value : TDBObject);
var C : TRttiContext;
    Y : TRttiType;
    A : TCustomAttribute;
    F : TRttiField;
    P : TRttiProperty;
    K : TList<String>;
    AC : TClass;
    S : String;

    Child : TDBObject;

    procedure K_KeyFields;
    var AF : TDBField;
    begin
       K.Clear;
       For AF in Value.Fields Do
          If (ftPrimaryKey in AF.FFieldTypes) Then
             K.Add(AF.Name);
    end;

begin
   If not Assigned(Value) Then
      Exit;

   Child := nil;
   AC    := nil;
   K     := TList<String>.Create;
   C     := TRttiContext.Create;
   Try
     Y := C.GetType(ValueClass);
     For F in Y.GetFields Do
     Begin
        K.Clear;
        For A in F.GetAttributes Do
        Begin
           If (A is Column) Then
           Begin
              K.Add(Column(A).Name);
              Value.Fields.Add(TDBField.Create(Column(A).Name,
                                               Column(A).Alias,
                                               Column(A).Size,
                                               Column(A).Default,
                                               F.Name,'',
                                               Column(A).FieldType,
                                               Column(A).ParamType));
           End;

           If (A is Table) Or (A is View) Then
           Begin
              If (F.FieldType.IsRecord) Then
                 AC := GetClass(F.FieldType.AsRecord.Name)
              Else If (F.FieldType.IsInstance) Then
                 AC := F.FieldType.AsInstance.MetaclassType;
              AC := GetClass(AC);

              If (A is Table) Then
                 Child := TDBTable.Create(Value.Name,Value.Alias,AC,F.Name,ptField)
              Else If (A is View) Then
                 Child := TDBView.Create(Value.Name,Value.Alias,AC,F.Name,ptField);

              GetAttributes(AC,Child);
              TDBObject(Value).Childs.Add(Child);
           End;

           If (A is Foreign) Then
           Begin
              If (K.Count = 0) Then
                 K_KeyFields;

              If (F.FieldType.IsRecord) Then
                 AC := GetClass(F.FieldType.AsRecord.Name)
              Else If (F.FieldType.IsInstance) Then
                 AC := F.FieldType.AsInstance.MetaclassType;

              TDBTable(Value).Foreign.Add(TDBForeign.Create(F.Name,'',
                                                            Foreign(A).Join,
                                                            Foreign(A).Load,
                                                            Foreign(A).Modifys,
                                                            Foreign(A).Keys,
                                                            K,
                                                            AC));

              {If (Pos('TList',AC.ClassName) = 0) Then
              Begin
                 S := '';
                 If (K.Count > 0) Then
                    S := K.First
                 Else If (Foreign(A).Keys.Count > 0) Then
                    S := Foreign(A).Keys.First;

                 If (Value.FieldIndexOf(S) = -1) Then
                    Value.Fields.Add(TDBField.Create(S,'',0,0,F.Name,'',[],[]));
              End;}

              TDBTable(Value).Foreign.TrimExcess;

              If (F.FieldType.TypeKind = tkClass) Then
                 TAObject.Add(F.FieldType.AsInstance.MetaclassType,FCache);
           End;
        End;
     End;

     For P in Y.GetProperties Do
     Begin
        K.Clear;
        For A in P.GetAttributes Do
        Begin
           If (A is Column) Then
           Begin
              K.Add(Column(A).Name);
              Value.Fields.Add(TDBField.Create(Column(A).Name,
                                               Column(A).Alias,
                                               Column(A).Size,
                                               Column(A).Default,
                                               '',P.Name,
                                               Column(A).FieldType,
                                               Column(A).ParamType));
           End;

           If (A is Table) Or (A is View) Then
           Begin
              If (P.PropertyType.IsRecord) Then
                 AC := GetClass(P.PropertyType.AsRecord.Name)
              Else If (P.PropertyType.IsInstance) Then
                 AC := P.PropertyType.AsInstance.MetaclassType;

              If (A is Table) Then
                 Child := TDBTable.Create(Value.Name,Value.Alias,AC,P.Name,ptProperty)
              Else If (A is View) Then
                 Child := TDBView.Create(Value.Name,Value.Alias,AC,P.Name,ptProperty);

              GetAttributes(AC,Child);
              TDBObject(Value).Childs.Add(Child);
           End;

           If (A is Foreign) Then
           Begin
              If (K.Count = 0) Then
                 K_KeyFields;

              If (F.FieldType.IsRecord) Then
                 AC := GetClass(F.FieldType.AsRecord.Name)
              Else If (F.FieldType.IsInstance) Then
                 AC := F.FieldType.AsInstance.MetaclassType;

              TDBTable(Value).Foreign.Add(TDBForeign.Create('',P.Name,
                                                           Foreign(A).Join,
                                                           Foreign(A).Load,
                                                           Foreign(A).Modifys,
                                                           Foreign(A).Keys,
                                                           K,
                                                           AClass));

              {If (Pos('TList',AC.ClassName) = 0) Then
              Begin
                 S := '';
                 If (K.Count > 0) Then
                    S := K.First
                 Else If (Foreign(A).Keys.Count > 0) Then
                    S := Foreign(A).Keys.First;

                 If (Value.FieldIndexOf(S) = -1) Then
                    Value.Fields.Add(TDBField.Create(S,'',0,0,'',P.Name,[],[]));
              End;}


              TDBTable(Value).Foreign.TrimExcess;

              If (P.PropertyType.TypeKind = tkClass) Then
                 TAObject.Add(P.PropertyType.AsInstance.MetaclassType,FCache);
           End;
        End;
     End;
   Finally
     Value.Fields.TrimExcess;
     FreeAndNil(K);
     C.Free;
   End;
end;

class function TAObject.GetKey(Value: TObject; var FieldKey: String; Cache : TCache): Variant;
var C : TRttiContext;
    Y : TRttiType;
    F : TRttiField;
    P : TRttiProperty;
    AF : TDBField;
    DBObject : TDBObject;
    ATable   : TDBTable;
begin
   Result := null;
   If not Assigned(Value) Then
      Exit;

   DBObject := TAObject.Add(Value.ClassType,Cache);
   If not Assigned(DBObject) Then
      Exit;

   C := TRttiContext.Create;
   Try
     Y := C.GetType(DBObject.AClass);
     For AF in DBObject.Fields Do
     Begin
        If not (ftPrimaryKey in AF.FieldTypes) Then
           Continue;

        ATable   := TDBTable(DBObject);
        FieldKey := Format('%s_%s',[ATable.Alias,AF.Name]).Remove(30);
        If (AF.FieldName <> '') Then
        Begin
           F := Y.GetField(AF.FieldName);
           If Assigned(F) Then
              Result := F.GetValue(Value).AsVariant;
        End Else If (AF.PropertyName <> '') Then
        Begin
           P := Y.GetProperty(AF.PropertyName);
           If Assigned(P) Then
              Result := P.GetValue(Value).AsVariant;
        End;

        Break;
     End;
   Finally
     C.Free;
   End;
end;

class function TAObject.GetKey(Value: TObject; Cache : TCache): Variant;
var F : String;
begin
   Result := GetKey(Value,F,Cache);
end;

class function TAObject.IsKeyEmpty(Value: TObject; Cache : TCache): Boolean;
begin
   Result := (GetKey(Value,Cache) = 0);
end;

procedure TAObject.SetClassT(Value: TClass);
begin
   FAClass := Value;
   GetAttributes(Value);
end;

procedure TAObject.SetObject(Value: TObject);
begin
   FAClass := Value.ClassType;
   FObject := Value;
end;

{ TAStoredProcedure }

constructor TDBStoredProcedure.Create(ValueName : String; ValueClass : TClass);
begin
   inherited Create(otStoredProc,ValueName,'',ValueClass);
end;

{ TAFunctionDB }

constructor TDBFunction.Create(ValueName : String; ValueClass : TClass);
begin
   inherited Create(otFunction,ValueName,'',ValueClass);
end;

{ TAView }

constructor TDBView.Create(ValueName, ValueAlias : String; ValueClass : TClass; ValueParent : String; ValueParentType : TParentType);
begin
   inherited Create(otView,ValueName,ValueAlias,ValueClass);
   FChilds     := TObjectList<TDBObject>.Create;
   FParent     := ValueParent;
   FParentType := ValueParentType;
end;

{ TAField }

function TDBField.AsDate: TDate;
begin
   Result := 0;
   If (Value <> null) Then
      Result := Value;
end;

function TDBField.AsDateTime: TDateTime;
begin
   Result := 0;
   If (Value <> null) Then
      Result := Value;
end;

function TDBField.AsExtended: Extended;
begin
   Result := 0;
   If (Value <> null) Then
      Result := Value;
end;

function TDBField.AsInteger: Int64;
begin
   Result := 0;
   If (Value <> null) Then
      Result := Value;
end;

function TDBField.AsString: String;
begin
   Result := '';
   If (Value <> null) Then
      Result := Value;
end;

function TDBField.AsTime: TTime;
begin
   Result := 0;
   If (Value <> null) Then
      Result := Value;
end;

{ TAlias }

constructor TAlias.Create(ValueOType: TObjectType; ValueName, ValueALias: String;
  ValueClass: TClass);
begin
   Created;
   FOType  := ValueOType;
   FName   := ValueName;
   FAlias  := ValueAlias;
   FAClass := ValueClass;
end;

constructor TAlias.Created;
begin
   Inherited Create;
end;

procedure TAlias.SetAlias(Value: String);
begin
   FAlias := Value;
   If (FAlias = '') Then
      FAlias := Name;
end;

{ TAField }

constructor TDBField.Create(ValueName, ValueAlias: String; ValueSize: Integer;
  ValueDefault: Variant; ValueField, ValueProperty : String; FTypes : TFieldTypes; PTypes : TParamTypes);
begin
   If (ptNone in PTypes) Or (PTypes = []) Then
      inherited Create(otField,ValueName,ValueAlias,nil)
   Else
      inherited Create(otParam,ValueName,ValueAlias,nil);
   FSize       := ValueSize;
   FDefault    := ValueDefault;
   FField      := ValueField;
   FProperty   := ValueProperty;
   FFieldTypes := FTypes;
   FParamTypes := PTypes;
end;

function TDBField.IsBytes: Boolean;
begin
   Result := (High(FBytes) <> -1);
end;

procedure TDBField.SetBytes(Value: TBytes);
begin
   SetLength(FBytes,0);
   If Assigned(Value) Then
      FBytes := Value;
end;

procedure TDBField.SetStream(Value: TStream);
var C : Integer;
begin
   If Assigned(Value) Then
   Begin
      C := Value.Size;
      Value.Position := 0;
      SetLength(FBytes, C);
      Value.ReadBuffer(Pointer(FBytes)^, C);
   End;
end;

{ TCache }

constructor TCache.Create;
begin
   inherited Create;
   OnValueNotify := ValueNotify;
end;

procedure TCache.ValueNotify(Sender: TObject; const Item: TDBObject;
  Action: TCollectionNotification);
//var V : TDBObject;
begin
   If (Action = TCollectionNotification.cnRemoved) And Assigned(Item) Then
      Item.DisposeOf;
   {   V := Item;
      FreeAndNil(V);
   End;}
end;

destructor TDBView.Destroy;
begin
   FreeAndNil(FChilds);
   inherited;
end;

{ TKey }

constructor TFieldValue.Create(ValueName: String; ValueValue: Variant);
begin
   FName  := ValueName;
   FValue := ValueValue;
end;

{ TCacheData }

function TCacheData.Cache(Key: String; Value: TObject): Boolean;
var K : String;
begin
   K := Value.ClassName +'/'+ Key;
   Result := ContainsKey(K);
   If not Result Then
   Begin
      Add(K,Value);
      Exit;
   End;

   orm.objects.utils.Copy(Items[K],Value);
end;

end.

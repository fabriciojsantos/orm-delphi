unit orm.attributes;

interface

uses System.SysUtils, System.Generics.Collections,
     //orm.Generics.Collections,
     orm.attributes.types;

type
  TObjectDB = Class Of ObjectDB;

  ObjectDB = Class(TCustomAttribute)
  Private
    FName  : String;
    FAlias : String;
  Public
    property Name : String Read FName Write FName;
    property Alias : String Read FAlias Write FAlias;

    constructor Create(Value : String); Overload;
    constructor Create(ValueName : String; ValueAlias : String); Overload;
  End;

  Table = Class(ObjectDB);

  StoredProcedure = Class(ObjectDB);

  FunctionDB = Class(ObjectDB);

  View = Class(ObjectDB);

  //Field = Class(ObjectDB);// nao pode ser utilizado o nome Field entao ficou Column
  Column = Class(ObjectDB)
  Private
    FSize      : Integer;
    FDefault   : Variant;
    FFieldType : TFieldTypes;
    FParamType : TParamTypes;
  Public
    property Size      : Integer     Read FSize;
    property Default   : Variant     Read FDefault;
    property FieldType : TFieldTypes Read FFieldType;
    property ParamType : TParamTypes Read FParamType;

    constructor Create(FieldName : String; FieldSize : Integer); Overload;
    constructor Create(FieldName : String; FieldSize : Integer; FieldTypes : TFieldTypes); Overload;
    constructor Create(FieldName : String; FieldTypes : TFieldTypes); Overload;
    constructor Create(FieldName : String; FieldSize : Integer; ParamTypes : TParamTypes; FieldTypes : TFieldTypes); Overload;
    constructor Create(FieldName : String; ParamTypes : TParamTypes; FieldTypes : TFieldTypes); Overload;
  End;

  Foreign = Class(TCustomAttribute)
  Private
    FJoin    : TJoin;
    FLoad    : TLoad;
    FKeys    : TList<String>;
    FModifys : TModifys;
  Public
    property Join    : TJoin         Read FJoin    Write FJoin;
    property Load    : TLoad         Read FLoad    Write FLoad;
    property Keys    : TList<String> Read FKeys    Write FKeys;
    property Modifys : TModifys      Read FModifys Write FModifys;

    constructor Create(ForeignKeys : String; ForeignModifys : TModifys = []; ForeignValue : TJoin = jLeft; ForeignLoad : TLoad = lEazy); Overload;
    constructor Create(ForeignModifys : TModifys = []; ForeignValue : TJoin = jLeft; ForeignLoad : TLoad = lEazy); Overload;
    constructor Create(ForeignLoad : TLoad; ForeignKeys : String = ''; ForeignModifys : TModifys = []); Overload;
    constructor Create(ForeignLoad : TLoad; ForeignModifys : TModifys); Overload;

    destructor  Destroy; Override;
  End;

implementation

{ ObjectDB }

constructor ObjectDB.Create(Value : String);
begin
   FName := Value;
end;

constructor ObjectDB.Create(ValueName, ValueAlias : String);
begin
   Name  := ValueName;
   Alias := ValueAlias;
   If (Alias = '') Then
      Alias := Name;
end;

{ Column }

constructor Column.Create(FieldName: String; FieldSize: Integer);
begin
   inherited Create(FieldName);
   FSize := FieldSize;
end;

constructor Column.Create(FieldName: String; FieldTypes: TFieldTypes);
begin
   inherited Create(FieldName);
   FFieldType := FieldTypes;
end;

constructor Column.Create(FieldName: String; FieldSize: Integer;
  FieldTypes : TFieldTypes);
begin
   inherited Create(FieldName);
   FSize      := FieldSize;
   FFieldType := FieldTypes;
end;

constructor Column.Create(FieldName: String; ParamTypes: TParamTypes;
  FieldTypes: TFieldTypes);
begin
   inherited Create(FieldName);
   FParamType := ParamTypes;
   FFieldType := FieldTypes;
end;

constructor Column.Create(FieldName: String; FieldSize: Integer;
  ParamTypes : TParamTypes; FieldTypes: TFieldTypes);
begin
   inherited Create(FieldName);
   FSize      := FieldSize;
   FParamType := ParamTypes;
   FFieldType := FieldTypes;
end;

{ Foreign }

constructor Foreign.Create(ForeignKeys : String; ForeignModifys: TModifys; ForeignValue : TJoin; ForeignLoad : TLoad);
begin
   FJoin    := ForeignValue;
   FLoad    := ForeignLoad;
   FModifys := ForeignModifys;
   FKeys    := TList<String>.Create;
   FKeys.AddRange(ForeignKeys.Split([';']));
end;

constructor Foreign.Create(ForeignModifys: TModifys; ForeignValue: TJoin;
  ForeignLoad: TLoad);
begin
   FJoin    := ForeignValue;
   FLoad    := ForeignLoad;
   FModifys := ForeignModifys;
   FKeys    := TList<String>.Create;
end;

constructor Foreign.Create(ForeignLoad: TLoad; ForeignKeys: String; ForeignModifys: TModifys);
begin
   FJoin    := jLeft;
   FLoad    := ForeignLoad;
   FModifys := ForeignModifys;
   FKeys    := TList<String>.Create;
   FKeys.AddRange(ForeignKeys.Split([';']));
end;

constructor Foreign.Create(ForeignLoad: TLoad; ForeignModifys: TModifys);
begin
   FJoin    := jLeft;
   FLoad    := ForeignLoad;
   FModifys := ForeignModifys;
   FKeys    := TList<String>.Create;
end;

destructor Foreign.Destroy;
begin
   FreeAndNil(FKeys);
   inherited;
end;

end.

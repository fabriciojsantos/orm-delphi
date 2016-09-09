unit orm.lazyload;

interface

uses System.SysUtils, System.Variants, System.Generics.Collections,
     System.Rtti, System.TypInfo;

type
   TLazyLoad<T : Class> = Class
   private
     FLoad     : Boolean;
     FKey      : Variant;
     FWhere    : String;
     FOrder    : String;
     FIsNull   : Boolean;

     FValue    : T;
     FValueAll : TObjectList<T>;

     function  GetIsNull : Boolean;
     procedure SetWhere(Value : String);
     procedure SetKey(Value : Variant);
   protected
     FField    : String;
   public
     Destructor Destroy; Override;

     function Value : T;
     function ValueAll : TObjectList<T>;
     function GetObject : TObject;

     property Field  : String  Read FField;
     property Key    : Variant Read FKey      Write SetKey;
     property Where  : String  Read FWhere    Write SetWhere;
     property Order  : String  Read FOrder    Write FOrder;
     property IsNull : Boolean Read GetIsNull Write FIsNull;
   end;

implementation

uses orm.Attributes.Objects, orm.Objects.Utils, orm.Session, orm.Where, sql.utils;

{ TLazyLoad<T> }

destructor TLazyLoad<T>.Destroy;
begin
   If Assigned(FValue) Then
      FreeAndNil(FValue);

   If Assigned(FValueAll) Then
   Begin
      FValueAll.OnNotify := nil;
      FreeAndNil(FValueAll);
   End;

   inherited;
end;

function TLazyLoad<T>.GetObject: TObject;
begin
   Result := FValue;
   If not Assigned(Result) Then
      Result := FValueAll;
end;

procedure TLazyLoad<T>.SetKey(Value: Variant);
begin
   If (Key <> Value) Then
      FLoad := False;
   FKey := Value;
end;

procedure TLazyLoad<T>.SetWhere(Value: String);
begin
   If (Value <> FWhere) Then
      FLoad := False;
   FWhere := Value;
end;

function TLazyLoad<T>.GetIsNull: Boolean;
begin
   Result := FIsNull;
   If not FIsNull Then
      Result := (not Assigned(FValueAll)) And (not Assigned(FValue));
end;

function TLazyLoad<T>.Value : T;
var V : T;
    C : TClass;
begin
   If FIsNull Then
      Exit(nil)
   Else If FLoad And Assigned(FValue) Then
      Exit(FValue);

   C := T;
   V := nil;
   Try

     If not FWhere.IsEmpty Then
     Begin
        If (not Field.IsEmpty) And (not ((FKey = Unassigned) Or (FKey = Null))) Then
           V := Session.Find<T>( orm.where.Where.Add(Field +' = '+ sql.utils.SQLFormat(FKey,-1)).Add(FWhere,wcNone) )
        Else
           V := Session.Find<T>( orm.where.Where.Add(FWhere,wcNone) );
     End Else If (not Field.IsEmpty) And (not ((FKey = Unassigned) Or (FKey = Null))) Then
        V := Session.Find<T>( orm.where.Where.Add(Field +' = '+ sql.utils.SQLFormat(FKey,-1),wcNone) )
     Else If (not ((FKey = Unassigned) Or (FKey = Null))) Then
        V := Session.Find<T>(FKey)
     Else
        V := T(orm.Objects.Utils.Factory(C));

   Finally
     If Assigned(V) And not Assigned(FValue) Then
        FValue := V
     Else If Assigned(V) Then
     Begin
        orm.Objects.Utils.Copy(V,FValue);
        FreeAndNil(V);
     End Else If (not Assigned(V)) And (not Assigned(FValue)) Then
        FValue := T(orm.Objects.Utils.Factory(C));
   End;

   Result  := FValue;
   FLoad   := True;
   FIsNull := False;
end;

function TLazyLoad<T>.ValueAll: TObjectList<T>;
var C : TClass;
    V : TObjectList<T>;
    Old : TCollectionNotifyEvent<T>;
begin
   If FIsNull Then
      Exit(nil)
   Else If FLoad And Assigned(FValueAll) Then
      Exit(FValueAll);

   V := nil;
   Try
     If not FWhere.IsEmpty Then
     Begin
        If not Field.IsEmpty Then
           V := Session.FindAll<T>( orm.where.Where.Add(Field +' = '+ sql.utils.SQLFormat(FKey,-1)).Add(FWhere,wcNone),FOrder)
        Else
           V := Session.FindAll<T>( FWhere, FOrder )
     End Else If not Field.IsEmpty Then
        V := Session.FindAll<T>( Field +' = '+ sql.utils.SQLFormat(FKey,-1), FOrder )
     Else
        V := TObjectList<T>.Create;
   Finally
     If Assigned(V) And not Assigned(FValueAll) Then
        FValueAll := V
     Else If Assigned(V) Then
     Begin
        Old := FValueAll.OnNotify;
        FValueAll.OnNotify := nil;
        Try
          FValueAll.Clear;
          While (V.Count > 0) Do
             FValueAll.Add(V.Extract(V.First));
        Finally
          FValueAll.OnNotify := Old;
        End;
        FreeAndNil(V);
     End Else If (not Assigned(V)) And (not Assigned(FValue)) Then
        FValue := T(orm.Objects.Utils.Factory(C));
   End;

   Result  := FValueAll;
   FLoad   := True;
   FIsNull := False;
end;

end.

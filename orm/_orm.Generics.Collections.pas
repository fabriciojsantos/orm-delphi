unit orm.Generics.Collections;

interface

uses System.SysUtils, System.Classes, System.StrUtils, System.DateUtils,
     System.TypInfo, System.Generics.Collections, System.Generics.Defaults;

type
  TList<T> = Class(System.Generics.Collections.TList<T>)
  private
    FFilter           : TPredicate<T>;
    FIndexOfIndex     : Integer;
    FIndexOfPredicate : TPredicate<T>;
    FIndexOfFunc      : TFunc<T,Variant,Boolean>;

    function DoIndexOfPredicate(Value : TPredicate<T>; V : T) : Boolean;
    function DoIndexOfFunc(Value : TFunc<T,Variant,Boolean>; A : T; B : Variant) : Boolean;
  public
    property Filter           : TPredicate<T>            Read FFilter           Write FFilter;
    property IndexOfIndex     : Integer                  Read FIndexOfIndex;
    property IndexOfPredicate : TPredicate<T>            Read FIndexOfPredicate Write FIndexOfPredicate;
    property IndexOfFunc      : TFunc<T,Variant,Boolean> Read FIndexOfFunc      Write FIndexOfFunc;

    function IndexOf(var Index : Integer; AIndexOf : TPredicate<T>; StartIndex : Integer = 0; IsFiltered : Boolean = True) : Boolean; Overload;
    function IndexOf(AIndexOf : TPredicate<T>; StartIndex : Integer = 0; IsFiltered : Boolean = True) : Boolean; Overload;
    function IndexOf(StartIndex : Integer = 0; IsFiltered : Boolean = True) : Boolean; Overload;

    function IndexOf(var Index : Integer; AIndexOf : TFunc<T,Variant,Boolean>; Value : Variant; StartIndex : Integer = 0; IsFiltered : Boolean = True) : Boolean; Overload;
    function IndexOf(var Index : Integer; Value : Variant; StartIndex : Integer = 0; IsFiltered : Boolean = True) : Boolean; Overload;
    function IndexOf(Value : Variant; StartIndex : Integer = 0; IsFiltered : Boolean = True) : Boolean; Overload;

    type
      TEnumerator = class(TEnumerator<T>)
      private
        FList      : TList<T>;
        FIndex     : Integer;
        FPredicate : TPredicate<T>;
      protected
        function DoGetCurrent: T; override;
        function DoMoveNext: Boolean; override;
        function DoPredicate(Value : T) : Boolean;
      public
        Constructor Create(AList: TList<T>; APredicate : TPredicate<T>);
      end;

    function GetEnumerator: TEnumerator; reintroduce;
  end;

  TObjectList<T: Class> = Class(System.Generics.Collections.TObjectList<T>)
  private
    FFilter           : TPredicate<T>;
    FIndexOfIndex     : Integer;
    FIndexOfPredicate : TPredicate<T>;
    FIndexOfFunc      : TFunc<T,Variant,Boolean>;

    function DoIndexOfPredicate(Value : TPredicate<T>; V : T) : Boolean;
    function DoIndexOfFunc(Value : TFunc<T,Variant,Boolean>; A : T; B : Variant) : Boolean;
  public
    property Filter           : TPredicate<T>            Read FFilter           Write FFilter;
    property IndexOfIndex     : Integer                  Read FIndexOfIndex;
    property IndexOfPredicate : TPredicate<T>            Read FIndexOfPredicate Write FIndexOfPredicate;
    property IndexOfFunc      : TFunc<T,Variant,Boolean> Read FIndexOfFunc      Write FIndexOfFunc;

    function IndexOf(var Index : Integer; AIndexOf : TPredicate<T>; StartIndex : Integer = 0; IsFiltered : Boolean = True) : Boolean; Overload;
    function IndexOf(AIndexOf : TPredicate<T>; StartIndex : Integer = 0; IsFiltered : Boolean = True) : Boolean; Overload;
    function IndexOf(StartIndex : Integer = 0; IsFiltered : Boolean = True) : Boolean; Overload;

    function IndexOf(var Index : Integer; AIndexOf : TFunc<T,Variant,Boolean>; Value : Variant; StartIndex : Integer = 0; IsFiltered : Boolean = True) : Boolean; Overload;
    function IndexOf(var Index : Integer; Value : Variant; StartIndex : Integer = 0; IsFiltered : Boolean = True) : Boolean; Overload;
    function IndexOf(Value : Variant; StartIndex : Integer = 0; IsFiltered : Boolean = True) : Boolean; Overload;

    procedure AddRange(AList : TObjectList<T>; IsFree : Boolean); Overload;

    type
      TEnumerator = class(TEnumerator<T>)
      private
        FList      : TObjectList<T>;
        FIndex     : Integer;
        FPredicate : TPredicate<T>;
      protected
        function DoGetCurrent: T; override;
        function DoMoveNext: Boolean; override;
        function DoPredicate(Value : T) : Boolean;
      public
        Constructor Create(AList: TObjectList<T>; APredicate : TPredicate<T>);
      end;

    function GetEnumerator: TEnumerator; reintroduce;
  End;


implementation

{ TList<T> }

constructor TList<T>.TEnumerator.Create(AList: TList<T>;
  APredicate: TPredicate<T>);
begin
   inherited Create;
   FList := AList;
   FIndex := -1;
   FPredicate := APredicate;
end;

function TList<T>.TEnumerator.DoGetCurrent: T;
begin
   Result := FList[FIndex];
end;

function TList<T>.TEnumerator.DoMoveNext: Boolean;
begin
   If FIndex >= FList.Count Then
      Exit(False);

   If not Assigned(FPredicate) Then
      Inc(FIndex)
   Else
   Begin
      Repeat
         Inc(FIndex);
      Until (FIndex >= FList.Count) Or DoPredicate(FList[FIndex]);
   End;
   Result := FIndex < FList.Count;
end;

function TList<T>.TEnumerator.DoPredicate(Value: T): Boolean;
begin
   Result := True;
   If Assigned(FPredicate) Then
      Result := FPredicate(Value);
end;

{ TObjectList<T> }

function TList<T>.DoIndexOfFunc(Value : TFunc<T,Variant,Boolean>; A: T; B: Variant): Boolean;
begin
   Result := True;
   If Assigned(Value) Then
      Result := Value(A,B);
end;

function TList<T>.DoIndexOfPredicate(Value : TPredicate<T>; V: T): Boolean;
begin
   Result := True;
   If Assigned(Value) Then
      Result := Value(V);
end;

function TList<T>.GetEnumerator: TEnumerator;
begin
   Result := TEnumerator.Create(Self,FFilter);
end;

function TList<T>.IndexOf(var Index: Integer;
  AIndexOf: TFunc<T, Variant, Boolean>; Value : Variant; StartIndex: Integer;
  IsFiltered: Boolean): Boolean;
var I : Integer;
    V : T;
begin
   Result := False;
   Index  := -1;

   If IsFiltered Then
   Begin
     For V in Self Do
        If DoIndexOfFunc(AIndexOf,V,Value) Then
        Begin
           Index := GetEnumerator.FIndex;
           Exit(True);
        End;
   End Else
   Begin
     For I := 0 To (Self.Count - 1) Do
        If DoIndexOfFunc(AIndexOf,Self[I],Value) Then
        Begin
           Index := I;
           Exit(True);
        End;
   End;
end;

function TList<T>.IndexOf(StartIndex: Integer; IsFiltered: Boolean): Boolean;
begin
   Result := IndexOf(FIndexOfIndex,FIndexOfPredicate,StartIndex,IsFiltered);
end;

function TList<T>.IndexOf(var Index: Integer; AIndexOf : TPredicate<T>;
  StartIndex : Integer; IsFiltered : Boolean): Boolean;
var I : Integer;
    V : T;
begin
   Result := False;
   Index  := -1;

   If IsFiltered Then
   Begin
     For V in Self Do
        If DoIndexOfPredicate(AIndexOf,V) Then
        Begin
           Index := GetEnumerator.FIndex;
           Exit(True);
        End;
   End Else
   Begin
     For I := 0 To (Self.Count - 1) Do
        If DoIndexOfPredicate(AIndexOf,Self[I]) Then
        Begin
           Index := I;
           Exit(True);
        End;
   End;
end;

{ TObjectList<T> }

procedure TObjectList<T>.AddRange(AList : TObjectList<T>; IsFree: Boolean);
var I : Integer;
begin
   I := 0;
   While (AList.Count > I) Do
   Begin
      If AList.Filter(AList[I]) Then
         Self.Add(AList.Extract(AList[I]))
      Else
         Inc(I);
   End;
   AList.TrimExcess;
   AList.Pack;
   If IsFree Then
      FreeAndNil(AList);
end;

function TObjectList<T>.DoIndexOfFunc(Value: TFunc<T, Variant, Boolean>; A: T; B: Variant): Boolean;
begin
   Result := True;
   If Assigned(Value) Then
      Result := Value(A,B);
end;

function TObjectList<T>.DoIndexOfPredicate(Value: TPredicate<T>; V: T): Boolean;
begin
   Result := True;
   If Assigned(Value) Then
      Result := Value(V);
end;

function TObjectList<T>.GetEnumerator: TEnumerator;
begin
   Result := TEnumerator.Create(Self,FFilter);
end;

function TObjectList<T>.IndexOf(AIndexOf: TPredicate<T>; StartIndex: Integer;
  IsFiltered: Boolean): Boolean;
begin
   Result := IndexOf(FIndexOfIndex,AIndexOf,StartIndex,IsFiltered);
end;

function TObjectList<T>.IndexOf(var Index: Integer; AIndexOf: TPredicate<T>;
  StartIndex: Integer; IsFiltered: Boolean): Boolean;
var I : Integer;
    V : T;
begin
   Result := False;
   Index  := -1;

   If IsFiltered Then
   Begin
     For V in Self Do
        If DoIndexOfPredicate(AIndexOf,V) Then
        Begin
           Index := GetEnumerator.FIndex;
           Exit(True);
        End;
   End Else
   Begin
     For I := 0 To (Self.Count - 1) Do
        If DoIndexOfPredicate(AIndexOf,Self[I]) Then
        Begin
           Index := I;
           Exit(True);
        End;
   End;
end;

function TObjectList<T>.IndexOf(var Index: Integer; Value: Variant;
  StartIndex: Integer; IsFiltered: Boolean): Boolean;
begin
   Result := IndexOf(Index,FIndexOfFunc,Value,StartIndex,IsFiltered);
end;

function TObjectList<T>.IndexOf(Value: Variant; StartIndex: Integer;
  IsFiltered: Boolean): Boolean;
begin
   Result := IndexOf(FIndexOfIndex,FIndexOfFunc,Value,StartIndex,IsFiltered);
end;

function TObjectList<T>.IndexOf(StartIndex: Integer;
  IsFiltered: Boolean): Boolean;
begin
   Result := IndexOf(FIndexOfIndex,FIndexOfPredicate,StartIndex,IsFiltered);
end;

function TObjectList<T>.IndexOf(var Index: Integer;
  AIndexOf: TFunc<T, Variant, Boolean>; Value: Variant; StartIndex: Integer;
  IsFiltered: Boolean): Boolean;
var I : Integer;
    V : T;
begin
   Result := False;
   Index  := -1;

   If IsFiltered Then
   Begin
     For V in Self Do
        If DoIndexOfFunc(AIndexOf,V,Value) Then
        Begin
           Index := GetEnumerator.FIndex;
           Exit(True);
        End;
   End Else
   Begin
     For I := 0 To (Self.Count - 1) Do
        If DoIndexOfFunc(AIndexOf,Self[I],Value) Then
        Begin
           Index := I;
           Exit(True);
        End;
   End;
end;

{ TObjectList<T>.TEnumerator }

constructor TObjectList<T>.TEnumerator.Create(AList: TObjectList<T>;
  APredicate: TPredicate<T>);
begin
   inherited Create;
   FList      := AList;
   FIndex     := -1;
   FPredicate := APredicate;
end;

function TObjectList<T>.TEnumerator.DoGetCurrent: T;
begin
   Result := FList[FIndex];
end;

function TObjectList<T>.TEnumerator.DoMoveNext: Boolean;
begin
   If FIndex >= FList.Count Then
      Exit(False);

   If not Assigned(FPredicate) Then
      Inc(FIndex)
   Else
   Begin
      Repeat
         Inc(FIndex);
      Until (FIndex >= FList.Count) Or DoPredicate(FList[FIndex]);
   End;
   Result := FIndex < FList.Count;
end;

function TObjectList<T>.TEnumerator.DoPredicate(Value: T): Boolean;
begin
   Result := True;
   If Assigned(FPredicate) Then
      Result := FPredicate(Value);
end;

function TList<T>.IndexOf(AIndexOf: TPredicate<T>; StartIndex: Integer; IsFiltered: Boolean): Boolean;
begin
   Result := IndexOf(FIndexOfIndex,AIndexOf,StartIndex,IsFiltered);
end;

function TList<T>.IndexOf(Value: Variant; StartIndex: Integer; IsFiltered: Boolean): Boolean;
begin
   Result := IndexOf(FIndexOfIndex,FIndexOfFunc,Value,StartIndex,IsFiltered);
end;

function TList<T>.IndexOf(var Index: Integer; Value: Variant;
  StartIndex: Integer; IsFiltered: Boolean): Boolean;
begin
   Result := IndexOf(Index,FIndexOfFunc,Value,StartIndex,IsFiltered);
end;

end.


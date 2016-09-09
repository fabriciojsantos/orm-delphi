unit orm.where;

interface

uses System.SysUtils, System.DateUtils, System.Variants,
     System.Generics.Collections;

type TWOperador = (woNone, woEquals, woMore, woLess, woMoreEquals, woLessEquals, woDif, woLike,
                   woIs, woIsNot, woBetween, woBetweenField, woIn, woInNot);

type TWClausule = (wcNone, wcAnd, wcOr, wcNot, wcIn);

type TWLike = (wlStart, wlEnd, wlBoth);

Type
   TWhere = Class
   private
     FTable    : String;
     FField    : String;
     FValue    : String;
     FValueMax : String;
     FCoalesce : String;
     FSetWhere : Boolean;
     FOperador : TWOperador;
     FLike     : TWLike;
     FClausule : TWClausule;
     FOwner    : TWhere;
   public
     Constructor Create(Owner : TWhere); Overload;
     Constructor Create(Table, Field, Value : String; Operador : TWOperador; Owner : TWhere = nil); Overload;

     function ToString : String; Override;

     function &And : TWhere;
     function &Or : TWhere;

     function Add(Value : TWhere) : TWhere; Overload;
     function Add(Value : String; W : TWClausule = wcAnd) : TWhere; Overload;

     function Equal(Table, Field : String; Value : Variant) : TWhere; Overload;
     function Equal(Table, Field : String; Value : Variant; Size : Integer) : TWhere; Overload;
     function Equal(Table, Field : String; Value, Coalesce : Variant; Size : Integer = 0) : TWhere; Overload;

     function MoreEqual(Table, Field : String; Value : Variant) : TWhere; Overload;
     function MoreEqual(Table, Field : String; Value : Variant; Size : Integer) : TWhere; Overload;
     function MoreEqual(Table, Field : String; Value, Coalesce : Variant; Size : Integer = 0) : TWhere; Overload;

     function LessEqual(Table, Field : String; Value : Variant) : TWhere; Overload;
     function LessEqual(Table, Field : String; Value : Variant; Size : Integer) : TWhere; Overload;
     function LessEqual(Table, Field : String; Value, Coalesce : Variant; Size : Integer = 0) : TWhere; Overload;

     function More(Table, Field : String; Value : Variant) : TWhere; Overload;
     function More(Table, Field : String; Value : Variant; Size : Integer) : TWhere; Overload;
     function More(Table, Field : String; Value, Coalesce : Variant; Size : Integer = 0) : TWhere; Overload;

     function Less(Table, Field : String; Value : Variant) : TWhere; Overload;
     function Less(Table, Field : String; Value : Variant; Size : Integer) : TWhere; Overload;
     function Less(Table, Field : String; Value, Coalesce : Variant; Size : Integer = 0) : TWhere; Overload;

     function Dif(Table, Field : String; Value : Variant) : TWhere; Overload;
     function Dif(Table, Field : String; Value : Variant; Size : Integer) : TWhere; Overload;
     function Dif(Table, Field : String; Value, Coalesce : Variant; Size : Integer = 0) : TWhere; Overload;

     function Like(Table, Field : String; Value : Variant; L : TWLike = wlBoth) : TWhere; Overload;
     function Like(Table, Field : String; Values : Array Of Variant; L : TWLike = wlBoth) : TWhere; Overload;

     function InYes(Table, Field : String; Value : String) : TWhere; Overload;
     function InYes(Table, Field : String; Values : Array Of Variant) : TWhere; Overload;

     function InNot(Table, Field : String; Value : String) : TWhere; Overload;
     function InNot(Table, Field : String; Values : Array Of Variant) : TWhere; Overload;

     function Between(Table, Field : String; ValueMin, ValueMax : TDateTime; IsDateTime : Boolean) : TWhere; Overload;
     function Between(Table, Field : String; ValueMin, ValueMax : Variant; Size : Integer) : TWhere; Overload;
     function Between(Value : Variant; Table, FieldMin, FieldMax : String) : TWhere; Overload;
   End;

   function OperadorToStr(O : TWOperador) : String;
   function ClausuleToStr(C : TWClausule) : String;

   function Where(IsWhere : Boolean = False) : TWhere;

implementation

uses sql.utils;

function OperadorToStr(O: TWOperador): String;
begin
   Result := '';
   Case O Of
     woEquals     : Result := ' = ';
     woDif        : Result := ' <> ';
     woMore       : Result := ' > ';
     woMoreEquals : Result := ' >= ';
     woLessEquals : Result := ' <= ';
     woLess       : Result := ' < ';
     woLike       : Result := ' like ';
     woIs         : Result := ' is ';
     woIsNot      : Result := ' is not ';
     woBetween,
     woBetweenField : Result := ' between ';
     woIn         : Result := ' in ';
     woInNot      : Result := ' not in ';
   End;
end;

function ClausuleToStr(C: TWClausule): String;
begin
   Result := '';
   Case C Of
     wcAnd : Result := ' and ';
     wcOr  : Result := ' or ';
     wcNot : Result := ' not ';
     wcIn  : Result := ' in ';
   End;
end;

{ TWhere }

function TWhere.Add(Value: TWhere): TWhere;
begin
   Result := TWhere.Create(Self);
   Result.FValue := Value.ToString;
end;

function TWhere.Add(Value: String; W : TWClausule): TWhere;
begin
   Result := TWhere.Create(Self);
   If (Value <> '') Then
   Begin
      Result.FValue    := Value;
      Result.FClausule := W;
   End;
end;

function TWhere.&And: TWhere;
begin
   Result := TWhere.Create(Self);
   Result.FClausule := wcAnd;
end;

function TWhere.Between(Value: Variant; Table, FieldMin,
  FieldMax: String): TWhere;
begin
   Result := TWhere.Create(Table,FieldMin,Value.SQLFormat(0,False),woBetweenField,Self);
   Result.FValueMax := FieldMax;
end;

function TWhere.Between(Table, Field: String; ValueMin, ValueMax: Variant;
  Size: Integer): TWhere;
begin
   Result := TWhere.Create(Table,Field,ValueMin.SQLFormat(Size,False),woBetween,Self);
   Result.FValueMax := ValueMax.SQLFormat(Size,False);
end;

constructor TWhere.Create(Owner: TWhere);
begin
   FOwner := Owner;
end;

function TWhere.Between(Table, Field: String; ValueMin, ValueMax : TDateTime; IsDateTime : Boolean): TWhere;
begin
   If IsDateTime Then
   Begin
      Result := TWhere.Create(Table,Field,SQLFormat(ValueMin,False),woBetween,Self);
      Result.FValueMax := SQLFormat(ValueMax,False);
      If (TimeOf(ValueMax) = 0) Then
         Result.FValueMax := SQLFormat(EndOfTheDay(ValueMax),False);
   End Else
   Begin
      Result := TWhere.Create(Table,Field,SQLFormat(TDate(ValueMin),False),woBetween,Self);
      Result.FValueMax := SQLFormat(TDate(ValueMax),False);
   End;
end;

constructor TWhere.Create(Table, Field, Value : String; Operador : TWOperador; Owner : TWhere);
begin
   FTable    := Table;
   FField    := Field;
   FValue    := Value;
   FOperador := Operador;
   FOwner    := Owner;
end;

function TWhere.Like(Table, Field: String; Value: Variant; L: TWLike): TWhere;
begin
   Case L Of
      wlStart : Value := '%' + Value;
      wlEnd   : Value := Value + '%';
      wlBoth  : Value := '%'+ Value + '%';
   End;
   Result := TWhere.Create(Table,Field,Value.SQLFormat(0,False),woLike,Self);
   Result.FLike := L;
end;

function TWhere.ToString : String;
var S : String;
begin
   S := '%s.%s';
   If FTable.IsEmpty Then
      S := '%s%s';

   If FSetWhere Then
      Result := ' where '
   Else If (FOperador = woNone) And (FClausule = wcNone) And (not FValue.IsEmpty) Then
      Result := Format('(%s)',[FValue])
   Else If not FField.IsEmpty Then
   Begin
      If (FOperador = woBetween) Then
         Result := Format('('+ S +' %s %s and %s)',[FTable,FField,OperadorToStr(FOperador),FValue,FValueMax])
      Else If (FOperador = woBetweenField) Then
         Result := Format('(%s %s '+ S +' and '+ S +')',[FValue,OperadorToStr(FOperador),FTable,FField,FTable,FValueMax])
      Else If (FOperador in [woIn,woInNot]) Then
         Result := Format('('+ S +' %s (%s))',[FTable,FField,OperadorToStr(FOperador),FValue])
      Else
      Begin
         If (FValue.Trim = 'null') Then
            If (FOperador = woEquals) Then
               FOperador := woIs
            Else If (FOperador = woDif) Then
               FOperador := woIsNot;

         If not FCoalesce.IsEmpty Then
            Result := Format('(coalesce('+ S +',%s) %s %s)',[FTable,FField,FCoalesce,OperadorToStr(FOperador),FValue])
         Else
            Result := Format('('+ S +' %s %s)',[FTable,FField,OperadorToStr(FOperador),FValue]);
      End;
   End Else If (FClausule <> wcNone) And (not FValue.IsEmpty) Then
      Result := Format('(%s)',[FValue]) + ClausuleToStr(FClausule)
   Else
      Result := ClausuleToStr(FClausule);

   If Assigned(FOwner) Then
      Result := FOwner.ToString + Result;

   Destroy;
end;

function TWhere.Dif(Table, Field: String; Value: Variant; Size: Integer): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(Size,False),woDif,Self);
end;

function TWhere.Dif(Table, Field: String; Value: Variant): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(0,False),woDif,Self);
end;

function TWhere.Equal(Table, Field: String; Value: Variant): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(0,False),woEquals,Self);
end;

function TWhere.Equal(Table, Field: String; Value: Variant; Size: Integer): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(Size,False),woEquals,Self);
end;

function TWhere.Equal(Table, Field: String; Value, Coalesce: Variant; Size : Integer): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(Size,False),woEquals,Self);
   Result.FCoalesce := Coalesce.SQLFormat(Size,False);
end;

function TWhere.InNot(Table, Field: String; Values: array of Variant): TWhere;
var S : String;
    V : Variant;
begin
   For V in Values Do
     If S.IsEmpty Then
       S := V.SQLFormat(0,False)
     Else
       S := S +','+ V.SQLFormat(0,False);

   Result := InNot(Table,Field,S);
end;

function TWhere.InNot(Table, Field, Value: String): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value,woInNot,Self);
end;

function TWhere.InYes(Table, Field, Value: String): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value,woIn,Self);
end;

function TWhere.InYes(Table, Field: String; Values: array of Variant): TWhere;
var S : String;
    V : Variant;
begin
   For V in Values Do
     If S.IsEmpty Then
       S := V.SQLFormat(0,False)
     Else
       S := S +','+ V.SQLFormat(0,False);

   Result := InYes(Table,Field,S);
end;

function TWhere.Less(Table, Field: String; Value: Variant): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(0,False),woLess,Self);
end;

function TWhere.Less(Table, Field: String; Value: Variant; Size: Integer): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(Size,False),woLess,Self);
end;

function TWhere.LessEqual(Table, Field: String; Value: Variant): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(0,False),woLessEquals,Self);
end;

function TWhere.LessEqual(Table, Field: String; Value: Variant;
  Size: Integer): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(Size,False),woLessEquals,Self);
end;

function TWhere.More(Table, Field: String; Value: Variant; Size: Integer): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(Size,False),woMore,Self);
end;

function TWhere.More(Table, Field: String; Value: Variant): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(0,False),woMore,Self);
end;

function TWhere.MoreEqual(Table, Field: String; Value: Variant;
  Size: Integer): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(Size,False),woMoreEquals,Self);
end;

function TWhere.&Or: TWhere;
begin
   Result := TWhere.Create(Self);
   Result.FClausule := wcOr;
end;

function TWhere.MoreEqual(Table, Field: String; Value: Variant): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(0,False),woMoreEquals,Self);
end;

function Where(IsWhere : Boolean) : TWhere;
Begin
   Result := TWhere.Create;
   Result.FSetWhere := IsWhere;
End;

function TWhere.Dif(Table, Field: String; Value, Coalesce: Variant;
  Size: Integer): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(Size,False),woDif,Self);
   Result.FCoalesce := Coalesce.SQLFormat(Size,False);
end;

function TWhere.Less(Table, Field: String; Value, Coalesce: Variant;
  Size: Integer): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(Size,False),woLess,Self);
   Result.FCoalesce := Coalesce.SQLFormat(Size,False);
end;

function TWhere.LessEqual(Table, Field: String; Value, Coalesce: Variant;
  Size: Integer): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(Size,False),woLessEquals,Self);
   Result.FCoalesce := Coalesce.SQLFormat(Size,False);
end;

function TWhere.Like(Table, Field: String; Values : Array of Variant;
  L: TWLike): TWhere;
var V : Variant;
begin
   Result := nil;
   For V in Values Do
      If not Assigned(Result) Then
         Result := Like(Table,Field,V,L)
      Else
         Result := Result;//.Or.Like(Table,Field,V,L);
end;

function TWhere.More(Table, Field: String; Value, Coalesce: Variant;
  Size: Integer): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(Size,False),woMore,Self);
   Result.FCoalesce := Coalesce.SQLFormat(Size,False);
end;

function TWhere.MoreEqual(Table, Field: String; Value, Coalesce: Variant;
  Size: Integer): TWhere;
begin
   Result := TWhere.Create(Table,Field,Value.SQLFormat(Size,False),woMoreEquals,Self);
   Result.FCoalesce := Coalesce.SQLFormat(Size,False);
end;

end.

unit sql.utils;

interface

uses System.SysUtils, System.TypInfo, System.Variants, System.Rtti;

   function SQLFormat(Value : String; IsNull : Boolean = False) : String; Overload;
   function SQLFormat(Value : String; Size : Integer; IsNull : Boolean = False) : String; Overload;
   function SQLFormat(Value : Integer; IsNull : Boolean = False) : String; Overload;
   function SQLFormat(Value : TDate; IsNull : Boolean = False) : String; Overload;
   function SQLFormat(Value : TDateTime; IsNull : Boolean = False) : String; Overload;
   function SQLFormat(Value : TTime; IsNull : Boolean = False) : String; Overload;
   function SQLFormat(Value : Extended; Decimal : Integer = 2; IsNull : Boolean = False) : String; Overload;
   function SQLFormat(Value : Variant; Size : Integer; IsNull : Boolean = False) : String; Overload;
   function SQLFormat(TypeInfo : PTypeInfo; Value : Variant; Size : Integer; IsNull : Boolean = True) : String; Overload;

   function SQLValueEmpty(Value : Variant) : Boolean;

implementation

uses sql.consts;

function SQLFormat(Value : String; IsNull : Boolean = False) : String; Overload;
begin
   If (Value.IsEmpty And IsNull) Then
      Result := SQLNull
   Else
      Result := Value.QuotedString;
end;

function SQLFormat(Value : String; Size : Integer; IsNull : Boolean = False) : String; Overload;
begin
   If (Value.IsEmpty And IsNull) Then
      Result := SQLNull
   Else If (Size > 0) Then
      Result := Value.Remove(Size).QuotedString
   Else
      Result := Value.QuotedString;
end;

function SQLFormat(Value : Integer; IsNull : Boolean = False) : String; Overload;
begin
   If (Value = 0) And IsNull Then
      Result := SQLNull
   Else
      Result := FormatFloat('0',Value);
end;

function SQLFormat(Value : TDate; IsNull : Boolean = False) : String; Overload;
begin
   If (Value = 0) And IsNull Then
      Result := SQLNull
   Else
      Result := SQLFormat(FormatDateTime(SQLDate,Value));
end;

function SQLFormat(Value : TDateTime; IsNull : Boolean = False) : String; Overload;
begin
   If (Value = 0) And IsNull Then
      Result := SQLNull
   Else
      Result := SQLFormat(FormatDateTime(SQLDateTime,Value));
end;

function SQLFormat(Value : TTime; IsNull : Boolean = False) : String; Overload;
begin
   If (Value = 0) And IsNull Then
      Result := SQLNull
   Else
      Result := SQLFormat(FormatDateTime(SQLTime,Value));
end;

function SQLFormat(Value : Extended; Decimal : Integer = 2; IsNull : Boolean = False) : String; Overload;
begin
   If (Value = 0) And IsNull Then
      Result := SQLNull
   Else
      Result := StringReplace(FormatFloat('0.' + StringOfChar('0',Decimal), Value),',','.',[rfIgnoreCase]);
end;

function SQLFormat(Value : Variant; Size : Integer; IsNull : Boolean = False) : String; Overload;
var V : TValue;
begin
   V := TValue.FromVariant(Value);

   Result := SQLNull;
   If (V.TypeInfo = TypeInfo(TDateTime)) Then
      Result := SQLFormat(TDateTime(Value),IsNull)
   Else If (V.TypeInfo = TypeInfo(TDate)) Then
      Result := SQLFormat(TDate(Value),IsNull)
   Else If (V.TypeInfo = TypeInfo(TTime)) Then
      Result := SQLFormat(TTime(Value),IsNull)
   Else If (V.TypeInfo = TypeInfo(String)) Then
      Result := SQLFormat(String(Value),IsNull)
   Else If (V.TypeInfo = System.TypeInfo(Boolean)) Then
      Result := SQLFormat(sql.consts.SQLBoolean[Boolean(Value)],IsNull)
   Else If (V.TypeInfo = TypeInfo(Integer)) Or (V.TypeInfo = TypeInfo(Int64)) Or (V.TypeInfo = TypeInfo(Int32)) Then
      Result := SQLFormat(Integer(Value),IsNull)
   Else If (V.TypeInfo = TypeInfo(Extended)) Or (V.TypeInfo = TypeInfo(Double)) Or (V.TypeInfo = TypeInfo(Real)) Then
   Begin
      If (Size = 0) Then
         Size := 2;
      Result := SQLFormat(Extended(Value),Size,IsNull);
   End;
end;

function SQLFormat(TypeInfo : PTypeInfo; Value : Variant; Size : Integer; IsNull : Boolean = True) : String; Overload;
Begin
   Try
     If (Value = null) Then
        Result := 'null'
     Else If (TypeInfo = System.TypeInfo(TDateTime)) Then
        Result := sql.utils.SQLFormat(TDateTime(Value),IsNull)
     Else If (TypeInfo = System.TypeInfo(TDate)) Then
        Result := sql.utils.SQLFormat(TDate(Value),IsNull)
     Else If (TypeInfo = System.TypeInfo(TTime)) Then
        Result := sql.utils.SQLFormat(TTime(Value),IsNull)
     Else If (TypeInfo = System.TypeInfo(Boolean)) Then
        Result := sql.utils.SQLFormat(SQLBoolean[Boolean(Value)],IsNull)
     Else If (TypeInfo = System.TypeInfo(Integer)) Or
             (TypeInfo = System.TypeInfo(Int64)) Or (TypeInfo = System.TypeInfo(Int32)) Then
        Result := sql.utils.SQLFormat(Integer(Value),IsNull)
     Else If (TypeInfo = System.TypeInfo(Extended)) Or
             (TypeInfo = System.TypeInfo(Double)) Or (TypeInfo = System.TypeInfo(Real)) Then
     Begin
        If (Size = 0) Then
           Size := 2;
        Result := sql.utils.SQLFormat(Extended(Value),Size,IsNull)
     End Else
        Result := sql.utils.SQLFormat(String(Value),Size,IsNull);
   Except
     Result := 'null';
   End;
End;

function SQLValueEmpty(Value : Variant) : Boolean;
begin
   Result := VarIsNull(Value);
   If VarIsStr(Value) Then
      Result := (Trim(String(Value)) = '')
   Else If VarIsType(Value,varDate) Then
      Result := (TDateTime(Value) = 0)
   Else If VarIsFloat(Value) Then
      Result := (Extended(Value) = 0)
   Else If VarIsNumeric(Value) Then
      Result := (Integer(Value) = 0);
end;

end.

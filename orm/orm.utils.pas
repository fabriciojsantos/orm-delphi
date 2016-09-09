unit orm.utils;

interface

uses System.SysUtils, System.Classes, System.Generics.Collections,
     System.Rtti, System.TypInfo;

   procedure Clear(Value : TObject);
   procedure Copy(A, B : TObject);

   function  Equals(A, B : TObject) : Boolean;
   function  Factory(Value : TClass) : TObject;

   function GetClass(Value: TClass) : TClass; Overload;
   function GetClass(Value : String) : TClass; Overload;
   function GetField(Name : String; Value : TObject) : TValue;

implementation

procedure Clear(Value : TObject);
var C : TRttiContext;
    Y : TRttiType;
    F : TRttiField;
begin
   Try
     If not Assigned(Value) Then
        Exit;

     C := TRttiContext.Create;
     Try
       Y := C.GetType(Value.ClassType);
       For F in Y.GetFields Do
         If (F.FieldType.TypeKind <> tkClass) Then
            F.SetValue(Value,TValue.Empty)
         Else If (F.FieldType.IsInstance) And (F.GetValue(Value).IsObject) And (F.GetValue(Value).AsObject <> nil) Then
         Begin
            If (Pos('List<',F.FieldType.AsInstance.MetaclassType.ClassName) > 0) Then
               TList<TObject>(F.GetValue(Value).AsObject).Clear
            Else
               Clear(F.GetValue(Value).AsObject);
         End Else
            F.SetValue(Value,TValue.Empty);
     Finally
       C.Free;
     End;
   Except
   End;
end;

procedure Copy(A, B : TObject);
var C : TRttiContext;
    Y : TRttiType;
    F : TRttiField;
begin
   If (A = nil) Then
      Exit;

   If not Assigned(B) Then
      B := Factory(A.ClassType);

   C := TRttiContext.Create;
   Try
     Y := C.GetType(A.ClassType);
     For F in Y.GetFields Do
       If (F.FieldType.TypeKind <> tkClass) Then
          F.SetValue(B,F.GetValue(A))
       Else If (F.FieldType.IsInstance) And (Pos('List<',F.FieldType.AsInstance.MetaclassType.ClassName) > 0) Then
       Begin
          If (F.GetValue(B).AsObject <> nil) And (F.GetValue(A).AsObject <> nil) Then
             TList<TObject>(F.GetValue(B).AsObject).AddRange(TList<TObject>(F.GetValue(A).AsObject));
       End Else
          Copy(F.GetValue(A).AsObject,F.GetValue(B).AsObject);
   Finally
     C.Free;
   End;
end;

function  Equals(A, B : TObject) : Boolean;
var C : TRttiContext;
    Y : TRttiType;
    F : TRttiField;
begin
   Result := False;

   If not Assigned(A) Then
      Exit;

   C := TRttiContext.Create;
   Try
     Y := C.GetType(A.ClassType);
     For F in Y.GetFields Do
     Begin
       If (F.FieldType.TypeKind <> tkClass) Then
          Result := (F.GetValue(A).ToString = F.GetValue(B).ToString)
       Else If (F.FieldType.IsInstance) And (Pos('List<',F.FieldType.AsInstance.MetaclassType.ClassName) > 0) Then
          Result := (TList<TObject>(F.GetValue(B).AsObject).Count = TList<TObject>(F.GetValue(A).AsObject).Count)
       Else
          Result := Equals(F.GetValue(A).AsObject,F.GetValue(B).AsObject);

       If not Result Then
          Break;
     End;
   Finally
     C.Free;
   End;
end;

function Factory(Value : TClass) : TObject;
var V : TValue;
    C : TRttiContext;
    R : TRttiType;
    M : TRttiMethod;
    I : TRttiInstanceType;
begin
  Result := nil;

  C := TRttiContext.Create;
  Try
    R := C.GetType(Value);
    For M in R.GetMethods Do
      If (not M.IsConstructor) Then
         Continue
      Else If (Length(M.GetParameters) = 0) Then
      Begin
        I      := R.AsInstance;
        V      := M.Invoke(I.MetaclassType, []);
        Result := V.AsObject;
        Break;
      End;
  Finally
    C.Free;
  End;
end;

function GetClass(Value: TClass) : TClass;
begin
   Result := Value;
   If Value.ClassName.Contains('<') Then
      Result := GetClass(Value.ClassName);
end;

function GetClass(Value: String) : TClass;
var C : TRttiContext;
    A : TArray<String>;
    I : Integer;
begin
   C := TRttiContext.Create;
   Try
     If Value.Contains('<') Then
     Begin
        A := Value.Split(['<','>']);
        For I := High(A) DownTo Low(A) Do
          If (not A[I].IsEmpty) Then
          Begin
             Value := A[I];
             Break;
          End;
     End;
     Result := C.FindType(Value).AsInstance.MetaclassType;
   Finally
     C.Free;
   End;
end;

function GetField(Name : String; Value : TObject) : TValue;
var C : TRttiContext;
    Y : TRttiType;
    P : TRttiProperty;
    F : TRttiField;
begin
   If not Assigned(Value) Then
      Exit;

   C := TRttiContext.Create;
   Try
     Y := C.GetType(Value.ClassType);
     P := Y.GetProperty(Name);
     If Assigned(P) Then
        Exit(P.GetValue(Value));

     {For P in Y.GetProperties Do
       If (P.Name.ToLower = Name.ToLower) Then
          Exit(P.GetValue(Value));}

     F := Y.GetField(Name);
     If Assigned(F) Then
        Exit(F.GetValue(Value));

     {For F in Y.GetFields Do
       If (F.Name.ToLower = Name.ToLower) Then
          Exit(F.GetValue(Value));}
   Finally
     C.Free;
   End;
end;

end.

unit sql.consts;

interface

uses System.SysUtils, System.Classes, System.Generics.Collections, Data.DB;

type TSQLConnect = (sqlcDBX, sqlcFD, sqlcADO, sqlcBDE, sqlcDSnap);

type TSQLDB = (dbNone, dbFirebird, dbMySQL, dbSQLServer, dbOracle, dbDataSnap);

type TSQLDBMode = (dbInsert, dbUpdate, dbDelete, dbSelect, dbRefresh, dbExecute);

type TOnProgress = reference to procedure (Index : Integer = 0; Max : Integer = 0; Mens : String = '');

{$REGION 'Const SQL'}
const SQLCommandSeparator = '^;';

const SQLNull      = ' null ';

const SQLInsert    = ' insert into %s (%s) values (%s) ';

const SQLInsertUpdate = ' update or ' + SQLInsert;

const SQLUpdate    = ' update %s set %s ';

const SQLDelete    = ' delete from %s ';

const SQLSelect    = ' select %s from %s ';

const SQLProcedure = ' execute procedure %s ';

const SQLProcedureOpen = ' select %s from %s(%s) ';

const SQLOrderBy   = ' order by %s ';

const SQLGroupBy   = ' group by %s ';

const SQLLeftJoin  = ' left join  ';

const SQLRightJoin = ' right join ';

const SQLInnerJoin = ' inner join ';

const SQLWhere     = ' where (%s) ';

const SQLCoalesce  = ' coalesce(%s,%s) ';

const SQLUpper     = ' upper(%s) ';

const SQLLower     = ' lower(%s) ';

const SQLDate      = 'yyyy-mm-dd';

const SQLTime      = 'hh:nn:ss';

const SQLDateTime  = 'yyyy-mm-dd hh:nn:ss:zzzz';

const SQLLike      = '(%s like %s)';

const SQLEquals    = '(%s = %s)';

const SQLDif       = '(%s <> %s)';

const SQLAnd       = '(%s and %s)';

const SQLBetween   = '(%s between %s and %s)';

const SQLYes       = ' ''S'' ';

const SQLNo        = ' ''N'' ';

const SQLBoolean : Array [Boolean] Of SmallInt = (-1,1);
{$ENDREGION}

function StringToSQLDB(Value : String) : TSQLDB;

function SQLDBToString(Value : TSQLDB) : String;

function StringToSQLMode(Value : String) : TSQLDBMode;

type
   TSQLEvents = Class
   Private
     FSQL   : TStrings;
     FBlobs : TList<TBytes>;
   Public
     constructor Create;
     Destructor Destroy; Override;

     property SQL   : TStrings      Read FSQL;
     property Blobs : TList<TBytes> Read FBlobs;
   End;

   TSQL = Class
   Private
     FSQLDB    : TSQLDB;
     FSQLKey   : String;
     FSQLFirst : String;
     FSQLNow   : String;
     FSQLDate  : String;
     FSQLTime  : String;
   Public
     property SQLDB    : TSQLDB Read FSQLDB;
     property SQLKey   : String Read FSQLKey;
     property SQLFirst : String Read FSQLFirst;
     property SQLNow   : String Read FSQLNow;
     property SQLDate  : String Read FSQLDate;
     property SQLTime  : String Read FSQLTime;

     function SQLInsert(Table, Fields, Values, Keys : String) : TStrings; Overload; Virtual; Abstract;
     function SQLInsert(Table : String; Fields, Values : Array Of String) : String; Overload;

     function SQLUpdate(Table, FieldsValues, Keys, FieldsAuto : String) : TStrings; Overload; Virtual; Abstract;
     function SQLUpdate(Table : String; Keys, Fields, Values : Array Of String) : String; Overload;

     function SQLDelete(Table : String; Keys, Values : Array Of String) : String; Overload;

     function SQLConnections : String; Virtual; Abstract;

     function SQLGetGenerator(Name : String) : String; Virtual; Abstract;
     function SQLGetDateTime : String; Virtual; Abstract;
     function SQLGetDate : String; Virtual; Abstract;
     function SQLGetTime : String; Virtual; Abstract;

     function SQLField(Table, Field : String) : String;
     function SQLFieldAlias(Table, Field : String) : String;
     function SQLFieldAsAlias(Table, Field : String) : String;

     Class function Factory(Value : TSQLDB) : TSQL;
   End;

   TSQLFirebird = Class(TSQL)
   Public
     Constructor Create;

     function SQLInsert(Table, Fields, Values, Keys : String) : TStrings; Override;
     function SQLUpdate(Table, FieldsValues, Keys, FieldsAuto : String) : TStrings; Override;

     function SQLConnections : String; Override;

     function SQLGetGenerator(Name : String) : String; Override;
     function SQLGetDateTime : String; Override;
     function SQLGetDate : String; Override;
     function SQLGetTime : String; Override;
   End;

   TSQLMySQL = Class(TSQL)
   Public
     Constructor Create;
   End;

implementation

function StringToSQLDB(Value : String) : TSQLDB;
begin
   Result := dbNone;
   If (Value = 'dbFirebird') Then
      Result := dbFirebird
   Else If (Value = 'dbSQLServer') Then
      Result := dbSQLServer
   Else If (Value = 'dbMySQL') Then
      Result := dbMySQL
   Else If (Value = 'dbOracle') Then
      Result := dbOracle;
end;

function SQLDBToString(Value : TSQLDB): String;
begin
   Result := '';
   Case Value Of
     dbFirebird  : Result := 'dbFirebird';
     dbSQLServer : Result := 'dbSQLServer';
     dbMySQL     : Result := 'dbMySQL';
     dbOracle    : Result := 'dbOracle';
   End;
end;

function StringToSQLMode(Value : String) : TSQLDBMode;
begin
   Result := dbExecute;
   If (Pos('insert',Value) > 0) Then
      Result := dbInsert
   Else If (Pos('delete',Value ) > 0) Then
      Result := dbDelete
   Else If (Pos('update',Value ) > 0) Then
      Result := dbUpdate
   Else If (Pos('select',Value ) > 0) Then
      Result := dbSelect;
end;


{ TSQLFirebird }

constructor TSQLFirebird.Create;
begin
   FSQLDB    := dbFirebird;
   FSQLKey   := ' returning %s ';
   FSQLFirst := ' First %s ';
   FSQLNow   := 'CURRENT_TIMESTAMP';
   FSQLDate  := 'CURRENT_DATE';
   FSQLTime  := 'CURRENT_TIME';
end;

{ TSQLMySQL }

constructor TSQLMySQL.Create;
begin
   FSQLDB    := dbMySQL;
   FSQLKey   := ' SELECT LAST_INSERT_ID() AS %s ';
   FSQLFirst := ' Limit%s ';
end;

{ TSQLFirebird }

function TSQLFirebird.SQLConnections: String;
begin
   Result := ' SELECT MON$ATTACHMENT_ID    AS ID,    '+
             '        MON$ATTACHMENT_NAME  AS NAME,  '+
             '        MON$REMOTE_ADDRESS   AS HOST,  '+
             '        MON$REMOTE_PROCESS   AS APP    '+
             ' FROM MON$ATTACHMENTS A                '+
             ' INNER JOIN MON$DATABASE B ON (B.MON$DATABASE_NAME = A.MON$ATTACHMENT_NAME) ' +
             ' WHERE (A.MON$ATTACHMENT_ID = CURRENT_CONNECTION) ';
end;

function TSQLFirebird.SQLGetDate: String;
begin
   Result := ' SELECT '+ SQLDate +' AS V FROM RDB$DATABASE ';
end;

function TSQLFirebird.SQLGetDateTime: String;
begin
   Result := ' SELECT '+ SQLNow +' AS V FROM RDB$DATABASE ';
end;

function TSQLFirebird.SQLGetGenerator(Name: String): String;
begin
   Result := Format(' SELECT GEN_ID(%s,1) AS V FROM RDB$DATABASE ',[Name]);
end;

function TSQLFirebird.SQLGetTime: String;
begin
   Result := ' SELECT '+ SQLTime +' AS V FROM RDB$DATABASE ';
end;

function TSQLFirebird.SQLInsert(Table, Fields, Values, Keys: String): TStrings;
begin
   Result := TStringList.Create;
   If Keys.IsEmpty Then
      Result.Add(Format(sql.consts.SQLInsert,[Table,Fields,Values]))
   Else
      Result.Add(Format(sql.consts.SQLInsert + SQLKey,[Table,Fields,Values,Keys]));
end;

function TSQLFirebird.SQLUpdate(Table, FieldsValues, Keys,
  FieldsAuto: String): TStrings;
begin
   Result := TStringList.Create;
   If Keys.IsEmpty Then
      Result.Add(Format(sql.consts.SQLUpdate,[Table,FieldsValues]))
   Else If FieldsAuto.IsEmpty Then
      Result.Add(Format(sql.consts.SQLUpdate + sLineBreak + sql.consts.SQLWhere,[Table,FieldsValues,Keys]))
   Else
      Result.Add(Format(sql.consts.SQLUpdate + sLineBreak + sql.consts.SQLWhere + sLineBreak + SQLKey,[Table,FieldsValues,Keys,FieldsAuto]));
end;

{ TSQL }

class function TSQL.Factory(Value: TSQLDB): TSQL;
begin
   Result := nil;
   Case Value Of
      dbFirebird : Result := TSQLFirebird.Create;
      dbMySQL    : Result := TSQLMySQL.Create;
   End;
end;

function TSQL.SQLDelete(Table: String; Keys, Values: array of String): String;
var I : Integer;
    _KeysValues : String;
begin
   _KeysValues := '';
   For I := Low(Keys) To High(Keys) Do
      If (_KeysValues = '') Then
         _KeysValues := Format(' (%s = %s) ',[Keys[I],Values[I]])
      Else
         _KeysValues := _KeysValues + Format(' AND (%s = %s) ',[Keys[I],Values[I]]);

   If not _KeysValues.IsEmpty Then
      Result := Format(sql.consts.SQLDelete + sql.consts.SQLWhere,[Table,_KeysValues])
   Else
      Result := Format(sql.consts.SQLDelete,[Table]);
end;

function TSQL.SQLField(Table, Field : String): String;
begin
   Result := Format('%s.%s',[Table,Field]);
end;

function TSQL.SQLFieldAlias(Table, Field : String): String;
begin
   Result := Format('%s_%s',[Table,Field]).Remove(30);
end;

function TSQL.SQLFieldAsAlias(Table, Field: String): String;
begin
   Result := Format('%s.%s AS %s',[Table,Field,Format('%s_%s',[Table,Field]).Remove(30)]);
end;

function TSQL.SQLInsert(Table: String; Fields, Values: Array of String): String;
var S : String;
    _F , _V : String;
begin
   _F := '';
   _V := '';

   For S in Fields Do
      If (_F = '') Then
         _F := S
      Else
         _F := _F + ',' + S;

   For S in Values Do
      If (_V = '') Then
         _V := S
      Else
         _V := _V + ',' + S;

   Result := Format(sql.consts.SQLInsert,[Table,_F,_V]);
end;

function TSQL.SQLUpdate(Table : String; Keys, Fields, Values: Array of String): String;
var I, X : Integer;
    _K, _FV : String;
    IsKey : Boolean;
begin
   _K  := '';
   _FV := '';

   For I := Low(Fields) To High(Fields) Do
   Begin
      IsKey := False;
      For X := Low(Keys) To High(Keys) Do
         If (Fields[I] = Keys[X]) Then
         Begin
            If (_K = '') Then
               _K := Keys[X] +' = '+ Values[I]
            Else
              _K := _K + ',' + Keys[X] +' = '+ Values[I];
            IsKey := True;
            Break;
         End;

      If IsKey Then
         Continue;

      If (_FV = '') Then
         _FV := Fields[I] +' = '+ Values[I]
      Else
         _FV := _FV + ',' + Fields[I] +' = '+ Values[I];
   End;

   If _K.IsEmpty Then
      Result := Format(sql.consts.SQLUpdate,[Table,_FV])
   Else
      Result := Format(sql.consts.SQLUpdate + sLineBreak + sql.consts.SQLWhere,[Table,_FV,_K]);
end;

{ TSQLEvents }

constructor TSQLEvents.Create;
begin
   FSQL   := TStringList.Create;
   FBlobs := TList<TBlobData>.Create;
end;

destructor TSQLEvents.Destroy;
begin
   FreeAndNil(FSQL);
   FreeAndNil(FBlobs);
   inherited;
end;

end.



unit orm.attributes.types;

interface

  type TModeSQL    = (msInsert, msUpdate, msDelete, msSelect, msRefresh);

  type TFieldType  = (ftPrimaryKey, ftAuto, ftNotNull, ftReadOnly, ftInsertOnly, ftUpdateOnly);
  type TFieldTypes = Set Of TFieldType;

  type TParamType  = (ptNone, ptInPut, ptOutPut);
  type TParamTypes = Set Of TParamType;

  type TObjectType = (otField, otParam, otTable, otForeign, otStoredProc, otFunction, otView);

  type TJoin       = (jLeft, jInner, jRight);

  type TLoad       = (lLazy, lEazy);

  type TModify     = (mNone, mInsert, mUpdate, mDelete);
  type TModifys    = Set Of TModify;

  type TParentType = (ptUnknow, ptField, ptProperty);

implementation

end.

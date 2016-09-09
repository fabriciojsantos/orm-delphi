//
// Created by the DataSnap proxy generator.
// 10/06/2016 18:08:54
//

unit sql.Connection.DataSnap.Proxy;

interface

uses System.JSON, Data.DBXCommon, Data.DBXClient, Data.DBXDataSnap, Data.DBXJSON, Datasnap.DSProxy, System.Classes, System.SysUtils, Data.DB, Data.SqlExpr, Data.DBXDBReaders, Data.DBXCDSReaders, System.Generics.Collections, Data.DBXJSONReflect;

type
  TServerDataBaseClient = class(TDSAdminClient)
  private
    FEchoStringCommand: TDBXCommand;
    FIsStartCommand: TDBXCommand;
    FStartCommand: TDBXCommand;
    FCommitCommand: TDBXCommand;
    FRollbackCommand: TDBXCommand;
    FExecuteCommand: TDBXCommand;
    FExecute1Command: TDBXCommand;
    FExecute2Command: TDBXCommand;
    FOpenCommand: TDBXCommand;
    FOpen1Command: TDBXCommand;
    FOpen2Command: TDBXCommand;
    FOpenQryCommand: TDBXCommand;
    FOpenExecCommand: TDBXCommand;
    FOpenExec1Command: TDBXCommand;
    FOpenExec2Command: TDBXCommand;
  public
    constructor Create(ADBXConnection: TDBXConnection); overload;
    constructor Create(ADBXConnection: TDBXConnection; AInstanceOwner: Boolean); overload;
    destructor Destroy; override;
    function EchoString(Value: string): string;
    function IsStart(Transact: Integer): Boolean;
    function Start(Transact: Integer): Boolean;
    function Commit(Transact: Integer): Boolean;
    function Rollback(Transact: Integer): Boolean;
    function Execute(Value: string): Boolean;
    function Execute1(Value: TStrings): Boolean;
    function Execute2(Value: TStrings; Blobs: TList<System.TArray<System.Byte>>): Boolean;
    function Open(Value: string): TDataSet;
    function Open1(Value: TStrings): TDataSet;
    function Open2(Value: TStrings; Blobs: TList<System.TArray<System.Byte>>): TDataSet;
    function OpenQry(Value: string): TDataSet;
    function OpenExec(Value: string): TDataSet;
    function OpenExec1(Value: TStrings): TDataSet;
    function OpenExec2(Value: TStrings; Blobs: TList<System.TArray<System.Byte>>): TDataSet;
  end;

  TServerGourmetClient = class(TDSAdminClient)
  private
    FGetTipoCommand: TDBXCommand;
    FGetSysTipoCommand: TDBXCommand;
    FGetListEmpresaCommand: TDBXCommand;
    FGetPessoaCommand: TDBXCommand;
    FGetListPessoaCommand: TDBXCommand;
    FGetListProdutoServicoCommand: TDBXCommand;
    FGetListSysUsuarioCommand: TDBXCommand;
    FGetListConsumacaoCommand: TDBXCommand;
    FGetListClassificacaoCommand: TDBXCommand;
    FGetProdServCommand: TDBXCommand;
    FGetProdServClassificacaoCommand: TDBXCommand;
    FGetProdServReceitaCommand: TDBXCommand;
    FGetProdServPreparoCommand: TDBXCommand;
    FGetProdServGourmetCommand: TDBXCommand;
    FGetProdServPizzaCommand: TDBXCommand;
    FGetConsumacaoModificadoCommand: TDBXCommand;
    FGetConsumacaoStatusCommand: TDBXCommand;
    FGetGourmetCommand: TDBXCommand;
    FPostGourmetCommand: TDBXCommand;
    FPrintGourmetCommand: TDBXCommand;
  public
    constructor Create(ADBXConnection: TDBXConnection); overload;
    constructor Create(ADBXConnection: TDBXConnection; AInstanceOwner: Boolean); overload;
    destructor Destroy; override;
    function GetTipo(Value: Integer): TJSONValue;
    function GetSysTipo(Value: Integer): TJSONValue;
    function GetListEmpresa: TJSONValue;
    function GetPessoa(Value: Integer): TJSONValue;
    function GetListPessoa(Filter: string): TJSONValue;
    function GetListProdutoServico(Filter: string): TJSONValue;
    function GetListSysUsuario(Empresa: Integer; Value: Integer): TJSONValue;
    function GetListConsumacao(Empresa: Integer): TJSONValue;
    function GetListClassificacao: TJSONValue;
    function GetProdServ(Value: Integer): TJSONValue;
    function GetProdServClassificacao(Empresa: Integer; Classificacao: Integer): TJSONValue;
    function GetProdServReceita(Value: Integer): TJSONValue;
    function GetProdServPreparo(Value: Integer): TJSONValue;
    function GetProdServGourmet(Value: Integer): TJSONValue;
    function GetProdServPizza(Value: TJSONValue): TJSONValue;
    function GetConsumacaoModificado(ID: Integer; Value: Boolean): TJSONValue;
    function GetConsumacaoStatus(Empresa: Integer; ID: Integer; Codigo: string; Referencia: string): TJSONValue;
    function GetGourmet(Value: Integer): TJSONValue;
    function PostGourmet(Value: TJSONValue): TJSONValue;
    procedure PrintGourmet(Value: Integer);
  end;

  TServerLicenseClient = class(TDSAdminClient)
  private
    FUploadCommand: TDBXCommand;
  public
    constructor Create(ADBXConnection: TDBXConnection); overload;
    constructor Create(ADBXConnection: TDBXConnection; AInstanceOwner: Boolean); overload;
    destructor Destroy; override;
    function Upload(FileName: string; var Size: Int64): TStream;
  end;

implementation

function TServerDataBaseClient.EchoString(Value: string): string;
begin
  if FEchoStringCommand = nil then
  begin
    FEchoStringCommand := FDBXConnection.CreateCommand;
    FEchoStringCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FEchoStringCommand.Text := 'TServerDataBase.EchoString';
    FEchoStringCommand.Prepare;
  end;
  FEchoStringCommand.Parameters[0].Value.SetWideString(Value);
  FEchoStringCommand.ExecuteUpdate;
  Result := FEchoStringCommand.Parameters[1].Value.GetWideString;
end;

function TServerDataBaseClient.IsStart(Transact: Integer): Boolean;
begin
  if FIsStartCommand = nil then
  begin
    FIsStartCommand := FDBXConnection.CreateCommand;
    FIsStartCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FIsStartCommand.Text := 'TServerDataBase.IsStart';
    FIsStartCommand.Prepare;
  end;
  FIsStartCommand.Parameters[0].Value.SetInt32(Transact);
  FIsStartCommand.ExecuteUpdate;
  Result := FIsStartCommand.Parameters[1].Value.GetBoolean;
end;

function TServerDataBaseClient.Start(Transact: Integer): Boolean;
begin
  if FStartCommand = nil then
  begin
    FStartCommand := FDBXConnection.CreateCommand;
    FStartCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FStartCommand.Text := 'TServerDataBase.Start';
    FStartCommand.Prepare;
  end;
  FStartCommand.Parameters[0].Value.SetInt32(Transact);
  FStartCommand.ExecuteUpdate;
  Result := FStartCommand.Parameters[1].Value.GetBoolean;
end;

function TServerDataBaseClient.Commit(Transact: Integer): Boolean;
begin
  if FCommitCommand = nil then
  begin
    FCommitCommand := FDBXConnection.CreateCommand;
    FCommitCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FCommitCommand.Text := 'TServerDataBase.Commit';
    FCommitCommand.Prepare;
  end;
  FCommitCommand.Parameters[0].Value.SetInt32(Transact);
  FCommitCommand.ExecuteUpdate;
  Result := FCommitCommand.Parameters[1].Value.GetBoolean;
end;

function TServerDataBaseClient.Rollback(Transact: Integer): Boolean;
begin
  if FRollbackCommand = nil then
  begin
    FRollbackCommand := FDBXConnection.CreateCommand;
    FRollbackCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FRollbackCommand.Text := 'TServerDataBase.Rollback';
    FRollbackCommand.Prepare;
  end;
  FRollbackCommand.Parameters[0].Value.SetInt32(Transact);
  FRollbackCommand.ExecuteUpdate;
  Result := FRollbackCommand.Parameters[1].Value.GetBoolean;
end;

function TServerDataBaseClient.Execute(Value: string): Boolean;
begin
  if FExecuteCommand = nil then
  begin
    FExecuteCommand := FDBXConnection.CreateCommand;
    FExecuteCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FExecuteCommand.Text := 'TServerDataBase.Execute';
    FExecuteCommand.Prepare;
  end;
  FExecuteCommand.Parameters[0].Value.SetWideString(Value);
  FExecuteCommand.ExecuteUpdate;
  Result := FExecuteCommand.Parameters[1].Value.GetBoolean;
end;

function TServerDataBaseClient.Execute1(Value: TStrings): Boolean;
begin
  if FExecute1Command = nil then
  begin
    FExecute1Command := FDBXConnection.CreateCommand;
    FExecute1Command.CommandType := TDBXCommandTypes.DSServerMethod;
    FExecute1Command.Text := 'TServerDataBase.Execute1';
    FExecute1Command.Prepare;
  end;
  if not Assigned(Value) then
    FExecute1Command.Parameters[0].Value.SetNull
  else
  begin
    FMarshal := TDBXClientCommand(FExecute1Command.Parameters[0].ConnectionHandler).GetJSONMarshaler;
    try
      FExecute1Command.Parameters[0].Value.SetJSONValue(FMarshal.Marshal(Value), True);
      if FInstanceOwner then
        Value.Free
    finally
      FreeAndNil(FMarshal)
    end
    end;
  FExecute1Command.ExecuteUpdate;
  Result := FExecute1Command.Parameters[1].Value.GetBoolean;
end;

function TServerDataBaseClient.Execute2(Value: TStrings; Blobs: TList<System.TArray<System.Byte>>): Boolean;
begin
  if FExecute2Command = nil then
  begin
    FExecute2Command := FDBXConnection.CreateCommand;
    FExecute2Command.CommandType := TDBXCommandTypes.DSServerMethod;
    FExecute2Command.Text := 'TServerDataBase.Execute2';
    FExecute2Command.Prepare;
  end;
  if not Assigned(Value) then
    FExecute2Command.Parameters[0].Value.SetNull
  else
  begin
    FMarshal := TDBXClientCommand(FExecute2Command.Parameters[0].ConnectionHandler).GetJSONMarshaler;
    try
      FExecute2Command.Parameters[0].Value.SetJSONValue(FMarshal.Marshal(Value), True);
      if FInstanceOwner then
        Value.Free
    finally
      FreeAndNil(FMarshal)
    end
    end;
  if not Assigned(Blobs) then
    FExecute2Command.Parameters[1].Value.SetNull
  else
  begin
    FMarshal := TDBXClientCommand(FExecute2Command.Parameters[1].ConnectionHandler).GetJSONMarshaler;
    try
      FExecute2Command.Parameters[1].Value.SetJSONValue(FMarshal.Marshal(Blobs), True);
      if FInstanceOwner then
        Blobs.Free
    finally
      FreeAndNil(FMarshal)
    end
    end;
  FExecute2Command.ExecuteUpdate;
  Result := FExecute2Command.Parameters[2].Value.GetBoolean;
end;

function TServerDataBaseClient.Open(Value: string): TDataSet;
begin
  if FOpenCommand = nil then
  begin
    FOpenCommand := FDBXConnection.CreateCommand;
    FOpenCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FOpenCommand.Text := 'TServerDataBase.Open';
    FOpenCommand.Prepare;
  end;
  FOpenCommand.Parameters[0].Value.SetWideString(Value);
  FOpenCommand.ExecuteUpdate;
  Result := TCustomSQLDataSet.Create(nil, FOpenCommand.Parameters[1].Value.GetDBXReader(False), True);
  Result.Open;
  if FInstanceOwner then
    FOpenCommand.FreeOnExecute(Result);
end;

function TServerDataBaseClient.Open1(Value: TStrings): TDataSet;
begin
  if FOpen1Command = nil then
  begin
    FOpen1Command := FDBXConnection.CreateCommand;
    FOpen1Command.CommandType := TDBXCommandTypes.DSServerMethod;
    FOpen1Command.Text := 'TServerDataBase.Open1';
    FOpen1Command.Prepare;
  end;
  if not Assigned(Value) then
    FOpen1Command.Parameters[0].Value.SetNull
  else
  begin
    FMarshal := TDBXClientCommand(FOpen1Command.Parameters[0].ConnectionHandler).GetJSONMarshaler;
    try
      FOpen1Command.Parameters[0].Value.SetJSONValue(FMarshal.Marshal(Value), True);
      if FInstanceOwner then
        Value.Free
    finally
      FreeAndNil(FMarshal)
    end
    end;
  FOpen1Command.ExecuteUpdate;
  Result := TCustomSQLDataSet.Create(nil, FOpen1Command.Parameters[1].Value.GetDBXReader(False), True);
  Result.Open;
  if FInstanceOwner then
    FOpen1Command.FreeOnExecute(Result);
end;

function TServerDataBaseClient.Open2(Value: TStrings; Blobs: TList<System.TArray<System.Byte>>): TDataSet;
begin
  if FOpen2Command = nil then
  begin
    FOpen2Command := FDBXConnection.CreateCommand;
    FOpen2Command.CommandType := TDBXCommandTypes.DSServerMethod;
    FOpen2Command.Text := 'TServerDataBase.Open2';
    FOpen2Command.Prepare;
  end;
  if not Assigned(Value) then
    FOpen2Command.Parameters[0].Value.SetNull
  else
  begin
    FMarshal := TDBXClientCommand(FOpen2Command.Parameters[0].ConnectionHandler).GetJSONMarshaler;
    try
      FOpen2Command.Parameters[0].Value.SetJSONValue(FMarshal.Marshal(Value), True);
      if FInstanceOwner then
        Value.Free
    finally
      FreeAndNil(FMarshal)
    end
    end;
  if not Assigned(Blobs) then
    FOpen2Command.Parameters[1].Value.SetNull
  else
  begin
    FMarshal := TDBXClientCommand(FOpen2Command.Parameters[1].ConnectionHandler).GetJSONMarshaler;
    try
      FOpen2Command.Parameters[1].Value.SetJSONValue(FMarshal.Marshal(Blobs), True);
      if FInstanceOwner then
        Blobs.Free
    finally
      FreeAndNil(FMarshal)
    end
    end;
  FOpen2Command.ExecuteUpdate;
  Result := TCustomSQLDataSet.Create(nil, FOpen2Command.Parameters[2].Value.GetDBXReader(False), True);
  Result.Open;
  if FInstanceOwner then
    FOpen2Command.FreeOnExecute(Result);
end;

function TServerDataBaseClient.OpenQry(Value: string): TDataSet;
begin
  if FOpenQryCommand = nil then
  begin
    FOpenQryCommand := FDBXConnection.CreateCommand;
    FOpenQryCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FOpenQryCommand.Text := 'TServerDataBase.OpenQry';
    FOpenQryCommand.Prepare;
  end;
  FOpenQryCommand.Parameters[0].Value.SetWideString(Value);
  FOpenQryCommand.ExecuteUpdate;
  Result := TCustomSQLDataSet.Create(nil, FOpenQryCommand.Parameters[1].Value.GetDBXReader(False), True);
  Result.Open;
  if FInstanceOwner then
    FOpenQryCommand.FreeOnExecute(Result);
end;

function TServerDataBaseClient.OpenExec(Value: string): TDataSet;
begin
  if FOpenExecCommand = nil then
  begin
    FOpenExecCommand := FDBXConnection.CreateCommand;
    FOpenExecCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FOpenExecCommand.Text := 'TServerDataBase.OpenExec';
    FOpenExecCommand.Prepare;
  end;
  FOpenExecCommand.Parameters[0].Value.SetWideString(Value);
  FOpenExecCommand.ExecuteUpdate;
  Result := TCustomSQLDataSet.Create(nil, FOpenExecCommand.Parameters[1].Value.GetDBXReader(False), True);
  Result.Open;
  if FInstanceOwner then
    FOpenExecCommand.FreeOnExecute(Result);
end;

function TServerDataBaseClient.OpenExec1(Value: TStrings): TDataSet;
begin
  if FOpenExec1Command = nil then
  begin
    FOpenExec1Command := FDBXConnection.CreateCommand;
    FOpenExec1Command.CommandType := TDBXCommandTypes.DSServerMethod;
    FOpenExec1Command.Text := 'TServerDataBase.OpenExec1';
    FOpenExec1Command.Prepare;
  end;
  if not Assigned(Value) then
    FOpenExec1Command.Parameters[0].Value.SetNull
  else
  begin
    FMarshal := TDBXClientCommand(FOpenExec1Command.Parameters[0].ConnectionHandler).GetJSONMarshaler;
    try
      FOpenExec1Command.Parameters[0].Value.SetJSONValue(FMarshal.Marshal(Value), True);
      if FInstanceOwner then
        Value.Free
    finally
      FreeAndNil(FMarshal)
    end
    end;
  FOpenExec1Command.ExecuteUpdate;
  Result := TCustomSQLDataSet.Create(nil, FOpenExec1Command.Parameters[1].Value.GetDBXReader(False), True);
  Result.Open;
  if FInstanceOwner then
    FOpenExec1Command.FreeOnExecute(Result);
end;

function TServerDataBaseClient.OpenExec2(Value: TStrings; Blobs: TList<System.TArray<System.Byte>>): TDataSet;
begin
  if FOpenExec2Command = nil then
  begin
    FOpenExec2Command := FDBXConnection.CreateCommand;
    FOpenExec2Command.CommandType := TDBXCommandTypes.DSServerMethod;
    FOpenExec2Command.Text := 'TServerDataBase.OpenExec2';
    FOpenExec2Command.Prepare;
  end;
  if not Assigned(Value) then
    FOpenExec2Command.Parameters[0].Value.SetNull
  else
  begin
    FMarshal := TDBXClientCommand(FOpenExec2Command.Parameters[0].ConnectionHandler).GetJSONMarshaler;
    try
      FOpenExec2Command.Parameters[0].Value.SetJSONValue(FMarshal.Marshal(Value), True);
      if FInstanceOwner then
        Value.Free
    finally
      FreeAndNil(FMarshal)
    end
    end;
  if not Assigned(Blobs) then
    FOpenExec2Command.Parameters[1].Value.SetNull
  else
  begin
    FMarshal := TDBXClientCommand(FOpenExec2Command.Parameters[1].ConnectionHandler).GetJSONMarshaler;
    try
      FOpenExec2Command.Parameters[1].Value.SetJSONValue(FMarshal.Marshal(Blobs), True);
      if FInstanceOwner then
        Blobs.Free
    finally
      FreeAndNil(FMarshal)
    end
    end;
  FOpenExec2Command.ExecuteUpdate;
  Result := TCustomSQLDataSet.Create(nil, FOpenExec2Command.Parameters[2].Value.GetDBXReader(False), True);
  Result.Open;
  if FInstanceOwner then
    FOpenExec2Command.FreeOnExecute(Result);
end;


constructor TServerDataBaseClient.Create(ADBXConnection: TDBXConnection);
begin
  inherited Create(ADBXConnection);
end;


constructor TServerDataBaseClient.Create(ADBXConnection: TDBXConnection; AInstanceOwner: Boolean);
begin
  inherited Create(ADBXConnection, AInstanceOwner);
end;


destructor TServerDataBaseClient.Destroy;
begin
  FEchoStringCommand.DisposeOf;
  FIsStartCommand.DisposeOf;
  FStartCommand.DisposeOf;
  FCommitCommand.DisposeOf;
  FRollbackCommand.DisposeOf;
  FExecuteCommand.DisposeOf;
  FExecute1Command.DisposeOf;
  FExecute2Command.DisposeOf;
  FOpenCommand.DisposeOf;
  FOpen1Command.DisposeOf;
  FOpen2Command.DisposeOf;
  FOpenQryCommand.DisposeOf;
  FOpenExecCommand.DisposeOf;
  FOpenExec1Command.DisposeOf;
  FOpenExec2Command.DisposeOf;
  inherited;
end;

function TServerGourmetClient.GetTipo(Value: Integer): TJSONValue;
begin
  if FGetTipoCommand = nil then
  begin
    FGetTipoCommand := FDBXConnection.CreateCommand;
    FGetTipoCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetTipoCommand.Text := 'TServerGourmet.GetTipo';
    FGetTipoCommand.Prepare;
  end;
  FGetTipoCommand.Parameters[0].Value.SetInt32(Value);
  FGetTipoCommand.ExecuteUpdate;
  Result := TJSONValue(FGetTipoCommand.Parameters[1].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetSysTipo(Value: Integer): TJSONValue;
begin
  if FGetSysTipoCommand = nil then
  begin
    FGetSysTipoCommand := FDBXConnection.CreateCommand;
    FGetSysTipoCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetSysTipoCommand.Text := 'TServerGourmet.GetSysTipo';
    FGetSysTipoCommand.Prepare;
  end;
  FGetSysTipoCommand.Parameters[0].Value.SetInt32(Value);
  FGetSysTipoCommand.ExecuteUpdate;
  Result := TJSONValue(FGetSysTipoCommand.Parameters[1].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetListEmpresa: TJSONValue;
begin
  if FGetListEmpresaCommand = nil then
  begin
    FGetListEmpresaCommand := FDBXConnection.CreateCommand;
    FGetListEmpresaCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetListEmpresaCommand.Text := 'TServerGourmet.GetListEmpresa';
    FGetListEmpresaCommand.Prepare;
  end;
  FGetListEmpresaCommand.ExecuteUpdate;
  Result := TJSONValue(FGetListEmpresaCommand.Parameters[0].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetPessoa(Value: Integer): TJSONValue;
begin
  if FGetPessoaCommand = nil then
  begin
    FGetPessoaCommand := FDBXConnection.CreateCommand;
    FGetPessoaCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetPessoaCommand.Text := 'TServerGourmet.GetPessoa';
    FGetPessoaCommand.Prepare;
  end;
  FGetPessoaCommand.Parameters[0].Value.SetInt32(Value);
  FGetPessoaCommand.ExecuteUpdate;
  Result := TJSONValue(FGetPessoaCommand.Parameters[1].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetListPessoa(Filter: string): TJSONValue;
begin
  if FGetListPessoaCommand = nil then
  begin
    FGetListPessoaCommand := FDBXConnection.CreateCommand;
    FGetListPessoaCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetListPessoaCommand.Text := 'TServerGourmet.GetListPessoa';
    FGetListPessoaCommand.Prepare;
  end;
  FGetListPessoaCommand.Parameters[0].Value.SetWideString(Filter);
  FGetListPessoaCommand.ExecuteUpdate;
  Result := TJSONValue(FGetListPessoaCommand.Parameters[1].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetListProdutoServico(Filter: string): TJSONValue;
begin
  if FGetListProdutoServicoCommand = nil then
  begin
    FGetListProdutoServicoCommand := FDBXConnection.CreateCommand;
    FGetListProdutoServicoCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetListProdutoServicoCommand.Text := 'TServerGourmet.GetListProdutoServico';
    FGetListProdutoServicoCommand.Prepare;
  end;
  FGetListProdutoServicoCommand.Parameters[0].Value.SetWideString(Filter);
  FGetListProdutoServicoCommand.ExecuteUpdate;
  Result := TJSONValue(FGetListProdutoServicoCommand.Parameters[1].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetListSysUsuario(Empresa: Integer; Value: Integer): TJSONValue;
begin
  if FGetListSysUsuarioCommand = nil then
  begin
    FGetListSysUsuarioCommand := FDBXConnection.CreateCommand;
    FGetListSysUsuarioCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetListSysUsuarioCommand.Text := 'TServerGourmet.GetListSysUsuario';
    FGetListSysUsuarioCommand.Prepare;
  end;
  FGetListSysUsuarioCommand.Parameters[0].Value.SetInt32(Empresa);
  FGetListSysUsuarioCommand.Parameters[1].Value.SetInt32(Value);
  FGetListSysUsuarioCommand.ExecuteUpdate;
  Result := TJSONValue(FGetListSysUsuarioCommand.Parameters[2].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetListConsumacao(Empresa: Integer): TJSONValue;
begin
  if FGetListConsumacaoCommand = nil then
  begin
    FGetListConsumacaoCommand := FDBXConnection.CreateCommand;
    FGetListConsumacaoCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetListConsumacaoCommand.Text := 'TServerGourmet.GetListConsumacao';
    FGetListConsumacaoCommand.Prepare;
  end;
  FGetListConsumacaoCommand.Parameters[0].Value.SetInt32(Empresa);
  FGetListConsumacaoCommand.ExecuteUpdate;
  Result := TJSONValue(FGetListConsumacaoCommand.Parameters[1].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetListClassificacao: TJSONValue;
begin
  if FGetListClassificacaoCommand = nil then
  begin
    FGetListClassificacaoCommand := FDBXConnection.CreateCommand;
    FGetListClassificacaoCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetListClassificacaoCommand.Text := 'TServerGourmet.GetListClassificacao';
    FGetListClassificacaoCommand.Prepare;
  end;
  FGetListClassificacaoCommand.ExecuteUpdate;
  Result := TJSONValue(FGetListClassificacaoCommand.Parameters[0].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetProdServ(Value: Integer): TJSONValue;
begin
  if FGetProdServCommand = nil then
  begin
    FGetProdServCommand := FDBXConnection.CreateCommand;
    FGetProdServCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetProdServCommand.Text := 'TServerGourmet.GetProdServ';
    FGetProdServCommand.Prepare;
  end;
  FGetProdServCommand.Parameters[0].Value.SetInt32(Value);
  FGetProdServCommand.ExecuteUpdate;
  Result := TJSONValue(FGetProdServCommand.Parameters[1].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetProdServClassificacao(Empresa: Integer; Classificacao: Integer): TJSONValue;
begin
  if FGetProdServClassificacaoCommand = nil then
  begin
    FGetProdServClassificacaoCommand := FDBXConnection.CreateCommand;
    FGetProdServClassificacaoCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetProdServClassificacaoCommand.Text := 'TServerGourmet.GetProdServClassificacao';
    FGetProdServClassificacaoCommand.Prepare;
  end;
  FGetProdServClassificacaoCommand.Parameters[0].Value.SetInt32(Empresa);
  FGetProdServClassificacaoCommand.Parameters[1].Value.SetInt32(Classificacao);
  FGetProdServClassificacaoCommand.ExecuteUpdate;
  Result := TJSONValue(FGetProdServClassificacaoCommand.Parameters[2].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetProdServReceita(Value: Integer): TJSONValue;
begin
  if FGetProdServReceitaCommand = nil then
  begin
    FGetProdServReceitaCommand := FDBXConnection.CreateCommand;
    FGetProdServReceitaCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetProdServReceitaCommand.Text := 'TServerGourmet.GetProdServReceita';
    FGetProdServReceitaCommand.Prepare;
  end;
  FGetProdServReceitaCommand.Parameters[0].Value.SetInt32(Value);
  FGetProdServReceitaCommand.ExecuteUpdate;
  Result := TJSONValue(FGetProdServReceitaCommand.Parameters[1].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetProdServPreparo(Value: Integer): TJSONValue;
begin
  if FGetProdServPreparoCommand = nil then
  begin
    FGetProdServPreparoCommand := FDBXConnection.CreateCommand;
    FGetProdServPreparoCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetProdServPreparoCommand.Text := 'TServerGourmet.GetProdServPreparo';
    FGetProdServPreparoCommand.Prepare;
  end;
  FGetProdServPreparoCommand.Parameters[0].Value.SetInt32(Value);
  FGetProdServPreparoCommand.ExecuteUpdate;
  Result := TJSONValue(FGetProdServPreparoCommand.Parameters[1].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetProdServGourmet(Value: Integer): TJSONValue;
begin
  if FGetProdServGourmetCommand = nil then
  begin
    FGetProdServGourmetCommand := FDBXConnection.CreateCommand;
    FGetProdServGourmetCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetProdServGourmetCommand.Text := 'TServerGourmet.GetProdServGourmet';
    FGetProdServGourmetCommand.Prepare;
  end;
  FGetProdServGourmetCommand.Parameters[0].Value.SetInt32(Value);
  FGetProdServGourmetCommand.ExecuteUpdate;
  Result := TJSONValue(FGetProdServGourmetCommand.Parameters[1].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetProdServPizza(Value: TJSONValue): TJSONValue;
begin
  if FGetProdServPizzaCommand = nil then
  begin
    FGetProdServPizzaCommand := FDBXConnection.CreateCommand;
    FGetProdServPizzaCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetProdServPizzaCommand.Text := 'TServerGourmet.GetProdServPizza';
    FGetProdServPizzaCommand.Prepare;
  end;
  FGetProdServPizzaCommand.Parameters[0].Value.SetJSONValue(Value, FInstanceOwner);
  FGetProdServPizzaCommand.ExecuteUpdate;
  Result := TJSONValue(FGetProdServPizzaCommand.Parameters[1].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetConsumacaoModificado(ID: Integer; Value: Boolean): TJSONValue;
begin
  if FGetConsumacaoModificadoCommand = nil then
  begin
    FGetConsumacaoModificadoCommand := FDBXConnection.CreateCommand;
    FGetConsumacaoModificadoCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetConsumacaoModificadoCommand.Text := 'TServerGourmet.GetConsumacaoModificado';
    FGetConsumacaoModificadoCommand.Prepare;
  end;
  FGetConsumacaoModificadoCommand.Parameters[0].Value.SetInt32(ID);
  FGetConsumacaoModificadoCommand.Parameters[1].Value.SetBoolean(Value);
  FGetConsumacaoModificadoCommand.ExecuteUpdate;
  Result := TJSONValue(FGetConsumacaoModificadoCommand.Parameters[2].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetConsumacaoStatus(Empresa: Integer; ID: Integer; Codigo: string; Referencia: string): TJSONValue;
begin
  if FGetConsumacaoStatusCommand = nil then
  begin
    FGetConsumacaoStatusCommand := FDBXConnection.CreateCommand;
    FGetConsumacaoStatusCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetConsumacaoStatusCommand.Text := 'TServerGourmet.GetConsumacaoStatus';
    FGetConsumacaoStatusCommand.Prepare;
  end;
  FGetConsumacaoStatusCommand.Parameters[0].Value.SetInt32(Empresa);
  FGetConsumacaoStatusCommand.Parameters[1].Value.SetInt32(ID);
  FGetConsumacaoStatusCommand.Parameters[2].Value.SetWideString(Codigo);
  FGetConsumacaoStatusCommand.Parameters[3].Value.SetWideString(Referencia);
  FGetConsumacaoStatusCommand.ExecuteUpdate;
  Result := TJSONValue(FGetConsumacaoStatusCommand.Parameters[4].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.GetGourmet(Value: Integer): TJSONValue;
begin
  if FGetGourmetCommand = nil then
  begin
    FGetGourmetCommand := FDBXConnection.CreateCommand;
    FGetGourmetCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FGetGourmetCommand.Text := 'TServerGourmet.GetGourmet';
    FGetGourmetCommand.Prepare;
  end;
  FGetGourmetCommand.Parameters[0].Value.SetInt32(Value);
  FGetGourmetCommand.ExecuteUpdate;
  Result := TJSONValue(FGetGourmetCommand.Parameters[1].Value.GetJSONValue(FInstanceOwner));
end;

function TServerGourmetClient.PostGourmet(Value: TJSONValue): TJSONValue;
begin
  if FPostGourmetCommand = nil then
  begin
    FPostGourmetCommand := FDBXConnection.CreateCommand;
    FPostGourmetCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FPostGourmetCommand.Text := 'TServerGourmet.PostGourmet';
    FPostGourmetCommand.Prepare;
  end;
  FPostGourmetCommand.Parameters[0].Value.SetJSONValue(Value, FInstanceOwner);
  FPostGourmetCommand.ExecuteUpdate;
  Result := TJSONValue(FPostGourmetCommand.Parameters[1].Value.GetJSONValue(FInstanceOwner));
end;

procedure TServerGourmetClient.PrintGourmet(Value: Integer);
begin
  if FPrintGourmetCommand = nil then
  begin
    FPrintGourmetCommand := FDBXConnection.CreateCommand;
    FPrintGourmetCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FPrintGourmetCommand.Text := 'TServerGourmet.PrintGourmet';
    FPrintGourmetCommand.Prepare;
  end;
  FPrintGourmetCommand.Parameters[0].Value.SetInt32(Value);
  FPrintGourmetCommand.ExecuteUpdate;
end;


constructor TServerGourmetClient.Create(ADBXConnection: TDBXConnection);
begin
  inherited Create(ADBXConnection);
end;


constructor TServerGourmetClient.Create(ADBXConnection: TDBXConnection; AInstanceOwner: Boolean);
begin
  inherited Create(ADBXConnection, AInstanceOwner);
end;


destructor TServerGourmetClient.Destroy;
begin
  FGetTipoCommand.DisposeOf;
  FGetSysTipoCommand.DisposeOf;
  FGetListEmpresaCommand.DisposeOf;
  FGetPessoaCommand.DisposeOf;
  FGetListPessoaCommand.DisposeOf;
  FGetListProdutoServicoCommand.DisposeOf;
  FGetListSysUsuarioCommand.DisposeOf;
  FGetListConsumacaoCommand.DisposeOf;
  FGetListClassificacaoCommand.DisposeOf;
  FGetProdServCommand.DisposeOf;
  FGetProdServClassificacaoCommand.DisposeOf;
  FGetProdServReceitaCommand.DisposeOf;
  FGetProdServPreparoCommand.DisposeOf;
  FGetProdServGourmetCommand.DisposeOf;
  FGetProdServPizzaCommand.DisposeOf;
  FGetConsumacaoModificadoCommand.DisposeOf;
  FGetConsumacaoStatusCommand.DisposeOf;
  FGetGourmetCommand.DisposeOf;
  FPostGourmetCommand.DisposeOf;
  FPrintGourmetCommand.DisposeOf;
  inherited;
end;

function TServerLicenseClient.Upload(FileName: string; var Size: Int64): TStream;
begin
  if FUploadCommand = nil then
  begin
    FUploadCommand := FDBXConnection.CreateCommand;
    FUploadCommand.CommandType := TDBXCommandTypes.DSServerMethod;
    FUploadCommand.Text := 'TServerLicense.Upload';
    FUploadCommand.Prepare;
  end;
  FUploadCommand.Parameters[0].Value.SetWideString(FileName);
  FUploadCommand.Parameters[1].Value.SetInt64(Size);
  FUploadCommand.ExecuteUpdate;
  Size := FUploadCommand.Parameters[1].Value.GetInt64;
  Result := FUploadCommand.Parameters[2].Value.GetStream(FInstanceOwner);
end;


constructor TServerLicenseClient.Create(ADBXConnection: TDBXConnection);
begin
  inherited Create(ADBXConnection);
end;


constructor TServerLicenseClient.Create(ADBXConnection: TDBXConnection; AInstanceOwner: Boolean);
begin
  inherited Create(ADBXConnection, AInstanceOwner);
end;


destructor TServerLicenseClient.Destroy;
begin
  FUploadCommand.DisposeOf;
  inherited;
end;

end.


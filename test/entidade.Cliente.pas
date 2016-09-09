unit entidade.Cliente;

interface

uses System.SysUtils, System.Generics.Collections,
     orm.attributes, orm.attributes.types, orm.lazyload,
     entidade.Cliente.Endereco;

type
   [Table('CLIENTE')]
   TCliente = Class
   Private
     [Column('ID',[ftPrimaryKey,ftAuto])]
     FID : Integer;

     [Column('DATA',[ftAuto,ftReadOnly])]
     FData : TDateTime;

     [Column('NOME',60)]
     FNome : String;

     [Foreign('CLIENTE')]
     FEnderecos : TLazyLoad<TClienteEndereco>;

     function GetEnderecos : TObjectList<TClienteEndereco>;

   Public
     Constructor Create;
     Destructor Destroy; Override;

     property ID   : Integer   Read FID;
     property Data : TDateTime Read FData;
     property Nome : String    Read FNome Write FNome;

     property Enderecos : TObjectList<TClienteEndereco> Read GetEnderecos;
   End;

implementation

{ TCliente }

constructor TCliente.Create;
begin
   FEnderecos := TLazyLoad<TClienteEndereco>.Create;
end;

destructor TCliente.Destroy;
begin
   FreeAndNil(FEnderecos);
   inherited;
end;

function TCliente.GetEnderecos: TObjectList<TClienteEndereco>;
begin
   Result := FEnderecos.ValueAll;
end;

end.

unit entidade.Cliente.Endereco;

interface

uses orm.attributes, orm.attributes.types;

type
   [Table('CLIENTE_ENDERECO')]
   TClienteEndereco = Class
   Private
     [Column('ID',[ftPrimaryKey,ftAuto])]
     FID : Integer;

     [Column('DATAHORA',[ftAuto,ftReadOnly])]
     FDataHora : TDateTime;

     [Column('LOGRADOURO',60)]
     FLogradouro : String;

     [Column('NUMERO',05)]
     FNumero : String;

     [Column('BAIRRO',60)]
     FBairro : String;
   Public
     property ID         : Integer   Read FID;
     property DataHora   : TDateTime Read FDataHora;
     property Logradouro : String    Read FLogradouro Write FLogradouro;
     property Numero     : String    Read FNumero     Write FNumero;
     property Bairro     : String    Read FBairro     Write FBairro;
   End;

implementation

end.

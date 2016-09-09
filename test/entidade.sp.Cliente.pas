unit entidade.sp.Cliente;

interface

uses System.Classes, System.SysUtils, System.DateUtils,
     orm.attributes, orm.attributes.types;

type
   [StoredProcedure('SP_CLIENTE')]
   TSPCliente = Class
   Private
     [Column('ID',[ptInPut],[])]
     FID : Integer;

     [Column('NOME')]
     FNome : String;
   Public
     property ID   : Integer  Read FID   Write FID;
     property Nome : String   Read FNome;
   End;

implementation

end.

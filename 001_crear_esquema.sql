/* =====================================================================
   Tras las Rejas - Script 001: Esquema de base de datos
   Motor: SQL Server Express / LocalDB
   Idempotente: se puede ejecutar varias veces sin error.

   NOTA: si ya tenias la base de datos creada con la version anterior,
   este script NO modifica tablas existentes. Como es un prototipo, lo
   mas simple es descartarla y recrearla:
       USE master; ALTER DATABASE TrasLasRejas SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
       DROP DATABASE TrasLasRejas;
   ===================================================================== */

IF DB_ID(N'TrasLasRejas') IS NULL
    CREATE DATABASE TrasLasRejas;
GO

USE TrasLasRejas;
GO

/* ---------------------------------------------------------------------
   Control de versiones de scripts
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.VersionEsquema', N'U') IS NULL
CREATE TABLE dbo.VersionEsquema
(
    Version      INT           NOT NULL CONSTRAINT PK_VersionEsquema PRIMARY KEY,
    Descripcion  NVARCHAR(200) NOT NULL,
    AplicadoEn   DATETIME2(0)  NOT NULL CONSTRAINT DF_VersionEsquema_AplicadoEn DEFAULT SYSDATETIME()
);
GO

/* ---------------------------------------------------------------------
   Usuarios (cajas / cajeros). Simple: el prototipo usa un usuario fijo.
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Usuarios', N'U') IS NULL
CREATE TABLE dbo.Usuarios
(
    Id      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Usuarios PRIMARY KEY,
    Nombre  NVARCHAR(100)     NOT NULL,
    Activo  BIT               NOT NULL CONSTRAINT DF_Usuarios_Activo DEFAULT 1
);
GO

/* ---------------------------------------------------------------------
   Catalogos: Tamanos, Sabores, Toppings, Productos
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Tamanos', N'U') IS NULL
CREATE TABLE dbo.Tamanos
(
    Id               INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Tamanos PRIMARY KEY,
    Nombre           NVARCHAR(30)      NOT NULL CONSTRAINT UQ_Tamanos_Nombre UNIQUE,
    CostoAdicional   DECIMAL(10,2)     NOT NULL,
    Orden            INT               NOT NULL CONSTRAINT DF_Tamanos_Orden DEFAULT 0,
    CONSTRAINT CK_Tamanos_Costo CHECK (CostoAdicional >= 0)
);
GO

IF OBJECT_ID(N'dbo.Sabores', N'U') IS NULL
CREATE TABLE dbo.Sabores
(
    Id          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Sabores PRIMARY KEY,
    Nombre      NVARCHAR(50)      NOT NULL CONSTRAINT UQ_Sabores_Nombre UNIQUE,
    Orden       INT               NOT NULL CONSTRAINT DF_Sabores_Orden DEFAULT 0,
    Disponible  BIT               NOT NULL CONSTRAINT DF_Sabores_Disponible DEFAULT 1
);
GO

IF OBJECT_ID(N'dbo.Toppings', N'U') IS NULL
CREATE TABLE dbo.Toppings
(
    Id          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Toppings PRIMARY KEY,
    Nombre      NVARCHAR(50)      NOT NULL CONSTRAINT UQ_Toppings_Nombre UNIQUE,
    Precio      DECIMAL(10,2)     NOT NULL,
    Orden       INT               NOT NULL CONSTRAINT DF_Toppings_Orden DEFAULT 0,
    Disponible  BIT               NOT NULL CONSTRAINT DF_Toppings_Disponible DEFAULT 1,
    CONSTRAINT CK_Toppings_Precio CHECK (Precio >= 0)
);
GO

/* Categoria coincide con las pestanas del menu: Raspados, Supremos, Paletas, Combos.
   Las banderas indican que opciones muestra el modal "Personaliza tu antojo":
   los combos, por ejemplo, normalmente no piden tamano, sabor ni toppings. */
IF OBJECT_ID(N'dbo.Productos', N'U') IS NULL
CREATE TABLE dbo.Productos
(
    Id               INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Productos PRIMARY KEY,
    Nombre           NVARCHAR(100)     NOT NULL CONSTRAINT UQ_Productos_Nombre UNIQUE,
    Descripcion      NVARCHAR(200)     NULL,
    PrecioBase       DECIMAL(10,2)     NOT NULL,
    Categoria        NVARCHAR(50)      NOT NULL,
    ImagenRuta       NVARCHAR(260)     NULL,
    RequiereTamano   BIT               NOT NULL CONSTRAINT DF_Productos_ReqTamano  DEFAULT 1,
    RequiereSabor    BIT               NOT NULL CONSTRAINT DF_Productos_ReqSabor   DEFAULT 1,
    PermiteToppings  BIT               NOT NULL CONSTRAINT DF_Productos_PermTopp   DEFAULT 1,
    Orden            INT               NOT NULL CONSTRAINT DF_Productos_Orden      DEFAULT 0,
    Disponible       BIT               NOT NULL CONSTRAINT DF_Productos_Disponible DEFAULT 1,
    CONSTRAINT CK_Productos_PrecioBase CHECK (PrecioBase > 0),
    CONSTRAINT CK_Productos_Categoria  CHECK (Categoria IN (N'Raspados', N'Supremos', N'Paletas', N'Combos'))
);
GO

/* ---------------------------------------------------------------------
   Charola (carrito activo).
   - TamanoId / SaborId son NULL solo para productos que no los piden
     (ver Productos.RequiereTamano / RequiereSabor; lo valida la aplicacion).
   - Cantidad >= 1: la cantidad cero no existe, el producto se elimina.
   - PrecioUnitario = base + tamano + toppings.
   - PrecioFinal    = PrecioUnitario * Cantidad.
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Charola', N'U') IS NULL
CREATE TABLE dbo.Charola
(
    Id              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Charola PRIMARY KEY,
    UsuarioId       INT               NOT NULL,
    ProductoId      INT               NOT NULL,
    TamanoId        INT               NULL,
    SaborId         INT               NULL,
    Cantidad        INT               NOT NULL,
    PrecioUnitario  DECIMAL(10,2)     NOT NULL,
    PrecioFinal     DECIMAL(10,2)     NOT NULL,
    CreadoEn        DATETIME2(0)      NOT NULL CONSTRAINT DF_Charola_CreadoEn DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Charola_Usuarios  FOREIGN KEY (UsuarioId)  REFERENCES dbo.Usuarios(Id),
    CONSTRAINT FK_Charola_Productos FOREIGN KEY (ProductoId) REFERENCES dbo.Productos(Id),
    CONSTRAINT FK_Charola_Tamanos   FOREIGN KEY (TamanoId)   REFERENCES dbo.Tamanos(Id),
    CONSTRAINT FK_Charola_Sabores   FOREIGN KEY (SaborId)    REFERENCES dbo.Sabores(Id),
    CONSTRAINT CK_Charola_Cantidad       CHECK (Cantidad >= 1),
    CONSTRAINT CK_Charola_PrecioUnitario CHECK (PrecioUnitario > 0),
    CONSTRAINT CK_Charola_PrecioFinal    CHECK (PrecioFinal = PrecioUnitario * Cantidad)
);
GO

IF OBJECT_ID(N'dbo.CharolaToppings', N'U') IS NULL
CREATE TABLE dbo.CharolaToppings
(
    CharolaId  INT NOT NULL,
    ToppingId  INT NOT NULL,
    CONSTRAINT PK_CharolaToppings PRIMARY KEY (CharolaId, ToppingId),
    CONSTRAINT FK_CharolaToppings_Charola  FOREIGN KEY (CharolaId) REFERENCES dbo.Charola(Id) ON DELETE CASCADE,
    CONSTRAINT FK_CharolaToppings_Toppings FOREIGN KEY (ToppingId) REFERENCES dbo.Toppings(Id)
);
GO

/* ---------------------------------------------------------------------
   Pedidos y detalle.
   - NumeroPedido: folio visible para el cliente ("#5797"), distinto del Id.
   - MetodoPago: Tarjeta, Efectivo o Transferencia (paso 2 del flujo).
   - Estado: Pendiente (efectivo por cobrar) -> Pagado -> EnPreparacion -> Listo.
   - El detalle guarda una "foto" (nombres y precios) para que cambios
     futuros en el catalogo no alteren pedidos ya cobrados.
   - Total > 0: un pedido con charola vacia no puede existir.
   --------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.sequences WHERE name = N'sq_NumeroPedido')
    CREATE SEQUENCE dbo.sq_NumeroPedido AS INT START WITH 1001 INCREMENT BY 1;
GO

IF OBJECT_ID(N'dbo.Pedidos', N'U') IS NULL
CREATE TABLE dbo.Pedidos
(
    Id            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Pedidos PRIMARY KEY,
    NumeroPedido  INT               NOT NULL
                  CONSTRAINT DF_Pedidos_NumeroPedido DEFAULT (NEXT VALUE FOR dbo.sq_NumeroPedido),
    UsuarioId     INT               NOT NULL,
    Total         DECIMAL(10,2)     NOT NULL,
    MetodoPago    NVARCHAR(20)      NOT NULL,
    Estado        NVARCHAR(20)      NOT NULL CONSTRAINT DF_Pedidos_Estado DEFAULT N'Pendiente',
    CreadoEn      DATETIME2(0)      NOT NULL CONSTRAINT DF_Pedidos_CreadoEn DEFAULT SYSDATETIME(),
    PagadoEn      DATETIME2(0)      NULL,
    CONSTRAINT UQ_Pedidos_NumeroPedido UNIQUE (NumeroPedido),
    CONSTRAINT FK_Pedidos_Usuarios FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuarios(Id),
    CONSTRAINT CK_Pedidos_Total      CHECK (Total > 0),
    CONSTRAINT CK_Pedidos_MetodoPago CHECK (MetodoPago IN (N'Tarjeta', N'Efectivo', N'Transferencia')),
    CONSTRAINT CK_Pedidos_Estado     CHECK (Estado IN (N'Pendiente', N'Pagado', N'EnPreparacion', N'Listo', N'Cancelado'))
);
GO

IF OBJECT_ID(N'dbo.PedidoDetalles', N'U') IS NULL
CREATE TABLE dbo.PedidoDetalles
(
    Id              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PedidoDetalles PRIMARY KEY,
    PedidoId        INT               NOT NULL,
    ProductoId      INT               NOT NULL,
    NombreProducto  NVARCHAR(100)     NOT NULL,
    Tamano          NVARCHAR(30)      NULL,
    Sabor           NVARCHAR(50)      NULL,
    Toppings        NVARCHAR(500)     NULL,
    Cantidad        INT               NOT NULL,
    PrecioUnitario  DECIMAL(10,2)     NOT NULL,
    PrecioFinal     DECIMAL(10,2)     NOT NULL,
    CONSTRAINT FK_PedidoDetalles_Pedidos   FOREIGN KEY (PedidoId)   REFERENCES dbo.Pedidos(Id) ON DELETE CASCADE,
    CONSTRAINT FK_PedidoDetalles_Productos FOREIGN KEY (ProductoId) REFERENCES dbo.Productos(Id),
    CONSTRAINT CK_PedidoDetalles_Cantidad CHECK (Cantidad >= 1),
    CONSTRAINT CK_PedidoDetalles_Final    CHECK (PrecioFinal = PrecioUnitario * Cantidad)
);
GO

/* ---------------------------------------------------------------------
   Indices de apoyo
   --------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Charola_UsuarioId')
    CREATE INDEX IX_Charola_UsuarioId ON dbo.Charola(UsuarioId);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PedidoDetalles_PedidoId')
    CREATE INDEX IX_PedidoDetalles_PedidoId ON dbo.PedidoDetalles(PedidoId);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Productos_Categoria')
    CREATE INDEX IX_Productos_Categoria ON dbo.Productos(Categoria, Orden);
GO

/* ---------------------------------------------------------------------
   Vista: resumen de la charola por usuario (contador del carrito y total)
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_ResumenCharola
AS
SELECT
    UsuarioId,
    ISNULL(SUM(Cantidad), 0)    AS TotalProductos,
    ISNULL(SUM(PrecioFinal), 0) AS TotalGeneral
FROM dbo.Charola
GROUP BY UsuarioId;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionEsquema WHERE Version = 1)
    INSERT INTO dbo.VersionEsquema (Version, Descripcion)
    VALUES (1, N'Esquema inicial: catalogos, charola, pedidos con folio y metodo de pago');
GO

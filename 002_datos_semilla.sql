/* =====================================================================
   Tras las Rejas - Script 002: Datos semilla
   Requiere haber ejecutado 001_crear_esquema.sql.
   Idempotente: usa MERGE por nombre, no duplica registros.
   Guardar este archivo como UTF-8 (con BOM) para conservar acentos.
   ===================================================================== */

USE TrasLasRejas;
GO

/* Usuario fijo del prototipo (caja principal) */
MERGE dbo.Usuarios AS destino
USING (VALUES (N'Caja 1')) AS origen (Nombre)
   ON destino.Nombre = origen.Nombre
WHEN NOT MATCHED THEN INSERT (Nombre) VALUES (origen.Nombre);
GO

/* Tamaños: Chico incluido, Mediano +$10, Grande +$15, Extra grande +$20 */
MERGE dbo.Tamanos AS destino
USING (VALUES
    (N'Chico',        0.00, 1),
    (N'Mediano',     10.00, 2),
    (N'Grande',      15.00, 3),
    (N'Extra grande',20.00, 4)
) AS origen (Nombre, CostoAdicional, Orden)
   ON destino.Nombre = origen.Nombre
WHEN MATCHED THEN UPDATE SET CostoAdicional = origen.CostoAdicional, Orden = origen.Orden
WHEN NOT MATCHED THEN INSERT (Nombre, CostoAdicional, Orden)
                      VALUES (origen.Nombre, origen.CostoAdicional, origen.Orden);
GO

/* Sabores (sin costo adicional) */
MERGE dbo.Sabores AS destino
USING (VALUES
    (N'Mango', 1), (N'Fresa', 2), (N'Tamarindo', 3),
    (N'Limón', 4), (N'Piña', 5),  (N'Uva', 6)
) AS origen (Nombre, Orden)
   ON destino.Nombre = origen.Nombre
WHEN MATCHED THEN UPDATE SET Orden = origen.Orden
WHEN NOT MATCHED THEN INSERT (Nombre, Orden) VALUES (origen.Nombre, origen.Orden);
GO

/* Toppings: cada uno suma $5 */
MERGE dbo.Toppings AS destino
USING (VALUES
    (N'Chamoy', 5.00, 1), (N'Miguelito', 5.00, 2), (N'Gomitas', 5.00, 3),
    (N'Lechera', 5.00, 4), (N'Chile en polvo', 5.00, 5), (N'Fruta fresca', 5.00, 6)
) AS origen (Nombre, Precio, Orden)
   ON destino.Nombre = origen.Nombre
WHEN MATCHED THEN UPDATE SET Precio = origen.Precio, Orden = origen.Orden
WHEN NOT MATCHED THEN INSERT (Nombre, Precio, Orden)
                      VALUES (origen.Nombre, origen.Precio, origen.Orden);
GO

/* Productos del catálogo (orden = el de la cuadrícula del menú).
   Nombre, Descripcion, PrecioBase, Categoria, ReqTamano, ReqSabor, PermiteToppings, Orden
   OJO: los precios de paletas y combos son supuestos, ajustalos a los reales. */
MERGE dbo.Productos AS destino
USING (VALUES
    (N'Raspado clásico',     N'Hielo raspado como lo recuerdas',        40.00, N'Raspados', 1, 1, 1, 1),
    (N'Raspado arcoíris',    N'Tres sabores en un solo vaso',           55.00, N'Raspados', 1, 1, 1, 2),
    (N'Mangonada',           N'Mango, chamoy y chile en polvo',         65.00, N'Supremos', 1, 1, 1, 3),
    (N'Diablito',            N'Picosito, dulce y bien frío',            65.00, N'Supremos', 1, 1, 1, 4),
    (N'Paleta de frutas',    N'Paleta de agua con fruta natural',       25.00, N'Paletas',  0, 1, 1, 5),
    (N'Paleta cremosa',      N'Paleta de crema suave',                  30.00, N'Paletas',  0, 1, 1, 6),
    (N'Combo amigos',        N'Para compartir: 2 raspados y 2 paletas', 120.00, N'Combos',  0, 0, 0, 7),
    (N'Combo Tras las Rejas',N'El combo de la casa',                    150.00, N'Combos',  0, 0, 0, 8)
) AS origen (Nombre, Descripcion, PrecioBase, Categoria, RequiereTamano, RequiereSabor, PermiteToppings, Orden)
   ON destino.Nombre = origen.Nombre
WHEN MATCHED THEN UPDATE SET
    Descripcion     = origen.Descripcion,
    PrecioBase      = origen.PrecioBase,
    Categoria       = origen.Categoria,
    RequiereTamano  = origen.RequiereTamano,
    RequiereSabor   = origen.RequiereSabor,
    PermiteToppings = origen.PermiteToppings,
    Orden           = origen.Orden
WHEN NOT MATCHED THEN INSERT
    (Nombre, Descripcion, PrecioBase, Categoria, RequiereTamano, RequiereSabor, PermiteToppings, Orden)
    VALUES (origen.Nombre, origen.Descripcion, origen.PrecioBase, origen.Categoria,
            origen.RequiereTamano, origen.RequiereSabor, origen.PermiteToppings, origen.Orden);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionEsquema WHERE Version = 2)
    INSERT INTO dbo.VersionEsquema (Version, Descripcion)
    VALUES (2, N'Datos semilla: usuario, tamanos, sabores, toppings, productos');
GO

/* ---------------------------------------------------------------------
   Verificacion rapida
   --------------------------------------------------------------------- */
SELECT N'Productos' AS Tabla, COUNT(*) AS Registros FROM dbo.Productos
UNION ALL SELECT N'Tamanos',  COUNT(*) FROM dbo.Tamanos
UNION ALL SELECT N'Sabores',  COUNT(*) FROM dbo.Sabores
UNION ALL SELECT N'Toppings', COUNT(*) FROM dbo.Toppings
UNION ALL SELECT N'Usuarios', COUNT(*) FROM dbo.Usuarios;
GO

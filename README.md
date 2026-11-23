Plan de despliegue
1. Requisitos previos en el equipo destino
Antes de iniciar la instalación, la computadora donde operará el kiosco debe contar con:
Sistema Operativo: Windows 10 o Windows 11 de 64 bits (x64).


Motor de Base de Datos: Microsoft SQL Server (edición Express, Developer o Standard) instalado y con su servicio activo en ejecución.


Herramienta de Administración SQL: SQL Server Management Studio (SSMS) instalado únicamente para la carga inicial de la base de datos (no requiere permanecer abierto durante la operación diaria del kiosco).


2. Preparación de la base de datos y configuración de conexión
Para que el kiosco pueda consultar el catálogo y registrar los pedidos en el equipo destino, se deben realizar estos pasos antes de abrir la aplicación:


Abrir SQL Server Management Studio (SSMS) e iniciar sesión en la instancia local de SQL Server (tomando nota del nombre exacto del servidor, por ejemplo localhost, .\SQLEXPRESS o el nombre del equipo).


Abrir y ejecutar el script de creación de estructura (001_crear_esquema.sql) para generar la base de datos TrasLasRejas junto con sus tablas (Usuarios, Productos, Pedidos, PedidoDetalles) y relaciones.


Abrir y ejecutar el script de datos iniciales (002_datos_semilla.sql) sobre la base TrasLasRejas para cargar el catálogo base de productos, precios y el usuario operativo (Id = 1).


Configurar appsettings.json: Abrir el archivo appsettings.json ubicado dentro de la carpeta publish con el Bloc de notas y actualizar el parámetro Server dentro de DefaultConnection con el nombre de la instancia de SQL Server del equipo destino:


JSON
"ConnectionStrings": {
"DefaultConnection": "Server=NOMBRE_INSTANCIA_DESTINO;Database=TrasLasRejas;Trusted_Connection=True;TrustServerCertificate=True"
}
(Nota: Si se utiliza autenticación por usuario y contraseña de SQL en lugar de autenticación de Windows, se debe reemplazar Trusted_Connection=True por User Id=usuario;Password=contraseña;).


Verificar en SSMS mediante una consulta rápida (SELECT * FROM Productos;) que los registros iniciales existan y cerrar la herramienta.

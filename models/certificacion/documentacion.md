SEEDS
------------------------------------
* Si llamamos a la configuracion "persist_doc", los campos han de estar igual que en el data wareshouse si no no lo detecta


-----------------------------------------------------------------------------------------------------------------------------------------------------------------
SOURCES
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
* Nomenclatura:
  

* Tiene preferencia el freshnes en el source yml y dentro de este las tablas
* El freshness si lo configuramos en el dbt_project no tiene campo loaded_at_field es genérico. Aunque 
podemos meternos en los distintos sources. 
* El source name ha de ser unico, cuidado con mayus y minusculas. Ha de ser IGUAL. El nombre de la tabla 
cuando se pone en el source ha de ser igual tambien. A la hora de hacer el freshnes en el CLI, si
hacemos sobre una tabla ha de coincidir Mayus y Minus
* Por defecto cuando se hace freshness se crea sources.json en el directorio target aunque se puede cambiar con --output o con -o
* Si no se añade nada o se deja vacio el freshnness no calculará nada. Si no se pone loaded_at_field no hara freshness
* Configurar el freshness cada 30 min
* Usar filtro de frescura para evitar costes grandes
* Si no queremos que chekee una tabla ponemos su freshness a NULL
* dbt build no incluye freshness
* El comando freshness se ha de ejecutar frecuentemente acuerdo con los SLAs. 
    - SLA 1 hora hacer freshnesss cada 30 min
    - SLA 1 day hacer freshnesss cada 12 horas
    - SLA 1 semana hacer freshnesss cada dia
* En snowflake usan LAST_ALTERED para el freshness
* En un STG se deberia hacer solo:
    - Renombrado
    - Casteos de tipo
    - cambios mínimos ( pasar de euros a dolareS)
    - Categorizar cosas (case when)
    - NO joins
    - NO agregaciones
    - Materializar como VISTAS
    - Relacion 1-1 con las tablas
    - Cambios siempre lo antes posible
* loaded_at_field puedo poner:
    loaded_at_field: campo
    loaded_at_field: "campo::timestamp"
    loaded_at_field: "CAST(campo as timestamp)"
    loaded_at_field: "convert_timezone...)"
COMANDOS

dbt source freshness --> hace el freshneess de todos los sources
dbt source freshness --output target/source_freshness.json --> saca la salida del freshness a un path distinto
dbt source freshness --select "source:source_name" --> solo hace freshness de un source específico
dbt source freshneess --select "source:source_name.table" --> hace el freshness de la tabla concreta
dbt build --select source_status:fresher+ --> hace build y test de modelos de los a partir de los sources que están SOLO FRESCOS
dbt source freshness --select source:source -->Sin comillas hace freshness de todo el source
dbt source freshness --select source:source_name.table source:source_name.table
dbt source freshness --select tag:cert --> Se llama con un tag concreto


------------------------------------------------------------------------------------------------------------------------------------------
TEST SINGULARES
------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------
TEST GENERICOS
------------------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------------------
MACROS
------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------
SNAPSHOTS
------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------
JINJA
------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------
INCREMENTALES
------------------------------------------------------------------------------------------------------------------------------------------
* En modelos complejos que usan CTES, hay que considerar el uso de "is_incremental". En algunos WH filtrar filas antes mejorar el rendimiento.
* Para ser incremental:
	el modelo ha de existir
	no llamar a full-refresh
	y materializar como incremental
* "incremental_predicates" : Usado cuando el volumne de información es muy gradnde y queremos mejorar performance. Aplica filtros adicionales
sobre el que ya tiene en la query. Estos filtros se aplicarán antes de ejecutar la query para evitar un gran escaneo. DBT no valida la expresion sql.
* UNIQUE_KEY:(opcional) Permite actualizar un registro si existe la clave y no se añade. Sino se pone sera "append only".
La clave unica ha de representar una columna o una lista  "[col1,col2..], no han de tener valores nulos. Usar coalesce para asegurarnos que no hay nulos.
o usar clave subrrogada (dbt_utils.generate_surrogate_key). Si a PK tiene varias claves usar "LISTA DE CAMPOS" en vez de concatenar.
* delete + insert , merge usan unique key . insert_overwrite y microbatch no usa unique key por que opera con particiones
* En caso de realizar modificaciones en el modelo que puedan afectar a como estan los datos historicos, se recomienda usar "full-refresh"
para recrear toda la inforamción desde el inicio.
*En caso de que una columna cambie en el modelo podemos usar "on_schema_change" evitando usar tanto el full-refresh
	on_schema_change:
		ignore: por defecto. Si en origen se crea columna nueva en destino no estará. Si en origen se borra una columna, en destino fallará 
		fail: salta un error cuando el origen con el destino no son iguales
		append_new_column: añade una columna nueva al modelo, pero si en origen se borra alguna columna, en el destino no se borrará
		sync_all_columns:  igual que el anterior pero si borra las columnas en el destino
	En caso de añadir columnas nueva, on_schema_change NO RELLENA. Se recomienda entonces un full-refresh o hacerlo manual si se quiere relleno.
	on_schema_change no rastrea sobre columnas anidadas. Solo en columnas principales.
* Se pueden configurar las estrategias en:
	dbt_project
	en un modelo
* En estrategia merge si se usa merge_update_columns se puede indicar una lista de columnas a actualizar o excluir "merge_exclude_columns "
* Estrategias incrementales:
	- append:   costes bajos de procesamiento. SOLO inserta en destino. No gestiona versionado de historial. No verifica duplicados o si existe 
	el registro en destino.Si en origen está el mismo registro varias veces, en destino tambien .
	- delete + insert: A partir de la unique_key borra en destino los registros que coincidan e inserta. Poco eficiente para grandes datasets
	Muy util cuando MERGE no se puede usar. Para implementar SCD2 usar Snapshot.
	- merge: Igual que delete+ insert. Es un espejo de SCD1 ya que no se conservan los cambios. No borra e inserta. Hace un insert o update.
	Si se pone estrategia de merge sin unique key hará un "append". Es ideal para tablas pequeñas. Para gran volumen de datos puede salir
	caro ya que escanea toda la tabla.
	- insert_overwrite:  Usada para actualziar particiones de las tablas reemplazandolas enteras con nuevos datos en vez de hacer merge. Esta estrategia
	solo afecta a las particiones, no a toda la tabla. No se alinea con la lógica SCD ya que borra y crea particiones enteras. Es ideal
	para tablas particionadas por "fecha" u otra clave usualmente para datos recientes o corregidos que no necesitan reconstrucción
	- microbatch: estrategia usada para procesar grandes series temporales partiendo la información en batches temporales (hora, dias)
* Desde version 1.2 se puede crear materializaciones personalidas.  Definiendo el macro "get_incremental_ESTRATEGIA.sql".
* merge_null_safe es una estrategia que está en un paquete que hay que instalar

-----------------------------------------------------------------------------------------
MATERIALIZACIONES
------------------------------------------------------------------------------------
Pasos que realiza una materializacion:
	- preparar la base de datos para el nuevo modelo
	- ejecuta pre hooks
	- ejecuta sql requerida para implementar la materializacion
	- ejecuta post hooks
	- limpia base de datos
	- actualiza cache
	
Prioridad en las materializaciones
	- proyecto global - defecto
	- proyecto global en un plugin
	- paquete importado defecto
	- paquete importado plugin
	- proyecto local defecto
	- proyecto local plugin

* Tipos materializacion:
	- Vistas: Usada por defecto.  Solo almacena LOGICA en sql de la transformación. Se construye en cada ejecución y tiene un coste bajo.
	 Siempre refleja la versión más actualizada de la información. Si tiene consultas complejas no es recomendado ya que tarda en construirse
	- Tablas: Al contrario que las vistas, la información si se almacena en el DW.se puede consulta la información transformada directamente
	obteniendo un mejor rendimiento. Tablas son rapidas y con mayor capacidad de respuesta en contraposición de las vistas. Computo es significativamente
	mas caro que el almacenamiento. Ideal para modelos que se consultan constantemente. 
	- INCREMENTALES: Construyen una tabla en partes  a lo largo del tiempo solo agregando y actualizando. Se construye más rapido que una tabla normal.
	Ejecuciones iniciales lentas ya que han de crear la tabla inicial . Los modelos incrementales requieren añaden complejidad al modelo.
	- Efimeras
	- Vistas materializadas
	* 
	* Se recomienda empezar siempre con una vista hasta que sea larga por lo que pasaremos a una tabla y si también se convierte en larga pararemos a una incremental.

-------------------------------------------------------------------
    NOMENCLATURAS Y BUENAS PRACTICAS
-------------------------------------------------------------------------
    -(PLATA) Ficheros de staging -->   stg_[source]__[table name].sql . Se recomienda separar los sources por origen de datos. Poner el nombre de las tablas en plural.
    -(PLATA) Ficheros base --> base_[source]__[table name].sql 
    -(PLATA) Ficheros intermedios --> int_[entidad de negocio]__[verbo que hace].sql. No se expone a usuarios finales. Materializaciones efimeras o como vistas en un schema aparte
    -(GOLD)  Ficheros marts --> [tabla].sql. No crear el mismo concepto para varias unidades de negocio. Materializar como tablas o incrementales
    Si para crear un mart se usan 4 o 5 modelos mejor usar intermedios
    - Crear un _[directory]__models.yml por carpeta para configurar todos los modelos del directorio.
    - Crear _[directory]__sources.yml para los sources. Guion bajo es para que salga arriba en los ficheros 
    - Usar dbt_project.yml para poner configuraciones a nivel de directorio
    - Creacion de grupos para ejecutar modelos concretos
    - Nombre de modelos en plural
    - Cada modelo ha de tener una PK
    - Usar guion bajo para nombrar modelos
    - Evitar usar palabras reservadas
    - Boleanos han de ser is_ o has_
    - valores de tiempo han de llamarse <event>_date
    - fechas y horas en tiempo pasado "created, updated"
    - En caso de monedas usar decimales
    - tablas, esquemas y columnas en camel case
    - sangrias 4 espacios
    - lineas de sql no mas de 80 caracteres
    - para alias usar "as"
    - los ref han de ser ctes. esas cts han de tener el nombre de las tablas. Un cte solo ha de hacer una cosa.
    -usar  {{ this }} en vez de {{this}}
    





------------------------------------------------------------
    GROUPS (GRUPOS)
-------------------------------------------------------

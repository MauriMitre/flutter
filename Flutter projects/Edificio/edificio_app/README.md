# Edificio App

## Descripción General
Edificio App es una aplicación móvil desarrollada con Flutter para la gestión de inquilinos de un edificio. Permite administrar inquilinos, controlar pagos de alquileres y expensas, gestionar documentos, tareas y generar reportes.

## Estructura del Proyecto

### Estructura de Directorios
- **lib/** - Código fuente principal de la aplicación
  - **models/** - Modelos de datos (inquilino, documento, tarea, etc.)
  - **screens/** - Pantallas de la aplicación
  - **services/** - Servicios para manejo de datos, archivos y lógica de negocio
  - **widgets/** - Componentes reutilizables
- **assets/** - Recursos estáticos como imágenes e iconos

## Arquitectura y Comunicación entre Archivos

### Punto de Entrada
El archivo `main.dart` es el punto de entrada de la aplicación. Inicializa los servicios necesarios, configura la localización y lanza la interfaz de usuario principal (`HomeScreen`).

Durante la inicialización:
1. Se configura el binding de Flutter (`WidgetsFlutterBinding.ensureInitialized()`)
2. Se inicializa la localización para español (`initializeDateFormatting('es_ES')`)
3. Se verifica si es la primera ejecución para cargar datos predefinidos
4. Se inicializa el servicio de almacenamiento (`StorageService`)
5. Se lanzan los logs de inicio
6. Se lanza la aplicación con la configuración de tema y localización

### Modelos de Datos
Los modelos definen la estructura de los datos utilizados en la aplicación:

- **Inquilino** (`models/inquilino.dart`): 
  - Almacena información sobre los inquilinos, incluyendo datos personales, departamento, historial de pagos y sistema de precios con períodos.
  - Implementa métodos para calcular deudas y verificar pagos.
  - Maneja la migración entre sistemas de precios antiguos y nuevos.
  - Campos principales:
    - Datos personales (id, nombre, apellido, departamento)
    - Mapas de control de pagos (pagos, pagosAlquiler, pagosExpensas)
    - Sistema de precios por períodos (periodosPrecio)
    - Métodos de pago y cuentas asociadas

- **Documento** (`models/documento.dart`): 
  - Gestiona documentos asociados a inquilinos.
  - Contiene metadatos como nombre, descripción, fecha y ruta del archivo.
  - Implementa métodos para serialización y deserialización.

- **Tarea** (`models/tarea.dart`): 
  - Maneja tareas pendientes relacionadas con la administración del edificio.
  - Incluye propiedades como título, descripción, estado y prioridad.
  - Permite organizar y dar seguimiento a trabajos pendientes.

- **CuentaTransferencia** (`models/cuenta_transferencia.dart`): 
  - Almacena información de cuentas bancarias para transferencias.
  - Incluye datos como titular, banco, tipo de cuenta y número.

- **PeriodoPrecio** (`models/periodo_precio.dart`): 
  - Sistema para manejar diferentes precios de alquiler en distintos períodos de tiempo.
  - Permite aplicar aumentos y mantener un historial de precios.
  - Es utilizado por el modelo Inquilino para determinar el precio aplicable en cada mes.

### Servicios

El proyecto implementa una arquitectura basada en servicios que encapsulan lógica específica:

1. **StorageService** (`services/storage_service.dart`):
   - Núcleo del sistema de persistencia de datos
   - Gestiona todas las operaciones CRUD (Crear, Leer, Actualizar, Eliminar) para los modelos
   - Implementa serialización/deserialización JSON para SharedPreferences
   - Maneja la inicialización de datos predefinidos
   - Implementa optimizaciones para reducir el uso de memoria y almacenamiento
   - Métodos principales:
     - `loadInquilinos()`: Carga inquilinos desde SharedPreferences
     - `saveInquilinos()`: Guarda inquilinos en SharedPreferences
     - `loadExpensas()/saveExpensas()`: Gestiona valores de expensas por mes
     - `loadTareas()/saveTareas()`: Gestiona tareas
     - `loadDocumentos()/saveDocumentos()`: Gestiona metadatos de documentos
     - `loadCuentasTransferencia()/saveCuentasTransferencia()`: Gestiona cuentas bancarias

2. **FileService** (`services/file_service.dart`):
   - Maneja operaciones de archivos físicos en el sistema
   - Implementa funciones para guardar, cargar y eliminar archivos
   - Gestiona la estructura de directorios para documentos
   - Genera nombres de archivo únicos basados en timestamps
   - Métodos principales:
     - `guardarArchivo()`: Guarda un archivo y devuelve ruta relativa
     - `getArchivo()`: Obtiene File a partir de ruta relativa
     - `eliminarArchivo()`: Elimina un archivo físico
     - `archivoExiste()`: Verifica existencia de archivo
     - `getTamanoArchivo()`: Calcula tamaño de archivo en KB

3. **PdfService** (`services/pdf_service.dart`):
   - Genera documentos PDF con reportes e informes
   - Crea recibos y resúmenes de pagos
   - Implementa plantillas para diferentes tipos de documentos
   - Utiliza el paquete `pdf` para generación de documentos

4. **DeudasService** (`services/deudas_service.dart`):
   - Calcula deudas y pagos pendientes
   - Implementa algoritmos para determinar montos adeudados
   - Genera resúmenes de situación financiera

5. **LogService** (`services/log_service.dart`):
   - Sistema centralizado de logging
   - Registra errores, advertencias e información
   - Facilita depuración y seguimiento de problemas
   - Implementa niveles de log (debug, info, warning, error)

### Flujo de Datos y Comunicación

1. **Pantallas → Servicios**:
   - Las pantallas (`screens/`) capturan la interacción del usuario y llaman a los servicios correspondientes para procesar los datos.
   - Ejemplo: `home_screen.dart` utiliza `storage_service.dart` para cargar y guardar datos de inquilinos.
   - Flujo típico:
     1. Usuario interactúa con un elemento de UI
     2. El widget llama a un método del State correspondiente
     3. El State llama al servicio apropiado
     4. El servicio procesa la solicitud y devuelve resultados
     5. El State actualiza la UI con `setState()`

2. **Servicios → Almacenamiento**:
   - Los servicios (`services/`) contienen la lógica de negocio y se comunican con el sistema de almacenamiento.
   - `storage_service.dart` maneja la persistencia de datos usando SharedPreferences.
   - `file_service.dart` gestiona el almacenamiento de archivos físicos.
   - Implementan patrones de optimización como:
     - Carga diferida (lazy loading)
     - Escritura batch para reducir operaciones de I/O
     - Compresión de datos cuando es posible
     - Manejo de errores y recuperación

3. **Servicios → Servicios**:
   - Los servicios también se comunican entre sí para tareas complejas.
   - Ejemplo: `pdf_service.dart` utiliza `deudas_service.dart` para generar reportes de deudas.
   - La comunicación se hace por inyección de dependencias implícita (creando instancias)

4. **Modelos → Servicios**:
   - Los modelos contienen métodos que pueden utilizar servicios para cálculos o transformaciones.
   - Ejemplo: La clase `Inquilino` tiene métodos para gestionar precios por período.
   - Esta relación facilita la encapsulación de lógica específica de dominio dentro de los modelos.

### Ciclo de Vida de los Datos

1. **Creación**:
   - Datos nuevos son creados por interacción del usuario en pantallas como `AgregarInquilinoScreen`
   - Se instancian nuevos objetos de modelo (ej: `Inquilino`, `Documento`)
   - Se asignan identificadores únicos (UUID) a las nuevas entidades

2. **Persistencia**:
   - Los servicios convierten los objetos a formato JSON mediante métodos `toMap()`
   - Los datos se almacenan en SharedPreferences
   - Los archivos físicos se guardan en el sistema de archivos
   - Se registra la operación en el sistema de logs

3. **Recuperación**:
   - Al iniciar la aplicación o navegar a una pantalla, se cargan datos desde SharedPreferences
   - Se convierten de JSON a objetos mediante constructores `fromMap()`
   - Se aplican migraciones si es necesario (ej: sistema de precios históricos a períodos)
   - Se realiza validación de datos para asegurar integridad

4. **Actualización**:
   - Los cambios se realizan creando copias modificadas de objetos inmutables (`copyWith`)
   - Las listas completas se guardan de nuevo en SharedPreferences
   - Se mantiene atomicidad en las operaciones para prevenir estados inconsistentes

5. **Eliminación**:
   - Remoción de elementos de listas
   - Borrado de archivos físicos asociados
   - Actualización de referencias para mantener integridad referencial

## Sistema de Almacenamiento

La aplicación utiliza dos métodos principales de almacenamiento:

### 1. SharedPreferences (Almacenamiento de Datos)
La clase `StorageService` utiliza `SharedPreferences` para almacenar datos estructurados de forma persistente:

- **Inquilinos**: Lista de inquilinos con toda su información.
  - Clave: `'inquilinos'`
  - Formato: Lista de strings JSON

- **Tareas**: Lista de tareas pendientes y completadas.
  - Clave: `'tareas'`
  - Formato: Lista de strings JSON

- **Expensas**: Valores de expensas por mes.
  - Clave: `'expensa_{mesAnio}'` (ej: `'expensa_01-2025'`)
  - Formato: Double

- **Cuentas de transferencia**: Datos de cuentas bancarias.
  - Clave: `'cuentas_transferencia'`
  - Formato: Lista de strings JSON

- **Documentos**: Metadatos de documentos (nombres, descripciones, referencias).
  - Clave: `'documentos'`
  - Formato: Lista de strings JSON

- **Flags de control**:
  - `'app_inicializada'`: Indica si la app ya realizó su primera inicialización
  - `'inquilinos_inicializados'`: Indica si los inquilinos predefinidos fueron cargados

Los datos se guardan en formato JSON, serializando los objetos de modelo mediante métodos `toMap()` y deserializándolos mediante constructores `fromMap()`.

```dart
// Ejemplo de serialización
final jsonInquilinos = inquilinos.map((i) => jsonEncode(i.toMap())).toList();
await prefs.setStringList(_inquilinosKey, jsonInquilinos);

// Ejemplo de deserialización
final jsonStr = prefs.getStringList(_inquilinosKey);
final inquilinos = jsonStr.map((json) => Inquilino.fromMap(jsonDecode(json))).toList();
```

#### Optimizaciones en el Almacenamiento de Datos:

1. **Manejo de excepciones**:
   - Control de errores durante la serialización/deserialización
   - Filtrado de elementos inválidos durante la carga
   - Logs detallados para identificar problemas

2. **Migraciones automáticas**:
   - Sistema para actualizar formatos de datos antiguos a nuevos
   - Ejemplo: migración del mapa `preciosAlquilerPorMes` a `periodosPrecio`
   - Permite actualizaciones sin pérdida de datos

3. **Validación de datos**:
   - Verificación de campos requeridos no vacíos
   - Control de tipos durante la deserialización
   - Valores predeterminados para campos faltantes

### 2. Almacenamiento de Archivos (Documentos)
La clase `FileService` gestiona el almacenamiento de archivos físicos (como documentos PDF):

- Utiliza `path_provider` para obtener el directorio de documentos de la aplicación.
- Los archivos se organizan en carpetas por inquilino usando su ID.
- Los nombres de archivos incluyen timestamps para evitar conflictos.
- La ruta relativa de los archivos se almacena en `SharedPreferences` como parte del modelo `Documento`.

```dart
// Estructura de directorios para archivos
// AppDocumentsDirectory/inquilinos/[ID_INQUILINO]/[TIMESTAMP].[EXTENSION]
```

#### Proceso de Manejo de Documentos:

1. **Subida**:
   - El usuario selecciona un archivo (ej: con `image_picker`)
   - `FileService` crea la estructura de directorios si no existe
   - Se genera un nombre único basado en timestamp
   - El archivo se copia a su ubicación final
   - Se crea un objeto `Documento` con metadatos y ruta relativa
   - Los metadatos se guardan en SharedPreferences

2. **Descarga/Visualización**:
   - Se recupera el objeto `Documento` de SharedPreferences
   - `FileService` obtiene la ruta completa del archivo
   - Se utiliza `flutter_pdfview` para mostrar PDFs
   - Se implementa `open_file` para otros tipos de archivos

3. **Eliminación**:
   - Se elimina el archivo físico con `File.delete()`
   - Se actualiza la lista de documentos en SharedPreferences
   - Se limpian directorios vacíos si es necesario

### Sistema de Precios por Períodos

La aplicación implementa un sistema sofisticado para manejar precios de alquiler que cambian con el tiempo:

1. **Estructura**:
   - Cada inquilino tiene una lista de `PeriodoPrecio`
   - Cada `PeriodoPrecio` tiene una fecha de inicio y un precio
   - El sistema determina qué precio aplicar para cada mes/año

2. **Algoritmo de selección de precio**:
   - Para un mes específico, se busca el `PeriodoPrecio` más reciente cuya fecha de inicio sea anterior o igual al mes consultado
   - Si no se encuentra ninguno, se usa el precio base
   - Implementación en `getPrecioAlquilerPorMes()`

3. **Migración desde sistema anterior**:
   - Anteriormente los precios se guardaban en un mapa `Map<String, double> preciosAlquilerPorMes`
   - El método `migrarPreciosAPeriodos()` convierte ese formato al nuevo sistema
   - Se mantiene compatibilidad hacia atrás durante la transición

4. **Aplicación de aumentos**:
   - Al aplicar un aumento, se añade un nuevo `PeriodoPrecio` a la lista
   - Los períodos anteriores se conservan para mantener el historial
   - Implementado en método estático `Inquilino.aplicarAumento()`

## Características Principales

### 1. Gestión de Inquilinos
- **Alta, baja y modificación de inquilinos**:
  - Pantalla dedicada (`AgregarInquilinoScreen`)
  - Validación de datos obligatorios
  - Asignación automática de identificadores únicos
  
- **Control de pagos de alquiler y expensas**:
  - Registro por mes/año
  - Diferentes métodos de pago (efectivo, transferencia)
  - Asociación con cuentas bancarias específicas

- **Sistema de precios por períodos para manejar aumentos**:
  - Histórico de precios
  - Aumentos programados
  - Calculadora de aumentos (`CalculadoraAumentoDialog`)

### 2. Gestión de Documentos
- **Almacenamiento de documentos asociados a inquilinos**:
  - Organización por inquilino
  - Sistema de metadatos (descripción, fecha, tipo)
  - Gestión de espacio en disco
  
- **Visualización de archivos PDF**:
  - Integración con `flutter_pdfview`
  - Visor integrado en la aplicación
  - Opción para compartir documentos

### 3. Control de Pagos
- **Registro de pagos de alquiler y expensas**:
  - Interfaz intuitiva por inquilino
  - Visualización por mes/año
  - Indicadores visuales de estado (pagado/pendiente)
  
- **Diferentes métodos de pago**:
  - Efectivo
  - Transferencia bancaria
  - Asociación con cuentas bancarias
  
- **Cálculo de montos pendientes**:
  - Algoritmo para determinar deudas acumuladas
  - Intereses y recargos (si aplica)
  - Resumen por inquilino y general

### 4. Reportes
- **Generación de reportes de pagos**:
  - Resumen mensual
  - Estado de cuenta por inquilino
  - Estadísticas globales
  
- **Exportación a PDF**:
  - Documentos formatados profesionalmente
  - Inclusión de detalles relevantes
  - Posibilidad de compartir/imprimir

### 5. Gestión de Tareas
- **Creación y seguimiento de tareas**:
  - Título, descripción y fecha límite
  - Estado de completitud
  - Asignación a responsables
  
- **Asignación de prioridades**:
  - Sistema de priorización
  - Filtrado y ordenamiento
  - Notificaciones para tareas urgentes

## Inicialización de Datos y Flujo de Primera Ejecución

La aplicación implementa un sistema robusto para la primera ejecución:

1. **Verificación de primera ejecución**:
   ```dart
   bool primeraEjecucion = !(prefs.getBool('app_inicializada') ?? false);
   ```

2. **Proceso de inicialización**:
   - Se eliminan marcas de inicialización anteriores
   - Se limpian datos existentes si los hubiera
   - Se establece la marca de inicialización
   ```dart
   await prefs.remove('inquilinos_inicializados');
   await prefs.remove('inquilinos');
   await prefs.setBool('app_inicializada', true);
   ```

3. **Carga de datos predefinidos**:
   - Método `_crearInquilinosPredefinidos()` genera inquilinos iniciales
   - Asignación de identificadores únicos a cada inquilino
   - Establecimiento de precios base

4. **Verificación de integridad**:
   - Comprobación de campos requeridos en inquilinos
   - Logs de advertencia para datos incorrectos
   - Recuperación ante fallos

## Consideraciones Técnicas

### 1. Sistema de Logs
- **Implementación en `log_service.dart`**:
  - Niveles: debug, info, warning, error
  - Registra mensaje, excepción y stack trace
  - Facilita la depuración y seguimiento de errores
  
- **Uso consistente en toda la aplicación**:
  - Inicialización: `log.i("Iniciando aplicación con datos existentes")`
  - Errores: `log.e("Error al cargar datos", e, stackTrace)`
  - Depuración: `log.d("Cargadas ${result.length} expensas comunes")`
  - Advertencias: `log.w("ADVERTENCIA: No se cargaron inquilinos predefinidos")`

### 2. Migración de Datos
- **Sistema para migrar datos entre versiones**:
  - Ejemplo: migración del sistema de precios históricos a períodos
  - Detección automática de formato antiguo
  - Conversión transparente al nuevo formato
  - Preservación de datos históricos

- **Proceso de migración**:
  1. Detectar si es necesario migrar (comprobando estructura de datos)
  2. Convertir datos antiguos al nuevo formato
  3. Guardar datos en nuevo formato
  4. Mantener temporalmente compatibilidad con formato antiguo

### 3. Localización y Formato
- **Configurada para español (es_ES)**:
  - Inicialización: `initializeDateFormatting('es_ES', null)`
  - Delegados de localización en MaterialApp
  
- **Formateo adaptado al formato local**:
  - Fechas: `DateFormat('MM-yyyy').format(DateTime.now())`
  - Números: Formato de moneda con puntos para miles y comas para decimales
  - Textos: Mensajes en español

### 4. Optimización de Rendimiento
- **Carga eficiente de datos**:
  - Carga bajo demanda (lazy loading)
  - Filtrado de datos innecesarios
  
- **Manejo de memoria**:
  - Liberación de recursos no utilizados
  - Prevención de fugas de memoria
  
- **Procesamiento asíncrono**:
  - Operaciones de I/O en hilos separados
  - Uso de `Future` y `async/await` para no bloquear la UI

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class DocumentationGenerator {
  Future<String> generateDocumentation() async {
    final pdf = pw.Document();
    
    // Colores para el PDF
    final colorPrimario = PdfColors.blue700;
    final colorSecundario = PdfColors.blue200;
    final colorTextoClaro = PdfColors.white;
    final colorResaltado = PdfColors.blue900;
    final colorSecundarioSuave = PdfColors.blue50;
    
    // Portada
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'DOCUMENTACIÓN TÉCNICA',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: colorPrimario,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 15),
              pw.Text(
                'APLICACIÓN EDIFICIO',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: colorResaltado,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 40),
              pw.Container(
                width: 200,
                height: 200,
                decoration: pw.BoxDecoration(
                  color: colorSecundarioSuave,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
                  border: pw.Border.all(color: colorSecundario, width: 2),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'EDIFICIO',
                  style: pw.TextStyle(
                    fontSize: 40,
                    fontWeight: pw.FontWeight.bold,
                    color: colorPrimario,
                  ),
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                'Gestión de Inquilinos y Expensas',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 14,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
    
    // Índice
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                color: colorPrimario,
                width: double.infinity,
                child: pw.Text(
                  'ÍNDICE',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: colorTextoClaro,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 20),
              _buildIndexItem(1, 'Introducción y Estructura General', colorPrimario),
              _buildIndexItem(2, 'Modelos de Datos', colorPrimario),
              _buildIndexItem(3, 'Servicios', colorPrimario),
              _buildIndexItem(4, 'Pantallas Principales', colorPrimario),
              _buildIndexItem(5, 'Widgets Personalizados', colorPrimario),
              _buildIndexItem(6, 'Flujo de Datos y Funcionamiento', colorPrimario),
              _buildIndexItem(7, 'Diagrama de Arquitectura', colorPrimario),
            ],
          );
        },
      ),
    );
    
    // Introducción
    pdf.addPage(_buildChapterPage('1. Introducción y Estructura General', colorPrimario, colorTextoClaro, [
      _buildSection('Propósito de la Aplicación', [
        _buildParagraph('La aplicación "Edificio" es una herramienta diseñada para la gestión de inquilinos, alquileres y expensas de un edificio. Permite administrar los pagos, generar recibos, calcular expensas y realizar un seguimiento de los inquilinos y sus obligaciones.'),
      ]),
      _buildSection('Estructura del Proyecto', [
        _buildParagraph('El proyecto sigue una arquitectura modular organizada en carpetas según la responsabilidad de cada componente:'),
        _buildList([
          'lib/main.dart: Punto de entrada de la aplicación',
          'lib/models/: Contiene las clases de modelo de datos',
          'lib/screens/: Pantallas principales de la aplicación',
          'lib/services/: Servicios para operaciones como almacenamiento y generación de PDFs',
          'lib/widgets/: Componentes UI reutilizables'
        ]),
      ]),
    ]));
    
    // Modelos
    pdf.addPage(_buildChapterPage('2. Modelos de Datos', colorPrimario, colorTextoClaro, [
      _buildSection('Inquilino (inquilino.dart)', [
        _buildParagraph('La clase Inquilino es el modelo central de la aplicación. Representa a un inquilino del edificio y almacena toda su información personal, así como el registro de sus pagos de alquiler y expensas.'),
        _buildList([
          'Atributos: id, nombre, apellido, departamento, precioAlquiler, pagos, expensas, etc.',
          'Métodos: getExpensasPorMes(), haPagado(), getMontoPendiente(), getMetodoPago(), etc.',
          'Enumeración: MetodoPago para definir si un pago fue en efectivo o transferencia'
        ]),
      ]),
      _buildSection('CuentaTransferencia (cuenta_transferencia.dart)', [
        _buildParagraph('Modelo que representa una cuenta bancaria para transferencias de pagos de alquiler.'),
        _buildList([
          'Atributos: id, nombre, numeroCuenta, titular, banco',
          'Métodos: toJson() y fromJson() para serialización/deserialización'
        ]),
      ]),
      _buildSection('Tarea (tarea.dart)', [
        _buildParagraph('Modelo para gestionar tareas relacionadas con el mantenimiento o administración del edificio.'),
        _buildList([
          'Atributos: id, titulo, descripcion, fechaCreacion, completada',
          'Métodos: toJson() y fromJson() para serialización/deserialización'
        ]),
      ]),
    ]));
    
    // Servicios
    pdf.addPage(_buildChapterPage('3. Servicios', colorPrimario, colorTextoClaro, [
      _buildSection('StorageService (storage_service.dart)', [
        _buildParagraph('Servicio encargado de la persistencia de datos utilizando SharedPreferences para almacenamiento local.'),
        _buildList([
          'Métodos para inquilinos: saveInquilinos(), loadInquilinos(), initializeInquilinos()',
          'Métodos para cuentas: saveCuentasTransferencia(), loadCuentasTransferencia()',
          'Métodos para tareas: saveTareas(), loadTareas()',
          'Métodos para expensas: saveExpensasComunes(), loadExpensasComunes()'
        ]),
      ]),
      _buildSection('PdfService (pdf_service.dart)', [
        _buildParagraph('Servicio que genera documentos PDF para recibos de pago y reportes de expensas.'),
        _buildList([
          'generarRecibo(): Crea un recibo PDF para el pago de un inquilino',
          'generarExpensasPdf(): Genera un reporte de expensas del edificio',
          'Utiliza el paquete pdf para la creación de documentos'
        ]),
      ]),
    ]));
    
    // Pantallas
    pdf.addPage(_buildChapterPage('4. Pantallas Principales', colorPrimario, colorTextoClaro, [
      _buildSection('HomeScreen (home_screen.dart)', [
        _buildParagraph('Es la pantalla principal y más compleja de la aplicación. Maneja la mayoría de la lógica de negocio y presenta dos pestañas principales: Inquilinos y Resumen.'),
        _buildList([
          'Gestión de inquilinos: listar, agregar, editar, eliminar',
          'Registro de pagos de alquiler y expensas',
          'Visualización de estadísticas y resumen de pagos',
          'Generación de recibos PDF',
          'Acceso a otras funcionalidades mediante un menú lateral (drawer)'
        ]),
      ]),
      _buildSection('AgregarInquilinoScreen (agregar_inquilino_screen.dart)', [
        _buildParagraph('Pantalla para agregar nuevos inquilinos o editar existentes.'),
        _buildList([
          'Formulario con validación para ingresar datos del inquilino',
          'Manejo de creación de nuevo inquilino o actualización de uno existente'
        ]),
      ]),
    ]));
    
    // Continuación de Pantallas
    pdf.addPage(_buildChapterPage('4. Pantallas Principales (continuación)', colorPrimario, colorTextoClaro, [
      _buildSection('ExpensasEditorScreen (expensas_editor_screen.dart)', [
        _buildParagraph('Pantalla para gestionar y editar las expensas comunes del edificio.'),
        _buildList([
          'Edición del monto de expensas comunes',
          'Generación de PDF con detalle de expensas',
          'Historial de expensas anteriores'
        ]),
      ]),
      _buildSection('CuentasTransferenciaScreen (cuentas_transferencia_screen.dart)', [
        _buildParagraph('Pantalla para gestionar las cuentas bancarias disponibles para transferencias.'),
        _buildList([
          'Listar, agregar, editar y eliminar cuentas',
          'Formulario para ingreso de datos bancarios'
        ]),
      ]),
      _buildSection('TareasScreen (tareas_screen.dart)', [
        _buildParagraph('Pantalla para gestión de tareas de mantenimiento o administrativas.'),
        _buildList([
          'Listar, agregar, editar y eliminar tareas',
          'Marcar tareas como completadas',
          'Filtrar tareas por estado'
        ]),
      ]),
    ]));
    
    // Widgets
    pdf.addPage(_buildChapterPage('5. Widgets Personalizados', colorPrimario, colorTextoClaro, [
      _buildSection('MonthYearPicker (month_year_picker.dart)', [
        _buildParagraph('Widget para seleccionar mes y año, utilizado para filtrar información por período.'),
      ]),
      _buildSection('EditarInquilinoDialog (editar_inquilino_dialog.dart)', [
        _buildParagraph('Diálogo para editar información básica de un inquilino directamente desde la pantalla principal.'),
      ]),
      _buildSection('EditarExpensasDialog (editar_expensas_dialog.dart)', [
        _buildParagraph('Diálogo para editar el monto de expensas comunes.'),
      ]),
    ]));
    
    // Flujo de datos
    pdf.addPage(_buildChapterPage('6. Flujo de Datos y Funcionamiento', colorPrimario, colorTextoClaro, [
      _buildSection('Inicialización de la Aplicación', [
        _buildParagraph('1. El archivo main.dart inicializa la aplicación y carga los datos guardados a través de StorageService.'),
        _buildParagraph('2. La aplicación comienza en HomeScreen que muestra la lista de inquilinos y el resumen de pagos.'),
      ]),
      _buildSection('Gestión de Inquilinos', [
        _buildParagraph('1. El usuario puede agregar nuevos inquilinos desde HomeScreen, lo que abre AgregarInquilinoScreen.'),
        _buildParagraph('2. Los datos ingresados se validan y se guardan utilizando StorageService.'),
        _buildParagraph('3. La lista de inquilinos se actualiza y muestra en la pestaña Inquilinos.'),
      ]),
      _buildSection('Registro de Pagos', [
        _buildParagraph('1. El usuario selecciona un inquilino y registra un pago de alquiler o expensas.'),
        _buildParagraph('2. Se actualiza el estado del inquilino y se guarda mediante StorageService.'),
        _buildParagraph('3. Se puede generar un recibo PDF utilizando PdfService.'),
      ]),
      _buildSection('Gestión de Expensas', [
        _buildParagraph('1. El usuario establece el monto de expensas comunes en ExpensasEditorScreen.'),
        _buildParagraph('2. Este valor se aplica a todos los inquilinos para el período seleccionado.'),
        _buildParagraph('3. Se puede generar un PDF con el detalle de expensas.'),
      ]),
    ]));
    
    // Diagrama de arquitectura
    pdf.addPage(_buildChapterPage('7. Diagrama de Arquitectura', colorPrimario, colorTextoClaro, [
      _buildSection('Arquitectura de la Aplicación', [
        _buildParagraph('La aplicación sigue un patrón de arquitectura simplificado donde:'),
        _buildParagraph('- Los Modelos definen la estructura de datos'),
        _buildParagraph('- Los Servicios gestionan la persistencia y operaciones complejas'),
        _buildParagraph('- Las Pantallas presentan la interfaz y manejan la lógica de usuario'),
        _buildParagraph('- Los Widgets proporcionan componentes UI reutilizables'),
      ]),
      _buildSection('Flujo de Interacción', [
        _buildParagraph('1. UI (Screens/Widgets) ⟷ Lógica de Negocio (dentro de Screens)'),
        _buildParagraph('2. Lógica de Negocio ⟷ Servicios (para operaciones complejas)'),
        _buildParagraph('3. Servicios ⟷ Almacenamiento Local (SharedPreferences)'),
        _buildParagraph('Este flujo simplificado permite una aplicación compacta pero funcional para la gestión de edificios.'),
      ]),
    ]));
    
    // Guardar y abrir el PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/documentacion_edificio.pdf');
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
    
    return file.path;
  }
  
  pw.Widget _buildIndexItem(int number, String title, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 30,
            height: 30,
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              number.toString(),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 0.5),
                ),
              ),
              child: pw.Text(
                title,
                style: const pw.TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  pw.Page _buildChapterPage(String title, PdfColor colorPrimario, PdfColor colorTextoClaro, List<pw.Widget> content) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              color: colorPrimario,
              width: double.infinity,
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: colorTextoClaro,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            ...content,
          ],
        );
      },
    );
  }
  
  pw.Widget _buildSection(String title, List<pw.Widget> content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 8),
        ...content,
        pw.SizedBox(height: 15),
      ],
    );
  }
  
  pw.Widget _buildParagraph(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 12),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }
  
  pw.Widget _buildList(List<String> items) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 15, bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: items.map((item) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 5,
                  height: 5,
                  margin: const pw.EdgeInsets.only(top: 4, right: 5),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.black,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    item,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
} 
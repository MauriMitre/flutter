import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:edificio_app/models/inquilino.dart';

class DeudasService {
  // Generar y guardar un informe de deudas del inquilino
  Future<String> generarInformeDeudas(Inquilino inquilino) async {
    // Crear documento PDF
    final pdf = pw.Document();
    
    // Obtener datos del inquilino
    final nombre = '${inquilino.nombre} ${inquilino.apellido}';
    final departamento = inquilino.departamento;
    
    // Fecha actual para el informe
    final fechaActual = DateFormat('dd/MM/yyyy', 'es_ES').format(DateTime.now());
    final horaActual = DateFormat('HH:mm', 'es_ES').format(DateTime.now());
    final DateTime now = DateTime.now();
    
    // Colores principales para el PDF
    final colorPrimario = PdfColors.red700;
    final colorSecundario = PdfColors.red200;
    final colorTextoClaro = PdfColors.white;
    final colorFilaAlternada = PdfColors.grey100;
    final colorResaltado = PdfColors.red900;
    final colorSecundarioSuave = PdfColors.red50;
    final colorNegroSombra = PdfColors.grey800;
    final colorPrimarioSuave = PdfColors.red100;
    
    // Recopilar todas las deudas del inquilino
    final deudas = <Map<String, dynamic>>[];
    double totalDeuda = 0.0;
    
    // Crear lista de meses hasta el mes actual
    final mesesRegistrados = <String>[];
    
    // Obtener año y mes actual
    final int anioActual = now.year;
    final int mesActual = now.month;
    
    // Definir año mínimo (2025)
    final int anioMinimo = 2025;
    
    print('Año mínimo para deudas: $anioMinimo');
    
    // Agregar todos los meses hasta el mes actual, pero solo desde el año mínimo
    for (int anio = anioActual; anio >= anioMinimo; anio--) {
      for (int mes = 12; mes >= 1; mes--) {
        // Si estamos en el año actual, solo incluir hasta el mes actual
        if (anio == anioActual && mes > mesActual) {
          continue;
        }
        
        final mesStr = mes < 10 ? '0$mes' : '$mes';
        mesesRegistrados.add('$mesStr-$anio');
        
        // Limitar a 12 meses para evitar PDF demasiado grande
        if (mesesRegistrados.length >= 12) {
          break;
        }
      }
      
      // Limitar a 12 meses para evitar PDF demasiado grande
      if (mesesRegistrados.length >= 12) {
        break;
      }
    }
    
    // Invertir la lista para que los meses más recientes aparezcan primero
    mesesRegistrados.sort((a, b) {
      final partesA = a.split('-');
      final partesB = b.split('-');
      
      final anioA = int.parse(partesA[1]);
      final anioB = int.parse(partesB[1]);
      
      if (anioA != anioB) {
        return anioB.compareTo(anioA); // Orden descendente por año
      }
      
      final mesA = int.parse(partesA[0]);
      final mesB = int.parse(partesB[0]);
      return mesB.compareTo(mesA); // Orden descendente por mes
    });
    
    // Obtener precio de alquiler (usar valor predeterminado si es necesario)
    double precioAlquiler = inquilino.precioAlquiler;
    if (precioAlquiler <= 0) {
      precioAlquiler = 10000.0; // Valor predeterminado
    }
    
    // Obtener valor de expensas predeterminado
    double expensasPredeterminadas = 5000.0;
    // Buscar el último valor de expensas registrado
    for (final mesAnio in inquilino.expensas.keys) {
      final valorExpensas = inquilino.expensas[mesAnio] ?? 0.0;
      if (valorExpensas > 0) {
        expensasPredeterminadas = valorExpensas;
      }
    }
    
    // Imprimir información de depuración inicial
    print('Generando deudas para ${inquilino.nombre} ${inquilino.apellido}');
    print('Precio de alquiler: $precioAlquiler');
    print('Expensas predeterminadas: $expensasPredeterminadas');
    print('Meses a procesar: $mesesRegistrados');
    
    // Para cada mes hasta el actual, generar deudas
    for (final mesAnio in mesesRegistrados) {
      final partesFecha = mesAnio.split('-');
      final mes = int.parse(partesFecha[0]);
      final anio = int.parse(partesFecha[1]);
      
      final fechaFormateada = DateFormat('MMMM yyyy', 'es_ES').format(DateTime(anio, mes));
      
      // Verificar si está pagado explícitamente
      final bool pagadoAlquiler = inquilino.pagosAlquiler.containsKey(mesAnio) && inquilino.pagosAlquiler[mesAnio] == true;
      final bool pagadoExpensas = inquilino.pagosExpensas.containsKey(mesAnio) && inquilino.pagosExpensas[mesAnio] == true;
      
      print('Procesando mes: $mesAnio (${fechaFormateada})');
      print('  - Alquiler pagado: $pagadoAlquiler');
      print('  - Expensas pagadas: $pagadoExpensas');
      
      // Agregar deuda de alquiler si no está pagado
      if (!pagadoAlquiler) {
        deudas.add({
          'periodo': fechaFormateada,
          'mesAnio': mesAnio,
          'concepto': 'Alquiler',
          'monto': precioAlquiler,
        });
        totalDeuda += precioAlquiler;
        print('  - Agregada deuda de alquiler: \$${precioAlquiler.toStringAsFixed(2)}');
      }
      
      // Agregar deuda de expensas si no está pagado
      if (!pagadoExpensas) {
        // Usar valor específico del mes o el predeterminado
        double expensasMes = inquilino.getExpensasPorMes(mesAnio);
        if (expensasMes <= 0) {
          expensasMes = expensasPredeterminadas;
        }
        
        deudas.add({
          'periodo': fechaFormateada,
          'mesAnio': mesAnio,
          'concepto': 'Expensas',
          'monto': expensasMes,
        });
        totalDeuda += expensasMes;
        print('  - Agregada deuda de expensas: \$${expensasMes.toStringAsFixed(2)}');
      }
      
      // Agregar montos pendientes si existen
      double montoPendiente = inquilino.getMontoPendiente(mesAnio);
      if (montoPendiente > 0) {
        deudas.add({
          'periodo': fechaFormateada,
          'mesAnio': mesAnio,
          'concepto': 'Monto Pendiente',
          'monto': montoPendiente,
        });
        totalDeuda += montoPendiente;
        print('  - Agregado monto pendiente: \$${montoPendiente.toStringAsFixed(2)}');
      }
    }
    
    // Verificar si hay deudas
    if (deudas.isEmpty) {
      print('¡ALERTA! No se generaron deudas para el inquilino.');
      // Agregar al menos una fila de ejemplo para asegurar que la tabla no esté vacía
      final mesActualStr = mesActual < 10 ? '0$mesActual' : '$mesActual';
      final mesAnioActual = '$mesActualStr-$anioActual';
      final fechaActualFormateada = DateFormat('MMMM yyyy', 'es_ES').format(DateTime(anioActual, mesActual));
      
      deudas.add({
        'periodo': fechaActualFormateada,
        'mesAnio': mesAnioActual,
        'concepto': 'Sin deudas pendientes desde 2025',
        'monto': 0.0,
      });
      totalDeuda = 0.0;
      print('  - Agregada fila indicando que no hay deudas pendientes');
    }
    
    // Ordenar deudas por fecha (más recientes primero)
    deudas.sort((a, b) {
      final mesAnioA = a['mesAnio'] as String;
      final mesAnioB = b['mesAnio'] as String;
      
      final partesA = mesAnioA.split('-');
      final partesB = mesAnioB.split('-');
      
      final anioA = int.parse(partesA[1]);
      final anioB = int.parse(partesB[1]);
      
      if (anioA != anioB) {
        return anioB.compareTo(anioA); // Orden descendente por año
      }
      
      final mesA = int.parse(partesA[0]);
      final mesB = int.parse(partesB[0]);
      return mesB.compareTo(mesA); // Orden descendente por mes
    });
    
    print('Total de deudas generadas: ${deudas.length}');
    print('Monto total de deuda: \$${totalDeuda.toStringAsFixed(2)}');
    
    // Dividir las deudas en grupos para manejar múltiples páginas si es necesario
    final int deudasPorPagina = 15; // Máximo de filas por página
    final List<List<Map<String, dynamic>>> grupoDeudas = [];
    
    for (int i = 0; i < deudas.length; i += deudasPorPagina) {
      final end = (i + deudasPorPagina < deudas.length) ? i + deudasPorPagina : deudas.length;
      grupoDeudas.add(deudas.sublist(i, end));
    }
    
    // Si no hay grupos (no debería ocurrir debido a la verificación anterior), crear uno vacío
    if (grupoDeudas.isEmpty) {
      grupoDeudas.add([]);
    }
    
    // Agregar páginas al PDF
    for (int pageIndex = 0; pageIndex < grupoDeudas.length; pageIndex++) {
      final deudasEnPagina = grupoDeudas[pageIndex];
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Cabecera con título
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  decoration: pw.BoxDecoration(
                    color: colorPrimario,
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(10),
                      topRight: pw.Radius.circular(10),
                    ),
                    boxShadow: [
                      pw.BoxShadow(
                        color: colorNegroSombra,
                        blurRadius: 3,
                        offset: const PdfPoint(0, 2),
                      ),
                    ],
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'INFORME DE DEUDAS',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: colorTextoClaro,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Pagos pendientes (desde 2025)',
                            style: pw.TextStyle(
                              fontSize: 16,
                              color: colorTextoClaro,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Fecha: $fechaActual',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: colorTextoClaro,
                            ),
                          ),
                          pw.Text(
                            'Hora: $horaActual',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: colorTextoClaro,
                            ),
                          ),
                          if (grupoDeudas.length > 1)
                            pw.Text(
                              'Página ${pageIndex + 1} de ${grupoDeudas.length}',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: colorTextoClaro,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Datos del inquilino
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: colorSecundarioSuave,
                    borderRadius: const pw.BorderRadius.only(
                      bottomLeft: pw.Radius.circular(10),
                      bottomRight: pw.Radius.circular(10),
                    ),
                    border: pw.Border.all(
                      color: colorSecundario,
                      width: 0.5,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DATOS DEL INQUILINO',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: colorPrimario,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                  children: [
                                    pw.Text(
                                      'Nombre: ',
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    pw.Text(
                                      nombre,
                                      style: const pw.TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                pw.SizedBox(height: 5),
                                pw.Row(
                                  children: [
                                    pw.Text(
                                      'Departamento: ',
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    pw.Text(
                                      departamento,
                                      style: const pw.TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            decoration: pw.BoxDecoration(
                              color: colorPrimarioSuave,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                              border: pw.Border.all(
                                color: colorPrimario,
                                width: 0.5,
                              ),
                            ),
                            child: pw.Column(
                              children: [
                                pw.Text(
                                  'DEUDA TOTAL',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                    color: colorPrimario,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  '\$${totalDeuda.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                    color: colorResaltado,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Tabla de deudas - Siempre mostrar la tabla
                pw.Table(
                  border: pw.TableBorder.all(
                    color: colorPrimarioSuave,
                    width: 0.5,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3), // Período
                    1: const pw.FlexColumnWidth(3), // Concepto
                    2: const pw.FlexColumnWidth(2), // Monto
                  },
                  children: [
                    // Encabezado de la tabla
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: colorPrimario,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Período',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: colorTextoClaro,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Concepto',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: colorTextoClaro,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Monto',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: colorTextoClaro,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    // Filas de deudas
                    ...deudasEnPagina.asMap().entries.map((entry) {
                      final index = entry.key;
                      final deuda = entry.value;
                      final bool filaAlternada = index % 2 == 1;
                      
                      // Imprimir información de depuración de cada fila
                      print('Renderizando fila $index: ${deuda['periodo']} - ${deuda['concepto']} - \$${(deuda['monto'] as double).toStringAsFixed(2)}');
                      
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: filaAlternada ? colorFilaAlternada : PdfColors.white,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              deuda['periodo'] as String,
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              deuda['concepto'] as String,
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '\$${(deuda['monto'] as double).toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    // Fila de total (solo en la última página)
                    if (pageIndex == grupoDeudas.length - 1)
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: colorPrimarioSuave,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '',
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'TOTAL',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '\$${totalDeuda.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: colorResaltado,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                
                pw.SizedBox(height: 30),
                
                // Pie de página
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Este informe muestra las deudas pendientes del inquilino hasta ${DateFormat('MMMM yyyy', 'es_ES').format(now)} (a partir de 2025).',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Generado el $fechaActual a las $horaActual',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    
    // Imprimir información de depuración
    print('Generando PDF de deudas para ${inquilino.nombre} ${inquilino.apellido}');
    print('Cantidad de deudas generadas: ${deudas.length}');
    print('Detalles de las deudas:');
    for (var deuda in deudas) {
      print('  - ${deuda['periodo']} - ${deuda['concepto']} - \$${(deuda['monto'] as double).toStringAsFixed(2)}');
    }
    
    // Guardar el PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/deudas_${inquilino.apellido}_${inquilino.nombre}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    print('PDF guardado en: ${file.path}');
    
    // Abrir el PDF
    await OpenFile.open(file.path);
    
    return file.path;
  }

  // Verificar si un inquilino tiene deudas
  bool tieneDeudas(Inquilino inquilino) {
    // Para la funcionalidad de deudas a partir de 2025, siempre devolvemos true
    // ya que queremos mostrar el botón para todos los inquilinos
    print('Verificando si ${inquilino.nombre} ${inquilino.apellido} tiene deudas: true (forzado)');
    return true;
  }
}

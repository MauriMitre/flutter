import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:edificio_app/models/inquilino.dart';

class ExpensaItem {
  final String articulo;
  final String descripcion;
  final double importe;
  final double saldoPorUnidad;

  ExpensaItem({
    required this.articulo,
    required this.descripcion,
    required this.importe,
    required this.saldoPorUnidad,
  });
}

class PdfService {
  // Generar y guardar el recibo de pago
  Future<String> generarRecibo(Inquilino inquilino, String mesAnio) async {
    // Crear documento PDF
    final pdf = pw.Document();
    
    // Obtener datos del inquilino
    final nombre = '${inquilino.nombre} ${inquilino.apellido}';
    final departamento = inquilino.departamento;
    final alquiler = inquilino.precioAlquiler;
    final expensas = inquilino.getExpensasPorMes(mesAnio);
    final total = alquiler + expensas;
    
    // Obtener método de pago
    final metodoPago = inquilino.getMetodoPago(mesAnio);
    final esPagoTransferencia = metodoPago == MetodoPago.transferencia;
    final cuentaTransferencia = inquilino.getCuentaTransferencia(mesAnio);
    final metodoPagoTexto = esPagoTransferencia 
        ? 'Transferencia a cuenta: $cuentaTransferencia' 
        : 'Efectivo';
    
    // Formatear fecha para mostrar
    final partesFecha = mesAnio.split('-');
    final mes = int.parse(partesFecha[0]);
    final anio = int.parse(partesFecha[1]);
    final fechaFormateada = DateFormat('MMMM yyyy', 'es_ES').format(DateTime(anio, mes));
    
    // Fecha actual para el recibo
    final fechaActual = DateFormat('dd/MM/yyyy', 'es_ES').format(DateTime.now());
    final horaActual = DateFormat('HH:mm', 'es_ES').format(DateTime.now());
    
    // Colores principales para el PDF
    const colorPrimario = PdfColors.blue700;
    const colorSecundario = PdfColors.blue200;
    const colorTextoClaro = PdfColors.white;
    const colorFilaAlternada = PdfColors.grey100;
    const colorResaltado = PdfColors.blue900;
    const colorSecundarioSuave = PdfColors.blue50;
    const colorNegroSombra = PdfColors.grey800;
    const colorPrimarioSuave = PdfColors.blue100;
    
    // Agregar página al PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabecera con título y número de recibo
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                decoration: const pw.BoxDecoration(
                  color: colorPrimario,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(10),
                    topRight: pw.Radius.circular(10),
                  ),
                  boxShadow: [
                    pw.BoxShadow(
                      color: colorNegroSombra,
                      blurRadius: 3,
                      offset: PdfPoint(0, 2),
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
                          'RECIBO DE PAGO',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: colorTextoClaro,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          fechaFormateada.toUpperCase(),
                          style: const pw.TextStyle(
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
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: colorTextoClaro,
                          ),
                        ),
                        pw.Text(
                          'Hora: $horaActual',
                          style: const pw.TextStyle(
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
                                'PERÍODO',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10,
                                  color: colorPrimario,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                fechaFormateada,
                                style: pw.TextStyle(
                                  fontSize: 12,
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
              
              // Detalle del pago
              pw.Container(
                decoration: const pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
                  boxShadow: [
                    pw.BoxShadow(
                      color: colorNegroSombra,
                      blurRadius: 3,
                      offset: PdfPoint(0, 1),
                    ),
                  ],
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 10,
                  verticalRadius: 10,
                  child: pw.Column(
                    children: [
                      // Encabezado del detalle
                      pw.Container(
                        color: colorPrimario,
                        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        width: double.infinity,
                        child: pw.Text(
                          'DETALLE DEL PAGO',
                          style: pw.TextStyle(
                            color: colorTextoClaro,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      
                      // Conceptos de pago
                      pw.Container(
                        color: PdfColors.white,
                        padding: const pw.EdgeInsets.all(15),
                        child: pw.Column(
                          children: [
                            // Encabezados
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'CONCEPTO',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 12,
                                    color: colorPrimario,
                                  ),
                                ),
                                pw.Text(
                                  'MONTO',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 12,
                                    color: colorPrimario,
                                  ),
                                ),
                              ],
                            ),
                            pw.Divider(color: colorSecundario),
                            
                            // Fila de alquiler
                            pw.Container(
                              color: colorFilaAlternada,
                              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Alquiler',
                                    style: const pw.TextStyle(fontSize: 12),
                                  ),
                                  pw.Text(
                                    '\$${alquiler.toStringAsFixed(2)}',
                                    style: const pw.TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Fila de expensas
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Expensas',
                                    style: const pw.TextStyle(fontSize: 12),
                                  ),
                                  pw.Text(
                                    '\$${expensas.toStringAsFixed(2)}',
                                    style: const pw.TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Separador antes del total
                            pw.Divider(color: colorSecundario),
                            
                            // Fila de total
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                              decoration: const pw.BoxDecoration(
                                color: colorPrimarioSuave,
                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                              ),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'TOTAL',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 14,
                                      color: colorResaltado,
                                    ),
                                  ),
                                  pw.Text(
                                    '\$${total.toStringAsFixed(2)}',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 14,
                                      color: colorResaltado,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            pw.SizedBox(height: 15),
                            
                            // Método de pago
                            pw.Container(
                              padding: const pw.EdgeInsets.all(10),
                              decoration: pw.BoxDecoration(
                                color: colorSecundarioSuave,
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                                border: pw.Border.all(
                                  color: colorSecundario,
                                ),
                              ),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    'Método de pago: ',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 12,
                                      color: colorPrimario,
                                    ),
                                  ),
                                  pw.Text(
                                    metodoPagoTexto,
                                    style: const pw.TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Firmas
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 150,
                        height: 50,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide()),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Firma del Inquilino',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 150,
                        height: 50,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide()),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Mitre Mauricio José',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.Spacer(),
              
              // Pie de página
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Column(
                  children: [
                    pw.Divider(color: colorSecundario),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'ESTE RECIBO ES VÁLIDO COMO COMPROBANTE DE PAGO',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Av. Independencia 1578 - ${DateTime.now().year}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: colorPrimario,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    
    // Guardar el PDF
    final output = await getTemporaryDirectory();
    final nombreArchivo = 'recibo_${inquilino.apellido.toLowerCase()}_${inquilino.departamento}_$mesAnio.pdf';
    final file = File('${output.path}/$nombreArchivo');
    await file.writeAsBytes(await pdf.save());
    
    // Abrir el PDF
    OpenFile.open(file.path);
    
    return file.path;
  }

  // Generar y guardar el PDF de expensas
  Future<String> generarExpensasPdf(String mesAnio, {List<ExpensaItem>? itemsPersonalizados}) async {
    // Crear documento PDF
    final pdf = pw.Document();
    
    // Formatear fecha para mostrar
    final partesFecha = mesAnio.split('-');
    final mes = int.parse(partesFecha[0]);
    final anio = int.parse(partesFecha[1]);
    final fechaFormateada = DateFormat('MMMM yyyy', 'es_ES').format(DateTime(anio, mes));
    
    // Fecha actual para el encabezado
    final fechaGeneracion = DateFormat('dd/MM/yyyy', 'es_ES').format(DateTime.now());
    
    // Datos de administración
    const administradorNombre = "Mauricio José Mitre";
    const administradorTel = "3814093864";
    const administradorEmail = "mitremauricio@gmail.com";
    
    // Crear lista de artículos de expensas (predeterminada si no se proporcionan artículos personalizados)
    final items = itemsPersonalizados ?? [
      ExpensaItem(
        articulo: "Servicio de limpieza",
        descripcion: "Limpieza unitaria semanal de palieres y escalera; Corresponde a dos semanas de ${DateFormat('MMMM', 'es_ES').format(DateTime(anio, mes))}",
        importe: 25000.00,
        saldoPorUnidad: 1250.00,
      ),
      ExpensaItem(
        articulo: "Artículos de limpieza",
        descripcion: "",
        importe: 15000.00,
        saldoPorUnidad: 750.00,
      ),
      ExpensaItem(
        articulo: "Servicio de recoleccion de residuos",
        descripcion: "Correspondinete a cuatro semanas de ${DateFormat('MMMM', 'es_ES').format(DateTime(anio, mes))}",
        importe: 20000.00,
        saldoPorUnidad: 1000.00,
      ),
      ExpensaItem(
        articulo: "Servicio de agua potable y saneamiento",
        descripcion: "El monto total se divide por la cantidad de unidades de vivienda, siendo 21 en total.",
        importe: 650067.00,
        saldoPorUnidad: 30955.57,
      ),
      ExpensaItem(
        articulo: "Energia electrica",
        descripcion: "Luz palieres, escalera y entrada mas bomba de agua",
        importe: 33610.00,
        saldoPorUnidad: 1680.50,
      ),
    ];
    
    // Calcular totales
    double totalImporte = 0;
    double totalSaldoUnidad = 0;
    for (var item in items) {
      totalImporte += item.importe;
      totalSaldoUnidad += item.saldoPorUnidad;
    }
    
          // Colores principales para el PDF
      const colorPrimario = PdfColors.blue700;
      const colorSecundario = PdfColors.blue200;
      const colorTextoClaro = PdfColors.white;
      const colorFilaAlternada = PdfColors.grey100;
      const colorResaltado = PdfColors.blue900;
      
      // Colores adicionales para efectos
      const colorSecundarioSuave = PdfColors.blue50;
      const colorNegroSombra = PdfColors.grey800;
      const colorPrimarioSuave = PdfColors.blue100;
    
    // Agregar página al PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado con título y fecha
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                decoration: const pw.BoxDecoration(
                  color: colorPrimario,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(10),
                    topRight: pw.Radius.circular(10),
                  ),
                  boxShadow: [
                    pw.BoxShadow(
                      color: colorNegroSombra,
                      blurRadius: 3,
                      offset: PdfPoint(0, 2),
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
                          'LIQUIDACIÓN DE EXPENSAS',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: colorTextoClaro,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          fechaFormateada.toUpperCase(),
                          style: const pw.TextStyle(
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
                          'Documento Nº: EXP-$mesAnio',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: colorTextoClaro,
                          ),
                        ),
                        pw.Text(
                          'Fecha de emisión: $fechaGeneracion',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: colorTextoClaro,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Información de administración
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
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ADMINISTRACIÓN',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: colorPrimario,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Administrador: $administradorNombre',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'Contacto: $administradorTel',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                          decoration: const pw.BoxDecoration(
                            color: colorPrimario,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(15)),
                          ),
                          child: pw.Text(
                            'Email: $administradorEmail',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: colorTextoClaro,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Sección de detalle de expensas
              pw.Container(
                width: double.infinity,
                decoration: const pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
                  boxShadow: [
                    pw.BoxShadow(
                      color: colorNegroSombra,
                      blurRadius: 3,
                      offset: PdfPoint(0, 1),
                    ),
                  ],
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 10,
                  verticalRadius: 10,
                  child: pw.Column(
                    children: [
                      // Encabezado de la tabla
                      pw.Container(
                        color: colorPrimario,
                        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                'CONCEPTO',
                                style: pw.TextStyle(
                                  color: colorTextoClaro,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              flex: 5,
                              child: pw.Text(
                                'DETALLE',
                                style: pw.TextStyle(
                                  color: colorTextoClaro,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                'MONTO TOTAL',
                                style: pw.TextStyle(
                                  color: colorTextoClaro,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                'POR UNIDAD',
                                style: pw.TextStyle(
                                  color: colorTextoClaro,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Filas de la tabla
                      ...items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isEven = index % 2 == 0;
                        
                        return pw.Container(
                          color: isEven ? colorFilaAlternada : PdfColors.white,
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Expanded(
                                flex: 3,
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Text(
                                    item.articulo,
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 5,
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Text(
                                    item.descripcion,
                                    style: const pw.TextStyle(fontSize: 10),
                                    textAlign: pw.TextAlign.justify,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.all(8),
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(
                                    '\$${item.importe.toStringAsFixed(2)}',
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.all(8),
                                  alignment: pw.Alignment.centerRight,
                                  decoration: const pw.BoxDecoration(
                                    color: colorSecundarioSuave,
                                    border: pw.Border(
                                      left: pw.BorderSide(
                                        color: colorSecundario,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: pw.Text(
                                    '\$${item.saldoPorUnidad.toStringAsFixed(2)}',
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      // Fila de totales
                      pw.Container(
                        decoration: const pw.BoxDecoration(
                          color: colorPrimarioSuave,
                          border: pw.Border(
                            top: pw.BorderSide(
                              color: colorPrimario,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 8,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(8),
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  'TOTAL GENERAL',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 12,
                                    color: colorResaltado,
                                  ),
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(8),
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  '\$${totalImporte.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 12,
                                    color: colorResaltado,
                                  ),
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(8),
                                alignment: pw.Alignment.centerRight,
                                decoration: const pw.BoxDecoration(
                                  color: colorSecundarioSuave,
                                  border: pw.Border(
                                    left: pw.BorderSide(
                                      color: colorSecundario,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: pw.Text(
                                  '\$${totalSaldoUnidad.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 12,
                                    color: colorResaltado,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Sección de notas y aclaraciones
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(
                    color: PdfColors.grey300,
                    width: 0.5,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'NOTAS IMPORTANTES:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: colorPrimario,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '- El pago de expensas debe realizarse dentro de los primeros 10 días de cada mes.',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '- Los importes de las expensas están sujetos a variaciones según los servicios utilizados en el período.',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '- Para consultas o reclamos, contactar al administrador dentro de los 5 días posteriores a la recepción.',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              
              // Pie de página
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Column(
                  children: [
                    pw.Divider(color: colorSecundario),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'DOCUMENTO GENERADO ELECTRÓNICAMENTE',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Av. Independencia 1578 - Gestión de Expensas ${DateTime.now().year}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: colorPrimario,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    
    // Guardar el PDF
    final output = await getTemporaryDirectory();
    final nombreArchivo = 'expensas_${fechaFormateada.toLowerCase().replaceAll(' ', '_')}.pdf';
    final file = File('${output.path}/$nombreArchivo');
    await file.writeAsBytes(await pdf.save());
    
    // Abrir el PDF
    OpenFile.open(file.path);
    
    return file.path;
  }

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
    
    // Colores principales para el PDF
    const colorPrimario = PdfColors.red700;
    const colorSecundario = PdfColors.red200;
    const colorTextoClaro = PdfColors.white;
    const colorFilaAlternada = PdfColors.grey100;
    const colorResaltado = PdfColors.red900;
    const colorSecundarioSuave = PdfColors.red50;
    const colorNegroSombra = PdfColors.grey800;
    const colorPrimarioSuave = PdfColors.red100;
    
    // Recopilar todas las deudas del inquilino
    final deudas = <Map<String, dynamic>>[];
    double totalDeuda = 0.0;
    
    // Obtener todos los meses con pagos registrados
    final mesesRegistrados = <String>{};
    for (var mesAnio in inquilino.pagos.keys) {
      mesesRegistrados.add(mesAnio);
    }
    for (var mesAnio in inquilino.pagosAlquiler.keys) {
      mesesRegistrados.add(mesAnio);
    }
    for (var mesAnio in inquilino.pagosExpensas.keys) {
      mesesRegistrados.add(mesAnio);
    }
    for (var mesAnio in inquilino.montosPendientes.keys) {
      mesesRegistrados.add(mesAnio);
    }
    
    // Para cada mes, verificar si hay deudas
    for (final mesAnio in mesesRegistrados) {
      final pagadoAlquiler = inquilino.haPagadoAlquiler(mesAnio);
      final pagadoExpensas = inquilino.haPagadoExpensas(mesAnio);
      final montoPendiente = inquilino.getMontoPendiente(mesAnio);
      
      // Formatear fecha para mostrar
      final partesFecha = mesAnio.split('-');
      final mes = int.parse(partesFecha[0]);
      final anio = int.parse(partesFecha[1]);
      final fechaFormateada = DateFormat('MMMM yyyy', 'es_ES').format(DateTime(anio, mes));
      
      // Verificar deuda de alquiler
      if (!pagadoAlquiler) {
        deudas.add({
          'periodo': fechaFormateada,
          'mesAnio': mesAnio,
          'concepto': 'Alquiler',
          'monto': inquilino.precioAlquiler,
        });
        totalDeuda += inquilino.precioAlquiler;
      }
      
      // Verificar deuda de expensas
      if (!pagadoExpensas) {
        final expensasMes = inquilino.getExpensasPorMes(mesAnio);
        deudas.add({
          'periodo': fechaFormateada,
          'mesAnio': mesAnio,
          'concepto': 'Expensas',
          'monto': expensasMes,
        });
        totalDeuda += expensasMes;
      }
      
      // Verificar montos pendientes
      if (montoPendiente > 0) {
        deudas.add({
          'periodo': fechaFormateada,
          'mesAnio': mesAnio,
          'concepto': 'Monto Pendiente',
          'monto': montoPendiente,
        });
        totalDeuda += montoPendiente;
      }
    }
    
    // Ordenar deudas por fecha (más antiguas primero)
    deudas.sort((a, b) {
      final mesAnioA = a['mesAnio'] as String;
      final mesAnioB = b['mesAnio'] as String;
      
      final partesA = mesAnioA.split('-');
      final partesB = mesAnioB.split('-');
      
      final anioA = int.parse(partesA[1]);
      final anioB = int.parse(partesB[1]);
      
      if (anioA != anioB) {
        return anioA.compareTo(anioB);
      }
      
      final mesA = int.parse(partesA[0]);
      final mesB = int.parse(partesB[0]);
      return mesA.compareTo(mesB);
    });
    
    // Agregar página al PDF
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
                decoration: const pw.BoxDecoration(
                  color: colorPrimario,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(10),
                    topRight: pw.Radius.circular(10),
                  ),
                  boxShadow: [
                    pw.BoxShadow(
                      color: colorNegroSombra,
                      blurRadius: 3,
                      offset: PdfPoint(0, 2),
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
                          'Detalle de pagos pendientes',
                          style: const pw.TextStyle(
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
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: colorTextoClaro,
                          ),
                        ),
                        pw.Text(
                          'Hora: $horaActual',
                          style: const pw.TextStyle(
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
              
              // Tabla de deudas
              deudas.isEmpty
                  ? pw.Center(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(20),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green50,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                          border: pw.Border.all(
                            color: PdfColors.green300,
                            width: 0.5,
                          ),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              '¡El inquilino no tiene deudas pendientes!',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green800,
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              'Todos los pagos están al día',
                              style: const pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.green800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : pw.Table(
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
                          decoration: const pw.BoxDecoration(
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
                        ...deudas.asMap().entries.map((entry) {
                          final index = entry.key;
                          final deuda = entry.value;
                          final bool filaAlternada = index % 2 == 1;
                          
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
                        // Fila de total
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
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
                      'Este informe es un detalle de las deudas pendientes del inquilino.',
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
    
    // Guardar el PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/deudas_${inquilino.apellido}_${inquilino.nombre}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    // Abrir el PDF
    await OpenFile.open(file.path);
    
    return file.path;
  }
}

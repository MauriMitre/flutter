import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/pdf_service.dart';

class ExpensasEditorScreen extends StatefulWidget {
  final String mesAnio;

  const ExpensasEditorScreen({Key? key, required this.mesAnio}) : super(key: key);

  @override
  ExpensasEditorScreenState createState() => ExpensasEditorScreenState();
}

class ExpensasEditorScreenState extends State<ExpensasEditorScreen> {
  List<ExpensaItem> _items = [];
  bool _isLoading = true;
  late String _fechaFormateada;
  
  @override
  void initState() {
    super.initState();
    _cargarItems();
  }
  
  void _cargarItems() {
    setState(() => _isLoading = true);
    
    try {
      // Formatear fecha para mostrar
      final partesFecha = widget.mesAnio.split('-');
      final mes = int.parse(partesFecha[0]);
      final anio = int.parse(partesFecha[1]);
      _fechaFormateada = DateFormat('MMMM yyyy', 'es_ES').format(DateTime(anio, mes));
      
      // Crear lista de artículos de expensas predeterminados
      _items = [
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
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar artículos: $e')),
      );
    }
  }
  
  void _agregarItem() {
    final articuloController = TextEditingController();
    final descripcionController = TextEditingController();
    final importeController = TextEditingController();
    final saldoController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar artículo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: articuloController,
                decoration: const InputDecoration(
                  labelText: 'Artículo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: importeController,
                decoration: const InputDecoration(
                  labelText: 'Importe',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: saldoController,
                decoration: const InputDecoration(
                  labelText: 'Saldo por unidad',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (articuloController.text.isEmpty || 
                  importeController.text.isEmpty || 
                  saldoController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debe completar los campos obligatorios')),
                );
                return;
              }
              
              final double importe = double.tryParse(importeController.text) ?? 0;
              final double saldo = double.tryParse(saldoController.text) ?? 0;
              
              setState(() {
                _items.add(
                  ExpensaItem(
                    articulo: articuloController.text,
                    descripcion: descripcionController.text,
                    importe: importe,
                    saldoPorUnidad: saldo,
                  ),
                );
              });
              
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
  
  void _editarItem(ExpensaItem item, int index) {
    final articuloController = TextEditingController(text: item.articulo);
    final descripcionController = TextEditingController(text: item.descripcion);
    final importeController = TextEditingController(text: item.importe.toString());
    final saldoController = TextEditingController(text: item.saldoPorUnidad.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar artículo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: articuloController,
                decoration: const InputDecoration(
                  labelText: 'Artículo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: importeController,
                decoration: const InputDecoration(
                  labelText: 'Importe',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: saldoController,
                decoration: const InputDecoration(
                  labelText: 'Saldo por unidad',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (articuloController.text.isEmpty || 
                  importeController.text.isEmpty || 
                  saldoController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debe completar los campos obligatorios')),
                );
                return;
              }
              
              final double importe = double.tryParse(importeController.text) ?? 0;
              final double saldo = double.tryParse(saldoController.text) ?? 0;
              
              setState(() {
                _items[index] = ExpensaItem(
                  articulo: articuloController.text,
                  descripcion: descripcionController.text,
                  importe: importe,
                  saldoPorUnidad: saldo,
                );
              });
              
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
  
  void _eliminarItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro que desea eliminar este artículo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _items.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _generarPdf() async {
    try {
      final pdfService = PdfService();
      await pdfService.generarExpensasPdf(widget.mesAnio, itemsPersonalizados: _items);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF de expensas generado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Calcular totales
    double totalImporte = 0;
    double totalSaldoUnidad = 0;
    for (var item in _items) {
      totalImporte += item.importe;
      totalSaldoUnidad += item.saldoPorUnidad;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Expensas ${_isLoading ? "" : _fechaFormateada}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generarPdf,
            tooltip: 'Generar PDF',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarItem,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Totales:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Importe: \$${totalImporte.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Saldo por unidad: \$${totalSaldoUnidad.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.articulo,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editarItem(item, index),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarItem(index),
                                    tooltip: 'Eliminar',
                                  ),
                                ],
                              ),
                              if (item.descripcion.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(item.descripcion),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Importe: \$${item.importe.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Unidad: \$${item.saldoPorUnidad.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

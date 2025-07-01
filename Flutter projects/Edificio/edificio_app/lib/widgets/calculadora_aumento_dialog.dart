import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/inquilino.dart';
import '../services/log_service.dart';

class CalculadoraAumentoDialog extends StatefulWidget {
  final List<Inquilino> inquilinos;
  final Function(Inquilino) onGuardarInquilino;
  final DateTime selectedDate;

  const CalculadoraAumentoDialog({
    Key? key,
    required this.inquilinos,
    required this.onGuardarInquilino,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<CalculadoraAumentoDialog> createState() => _CalculadoraAumentoDialogState();
}

class _CalculadoraAumentoDialogState extends State<CalculadoraAumentoDialog> {
  // Controlador para el porcentaje general
  final TextEditingController porcentajeGeneralController = TextEditingController();
  
  // Mapa para almacenar los porcentajes individuales por inquilino
  late Map<String, TextEditingController> porcentajesIndividuales = {};
  
  // Mapa para almacenar si un inquilino está seleccionado
  late Map<String, bool> inquilinosSeleccionados = {};
  
  // Mapa para almacenar los nuevos montos calculados
  late Map<String, double> nuevosMontos = {};
  
  // Obtener el mes actual para el registro histórico
  late final String mesActual;
  
  @override
  void initState() {
    super.initState();
    
    mesActual = DateFormat('MM-yyyy').format(widget.selectedDate);
    
    // Inicializar los controladores y selecciones para cada inquilino
    for (final inquilino in widget.inquilinos) {
      porcentajesIndividuales[inquilino.id] = TextEditingController();
      inquilinosSeleccionados[inquilino.id] = false;
      
      // Obtener el precio específico para este mes
      double precioMes = inquilino.getPrecioAlquilerPorMes(mesActual);
      nuevosMontos[inquilino.id] = precioMes;
      log.d('Inicializando inquilino ${inquilino.nombre}: precio para $mesActual = $precioMes');
    }
  }
  
  @override
  void dispose() {
    // Desechar controladores antes de cerrar
    porcentajeGeneralController.dispose();
    for (final controller in porcentajesIndividuales.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Aumentos'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _aplicarAumentosTodos(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Panel de porcentaje general
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(51),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Porcentaje general',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: porcentajeGeneralController,
                          decoration: InputDecoration(
                            labelText: 'Porcentaje %',
                            hintText: 'Ej: 15',
                            suffixText: '%',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          final porcentajeGeneral = porcentajeGeneralController.text;
                          if (porcentajeGeneral.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ingrese un porcentaje general'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          
                          // Solo actualizar el valor en los campos, sin aplicar el aumento todavía
                          setState(() {
                            for (final inquilino in widget.inquilinos) {
                              if (inquilinosSeleccionados[inquilino.id] == true) {
                                porcentajesIndividuales[inquilino.id]!.text = porcentajeGeneral;
                                
                                // Calcular el nuevo monto para mostrar (pero no aplicar)
                                final porcentaje = double.tryParse(porcentajeGeneral) ?? 0;
                                final precioActual = inquilino.getPrecioAlquilerPorMes(mesActual);
                                nuevosMontos[inquilino.id] = precioActual + 
                                  (precioActual * porcentaje / 100);
                              }
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        child: const Text('Calcular'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: widget.inquilinos.every((i) => inquilinosSeleccionados[i.id] == true),
                        onChanged: (value) {
                          setState(() {
                            for (final inquilino in widget.inquilinos) {
                              inquilinosSeleccionados[inquilino.id] = value ?? false;
                            }
                          });
                        },
                      ),
                      const Flexible(
                        child: Text(
                          'Seleccionar todos',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            for (final inquilino in widget.inquilinos) {
                              inquilinosSeleccionados[inquilino.id] = false;
                              porcentajesIndividuales[inquilino.id]!.clear();
                              nuevosMontos[inquilino.id] = inquilino.precioAlquiler;
                            }
                            porcentajeGeneralController.clear();
                          });
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Limpiar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Lista de inquilinos
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.inquilinos.length,
                itemBuilder: (context, index) {
                  final inquilino = widget.inquilinos[index];
                  final nuevoMonto = nuevosMontos[inquilino.id] ?? inquilino.precioAlquiler;
                  final aumento = nuevoMonto - inquilino.precioAlquiler;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: inquilinosSeleccionados[inquilino.id] == true 
                            ? Colors.blue.shade300 
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: inquilinosSeleccionados[inquilino.id],
                                onChanged: (value) {
                                  setState(() {
                                    inquilinosSeleccionados[inquilino.id] = value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${inquilino.nombre} ${inquilino.apellido}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      'Departamento: ${inquilino.departamento}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Información de precios
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Alquiler actual: \$${inquilino.precioAlquiler.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Nuevo alquiler: \$${nuevoMonto.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: aumento > 0 ? Colors.green.shade700 : Colors.grey,
                                      ),
                                    ),
                                    if (aumento > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Aumento: \$${aumento.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              // Controles de porcentaje y aplicar
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: TextField(
                                      controller: porcentajesIndividuales[inquilino.id],
                                      decoration: InputDecoration(
                                        labelText: '%',
                                        hintText: '0',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                      ],
                                      onChanged: (value) {
                                        // Solo calcular el nuevo monto para mostrar
                                        setState(() {
                                          final porcentaje = double.tryParse(value) ?? 0;
                                          final precioActual = inquilino.getPrecioAlquilerPorMes(mesActual);
                                          nuevosMontos[inquilino.id] = precioActual + 
                                            (precioActual * porcentaje / 100);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: 120,
                                    child: ElevatedButton(
                                      onPressed: () => _aplicarAumentoIndividual(inquilino, context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                      child: const Text(
                                        'Aplicar',
                                        style: TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ],
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
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => _aplicarAumentosTodos(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Aplicar a todos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _aplicarAumentoIndividual(Inquilino inquilino, BuildContext context) {
    final porcentaje = double.tryParse(
      porcentajesIndividuales[inquilino.id]!.text) ?? 0;
    
    if (porcentaje <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un porcentaje válido'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Obtener el precio actual para el mes seleccionado
    final precioActual = inquilino.getPrecioAlquilerPorMes(mesActual);
    
    // Calcular el nuevo monto
    final nuevoMonto = precioActual + (precioActual * porcentaje / 100);
    log.d('Calculando aumento para ${inquilino.nombre}: $precioActual -> $nuevoMonto ($porcentaje%)');
    
    try {
      // Aplicar el aumento usando el método estático
      final inquilinoActualizado = Inquilino.aplicarAumento(
        inquilino, 
        mesActual, 
        nuevoMonto
      );
      
      // Guardar los cambios
      widget.onGuardarInquilino(inquilinoActualizado);
      
      // Actualizar la UI
      setState(() {
        nuevosMontos[inquilino.id] = nuevoMonto;
        porcentajesIndividuales[inquilino.id]!.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aumento aplicado a ${inquilino.nombre}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      log.e('Error al aplicar aumento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aplicar aumento: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _aplicarAumentosTodos(BuildContext context) {
    // Aplicar los aumentos a todos los inquilinos seleccionados
    bool algunoSeleccionado = false;
    List<String> inquilinosActualizados = [];
    
    try {
      for (int i = 0; i < widget.inquilinos.length; i++) {
        final inquilino = widget.inquilinos[i];
        if (inquilinosSeleccionados[inquilino.id] == true &&
            porcentajesIndividuales[inquilino.id]!.text.isNotEmpty) {
          algunoSeleccionado = true;
          final porcentaje = double.tryParse(porcentajesIndividuales[inquilino.id]!.text) ?? 0;
          if (porcentaje > 0) {
            // Obtener el precio actual para el mes seleccionado
            final precioActual = inquilino.getPrecioAlquilerPorMes(mesActual);
            
            // Calcular el nuevo monto
            final nuevoMonto = precioActual + (precioActual * porcentaje / 100);
            log.d('Calculando aumento para ${inquilino.nombre}: $precioActual -> $nuevoMonto ($porcentaje%)');
            
            // Aplicar el aumento usando el método estático
            final inquilinoActualizado = Inquilino.aplicarAumento(
              inquilino,
              mesActual,
              nuevoMonto
            );
            
            // Guardar los cambios
            widget.onGuardarInquilino(inquilinoActualizado);
            
            inquilinosActualizados.add(inquilino.nombre);
          }
        }
      }
      
      if (!algunoSeleccionado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seleccione al menos un inquilino y asigne un porcentaje'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      // Cerrar la pantalla y devolver la lista de inquilinos actualizados
      Navigator.pop(context, inquilinosActualizados);
      
    } catch (e) {
      log.e('Error al aplicar aumentos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aplicar aumentos: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

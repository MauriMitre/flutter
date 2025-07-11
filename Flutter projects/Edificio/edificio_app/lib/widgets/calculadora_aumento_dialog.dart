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
  
  // Controlador para el monto fijo general (nuevo)
  final TextEditingController montoFijoGeneralController = TextEditingController();
  
  // Modo seleccionado: porcentaje o monto fijo
  bool _usarModoMonto = false;
  
  // Estado de expansión del panel de opciones
  bool _panelExpandido = false;
  
  // Mapa para almacenar los porcentajes individuales por inquilino
  late Map<String, TextEditingController> porcentajesIndividuales = {};
  
  // Mapa para almacenar los montos fijos individuales por inquilino (nuevo)
  late Map<String, TextEditingController> montosIndividuales = {};
  
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
      montosIndividuales[inquilino.id] = TextEditingController(); // Nuevo controlador para montos
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
    montoFijoGeneralController.dispose(); // Nuevo controlador
    
    for (final controller in porcentajesIndividuales.values) {
      controller.dispose();
    }
    
    for (final controller in montosIndividuales.values) { // Nuevos controladores
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
            // Panel de porcentaje/monto general colapsable
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Cabecera del panel siempre visible
                  InkWell(
                    onTap: () {
                      setState(() {
                        _panelExpandido = !_panelExpandido;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            _panelExpandido ? Icons.expand_less : Icons.expand_more,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Opciones de aumento',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          // Mostrar un resumen cuando está colapsado
                          if (!_panelExpandido)
                            Text(
                              _usarModoMonto ? 'Monto fijo' : 'Porcentaje',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Contenido expandible
                  if (_panelExpandido)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          // Selector de modo - Versión adaptable
                          Wrap(
                            spacing: 16,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Tipo de aumento:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ToggleButtons(
                                constraints: const BoxConstraints(minWidth: 95),
                                isSelected: [!_usarModoMonto, _usarModoMonto],
                                onPressed: (int index) {
                                  setState(() {
                                    _usarModoMonto = (index == 1);
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('Porcentaje %'),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('Monto Fijo \$'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Título según modo
                          Text(
                            _usarModoMonto ? 'Monto fijo general' : 'Porcentaje general',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Campo de entrada según el modo seleccionado
                          Row(
                            children: [
                              Expanded(
                                child: _usarModoMonto
                                  ? TextField(
                                      controller: montoFijoGeneralController,
                                      decoration: InputDecoration(
                                        labelText: 'Monto \$',
                                        hintText: 'Ej: 5000',
                                        prefixText: '\$',
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
                                    )
                                  : TextField(
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
                                  if (_usarModoMonto) {
                                    final montoFijo = montoFijoGeneralController.text;
                                    if (montoFijo.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Ingrese un monto'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    
                                    // Actualizar con montos fijos
                                    setState(() {
                                      for (final inquilino in widget.inquilinos) {
                                        if (inquilinosSeleccionados[inquilino.id] == true) {
                                          montosIndividuales[inquilino.id]!.text = montoFijo;
                                          porcentajesIndividuales[inquilino.id]!.clear(); // Limpiar el otro campo
                                          
                                          // Calcular el nuevo monto sumando el monto fijo
                                          final monto = double.tryParse(montoFijo) ?? 0;
                                          final precioActual = inquilino.getPrecioAlquilerPorMes(mesActual);
                                          nuevosMontos[inquilino.id] = precioActual + monto;
                                        }
                                      }
                                    });
                                  } else {
                                    final porcentajeGeneral = porcentajeGeneralController.text;
                                    if (porcentajeGeneral.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Ingrese un porcentaje'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    
                                    // Actualizar con porcentajes
                                    setState(() {
                                      for (final inquilino in widget.inquilinos) {
                                        if (inquilinosSeleccionados[inquilino.id] == true) {
                                          porcentajesIndividuales[inquilino.id]!.text = porcentajeGeneral;
                                          montosIndividuales[inquilino.id]!.clear(); // Limpiar el otro campo
                                          
                                          // Calcular el nuevo monto para mostrar (pero no aplicar)
                                          final porcentaje = double.tryParse(porcentajeGeneral) ?? 0;
                                          final precioActual = inquilino.getPrecioAlquilerPorMes(mesActual);
                                          nuevosMontos[inquilino.id] = precioActual + 
                                            (precioActual * porcentaje / 100);
                                        }
                                      }
                                    });
                                  }
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
                                      montosIndividuales[inquilino.id]!.clear();
                                      nuevosMontos[inquilino.id] = inquilino.getPrecioAlquilerPorMes(mesActual);
                                    }
                                    porcentajeGeneralController.clear();
                                    montoFijoGeneralController.clear();
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
                  final precioActual = inquilino.getPrecioAlquilerPorMes(mesActual);
                  final nuevoMonto = nuevosMontos[inquilino.id] ?? precioActual;
                  final aumento = nuevoMonto - precioActual;
                  
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
                                      'Alquiler actual: \$${precioActual.toStringAsFixed(2)}',
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
                              
                              // Controles según modo seleccionado
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: _usarModoMonto 
                                      ? TextField(
                                          controller: montosIndividuales[inquilino.id],
                                          decoration: InputDecoration(
                                            labelText: 'Monto \$',
                                            hintText: '0',
                                            prefixText: '\$',
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
                                            // Limpiar el otro campo
                                            porcentajesIndividuales[inquilino.id]!.clear();
                                            
                                            // Solo calcular el nuevo monto para mostrar
                                            setState(() {
                                              final monto = double.tryParse(value) ?? 0;
                                              final precioActual = inquilino.getPrecioAlquilerPorMes(mesActual);
                                              nuevosMontos[inquilino.id] = precioActual + monto;
                                            });
                                          },
                                        )
                                      : TextField(
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
                                            // Limpiar el otro campo
                                            montosIndividuales[inquilino.id]!.clear();
                                            
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
    final precioActual = inquilino.getPrecioAlquilerPorMes(mesActual);
    double nuevoMonto = precioActual;
    
    if (_usarModoMonto) {
      // Modo monto fijo
      final montoTexto = montosIndividuales[inquilino.id]!.text;
      if (montoTexto.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingrese un monto válido'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      final monto = double.tryParse(montoTexto) ?? 0;
      if (monto <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El monto debe ser mayor a 0'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      nuevoMonto = precioActual + monto;
    } else {
      // Modo porcentaje
      final porcentajeTexto = porcentajesIndividuales[inquilino.id]!.text;
      if (porcentajeTexto.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingrese un porcentaje válido'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      final porcentaje = double.tryParse(porcentajeTexto) ?? 0;
      if (porcentaje <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El porcentaje debe ser mayor a 0'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      nuevoMonto = precioActual + (precioActual * porcentaje / 100);
    }
    
    log.d('Aplicando aumento para ${inquilino.nombre}: $precioActual -> $nuevoMonto');
    
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
        montosIndividuales[inquilino.id]!.clear();
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
        if (inquilinosSeleccionados[inquilino.id] != true) continue;
        
        algunoSeleccionado = true;
        double nuevoMonto = inquilino.getPrecioAlquilerPorMes(mesActual);
        bool tieneValor = false;
        
        if (_usarModoMonto && montosIndividuales[inquilino.id]!.text.isNotEmpty) {
          // Modo monto fijo
          final monto = double.tryParse(montosIndividuales[inquilino.id]!.text) ?? 0;
          if (monto > 0) {
            nuevoMonto = inquilino.getPrecioAlquilerPorMes(mesActual) + monto;
            tieneValor = true;
          }
        } else if (!_usarModoMonto && porcentajesIndividuales[inquilino.id]!.text.isNotEmpty) {
          // Modo porcentaje
          final porcentaje = double.tryParse(porcentajesIndividuales[inquilino.id]!.text) ?? 0;
          if (porcentaje > 0) {
            final precioActual = inquilino.getPrecioAlquilerPorMes(mesActual);
            nuevoMonto = precioActual + (precioActual * porcentaje / 100);
            tieneValor = true;
          }
        }
        
        if (tieneValor) {
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
      
      if (!algunoSeleccionado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seleccione al menos un inquilino'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      if (inquilinosActualizados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingrese valores para al menos un inquilino seleccionado'),
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
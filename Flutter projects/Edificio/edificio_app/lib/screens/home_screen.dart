import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inquilino.dart';
import '../screens/agregar_inquilino_screen.dart';
import '../screens/tareas_screen.dart';
import '../screens/expensas_editor_screen.dart';
import '../services/storage_service.dart';
import '../widgets/editar_expensas_dialog.dart';
import '../services/pdf_service.dart';
import '../services/deudas_service.dart';
import '../services/log_service.dart';
import '../widgets/month_year_picker.dart';
import '../screens/cuentas_transferencia_screen.dart';
import '../screens/documentos_inquilino_screen.dart';
import '../widgets/calculadora_aumento_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StorageService _storageService = StorageService();

  List<Inquilino> _inquilinos = [];
  // Usar enero de 2025 como fecha inicial
  DateTime _selectedDate = DateTime(2025, 1, 1);
  double _expensasComunes = 0.0;
  final PdfService _pdfService = PdfService();
  final DeudasService _deudasService = DeudasService();
  bool _isLoading = true;
  bool _hayPagosPendientes = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Variables para almacenar los totales
  double _totalAlquileresRecibidos = 0.0;
  double _totalExpensasRecibidas = 0.0;
  double _totalGeneral = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarInquilinos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarInquilinos() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Cargar inquilinos
      var inquilinos = await _storageService.loadInquilinos();
      
      // Si no hay inquilinos, intentar forzar la carga de predefinidos
      if (inquilinos.isEmpty) {
        log.w("No se encontraron inquilinos, forzando carga de predefinidos");
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('inquilinos_inicializados');
        await prefs.remove('inquilinos');
        
        // Recargar después de reiniciar
        inquilinos = await _storageService.loadInquilinos();
        log.i("Reintento de carga completado: ${inquilinos.length} inquilinos cargados");
      }

      final mesAnio = DateFormat('MM-yyyy').format(_selectedDate);
      final expensas = await _storageService.loadExpensas(mesAnio);
      
      // Verificar si hay pagos pendientes
      final detallesPendientes = _obtenerDetallesPagosPendientes(inquilinos);
      
      // Calcular totales usando los precios específicos por mes
      double totalAlquileres = 0.0;
      double totalExpensas = 0.0;
      
      for (var inquilino in inquilinos) {
        // Obtener el precio específico para este mes
        double precioAlquilerMes = inquilino.getPrecioAlquilerPorMes(mesAnio);
        
        // Calcular totales
        if (inquilino.haPagadoAlquiler(mesAnio)) {
          totalAlquileres += precioAlquilerMes;
        }
        
        if (inquilino.haPagadoExpensas(mesAnio)) {
          double expensasInquilino = inquilino.getExpensasPorMes(mesAnio);
          totalExpensas += (expensasInquilino > 0) ? expensasInquilino : expensas;
        }
      }

      if (mounted) {
        setState(() {
          _inquilinos = inquilinos;
          _expensasComunes = expensas;
          _hayPagosPendientes = detallesPendientes.isNotEmpty;
          _isLoading = false;
          
          // Actualizar totales para el resumen
          _totalAlquileresRecibidos = totalAlquileres;
          _totalExpensasRecibidas = totalExpensas;
          _totalGeneral = totalAlquileres + totalExpensas;
        });
      }
    } catch (e, stackTrace) {
      log.e("Error al cargar datos", e, stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _editarExpensas() async {
    final mesAnio = DateFormat('MM-yyyy').format(_selectedDate);
    final result = await showDialog<double>(
      context: context,
      builder: (context) => EditarExpensasDialog(
        expensasActuales: _expensasComunes,
      ),
    );

    if (result != null) {
      try {
        log.i("Actualizando expensas para $mesAnio: $result");
        await _storageService.saveExpensas(mesAnio, result);

        // Actualizar las expensas de todos los inquilinos para este mes
        for (var inquilino in _inquilinos) {
          inquilino.setExpensas(mesAnio, result);
        }

        // Guardar los inquilinos con las nuevas expensas
        await _storageService.saveInquilinos(_inquilinos);

        // Recalcular totales con los nuevos valores de expensas
        _calcularTotalesRecibidos(_inquilinos, mesAnio);

        if (mounted) {
          setState(() {
            _expensasComunes = result;
          });
          
          log.i("Expensas actualizadas correctamente para $mesAnio");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expensas actualizadas correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stackTrace) {
        log.e("Error al guardar expensas", e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar expensas: $e')),
          );
        }
      }
    }
  }

  Future<void> _mostrarEditarInquilinoDialog(Inquilino inquilino) async {
    final result = await Navigator.push<Inquilino>(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarInquilinoScreen(inquilino: inquilino),
      ),
    );

    if (result != null) {
      try {
        log.i("Actualizando inquilino: ${result.nombre} ${result.apellido}");
        final index = _inquilinos.indexWhere((i) => i.id == result.id);
        if (index != -1) {
          setState(() {
            _inquilinos[index] = result;
          });
          await _storageService.saveInquilinos(_inquilinos);
          if (mounted) {
            log.i("Inquilino actualizado correctamente");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Inquilino actualizado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        log.e("Error al actualizar inquilino", e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar inquilino: $e')),
          );
        }
      }
    }
  }

  Future<void> _eliminarInquilino(Inquilino inquilino) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Está seguro que desea eliminar a ${inquilino.nombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        _inquilinos.removeWhere((i) => i.id == inquilino.id);
      });
      try {
        await _storageService.saveInquilinos(_inquilinos);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inquilino eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar inquilino: $e')),
          );
        }
      }
    }
  }

  // Método optimizado para marcar/desmarcar pago de un inquilino
  Future<void> _togglePago(Inquilino inquilino) async {
    if (!mounted) return;
    
    final mesAnio = DateFormat('MM-yyyy').format(_selectedDate);
    final pagado = !inquilino.haPagado(mesAnio);
    
    // Aplicar el cambio directamente al modelo
    inquilino.marcarPagado(mesAnio, pagado);
    
    try {
      // Guardar el cambio una sola vez después de las modificaciones
      await _storageService.saveInquilinos(_inquilinos);
      
      // Actualizar totales recibidos después de cambiar el estado
      _calcularTotalesRecibidos(_inquilinos, mesAnio);
      
      // Actualizar UI solo si el widget sigue montado
      if (mounted) {
        setState(() {}); // Refresh UI
      }
    } catch (e) {
      // Error al guardar estado de pago
      // Revertir el cambio en caso de error
      inquilino.marcarPagado(mesAnio, !pagado);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar pago: $e')),
        );
      }
    }
  }

  // Método optimizado para marcar/desmarcar pago de alquiler
  Future<void> _togglePagoAlquiler(Inquilino inquilino) async {
    if (!mounted) return;
    
    final mesAnio = DateFormat('MM-yyyy').format(_selectedDate);
    final pagado = !inquilino.haPagadoAlquiler(mesAnio);
    
    // Aplicar el cambio directamente al modelo
    inquilino.marcarPagoAlquiler(mesAnio, pagado);
    
    try {
      // Guardar el cambio una sola vez después de las modificaciones
      await _storageService.saveInquilinos(_inquilinos);
      
      // Actualizar totales recibidos después de cambiar el estado
      _calcularTotalesRecibidos(_inquilinos, mesAnio);
      
      // Actualizar UI solo si el widget sigue montado
      if (mounted) {
        setState(() {}); // Refresh UI
      }
    } catch (e) {
      // Error al guardar estado de pago de alquiler
      // Revertir el cambio en caso de error
      inquilino.marcarPagoAlquiler(mesAnio, !pagado);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar pago de alquiler: $e')),
        );
      }
    }
  }

  // Método optimizado para marcar/desmarcar pago de expensas
  Future<void> _togglePagoExpensas(Inquilino inquilino) async {
    if (!mounted) return;
    
    final mesAnio = DateFormat('MM-yyyy').format(_selectedDate);
    final pagado = !inquilino.haPagadoExpensas(mesAnio);
    
    // Aplicar el cambio directamente al modelo
    inquilino.marcarPagoExpensas(mesAnio, pagado);
    
    try {
      // Guardar el cambio una sola vez después de las modificaciones
      await _storageService.saveInquilinos(_inquilinos);
      
      // Actualizar totales recibidos después de cambiar el estado
      _calcularTotalesRecibidos(_inquilinos, mesAnio);
      
      // Actualizar UI solo si el widget sigue montado
      if (mounted) {
        setState(() {}); // Refresh UI
      }
    } catch (e) {
      // Error al guardar estado de pago de expensas
      // Revertir el cambio en caso de error
      inquilino.marcarPagoExpensas(mesAnio, !pagado);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar pago de expensas: $e')),
        );
      }
    }
  }

  Future<void> _agregarMontoPendiente(Inquilino inquilino) async {
    final mesAnio = DateFormat('MM-yyyy').format(_selectedDate);
    final montoPendienteActual = inquilino.getMontoPendiente(mesAnio);

    final TextEditingController montoController = TextEditingController(
      text: montoPendienteActual > 0 ? montoPendienteActual.toString() : '',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar monto pendiente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: montoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto pendiente',
                hintText: 'Ingrese el monto pendiente',
                prefixText: '\$',
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  final monto = double.tryParse(value) ?? 0.0;
                  Navigator.pop(context, monto);
                } else {
                  Navigator.pop(context, 0.0);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final monto = double.tryParse(montoController.text) ?? 0.0;
              Navigator.pop(context, monto);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        inquilino.setMontoPendiente(mesAnio, result);
        await _storageService.saveInquilinos(_inquilinos);

        // Recalcular totales
        _calcularTotalesRecibidos(_inquilinos, mesAnio);

        setState(() {}); // Actualizar UI

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result > 0
                  ? 'Monto pendiente registrado: \$${result.toStringAsFixed(2)}'
                  : 'Monto pendiente eliminado'),
              backgroundColor: result > 0 ? Colors.orange : Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar monto pendiente: $e')),
          );
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // Mostrar un diálogo personalizado para seleccionar solo mes y año
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => MonthYearPicker(
        initialDate: _selectedDate,
      ),
    );

    if (result != null && result != _selectedDate) {
      setState(() {
        _selectedDate = result;
      });
      _cargarInquilinos(); // Cargar los datos correctos para el nuevo mes
    }
  }

  void _agregarInquilino() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AgregarInquilinoScreen()),
    );

    if (result != null && result is Inquilino) {
      setState(() {
        _inquilinos.add(result);
      });
      await _storageService.saveInquilinos(_inquilinos);
    }
  }

  // Verificar pagos pendientes de meses a partir de 2025
  List<Map<String, dynamic>> _obtenerDetallesPagosPendientes(
      List<Inquilino> inquilinos) {
    // Usar 2025 como año base
    const anioBase = 2025;
    final DateTime now = DateTime.now();
    final int mesActual = now.month;
    final int anioActual = now.year;

    List<Map<String, dynamic>> detallesPendientes = [];

    for (var inquilino in inquilinos) {
      Map<String, List<String>> mesesPendientes = {};

      // Revisar los meses desde enero 2025 hasta el mes actual
      for (int anio = anioBase; anio <= anioActual; anio++) {
        // Determinar el último mes a revisar para este año
        int ultimoMes = (anio == anioActual) ? mesActual : 12;
        
        for (int mes = 1; mes <= ultimoMes; mes++) {
          final mesStr = mes < 10 ? '0$mes' : '$mes';
          final mesAnio = '$mesStr-$anio';

          List<String> pendientes = [];

          // Verificar qué está pendiente
          if (!inquilino.haPagadoAlquiler(mesAnio)) {
            pendientes.add('Alquiler');
          }

          if (!inquilino.haPagadoExpensas(mesAnio)) {
            pendientes.add('Expensas');
          }

          if (pendientes.isNotEmpty) {
            mesesPendientes[mesAnio] = pendientes; // Usar mesAnio como clave para ordenar después
          }
        }
      }

      if (mesesPendientes.isNotEmpty) {
        // Convertir las claves mesAnio a nombres de mes para mostrar, pero mantener el orden
        final mesesOrdenados = mesesPendientes.keys.toList()
          ..sort((a, b) {
            final partesA = a.split('-');
            final partesB = b.split('-');
            final anioA = int.parse(partesA[1]);
            final anioB = int.parse(partesB[1]);
            if (anioA != anioB) return anioA.compareTo(anioB);
            final mesA = int.parse(partesA[0]);
            final mesB = int.parse(partesB[0]);
            return mesA.compareTo(mesB);
          });
        
        final Map<String, Map<String, dynamic>> mesesFormateados = {};
        
        for (final mesAnio in mesesOrdenados) {
          final partes = mesAnio.split('-');
          final mes = int.parse(partes[0]);
          final anio = int.parse(partes[1]);
          final nombreMes = DateFormat('MMMM', 'es_ES').format(DateTime(anio, mes));
          final nombreCompleto = '$nombreMes $anio';
          
          mesesFormateados[mesAnio] = {
            'nombre': nombreCompleto,
            'pendientes': mesesPendientes[mesAnio]!,
            'mes': mes,
            'anio': anio,
          };
        }
        
        detallesPendientes.add({
          'inquilino': inquilino,
          'mesesPendientes': mesesFormateados,
        });
      }
    }

    return detallesPendientes;
  }

  void _navigateToTareasScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TareasScreen(inquilinos: _inquilinos),
      ),
    );
  }

  void _navigateToExpensasEditorScreen() {
    final mesAnio = DateFormat('MM-yyyy').format(_selectedDate);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpensasEditorScreen(mesAnio: mesAnio),
      ),
    );
  }

  void _navigateToCuentasTransferenciaScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const CuentasTransferenciaScreen()),
    );
  }

  void _mostrarAcercaDe() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acerca de'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aplicación de Gestión de Edificio'),
            SizedBox(height: 8),
            Text('Versión 1.0.0'),
            SizedBox(height: 8),
            Text('Desarrollado por DIGICOM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarPagosPendientes() {
    final detallesPendientes = _obtenerDetallesPagosPendientes(_inquilinos);

    if (detallesPendientes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay inquilinos con pagos pendientes'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Pagos Pendientes'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: detallesPendientes.length,
            itemBuilder: (context, index) {
              final detalle = detallesPendientes[index];
              final inquilino = detalle['inquilino'] as Inquilino;
              final mesesPendientes =
                  detalle['mesesPendientes'] as Map<String, Map<String, dynamic>>;

              // Colores para los diferentes meses
              final List<Color> coloresMeses = [
                Colors.red.shade100,
                Colors.orange.shade100,
                Colors.amber.shade100,
                Colors.green.shade100,
                Colors.blue.shade100,
                Colors.indigo.shade100,
                Colors.purple.shade100,
                Colors.pink.shade100,
                Colors.teal.shade100,
                Colors.cyan.shade100,
                Colors.lime.shade100,
                Colors.brown.shade100,
              ];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${inquilino.nombre} ${inquilino.apellido}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('Depto: ${inquilino.departamento}'),
                      const Divider(),
                      ...mesesPendientes.entries.map((entry) {
                        final datos = entry.value;
                        final nombreMes = datos['nombre'] as String;
                        final pendientes = datos['pendientes'] as List<String>;
                        final mes = datos['mes'] as int;
                        
                        // Seleccionar color basado en el mes (índice 0-11)
                        final colorMes = coloresMeses[(mes - 1) % coloresMeses.length];
                        final colorBorde = colorMes.withAlpha(204); // 0.8 * 255 = 204
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: colorMes,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorBorde,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombreMes,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pendientes.join(', '),
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarCalculadoraAumento() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CalculadoraAumentoDialog(
          inquilinos: _inquilinos,
          selectedDate: _selectedDate,
          onGuardarInquilino: (inquilinoActualizado) {
            _guardarInquilino(inquilinoActualizado);
          },
        ),
      ),
    ).then((inquilinosActualizados) {
      if (inquilinosActualizados != null && inquilinosActualizados is List<String> && inquilinosActualizados.isNotEmpty) {
        // Recargar los inquilinos desde el almacenamiento para asegurar que tenemos los datos más recientes
        _storageService.loadInquilinos().then((inquilinosActualizados) {
          if (mounted) {
            setState(() {
              _inquilinos = inquilinosActualizados;
            });
            
            // Forzar una recarga completa de los datos y la UI
            _cargarInquilinos();
          }
          
          // Mostrar mensaje de éxito
          if (mounted) {
            ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
              const SnackBar(
                content: Text('Aumentos aplicados correctamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    });
  }

  void _mostrarHistorialExpensas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historial de Expensas'),
        content: FutureBuilder<Map<String, double>>(
          future: _cargarHistorialExpensas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final historial = snapshot.data ?? {};

            if (historial.isEmpty) {
              return const Text('No hay datos de expensas disponibles.');
            }

            // Ordenar por fecha (más reciente primero)
            final entradas = historial.entries.toList()
              ..sort((a, b) {
                final partsA = a.key.split('-');
                final partsB = b.key.split('-');
                final dateA =
                    DateTime(int.parse(partsA[1]), int.parse(partsA[0]));
                final dateB =
                    DateTime(int.parse(partsB[1]), int.parse(partsB[0]));
                return dateB.compareTo(dateA);
              });

            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: entradas.length,
                itemBuilder: (context, index) {
                  final entry = entradas[index];
                  final parts = entry.key.split('-');
                  final fecha =
                      DateTime(int.parse(parts[1]), int.parse(parts[0]));
                  final mesAnio =
                      DateFormat('MMMM yyyy', 'es_ES').format(fecha);

                  return ListTile(
                    title: Text(mesAnio),
                    trailing: Text('\$${entry.value.toStringAsFixed(2)}'),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, double>> _cargarHistorialExpensas() async {
    // Implementar carga de historial de expensas
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final expensasKeys =
        keys.where((key) => key.startsWith('expensa_')).toList();

    Map<String, double> historial = {};

    for (final key in expensasKeys) {
      final mesAnio = key.substring(8); // Quitar 'expensa_'
      final valor = prefs.getDouble(key) ?? 0.0;
      historial[mesAnio] = valor;
    }

    return historial;
  }

  Future<void> _generarReciboPDF(Inquilino inquilino) async {
    final mesAnio = DateFormat('MM-yyyy').format(_selectedDate);

    try {
      await _pdfService.generarRecibo(inquilino, mesAnio);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recibo generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar recibo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Generar informe de deudas
  Future<void> _generarInformeDeudas(Inquilino inquilino) async {
    // Mostrar diálogo de carga
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Generando informe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generando informe de deudas...'),
            ],
          ),
        ),
      );
    }
    
    try {
      // Generar el informe
      await _deudasService.generarInformeDeudas(inquilino);
      
      // Cerrar el diálogo de carga
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informe de deudas generado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Cerrar el diálogo de carga en caso de error
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar informe de deudas: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Agregar método para registrar método de pago
  Future<void> _registrarMetodoPago(Inquilino inquilino) async {
    if (!mounted) return;
    
    final mesAnio = DateFormat('MM-yyyy').format(_selectedDate);
    final metodoPagoActual = inquilino.getMetodoPago(mesAnio);
    final cuentaActual = inquilino.getCuentaTransferencia(mesAnio);

    MetodoPago metodoPagoSeleccionado = metodoPagoActual;
    String cuentaSeleccionada = cuentaActual;

    // Cargar cuentas disponibles
    final cuentasDisponibles = await _storageService.loadCuentasTransferencia();

    if (!mounted) return;

    if (cuentasDisponibles.isEmpty &&
        metodoPagoSeleccionado == MetodoPago.transferencia) {
      // Si no hay cuentas disponibles y se intenta seleccionar transferencia
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No hay cuentas de transferencia disponibles. Debe agregar cuentas primero.'),
          duration: Duration(seconds: 3),
        ),
      );

      // Preguntar si desea ir a la pantalla de cuentas
      final irACuentas = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sin cuentas'),
          content: const Text(
              'No hay cuentas de transferencia disponibles. ¿Desea agregar una cuenta ahora?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (irACuentas == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const CuentasTransferenciaScreen()),
        );
        if (mounted) {
          return _registrarMetodoPago(
              inquilino); // Volver a intentar luego de agregar cuentas
        }
      }

      return;
    }

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Método de Pago'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seleccione el método de pago:'),
                const SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<MetodoPago>(
                      title: const Text('Efectivo'),
                      value: MetodoPago.efectivo,
                      groupValue: metodoPagoSeleccionado,
                      onChanged: (value) {
                        setState(() {
                          metodoPagoSeleccionado = value!;
                        });
                      },
                    ),
                    RadioListTile<MetodoPago>(
                      title: const Text('Transferencia'),
                      value: MetodoPago.transferencia,
                      groupValue: metodoPagoSeleccionado,
                      onChanged: (value) {
                        if (cuentasDisponibles.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'No hay cuentas disponibles. Debe agregar cuentas primero.'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          metodoPagoSeleccionado = value!;
                          if (cuentaSeleccionada.isEmpty &&
                              cuentasDisponibles.isNotEmpty) {
                            cuentaSeleccionada = cuentasDisponibles.first.id;
                          }
                        });
                      },
                    ),
                  ],
                ),
                if (metodoPagoSeleccionado == MetodoPago.transferencia) ...[
                  const SizedBox(height: 16),
                  const Text('Seleccione la cuenta:'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: cuentaSeleccionada.isNotEmpty &&
                              cuentasDisponibles
                                  .any((c) => c.id == cuentaSeleccionada)
                          ? cuentaSeleccionada
                          : (cuentasDisponibles.isNotEmpty
                              ? cuentasDisponibles.first.id
                              : null),
                      items: cuentasDisponibles.map((cuenta) {
                        return DropdownMenuItem<String>(
                          value: cuenta.id,
                          child: Text(
                            cuenta.nombre,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            cuentaSeleccionada = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
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
                if (metodoPagoSeleccionado == MetodoPago.transferencia &&
                    (cuentaSeleccionada.isEmpty ||
                        !cuentasDisponibles
                            .any((c) => c.id == cuentaSeleccionada))) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Debe seleccionar una cuenta de transferencia'),
                    ),
                  );
                  return;
                }

                final nombreCuenta =
                    metodoPagoSeleccionado == MetodoPago.transferencia
                        ? cuentasDisponibles
                            .firstWhere((c) => c.id == cuentaSeleccionada)
                            .nombre
                        : '';

                Navigator.pop(context, {
                  'metodoPago': metodoPagoSeleccionado,
                  'cuenta': nombreCuenta,
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        final metodoPago = result['metodoPago'] as MetodoPago;
        final cuenta = result['cuenta'] as String;

        inquilino.setMetodoPago(mesAnio, metodoPago);

        if (metodoPago == MetodoPago.transferencia) {
          inquilino.setCuentaTransferencia(mesAnio, cuenta);
        } else {
          inquilino.setCuentaTransferencia(mesAnio, '');
        }

        await _storageService.saveInquilinos(_inquilinos);

        setState(() {}); // Actualizar UI

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Método de pago registrado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al registrar método de pago: $e')),
          );
        }
      }
    }
  }

  // Método optimizado para calcular totales recibidos para un mes específico
  Future<void> _calcularTotalesRecibidos(List<Inquilino> inquilinos, String mesAnio) {
    double totalAlquileres = 0.0;
    double totalExpensas = 0.0;
    
    for (var inquilino in inquilinos) {
      // Usar el precio específico para el mes seleccionado
      double precioAlquilerMes = inquilino.getPrecioAlquilerPorMes(mesAnio);
      
      if (inquilino.haPagadoAlquiler(mesAnio)) {
        totalAlquileres += precioAlquilerMes;
      }
      
      if (inquilino.haPagadoExpensas(mesAnio)) {
        double expensasInquilino = inquilino.getExpensasPorMes(mesAnio);
        totalExpensas += (expensasInquilino > 0) ? expensasInquilino : _expensasComunes;
      }
    }
    
    setState(() {
      _totalAlquileresRecibidos = totalAlquileres;
      _totalExpensasRecibidas = totalExpensas;
      _totalGeneral = totalAlquileres + totalExpensas;
    });
    
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Gestión de Edificio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _agregarInquilino,
            tooltip: 'Agregar inquilino',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gestión de Edificio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mes actual: ${DateFormat('MMMM yyyy', 'es_ES').format(_selectedDate)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.apartment),
              title: const Text('Inquilinos'),
              onTap: () {
                Navigator.pop(context); // cerrar drawer
                _cargarInquilinos();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.warning_amber,
                color: _hayPagosPendientes ? Colors.orange : null,
              ),
              title: Text(
                'Pagos Pendientes',
                style: TextStyle(
                  color: _hayPagosPendientes ? Colors.orange : null,
                  fontWeight: _hayPagosPendientes ? FontWeight.bold : null,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // cerrar drawer
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) _mostrarPagosPendientes();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.task),
              title: const Text('Tareas'),
              onTap: () {
                Navigator.pop(context); // cerrar drawer
                _navigateToTareasScreen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Expensas'),
              onTap: () {
                Navigator.pop(context); // cerrar drawer
                _navigateToExpensasEditorScreen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial de Expensas'),
              onTap: () {
                Navigator.pop(context); // cerrar drawer
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) _mostrarHistorialExpensas();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Cuentas de Transferencia'),
              onTap: () {
                Navigator.pop(context); // cerrar drawer
                _navigateToCuentasTransferenciaScreen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Aumento'),
              onTap: () {
                // Primero cerrar el drawer
                Navigator.pop(context);
                // Luego mostrar la calculadora con un pequeño retraso
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) _mostrarCalculadoraAumento();
                });
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Acerca de'),
              onTap: () {
                Navigator.pop(context); // cerrar drawer
                _mostrarAcercaDe();
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildInquilinosTab(),
          _buildResumenTab(),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.people),
            text: 'Inquilinos',
          ),
          Tab(
            icon: Icon(Icons.summarize),
            text: 'Resumen',
          ),
        ],
      ),
    );
  }

  // Widget para la pestaña de inquilinos
  Widget _buildInquilinosTab() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
              child: Padding(
            padding: const EdgeInsets.all(16),
                child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                          'Expensas comunes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                            fontSize: 16,
                      ),
                    ),
                    Text(
                          '\$${_expensasComunes.toStringAsFixed(2)}',
                      style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                    ElevatedButton(
                      onPressed: _editarExpensas,
                      child: const Text('Editar'),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Período: ${DateFormat('MMMM yyyy', 'es_ES').format(_selectedDate)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Cambiar'),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
          Expanded(
          child: _inquilinos.isEmpty
              ? const Center(
                  child: Text('No hay inquilinos registrados'),
                )
              : ListView.builder(
                  itemCount: _inquilinos.length,
              itemBuilder: (context, index) {
                    final inquilino = _inquilinos[index];
                    return _buildInquilinoCard(inquilino);
                  },
                ),
        ),
      ],
    );
  }

  // Widget para la pestaña de resumen
  Widget _buildResumenTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final mesAnio = DateFormat('MM-yyyy').format(_selectedDate);
    final mesAnioFormatted = DateFormat('MMMM yyyy', 'es_ES').format(_selectedDate);
    
    // Usar variables precalculadas para evitar recalcular
    final int totalInquilinos = _inquilinos.length;
    int inquilinosPagaron = 0;
    int inquilinosNoPagaron = 0;
    double totalPendiente = 0;
    
    // Mapas para método de pago (calculados una sola vez)
    double totalEfectivo = 0;
    double totalTransferencia = 0;
    Map<String, double> resumenPorCuenta = {};
    
    // Recorrer inquilinos una sola vez para todos los cálculos
    for (final inquilino in _inquilinos) {
      final pagado = inquilino.haPagado(mesAnio);
      final montoPendiente = inquilino.getMontoPendiente(mesAnio);
      
      if (pagado) {
        inquilinosPagaron++;
        
        // Calcular por método de pago
        final metodoPago = inquilino.getMetodoPago(mesAnio);
        final expensasInquilino = inquilino.getExpensasPorMes(mesAnio);
        final totalInquilino = inquilino.precioAlquiler + expensasInquilino;
        
        if (metodoPago == MetodoPago.efectivo) {
          totalEfectivo += totalInquilino;
        } else if (metodoPago == MetodoPago.transferencia) {
          totalTransferencia += totalInquilino;
          
          final cuenta = inquilino.getCuentaTransferencia(mesAnio);
          if (cuenta.isNotEmpty) {
            resumenPorCuenta[cuenta] = (resumenPorCuenta[cuenta] ?? 0) + totalInquilino;
          }
        }
      } else {
        inquilinosNoPagaron++;
      }
      
      totalPendiente += montoPendiente;
    }
    
    // Separamos la construcción del UI de los cálculos
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Resumen del mes: $mesAnioFormatted',
                      style: const TextStyle(
                fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
          const SizedBox(height: 24),
          
          // Card para totales
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RESUMEN GENERAL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildResumenRow('Total Inquilinos', '$totalInquilinos',
                      FontWeight.normal),
                  _buildResumenRow(
                      'Pagaron', '$inquilinosPagaron', FontWeight.normal),
                  _buildResumenRow('No Pagaron', '$inquilinosNoPagaron',
                      FontWeight.normal),
                  const Divider(),
                  _buildResumenRow(
                      'Total Alquiler',
                      '\$${_totalAlquileresRecibidos.toStringAsFixed(2)}',
                      FontWeight.normal),
                  _buildResumenRow(
                      'Total Expensas',
                      '\$${_totalExpensasRecibidas.toStringAsFixed(2)}',
                      FontWeight.normal),
                  _buildResumenRow(
                      'Total Pendiente',
                      '\$${totalPendiente.toStringAsFixed(2)}',
                      FontWeight.normal),
                  const Divider(),
                  _buildResumenRow(
                      'TOTAL RECAUDADO',
                      '\$${_totalGeneral.toStringAsFixed(2)}',
                      FontWeight.bold),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Card para métodos de pago
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MÉTODOS DE PAGO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.money,
                                  color: Colors.green.shade800, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Efectivo',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${totalEfectivo.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.account_balance,
                                  color: Colors.blue.shade800, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Transferencia',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${totalTransferencia.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (resumenPorCuenta.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'DETALLE POR CUENTA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...resumenPorCuenta.entries
                        .map((entry) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      entry.key,
                                      style:
                                          const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '\$${entry.value.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenRow(String label, String value, FontWeight weight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: weight),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: weight),
          ),
        ],
      ),
    );
  }

  Widget _buildInquilinoCard(Inquilino inquilino) {
    final mesAnio = DateFormat('MM-yyyy').format(_selectedDate);
    final estaPagado = inquilino.haPagado(mesAnio);
    final estaPagadoAlquiler = inquilino.haPagadoAlquiler(mesAnio);
    final estaPagadoExpensas = inquilino.haPagadoExpensas(mesAnio);
    final montoPendiente = inquilino.getMontoPendiente(mesAnio);
    
    // Obtener el precio del alquiler específico para este mes
    final precioAlquilerMes = inquilino.getPrecioAlquilerPorMes(mesAnio);
    
    // Obtener las expensas específicas para este mes
    final expensasMes = inquilino.getExpensasPorMes(mesAnio);
    final expensasAMostrar = expensasMes > 0 ? expensasMes : _expensasComunes;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${inquilino.nombre} ${inquilino.apellido}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Depto: ${inquilino.departamento}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _mostrarEditarInquilinoDialog(inquilino),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _confirmarEliminarInquilino(inquilino),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Alquiler:'),
                Text(
                  '\$${NumberFormat('#,###.##', 'es_AR').format(precioAlquilerMes)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Expensas:'),
                Text(
                  '\$${NumberFormat('#,###.##', 'es_AR').format(expensasAMostrar)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (montoPendiente > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monto pendiente:',
                    style: TextStyle(color: Colors.red),
                  ),
                  Text(
                    '\$${NumberFormat('#,###.##', 'es_AR').format(montoPendiente)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPagoButton(
                    label: 'Alquiler',
                    isPaid: estaPagadoAlquiler,
                    onPressed: () => _togglePagoAlquiler(inquilino),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPagoButton(
                    label: 'Expensas',
                    isPaid: estaPagadoExpensas,
                    onPressed: () => _togglePagoExpensas(inquilino),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildPagoButton(
              label: 'Marcar Todo como Pagado',
              isPaid: estaPagado,
              onPressed: () => _togglePago(inquilino),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _mostrarOpcionesPago(inquilino),
                    icon: const Icon(Icons.payment),
                    label: const Text('Opciones de Pago'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Método para guardar un inquilino en el almacenamiento
  Future<void> _guardarInquilino(Inquilino inquilino) async {
    try {
      log.i('Guardando inquilino: ${inquilino.nombre} ${inquilino.apellido}');
      
      // Verificar si el widget sigue montado antes de actualizar el estado
      if (!mounted) return;
      
      // Actualizar la lista de inquilinos en memoria
      setState(() {
        // Buscar si el inquilino ya existe en la lista
        final index = _inquilinos.indexWhere((i) => i.id == inquilino.id);
        if (index >= 0) {
          // Actualizar el inquilino existente
          _inquilinos[index] = inquilino;
        } else {
          // Añadir el nuevo inquilino
          _inquilinos.add(inquilino);
        }
      });
      
      // Guardar todos los inquilinos utilizando el StorageService
      await _storageService.saveInquilinos(_inquilinos);
      
      // Forzar una recarga completa para asegurar que todos los datos se actualicen correctamente
      _cargarInquilinos();
      
      log.i('Inquilino guardado exitosamente');
    } catch (e) {
      log.e('Error al guardar inquilino: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar inquilino: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método para construir botones de pago con estado
  Widget _buildPagoButton({
    required String label,
    required bool isPaid,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        isPaid ? Icons.check_circle : Icons.unpublished,
        color: isPaid ? Colors.white : Colors.white70,
      ),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPaid ? Colors.green : Colors.grey,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 40),
      ),
    );
  }

  // Método para mostrar opciones de pago
  void _mostrarOpcionesPago(Inquilino inquilino) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Opciones de pago',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Registrar método de pago'),
                  onTap: () {
                    Navigator.pop(context);
                    _registrarMetodoPago(inquilino);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.pending_actions),
                  title: const Text('Registrar monto pendiente'),
                  onTap: () {
                    Navigator.pop(context);
                    _agregarMontoPendiente(inquilino);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('Generar recibo'),
                  onTap: () {
                    Navigator.pop(context);
                    _generarReciboPDF(inquilino);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report),
                  title: const Text('Informe de deudas'),
                  onTap: () {
                    Navigator.pop(context);
                    _generarInformeDeudas(inquilino);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text('Documentos'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DocumentosInquilinoScreen(
                          inquilino: inquilino,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Método para confirmar eliminación de inquilino
  Future<void> _confirmarEliminarInquilino(Inquilino inquilino) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Está seguro que desea eliminar a ${inquilino.nombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      _eliminarInquilino(inquilino);
    }
  }
} 

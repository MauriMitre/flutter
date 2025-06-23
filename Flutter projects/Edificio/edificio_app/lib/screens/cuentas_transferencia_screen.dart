import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/cuenta_transferencia.dart';
import '../services/storage_service.dart';

class CuentasTransferenciaScreen extends StatefulWidget {
  const CuentasTransferenciaScreen({Key? key}) : super(key: key);

  @override
  _CuentasTransferenciaScreenState createState() => _CuentasTransferenciaScreenState();
}

class _CuentasTransferenciaScreenState extends State<CuentasTransferenciaScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _nombreController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  List<CuentaTransferencia> _cuentas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCuentas();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _cargarCuentas() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final cuentas = await _storageService.loadCuentasTransferencia();
      setState(() {
        _cuentas = cuentas;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar cuentas: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar cuentas: $e')),
        );
      }
    }
  }

  Future<void> _agregarCuenta() async {
    if (_formKey.currentState?.validate() ?? false) {
      final nombre = _nombreController.text.trim();
      
      final nuevaCuenta = CuentaTransferencia(
        id: const Uuid().v4(),
        nombre: nombre,
      );
      
      setState(() {
        _cuentas.add(nuevaCuenta);
      });
      
      await _storageService.saveCuentasTransferencia(_cuentas);
      
      _nombreController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta agregada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _eliminarCuenta(CuentaTransferencia cuenta) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text('¿Está seguro que desea eliminar la cuenta "${cuenta.nombre}"?'),
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
    
    if (confirmacion == true) {
      setState(() {
        _cuentas.removeWhere((c) => c.id == cuenta.id);
      });
      
      await _storageService.saveCuentasTransferencia(_cuentas);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta eliminada correctamente'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _editarCuenta(CuentaTransferencia cuenta) async {
    final controller = TextEditingController(text: cuenta.nombre);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar cuenta'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nombre = controller.text.trim();
              if (nombre.isNotEmpty) {
                Navigator.pop(context, nombre);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El nombre no puede estar vacío')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      final index = _cuentas.indexWhere((c) => c.id == cuenta.id);
      if (index != -1) {
        setState(() {
          _cuentas[index].nombre = result;
        });
        
        await _storageService.saveCuentasTransferencia(_cuentas);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas de Transferencia'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la cuenta',
                              hintText: 'Ej. Banco Nación, Mercado Pago...',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor ingrese un nombre';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _agregarCuenta,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Agregar'),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _cuentas.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay cuentas registradas',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _cuentas.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final cuenta = _cuentas[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(cuenta.nombre),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editarCuenta(cuenta),
                                      tooltip: 'Editar',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _eliminarCuenta(cuenta),
                                      tooltip: 'Eliminar',
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
import 'package:flutter/material.dart';
import 'package:edificio_app/models/inquilino.dart';
import 'package:edificio_app/models/tarea.dart';
import 'package:edificio_app/services/storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class TareasScreen extends StatefulWidget {
  final List<Inquilino> inquilinos;

  const TareasScreen({Key? key, required this.inquilinos}) : super(key: key);

  @override
  _TareasScreenState createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  final StorageService _storageService = StorageService();
  List<Tarea> _tareas = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _cargarTareas();
  }
  
  Future<void> _cargarTareas() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final tareas = await _storageService.loadTareas();
      setState(() {
        _tareas = tareas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar tareas: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas de Mantenimiento'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tareas.isEmpty
              ? const Center(
                  child: Text(
                    'No hay tareas registradas',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tareas.length,
                  itemBuilder: (context, index) {
                    final tarea = _tareas[index];
                    final inquilino = widget.inquilinos.firstWhere(
                      (i) => i.id == tarea.inquilinoId,
                      orElse: () => Inquilino(
                        id: 'desconocido',
                        nombre: 'Inquilino',
                        apellido: 'Desconocido',
                        departamento: 'N/A',
                        precioAlquiler: 0,
                      ),
                    );
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
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
                                    tarea.titulo,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Checkbox(
                                  value: tarea.completada,
                                  onChanged: (value) => _marcarCompletada(tarea, value ?? false),
                                ),
                              ],
                            ),
                            const Divider(),
                            Text(
                              'Inquilino: ${inquilino.nombre} ${inquilino.apellido} (${inquilino.departamento})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Descripción: ${tarea.descripcion}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Fecha de creación: ${DateFormat('dd/MM/yyyy').format(tarea.fechaCreacion)}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            if (tarea.fechaFinalizacion != null)
                              Text(
                                'Finalizada: ${DateFormat('dd/MM/yyyy').format(tarea.fechaFinalizacion!)}',
                                style: const TextStyle(fontSize: 14, color: Colors.green),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editarTarea(tarea),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmarEliminarTarea(tarea),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarTarea,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Future<void> _marcarCompletada(Tarea tarea, bool completada) async {
    final nuevaTarea = Tarea(
      id: tarea.id,
      inquilinoId: tarea.inquilinoId,
      titulo: tarea.titulo,
      descripcion: tarea.descripcion,
      fechaCreacion: tarea.fechaCreacion,
      fechaFinalizacion: completada ? DateTime.now() : null,
      completada: completada,
    );
    
    try {
      await _storageService.saveTarea(nuevaTarea, _tareas);
      await _cargarTareas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar tarea: $e')),
      );
    }
  }
  
  Future<void> _confirmarEliminarTarea(Tarea tarea) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro que desea eliminar la tarea "${tarea.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    if (confirmacion == true) {
      try {
        await _storageService.deleteTarea(tarea.id, _tareas);
        await _cargarTareas();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarea eliminada con éxito')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar tarea: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _agregarTarea() async {
    await _mostrarFormularioTarea();
  }
  
  Future<void> _editarTarea(Tarea tarea) async {
    await _mostrarFormularioTarea(tarea);
  }
  
  Future<void> _mostrarFormularioTarea([Tarea? tarea]) async {
    final tituloController = TextEditingController(text: tarea?.titulo ?? '');
    final descripcionController = TextEditingController(text: tarea?.descripcion ?? '');
    String? inquilinoSeleccionadoId = tarea?.inquilinoId ?? widget.inquilinos.first.id;
    
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarea == null ? 'Agregar Tarea' : 'Editar Tarea',
                  style: const TextStyle(
                    fontSize: 20.0, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: inquilinoSeleccionadoId,
                  decoration: const InputDecoration(
                    labelText: 'Inquilino',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.inquilinos.map((inquilino) {
                    return DropdownMenuItem<String>(
                      value: inquilino.id,
                      child: Text(
                        '${inquilino.nombre} ${inquilino.apellido} (${inquilino.departamento})',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      inquilinoSeleccionadoId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ej. Reparación de caño',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej. Pérdida de agua en el baño',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (tituloController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('El título es obligatorio')),
                          );
                          return;
                        }
                        
                        Navigator.pop(context, {
                          'inquilinoId': inquilinoSeleccionadoId,
                          'titulo': tituloController.text.trim(),
                          'descripcion': descripcionController.text.trim(),
                        });
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    if (resultado != null) {
      final nuevaTarea = Tarea(
        id: tarea?.id ?? const Uuid().v4(),
        inquilinoId: resultado['inquilinoId'],
        titulo: resultado['titulo'],
        descripcion: resultado['descripcion'],
        fechaCreacion: tarea?.fechaCreacion ?? DateTime.now(),
        fechaFinalizacion: tarea?.fechaFinalizacion,
        completada: tarea?.completada ?? false,
      );
      
      try {
        await _storageService.saveTarea(nuevaTarea, _tareas);
        await _cargarTareas();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tarea == null ? 'Tarea agregada con éxito' : 'Tarea actualizada con éxito')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar tarea: $e')),
          );
        }
      }
    }
  }
}

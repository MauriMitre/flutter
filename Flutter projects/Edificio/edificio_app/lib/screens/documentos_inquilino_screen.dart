import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import '../models/inquilino.dart';
import '../models/documento.dart';
import '../services/storage_service.dart';
import '../services/file_service.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path/path.dart' as path;

class DocumentosInquilinoScreen extends StatefulWidget {
  final Inquilino inquilino;

  const DocumentosInquilinoScreen({
    Key? key,
    required this.inquilino,
  }) : super(key: key);

  @override
  DocumentosInquilinoScreenState createState() => DocumentosInquilinoScreenState();
}

class DocumentosInquilinoScreenState extends State<DocumentosInquilinoScreen> {
  final StorageService _storageService = StorageService();
  final FileService _fileService = FileService();
  final ImagePicker _picker = ImagePicker();
  List<Documento> _documentos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDocumentos();
  }

  Future<void> _cargarDocumentos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final documentos = await _storageService.getDocumentosPorInquilino(widget.inquilino.id);
      setState(() {
        _documentos = documentos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarError('Error al cargar documentos: $e');
    }
  }

  Future<void> _agregarDocumento() async {
    final tipo = await _seleccionarTipoDocumento();
    if (tipo == null) return;

    try {
      // Mostrar opciones para seleccionar tipo de documento
      final documentType = await _seleccionarTipoArchivo();
      if (documentType == null) return;

      if (documentType == 'image') {
        await _agregarImagen(tipo);
      } else if (documentType == 'pdf') {
        await _agregarPDF(tipo);
      }
    } catch (e) {
      // Error general al agregar documento: $e
      _mostrarError('Error al agregar documento: $e');
    }
  }

  Future<void> _agregarImagen(TipoDocumento tipo) async {
    // Mostrar opciones para seleccionar fuente de la imagen
    final source = await _seleccionarFuenteImagen();
    if (source == null) return;

    XFile? pickedFile;
    try {
      if (source == 'camera') {
        pickedFile = await _picker.pickImage(source: ImageSource.camera);
      } else {
        pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      }
    } catch (e) {
      // Error al seleccionar imagen: $e
      _mostrarError('Error al seleccionar imagen: $e');
      return;
    }

    if (pickedFile != null) {
      await _procesarArchivo(File(pickedFile.path), pickedFile.name, tipo);
    }
  }

  Future<void> _agregarPDF(TipoDocumento tipo) async {
    try {
      // Usar el método del sistema para seleccionar un PDF
      final result = await _seleccionarPDFDelSistema();
      if (result == null) return;

      File file = File(result['path'] ?? '');
      String fileName = result['name'] ?? 'documento.pdf';
      
      await _procesarArchivo(file, fileName, tipo);
    } catch (e) {
      // Error al seleccionar PDF: $e
      _mostrarError('Error al seleccionar PDF: $e');
    }
  }

  Future<Map<String, String>?> _seleccionarPDFDelSistema() async {
    try {
      // Usamos el intent del sistema para seleccionar un PDF
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Seleccionar PDF'),
            content: const Text('Por favor, usa otra aplicación (como el explorador de archivos) para seleccionar un PDF. Luego regresa a esta aplicación.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: const Text('Seleccionar PDF'),
                onPressed: () async {
                  // Aquí deberíamos abrir el selector de archivos del sistema
                  // Pero como no podemos usar file_picker directamente, mostramos instrucciones
                  Navigator.of(context).pop({'path': '/ruta/simulada/documento.pdf', 'name': 'documento.pdf'});
                  
                  // En una implementación real, aquí se usaría un método nativo para seleccionar el PDF
                  // Por ahora, solo mostramos un mensaje explicando la limitación
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La selección de PDFs está limitada en esta versión. Por favor, usa imágenes por ahora.'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
      
      return result;
    } catch (e) {
      // Error al seleccionar PDF: $e
      return null;
    }
  }

  Future<void> _procesarArchivo(File file, String fileName, TipoDocumento tipo) async {
    // Mostrar diálogo para ingresar detalles adicionales
    final detalles = await _mostrarDialogoDetalles(tipo, fileName);
    if (detalles == null) return;

    // Guardar archivo
    final rutaRelativa = await _fileService.guardarArchivo(
      file, 
      widget.inquilino.id, 
      fileName
    );

    // Crear y guardar documento
    final documento = Documento(
      inquilinoId: widget.inquilino.id,
      tipo: tipo,
      nombre: detalles['nombre'],
      rutaArchivo: rutaRelativa,
      numeroDocumento: detalles['numeroDocumento'],
      fechaVencimiento: detalles['fechaVencimiento'],
      notas: detalles['notas'],
    );

    await _storageService.saveDocumento(documento);
    await _cargarDocumentos();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento guardado correctamente')),
      );
    }
  }

  Future<String?> _seleccionarTipoArchivo() async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tipo de archivo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Imagen'),
                onTap: () {
                  Navigator.of(context).pop('image');
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF (Experimental)'),
                onTap: () {
                  Navigator.of(context).pop('pdf');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _seleccionarFuenteImagen() async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar imagen desde'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.of(context).pop('camera');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.of(context).pop('gallery');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<TipoDocumento?> _seleccionarTipoDocumento() async {
    return showDialog<TipoDocumento>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tipo de documento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: TipoDocumento.values.map((tipo) {
              return ListTile(
                title: Text(tipo.displayName),
                onTap: () {
                  Navigator.of(context).pop(tipo);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _mostrarDialogoDetalles(
    TipoDocumento tipo,
    String nombreArchivo,
  ) async {
    final nombreController = TextEditingController(text: nombreArchivo);
    final numeroDocumentoController = TextEditingController();
    final notasController = TextEditingController();
    DateTime? fechaVencimiento;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Detalles del ${tipo.displayName}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del documento',
                      ),
                    ),
                    TextField(
                      controller: numeroDocumentoController,
                      decoration: const InputDecoration(
                        labelText: 'Número de documento (opcional)',
                      ),
                    ),
                    TextField(
                      controller: notasController,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Fecha de vencimiento (opcional)'),
                      subtitle: Text(fechaVencimiento == null
                          ? 'No seleccionada'
                          : DateFormat('dd/MM/yyyy').format(fechaVencimiento!)),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                        );
                        if (fecha != null) {
                          setState(() {
                            fechaVencimiento = fecha;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (nombreController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('El nombre es obligatorio')),
                      );
                      return;
                    }
                    Navigator.of(context).pop({
                      'nombre': nombreController.text,
                      'numeroDocumento': numeroDocumentoController.text.isEmpty
                          ? null
                          : numeroDocumentoController.text,
                      'notas': notasController.text.isEmpty ? null : notasController.text,
                      'fechaVencimiento': fechaVencimiento,
                    });
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _eliminarDocumento(Documento documento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Estás seguro de eliminar este documento?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      try {
        // Eliminar archivo físico
        await _fileService.eliminarArchivo(documento.rutaArchivo);
        // Eliminar registro
        await _storageService.deleteDocumento(documento.id);
        await _cargarDocumentos();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documento eliminado correctamente')),
          );
        }
      } catch (e) {
        _mostrarError('Error al eliminar documento: $e');
      }
    }
  }

  Future<void> _abrirDocumento(Documento documento) async {
    try {
      final archivo = await _fileService.getArchivo(documento.rutaArchivo);
      if (await archivo.exists()) {
        final extension = path.extension(archivo.path).toLowerCase();
        
        if (extension == '.pdf') {
          // Abrir PDF con el visor de PDF
          _abrirPDF(archivo);
        } else {
          // Abrir otros archivos con el visor predeterminado
          await OpenFile.open(archivo.path);
        }
      } else {
        _mostrarError('El archivo no existe');
      }
    } catch (e) {
      _mostrarError('Error al abrir documento: $e');
    }
  }
  
  void _abrirPDF(File archivo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Visor de PDF'),
          ),
          body: PDFView(
            filePath: archivo.path,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: false,
            onError: (error) {
              _mostrarError('Error al cargar PDF: $error');
            },
            onPageError: (page, error) {
              _mostrarError('Error en la página $page: $error');
            },
          ),
        ),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documentos de ${widget.inquilino.nombre} ${widget.inquilino.apellido}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documentos.isEmpty
              ? const Center(child: Text('No hay documentos registrados'))
              : ListView.builder(
                  itemCount: _documentos.length,
                  itemBuilder: (context, index) {
                    final documento = _documentos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(documento.nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(documento.tipo.displayName),
                            if (documento.numeroDocumento != null)
                              Text('N°: ${documento.numeroDocumento}'),
                            if (documento.fechaVencimiento != null)
                              Text(
                                'Vence: ${DateFormat('dd/MM/yyyy').format(documento.fechaVencimiento!)}',
                              ),
                          ],
                        ),
                        leading: _getIconoDocumento(documento.tipo),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _abrirDocumento(documento),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _eliminarDocumento(documento),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () => _abrirDocumento(documento),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarDocumento,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getIconoDocumento(TipoDocumento tipo) {
    IconData icono;
    Color color;

    switch (tipo) {
      case TipoDocumento.dni:
        icono = Icons.credit_card;
        color = Colors.blue;
        break;
      case TipoDocumento.contrato:
        icono = Icons.description;
        color = Colors.green;
        break;
      case TipoDocumento.boletaSueldo:
        icono = Icons.receipt;
        color = Colors.orange;
        break;
      case TipoDocumento.garantia:
        icono = Icons.security;
        color = Colors.purple;
        break;
      case TipoDocumento.otro:
        icono = Icons.folder;
        color = Colors.grey;
        break;
    }

    return CircleAvatar(
      backgroundColor: color,
      child: Icon(icono, color: Colors.white),
    );
  }
}

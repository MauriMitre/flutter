import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'log_service.dart';

class FileService {
  // Esta función se eliminó porque no estaba siendo utilizada
  
  // Guardar un archivo y obtener su ruta relativa
  Future<String> guardarArchivo(File archivo, String inquilinoId, String nombreOriginal) async {
    try {
      // Obtener directorio de documentos
      final appDir = await getApplicationDocumentsDirectory();
      
      // Crear carpeta para el inquilino si no existe
      final inquilinoDir = Directory('${appDir.path}/inquilinos/$inquilinoId');
      if (!await inquilinoDir.exists()) {
        await inquilinoDir.create(recursive: true);
      }
      
      // Generar nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = nombreOriginal.split('.').last;
      final nombreArchivo = '$timestamp.$extension';
      
      // Ruta completa del archivo
      final rutaDestino = '${inquilinoDir.path}/$nombreArchivo';
      
      // Copiar archivo a la ubicación final
      await archivo.copy(rutaDestino);
      
      // Devolver ruta relativa para guardar en la base de datos
      return 'inquilinos/$inquilinoId/$nombreArchivo';
    } catch (e, stackTrace) {
      log.e('Error al guardar archivo', e, stackTrace);
      rethrow;
    }
  }
  
  // Obtener archivo a partir de ruta relativa
  Future<File> getArchivo(String rutaRelativa) async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$rutaRelativa');
  }
  
  // Eliminar archivo
  Future<void> eliminarArchivo(String rutaRelativa) async {
    try {
      final archivo = await getArchivo(rutaRelativa);
      if (await archivo.exists()) {
        await archivo.delete();
        log.i('Archivo eliminado: $rutaRelativa');
      } else {
        log.w('Archivo no encontrado para eliminar: $rutaRelativa');
      }
    } catch (e, stackTrace) {
      log.e('Error al eliminar archivo', e, stackTrace);
      rethrow;
    }
  }
  
  // Verificar si un archivo existe
  Future<bool> archivoExiste(String rutaRelativa) async {
    try {
      final archivo = await getArchivo(rutaRelativa);
      return await archivo.exists();
    } catch (e) {
      return false;
    }
  }
  
  // Obtener tamaño del archivo en KB
  Future<double> getTamanoArchivo(String rutaRelativa) async {
    try {
      final archivo = await getArchivo(rutaRelativa);
      if (await archivo.exists()) {
        final tamanoBytes = await archivo.length();
        return tamanoBytes / 1024; // Convertir a KB
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
} 
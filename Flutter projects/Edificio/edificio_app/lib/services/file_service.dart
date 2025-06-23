import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class FileService {
  // Obtener directorio para almacenar documentos
  Future<Directory> get _documentosDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final documentosDir = Directory('${appDir.path}/documentos');
    
    // Crear directorio si no existe
    if (!await documentosDir.exists()) {
      await documentosDir.create(recursive: true);
    }
    
    return documentosDir;
  }
  
  // Guardar un archivo y obtener su ruta relativa
  Future<String> guardarArchivo(File archivo, String inquilinoId, String nombre) async {
    try {
      final dir = await _documentosDir;
      
      // Crear directorio específico para el inquilino
      final inquilinoDir = Directory('${dir.path}/$inquilinoId');
      if (!await inquilinoDir.exists()) {
        await inquilinoDir.create(recursive: true);
      }
      
      // Generar nombre único para el archivo
      final extension = path.extension(archivo.path);
      final nombreArchivo = '${const Uuid().v4()}$extension';
      
      // Ruta completa del archivo
      final rutaDestino = '${inquilinoDir.path}/$nombreArchivo';
      
      // Copiar archivo a destino
      await archivo.copy(rutaDestino);
      
      // Devolver ruta relativa para almacenar en la base de datos
      return '$inquilinoId/$nombreArchivo';
    } catch (e) {
      debugPrint('Error al guardar archivo: $e');
      rethrow;
    }
  }
  
  // Obtener archivo a partir de ruta relativa
  Future<File> getArchivo(String rutaRelativa) async {
    final dir = await _documentosDir;
    final rutaCompleta = '${dir.path}/$rutaRelativa';
    return File(rutaCompleta);
  }
  
  // Eliminar archivo
  Future<void> eliminarArchivo(String rutaRelativa) async {
    try {
      final archivo = await getArchivo(rutaRelativa);
      if (await archivo.exists()) {
        await archivo.delete();
      }
    } catch (e) {
      debugPrint('Error al eliminar archivo: $e');
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
import 'dart:io';
import 'package:flutter/material.dart';
import 'documentation_generator.dart';
import 'services/log_service.dart';

// Archivo ejecutable para generar la documentación
void main() async {
  // Inicializar Flutter
  WidgetsFlutterBinding.ensureInitialized();

  
  // Generar documentación
  await generateDocs();
}

Future<void> generateDocs() async {
  try {
    log.i('Generando documentación...');
    
    final generator = DocumentationGenerator();
    final filePath = await generator.generateDocumentation();
    
    log.i('Documentación generada en: $filePath');
    
    // Abrir el archivo generado si es posible
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final file = File(filePath);
      if (await file.exists()) {
        log.i('Abriendo documentación generada...');
        if (Platform.isWindows) {
          Process.run('start', [filePath], runInShell: true);
        } else if (Platform.isMacOS) {
          Process.run('open', [filePath]);
        } else {
          Process.run('xdg-open', [filePath]);
        }
      }
    }
  } catch (e, stackTrace) {
    log.e('Error al generar documentación', e, stackTrace);
  }
} 
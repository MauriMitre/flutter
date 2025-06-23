import 'package:flutter/material.dart';
import 'documentation_generator.dart';

// Archivo ejecutable para generar la documentación
void main() async {
  // Inicializar Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Crear instancia del generador
  final docGenerator = DocumentationGenerator();
  
  // Generar documentación
  print('Generando documentación...');
  final filePath = await docGenerator.generateDocumentation();
  
  print('Documentación generada en: $filePath');
} 
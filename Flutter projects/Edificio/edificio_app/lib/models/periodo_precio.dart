import 'dart:convert';
import 'package:intl/intl.dart';

/// Clase que representa un período de tiempo con un precio específico
/// Esto permite gestionar cambios de precios de alquiler de forma más eficiente
class PeriodoPrecio {
  /// Fecha de inicio del período (el primer mes en que aplica este precio)
  final DateTime fechaInicio;
  
  /// Precio para este período
  final double precio;

  /// Constructor
  PeriodoPrecio({
    required this.fechaInicio,
    required this.precio,
  });

  /// Convertir a Map para almacenar en SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'fechaInicio': DateFormat('MM-yyyy').format(fechaInicio),
      'precio': precio,
    };
  }

  /// Crear desde Map al cargar de SharedPreferences
  factory PeriodoPrecio.fromMap(Map<String, dynamic> map) {
    final partes = (map['fechaInicio'] as String).split('-');
    return PeriodoPrecio(
      fechaInicio: DateTime(
        int.parse(partes[1]),  // año
        int.parse(partes[0]),  // mes
        1,                     // día (siempre 1)
      ),
      precio: (map['precio'] is int) 
          ? (map['precio'] as int).toDouble() 
          : map['precio'] as double,
    );
  }

  /// Serialización a JSON
  String toJson() => json.encode(toMap());

  /// Creación desde JSON
  factory PeriodoPrecio.fromJson(String source) => 
      PeriodoPrecio.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Para depuración
  @override
  String toString() {
    return 'PeriodoPrecio(${DateFormat('MM-yyyy').format(fechaInicio)}: \$${precio.toStringAsFixed(2)})';
  }
} 
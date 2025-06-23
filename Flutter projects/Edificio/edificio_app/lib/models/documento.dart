import 'dart:convert';
import 'package:uuid/uuid.dart';

// Enum para los tipos de documentos
enum TipoDocumento {
  dni,
  contrato,
  boletaSueldo,
  garantia,
  otro
}

// Extensión para convertir String a Enum y viceversa
extension TipoDocumentoExtension on TipoDocumento {
  String toValue() {
    return toString().split('.').last;
  }
  
  static TipoDocumento fromValue(String? value) {
    if (value == null) return TipoDocumento.otro;
    return TipoDocumento.values.firstWhere(
      (e) => e.toValue() == value,
      orElse: () => TipoDocumento.otro,
    );
  }
  
  String get displayName {
    switch (this) {
      case TipoDocumento.dni:
        return 'DNI';
      case TipoDocumento.contrato:
        return 'Contrato';
      case TipoDocumento.boletaSueldo:
        return 'Boleta de Sueldo';
      case TipoDocumento.garantia:
        return 'Garantía';
      case TipoDocumento.otro:
        return 'Otro';
    }
  }
}

class Documento {
  final String id;
  final String inquilinoId;
  final TipoDocumento tipo;
  final String nombre;
  final String rutaArchivo;
  final DateTime fechaSubida;
  final String? notas;
  final String? numeroDocumento;
  final DateTime? fechaVencimiento;

  Documento({
    String? id,
    required this.inquilinoId,
    required this.tipo,
    required this.nombre,
    required this.rutaArchivo,
    DateTime? fechaSubida,
    this.notas,
    this.numeroDocumento,
    this.fechaVencimiento,
  }) : 
    id = id ?? const Uuid().v4(),
    fechaSubida = fechaSubida ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inquilinoId': inquilinoId,
      'tipo': tipo.toValue(),
      'nombre': nombre,
      'rutaArchivo': rutaArchivo,
      'fechaSubida': fechaSubida.millisecondsSinceEpoch,
      'notas': notas,
      'numeroDocumento': numeroDocumento,
      'fechaVencimiento': fechaVencimiento?.millisecondsSinceEpoch,
    };
  }

  factory Documento.fromMap(Map<String, dynamic> map) {
    return Documento(
      id: map['id'] as String? ?? const Uuid().v4(),
      inquilinoId: map['inquilinoId'] as String? ?? '',
      tipo: TipoDocumentoExtension.fromValue(map['tipo'] as String?),
      nombre: map['nombre'] as String? ?? '',
      rutaArchivo: map['rutaArchivo'] as String? ?? '',
      fechaSubida: map['fechaSubida'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['fechaSubida'] as int) 
        : DateTime.now(),
      notas: map['notas'] as String?,
      numeroDocumento: map['numeroDocumento'] as String?,
      fechaVencimiento: map['fechaVencimiento'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['fechaVencimiento'] as int) 
        : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Documento.fromJson(String source) => 
      Documento.fromMap(json.decode(source) as Map<String, dynamic>);
      
  Documento copyWith({
    String? id,
    String? inquilinoId,
    TipoDocumento? tipo,
    String? nombre,
    String? rutaArchivo,
    DateTime? fechaSubida,
    String? notas,
    String? numeroDocumento,
    DateTime? fechaVencimiento,
  }) {
    return Documento(
      id: id ?? this.id,
      inquilinoId: inquilinoId ?? this.inquilinoId,
      tipo: tipo ?? this.tipo,
      nombre: nombre ?? this.nombre,
      rutaArchivo: rutaArchivo ?? this.rutaArchivo,
      fechaSubida: fechaSubida ?? this.fechaSubida,
      notas: notas ?? this.notas,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
    );
  }
} 
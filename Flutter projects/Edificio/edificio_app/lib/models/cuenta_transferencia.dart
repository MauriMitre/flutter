import 'dart:convert';

class CuentaTransferencia {
  final String id;
  String nombre;

  CuentaTransferencia({
    required this.id,
    required this.nombre,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }

  factory CuentaTransferencia.fromMap(Map<String, dynamic> map) {
    return CuentaTransferencia(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory CuentaTransferencia.fromJson(String source) => 
      CuentaTransferencia.fromMap(json.decode(source));
} 
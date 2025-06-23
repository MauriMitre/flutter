import 'dart:convert';

class Tarea {
  final String id;
  final String inquilinoId;
  String titulo;
  String descripcion;
  DateTime fechaCreacion;
  DateTime? fechaFinalizacion;
  bool completada;

  Tarea({
    required this.id,
    required this.inquilinoId,
    required this.titulo,
    required this.descripcion,
    required this.fechaCreacion,
    this.fechaFinalizacion,
    this.completada = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inquilinoId': inquilinoId,
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaCreacion': fechaCreacion.millisecondsSinceEpoch,
      'fechaFinalizacion': fechaFinalizacion?.millisecondsSinceEpoch,
      'completada': completada,
    };
  }

  factory Tarea.fromMap(Map<String, dynamic> map) {
    return Tarea(
      id: map['id'],
      inquilinoId: map['inquilinoId'],
      titulo: map['titulo'],
      descripcion: map['descripcion'],
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(map['fechaCreacion']),
      fechaFinalizacion: map['fechaFinalizacion'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fechaFinalizacion'])
          : null,
      completada: map['completada'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Tarea.fromJson(String source) => Tarea.fromMap(json.decode(source));
} 
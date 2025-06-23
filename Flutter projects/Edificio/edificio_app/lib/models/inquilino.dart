import 'dart:convert';

// Enum para el método de pago
enum MetodoPago {
  efectivo,
  transferencia
}

// Extensión para convertir String a Enum y viceversa
extension MetodoPagoExtension on MetodoPago {
  String toValue() {
    return toString().split('.').last;
  }
  
  static MetodoPago fromValue(String? value) {
    if (value == null) return MetodoPago.efectivo;
    return MetodoPago.values.firstWhere(
      (e) => e.toValue() == value,
      orElse: () => MetodoPago.efectivo,
    );
  }
}

class Inquilino {
  final String id;
  String nombre;
  String departamento;
  String apellido;
  double precioAlquiler;
  Map<String, double> expensas; // Mapa con formato "MM-yyyy" -> monto
  Map<String, bool> pagos; // Formato "MM-yyyy" -> pagado
  Map<String, bool> pagosAlquiler; // Pagos de alquiler por mes
  Map<String, bool> pagosExpensas; // Pagos de expensas por mes
  Map<String, double> montosPendientes; // Montos pendientes por mes
  
  // Nuevos campos para método de pago
  Map<String, String> metodosPago; // Formato "MM-yyyy" -> "efectivo" o "transferencia"
  Map<String, String> cuentasTransferencia; // Formato "MM-yyyy" -> "cuenta destino"

  Inquilino({
    required this.id,
    required this.nombre,
    required this.departamento,
    required this.precioAlquiler,
    required this.apellido,
    Map<String, double>? expensas,
    Map<String, bool>? pagos,
    Map<String, bool>? pagosAlquiler,
    Map<String, bool>? pagosExpensas,
    Map<String, double>? montosPendientes,
    Map<String, String>? metodosPago,
    Map<String, String>? cuentasTransferencia,
  }) : 
    expensas = expensas ?? {},
    pagos = pagos ?? {},
    pagosAlquiler = pagosAlquiler ?? {},
    pagosExpensas = pagosExpensas ?? {},
    montosPendientes = montosPendientes ?? {},
    metodosPago = metodosPago ?? {},
    cuentasTransferencia = cuentasTransferencia ?? {};

  // Verifica si ha pagado tanto alquiler como expensas
  bool haPagado(String mesAnio) {
    return pagos[mesAnio] ?? false;
  }

  // Verifica si ha pagado el alquiler
  bool haPagadoAlquiler(String mesAnio) {
    // Imprimir información de depuración
    print('Verificando pago de alquiler para $mesAnio: ${pagosAlquiler[mesAnio] ?? false}');
    return pagosAlquiler[mesAnio] ?? false;
  }

  // Verifica si ha pagado las expensas
  bool haPagadoExpensas(String mesAnio) {
    // Imprimir información de depuración
    print('Verificando pago de expensas para $mesAnio: ${pagosExpensas[mesAnio] ?? false}');
    return pagosExpensas[mesAnio] ?? false;
  }

  // Obtener el monto pendiente para un mes específico
  double getMontoPendiente(String mesAnio) {
    // Imprimir información de depuración
    print('Obteniendo monto pendiente para $mesAnio: ${montosPendientes[mesAnio] ?? 0.0}');
    return montosPendientes[mesAnio] ?? 0.0;
  }
  
  // Obtener el método de pago para un mes específico
  MetodoPago getMetodoPago(String mesAnio) {
    final metodoPagoStr = metodosPago[mesAnio];
    return MetodoPagoExtension.fromValue(metodoPagoStr);
  }
  
  // Establecer el método de pago para un mes específico
  void setMetodoPago(String mesAnio, MetodoPago metodoPago) {
    metodosPago[mesAnio] = metodoPago.toValue();
  }
  
  // Obtener la cuenta de transferencia para un mes específico
  String getCuentaTransferencia(String mesAnio) {
    return cuentasTransferencia[mesAnio] ?? '';
  }
  
  // Establecer la cuenta de transferencia para un mes específico
  void setCuentaTransferencia(String mesAnio, String cuenta) {
    cuentasTransferencia[mesAnio] = cuenta;
  }

  // Marcar como pagado (tanto alquiler como expensas)
  void marcarPagado(String mesAnio, bool pagado) {
    pagos[mesAnio] = pagado;
    
    // Si se marca como pagado, marcar ambos como pagados
    if (pagado) {
      pagosAlquiler[mesAnio] = true;
      pagosExpensas[mesAnio] = true;
      montosPendientes[mesAnio] = 0.0; // Eliminar monto pendiente
    } else {
      // Si se desmarca, desmarcar ambos pagos
      pagosAlquiler[mesAnio] = false;
      pagosExpensas[mesAnio] = false;
    }
  }

  // Marcar pago de alquiler
  void marcarPagoAlquiler(String mesAnio, bool pagado) {
    pagosAlquiler[mesAnio] = pagado;
    
    // Actualizar estado general
    pagos[mesAnio] = pagosAlquiler[mesAnio] == true && pagosExpensas[mesAnio] == true;
  }

  // Marcar pago de expensas
  void marcarPagoExpensas(String mesAnio, bool pagado) {
    pagosExpensas[mesAnio] = pagado;
    
    // Actualizar estado general
    pagos[mesAnio] = pagosAlquiler[mesAnio] == true && pagosExpensas[mesAnio] == true;
  }

  // Establecer monto pendiente
  void setMontoPendiente(String mesAnio, double monto) {
    if (monto <= 0) {
      montosPendientes.remove(mesAnio); // Eliminar del mapa si es cero
    } else {
      montosPendientes[mesAnio] = monto;
    }
  }

  // Obtener las expensas para un mes específico
  double getExpensasPorMes(String mesAnio) {
    // Si el inquilino tiene expensas personalizadas para este mes, devolver esas
    final expensasMes = expensas[mesAnio] ?? 0.0;
    print('Obteniendo expensas para $mesAnio: $expensasMes');
    return expensasMes;
  }

  // Establecer expensas para un mes específico
  void setExpensas(String mesAnio, double monto) {
    if (monto <= 0) {
      expensas.remove(mesAnio); // Eliminar del mapa si es cero
    } else {
      expensas[mesAnio] = monto;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'departamento': departamento,
      'apellido': apellido,
      'precioAlquiler': precioAlquiler,
      'expensas': expensas,
      'pagos': pagos,
      'pagosAlquiler': pagosAlquiler,
      'pagosExpensas': pagosExpensas,
      'montosPendientes': montosPendientes,
      'metodosPago': metodosPago,
      'cuentasTransferencia': cuentasTransferencia,
    };
  }

  factory Inquilino.fromMap(Map<String, dynamic> map) {
    // Convertir los mapas del JSON
    Map<String, double> expensasMap = {};
    Map<String, bool> pagosMap = {};
    Map<String, bool> pagosAlquilerMap = {};
    Map<String, bool> pagosExpensasMap = {};
    Map<String, double> montosPendientesMap = {};
    Map<String, String> metodosPagoMap = {};
    Map<String, String> cuentasTransferenciaMap = {};

    if (map['expensas'] != null) {
      final expensasData = map['expensas'] as Map<String, dynamic>;
      expensasMap = expensasData.map((key, value) => 
        MapEntry(key, (value is int) ? value.toDouble() : (value as num).toDouble()));
    }

    if (map['pagos'] != null) {
      final pagosData = map['pagos'] as Map<String, dynamic>;
      pagosMap = pagosData.map((key, value) => MapEntry(key, value as bool));
    }

    if (map['pagosAlquiler'] != null) {
      final pagosAlquilerData = map['pagosAlquiler'] as Map<String, dynamic>;
      pagosAlquilerMap = pagosAlquilerData.map((key, value) => MapEntry(key, value as bool));
    }

    if (map['pagosExpensas'] != null) {
      final pagosExpensasData = map['pagosExpensas'] as Map<String, dynamic>;
      pagosExpensasMap = pagosExpensasData.map((key, value) => MapEntry(key, value as bool));
    }

    if (map['montosPendientes'] != null) {
      final montosPendientesData = map['montosPendientes'] as Map<String, dynamic>;
      montosPendientesMap = montosPendientesData.map((key, value) => 
        MapEntry(key, (value is int) ? value.toDouble() : (value as num).toDouble()));
    }
    
    if (map['metodosPago'] != null) {
      final metodosPagoData = map['metodosPago'] as Map<String, dynamic>;
      metodosPagoMap = metodosPagoData.map((key, value) => MapEntry(key, value as String));
    }
    
    if (map['cuentasTransferencia'] != null) {
      final cuentasTransferenciaData = map['cuentasTransferencia'] as Map<String, dynamic>;
      cuentasTransferenciaMap = cuentasTransferenciaData.map((key, value) => MapEntry(key, value as String));
    }

    // Asegurarse de que ningún campo requerido sea nulo
    final id = map['id'] as String? ?? '';
    final nombre = map['nombre'] as String? ?? '';
    final departamento = map['departamento'] as String? ?? '';
    final apellido = map['apellido'] as String? ?? '';
    
    // Manejar el precioAlquiler adecuadamente
    double precioAlquiler = 0.0;
    if (map['precioAlquiler'] != null) {
      if (map['precioAlquiler'] is int) {
        precioAlquiler = (map['precioAlquiler'] as int).toDouble();
      } else if (map['precioAlquiler'] is double) {
        precioAlquiler = map['precioAlquiler'] as double;
      } else if (map['precioAlquiler'] is num) {
        precioAlquiler = (map['precioAlquiler'] as num).toDouble();
      }
    }

    return Inquilino(
      id: id,
      nombre: nombre,
      departamento: departamento,
      apellido: apellido,
      precioAlquiler: precioAlquiler,
      expensas: expensasMap,
      pagos: pagosMap,
      pagosAlquiler: pagosAlquilerMap,
      pagosExpensas: pagosExpensasMap,
      montosPendientes: montosPendientesMap,
      metodosPago: metodosPagoMap,
      cuentasTransferencia: cuentasTransferenciaMap,
    );
  }

  String toJson() => json.encode(toMap());

  factory Inquilino.fromJson(String source) =>
      Inquilino.fromMap(json.decode(source));
} 
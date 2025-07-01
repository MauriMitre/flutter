import 'dart:convert';
import '../services/log_service.dart';
import 'package:intl/intl.dart';

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
  final String nombre;
  final String apellido;
  final String departamento;
  final double _precioAlquilerBase;  // Precio base/predeterminado
  final Map<String, bool> pagos;
  final Map<String, double> expensas;
  final Map<String, bool> pagosAlquiler;
  final Map<String, bool> pagosExpensas;
  final Map<String, double> montosPendientes;
  final Map<String, MetodoPago> metodosPago;
  final Map<String, String> cuentasTransferencia;
  final Map<String, double> preciosAlquilerPorMes;  // Mapa para precios históricos

  // Getter para obtener el precio actual del alquiler
  double get precioAlquiler {
    // Obtener el mes actual
    final mesActual = DateFormat('MM-yyyy').format(DateTime.now());
    // Devolver el precio específico para este mes si existe, de lo contrario devolver el precio base
    return preciosAlquilerPorMes[mesActual] ?? _precioAlquilerBase;
  }

  Inquilino({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.departamento,
    required double precioAlquiler,
    this.pagos = const {},
    this.expensas = const {},
    this.pagosAlquiler = const {},
    this.pagosExpensas = const {},
    this.montosPendientes = const {},
    this.metodosPago = const {},
    this.cuentasTransferencia = const {},
    this.preciosAlquilerPorMes = const {},
  }) : _precioAlquilerBase = precioAlquiler;

  // Crear una copia del inquilino con valores actualizados
  Inquilino copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? departamento,
    double? precioAlquiler,
    Map<String, bool>? pagos,
    Map<String, double>? expensas,
    Map<String, bool>? pagosAlquiler,
    Map<String, bool>? pagosExpensas,
    Map<String, double>? montosPendientes,
    Map<String, MetodoPago>? metodosPago,
    Map<String, String>? cuentasTransferencia,
    Map<String, double>? preciosAlquilerPorMes,
  }) {
    return Inquilino(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      departamento: departamento ?? this.departamento,
      precioAlquiler: precioAlquiler ?? _precioAlquilerBase,
      pagos: pagos ?? Map.from(this.pagos),
      expensas: expensas ?? Map.from(this.expensas),
      pagosAlquiler: pagosAlquiler ?? Map.from(this.pagosAlquiler),
      pagosExpensas: pagosExpensas ?? Map.from(this.pagosExpensas),
      montosPendientes: montosPendientes ?? Map.from(this.montosPendientes),
      metodosPago: metodosPago ?? Map.from(this.metodosPago),
      cuentasTransferencia: cuentasTransferencia ?? Map.from(this.cuentasTransferencia),
      preciosAlquilerPorMes: preciosAlquilerPorMes ?? Map.from(this.preciosAlquilerPorMes),
    );
  }

  // Obtener el precio de alquiler para un mes específico
  double getPrecioAlquilerPorMes(String mesAnio) {
    log.d('Obteniendo precio para $mesAnio, mapa: ${preciosAlquilerPorMes.length} entradas');
    
    // Si hay un precio específico para este mes, devolver ese
    if (preciosAlquilerPorMes.containsKey(mesAnio)) {
      log.d('Precio encontrado directamente para $mesAnio: ${preciosAlquilerPorMes[mesAnio]}');
      return preciosAlquilerPorMes[mesAnio]!;
    }
    
    // Obtener mes y año del parámetro
    final partes = mesAnio.split('-');
    if (partes.length != 2) {
      log.d('Formato de fecha inválido: $mesAnio, usando precio base: $_precioAlquilerBase');
      return _precioAlquilerBase;
    }
    
    final mesNum = int.tryParse(partes[0]) ?? 0;
    final anioNum = int.tryParse(partes[1]) ?? 0;
    
    if (mesNum <= 0 || anioNum <= 0) {
      log.d('Números de mes/año inválidos: $mesAnio, usando precio base: $_precioAlquilerBase');
      return _precioAlquilerBase;
    }
    
    // Buscar el precio más reciente anterior a esta fecha
    String? mesReciente;
    DateTime fechaReciente = DateTime(1900);
    DateTime fechaActual = DateTime(anioNum, mesNum, 1);
    
    // Mostrar todas las fechas disponibles para depuración
    log.d('Fechas disponibles en preciosAlquilerPorMes: ${preciosAlquilerPorMes.keys.toList().join(", ")}');
    
    for (final key in preciosAlquilerPorMes.keys) {
      final partesMes = key.split('-');
      if (partesMes.length != 2) continue;
      
      final mesItem = int.tryParse(partesMes[0]) ?? 0;
      final anioItem = int.tryParse(partesMes[1]) ?? 0;
      
      if (mesItem <= 0 || anioItem <= 0) continue;
      
      final fechaItem = DateTime(anioItem, mesItem, 1);
      
      // Si esta fecha es anterior a la fecha actual pero más reciente que la encontrada hasta ahora
      if (fechaItem.isBefore(fechaActual) && fechaItem.isAfter(fechaReciente)) {
        fechaReciente = fechaItem;
        mesReciente = key;
        log.d('Encontrada fecha más reciente: $mesReciente (${preciosAlquilerPorMes[mesReciente]})');
      }
    }
    
    // Si encontramos un mes anterior, devolver su precio
    if (mesReciente != null) {
      log.d('Usando precio histórico para $mesAnio desde $mesReciente: ${preciosAlquilerPorMes[mesReciente]}');
      return preciosAlquilerPorMes[mesReciente]!;
    }
    
    // Si no hay precio para este mes ni para meses anteriores, devolver el precio base
    log.d('No se encontró precio histórico para $mesAnio, usando precio base: $_precioAlquilerBase');
    return _precioAlquilerBase;
  }

  // Aplicar un aumento de alquiler preservando el historial
  static Inquilino aplicarAumento(Inquilino inquilino, String mesActual, double nuevoPrecio) {
    log.i('Aplicando aumento: ${inquilino._precioAlquilerBase} -> $nuevoPrecio a partir de $mesActual');
    
    // Crear un nuevo mapa para los precios históricos
    final nuevosPreciosHistoricos = Map<String, double>.from(inquilino.preciosAlquilerPorMes);
    
    // Guardar el precio actual como histórico para TODOS los meses anteriores a mesActual
    // que no tengan un precio específico ya establecido
    final partes = mesActual.split('-');
    if (partes.length == 2) {
      final mesActualNum = int.tryParse(partes[0]) ?? 0;
      final anioActualNum = int.tryParse(partes[1]) ?? 0;
      
      if (mesActualNum > 0 && anioActualNum > 0) {
        // Para todos los meses anteriores al mes actual, guardar el precio actual
        for (int anio = 2020; anio <= anioActualNum; anio++) {
          for (int mes = 1; mes <= 12; mes++) {
            // Si es un mes anterior al mes actual del año actual, o un año anterior
            if ((anio < anioActualNum) || (anio == anioActualNum && mes < mesActualNum)) {
              final mesAnioStr = '${mes.toString().padLeft(2, '0')}-$anio';
              
              // Solo guardar si no hay un precio específico ya establecido
              if (!nuevosPreciosHistoricos.containsKey(mesAnioStr)) {
                nuevosPreciosHistoricos[mesAnioStr] = inquilino._precioAlquilerBase;
                log.d('Guardando precio histórico para $mesAnioStr: ${inquilino._precioAlquilerBase}');
              }
            }
          }
        }
      }
    }
    
    // Guardar el nuevo precio para el mes actual y futuros
    nuevosPreciosHistoricos[mesActual] = nuevoPrecio;
    log.d('Guardando nuevo precio para $mesActual: $nuevoPrecio');
    
    // Crear una nueva instancia actualizando tanto el precio base como el historial
    // Es necesario actualizar el precio base para que se muestre correctamente en todas las partes de la app
    return inquilino.copyWith(
      precioAlquiler: nuevoPrecio,  // Actualizamos el precio base para reflejarlo en toda la app
      preciosAlquilerPorMes: nuevosPreciosHistoricos,
    );
  }

  // Verifica si ha pagado tanto alquiler como expensas
  bool haPagado(String mesAnio) {
    return pagos[mesAnio] ?? false;
  }

  // Verifica si ha pagado el alquiler
  bool haPagadoAlquiler(String mesAnio) {
    log.d('Verificando pago de alquiler para $mesAnio: ${pagosAlquiler[mesAnio] ?? false}');
    return pagosAlquiler[mesAnio] ?? false;
  }

  // Verifica si ha pagado las expensas
  bool haPagadoExpensas(String mesAnio) {
    log.d('Verificando pago de expensas para $mesAnio: ${pagosExpensas[mesAnio] ?? false}');
    return pagosExpensas[mesAnio] ?? false;
  }

  // Obtener el monto pendiente para un mes específico
  double getMontoPendiente(String mesAnio) {
    log.d('Obteniendo monto pendiente para $mesAnio: ${montosPendientes[mesAnio] ?? 0.0}');
    return montosPendientes[mesAnio] ?? 0.0;
  }
  
  // Obtener el método de pago para un mes específico
  MetodoPago getMetodoPago(String mesAnio) {
    return metodosPago[mesAnio] ?? MetodoPago.efectivo;
  }
  
  // Establecer el método de pago para un mes específico
  void setMetodoPago(String mesAnio, MetodoPago metodoPago) {
    metodosPago[mesAnio] = metodoPago;
    log.d('Establecido método de pago para $mesAnio: ${metodoPago.toString()}');
  }
  
  // Obtener la cuenta de transferencia para un mes específico
  String getCuentaTransferencia(String mesAnio) {
    return cuentasTransferencia[mesAnio] ?? '';
  }
  
  // Establecer la cuenta de transferencia para un mes específico
  void setCuentaTransferencia(String mesAnio, String cuenta) {
    cuentasTransferencia[mesAnio] = cuenta;
    log.d('Establecida cuenta de transferencia para $mesAnio: $cuenta');
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
    log.d('Obteniendo expensas para $mesAnio: $expensasMes');
    return expensasMes;
  }

  // Establecer expensas para un mes específico
  void setExpensas(String mesAnio, double monto) {
    if (monto <= 0) {
      expensas.remove(mesAnio); // Eliminar del mapa si es cero
    } else {
      expensas[mesAnio] = monto;
    }
    log.d('Establecidas expensas para $mesAnio: $monto');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'departamento': departamento,
      'precioAlquiler': _precioAlquilerBase,
      'pagos': jsonEncode(pagos),
      'expensas': jsonEncode(expensas),
      'pagosAlquiler': jsonEncode(pagosAlquiler),
      'pagosExpensas': jsonEncode(pagosExpensas),
      'montosPendientes': jsonEncode(montosPendientes),
      'metodosPago': jsonEncode(metodosPago.map((k, v) => MapEntry(k, v.index))),
      'cuentasTransferencia': jsonEncode(cuentasTransferencia),
      'preciosAlquilerPorMes': jsonEncode(preciosAlquilerPorMes),
    };
  }

  factory Inquilino.fromMap(Map<String, dynamic> map) {
    try {
      // Función auxiliar para convertir JSON a Map<String, bool>
      Map<String, bool> parseBoolMap(String jsonStr) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        return jsonMap.map((key, value) => MapEntry(key, value as bool));
      }

      // Función auxiliar para convertir JSON a Map<String, double>
      Map<String, double> parseDoubleMap(String jsonStr) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        return jsonMap.map((key, value) {
          if (value is int) {
            return MapEntry(key, value.toDouble());
          }
          return MapEntry(key, value as double);
        });
      }

      // Función auxiliar para convertir JSON a Map<String, MetodoPago>
      Map<String, MetodoPago> parseMetodoPagoMap(String jsonStr) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        return jsonMap.map((key, value) => MapEntry(key, MetodoPago.values[value as int]));
      }

      // Función auxiliar para convertir JSON a Map<String, String>
      Map<String, String> parseStringMap(String jsonStr) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        return jsonMap.map((key, value) => MapEntry(key, value as String));
      }

      return Inquilino(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        apellido: map['apellido'] as String,
        departamento: map['departamento'] as String,
        precioAlquiler: (map['precioAlquiler'] is int)
            ? (map['precioAlquiler'] as int).toDouble()
            : map['precioAlquiler'] as double,
        pagos: map.containsKey('pagos') && map['pagos'] != null
            ? parseBoolMap(map['pagos'] as String)
            : {},
        expensas: map.containsKey('expensas') && map['expensas'] != null
            ? parseDoubleMap(map['expensas'] as String)
            : {},
        pagosAlquiler: map.containsKey('pagosAlquiler') && map['pagosAlquiler'] != null
            ? parseBoolMap(map['pagosAlquiler'] as String)
            : {},
        pagosExpensas: map.containsKey('pagosExpensas') && map['pagosExpensas'] != null
            ? parseBoolMap(map['pagosExpensas'] as String)
            : {},
        montosPendientes: map.containsKey('montosPendientes') && map['montosPendientes'] != null
            ? parseDoubleMap(map['montosPendientes'] as String)
            : {},
        metodosPago: map.containsKey('metodosPago') && map['metodosPago'] != null
            ? parseMetodoPagoMap(map['metodosPago'] as String)
            : {},
        cuentasTransferencia: map.containsKey('cuentasTransferencia') && map['cuentasTransferencia'] != null
            ? parseStringMap(map['cuentasTransferencia'] as String)
            : {},
        preciosAlquilerPorMes: map.containsKey('preciosAlquilerPorMes') && map['preciosAlquilerPorMes'] != null
            ? parseDoubleMap(map['preciosAlquilerPorMes'] as String)
            : {},
      );
    } catch (e, stackTrace) {
      log.e("Error al crear Inquilino desde Map", e, stackTrace);
      rethrow;
    }
  }

  String toJson() => json.encode(toMap());

  factory Inquilino.fromJson(String source) =>
      Inquilino.fromMap(json.decode(source));
} 
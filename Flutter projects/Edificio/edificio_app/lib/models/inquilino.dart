import 'dart:convert';
import '../services/log_service.dart';
import 'package:intl/intl.dart';
import 'periodo_precio.dart';

// Enum para el método de pago
enum MetodoPago { efectivo, transferencia }

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
  final double _precioAlquilerBase; // Precio base/predeterminado
  final Map<String, bool> pagos;
  final Map<String, double> expensas;
  final Map<String, bool> pagosAlquiler;
  final Map<String, bool> pagosExpensas;
  final Map<String, double> montosPendientes;
  final Map<String, MetodoPago> metodosPago;
  final Map<String, String> cuentasTransferencia;

  // Nuevo campo para períodos de precios
  final List<PeriodoPrecio> periodosPrecio;

  // Mantenemos el mapa antiguo para compatibilidad durante la migración
  final Map<String, double> preciosAlquilerPorMes;

  // Getter para obtener el precio actual del alquiler
  double get precioAlquiler {
    // Obtener el mes actual
    final mesActual = DateFormat('MM-yyyy').format(DateTime.now());
    // Devolver el precio específico para este mes
    return getPrecioAlquilerPorMes(mesActual);
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
    List<PeriodoPrecio>? periodosPrecio,
  })  : _precioAlquilerBase = precioAlquiler,
        periodosPrecio = periodosPrecio ??
            [
              PeriodoPrecio(
                fechaInicio: DateTime(2020, 1, 1),
                precio: precioAlquiler,
              )
            ];

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
    List<PeriodoPrecio>? periodosPrecio,
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
      cuentasTransferencia:
          cuentasTransferencia ?? Map.from(this.cuentasTransferencia),
      preciosAlquilerPorMes:
          preciosAlquilerPorMes ?? Map.from(this.preciosAlquilerPorMes),
      periodosPrecio: periodosPrecio ?? List.from(this.periodosPrecio),
    );
  }

  // Obtener el precio de alquiler para un mes específico usando períodos
  double getPrecioAlquilerPorMes(String mesAnio) {
    log.d('Obteniendo precio para $mesAnio');

    // Si no hay períodos definidos o la lista está vacía, usar el precio base
    if (periodosPrecio.isEmpty) {
      // Verificar el mapa antiguo durante la migración
      if (preciosAlquilerPorMes.containsKey(mesAnio)) {
        return preciosAlquilerPorMes[mesAnio]!;
      }
      return _precioAlquilerBase;
    }

    // Obtener mes y año del parámetro
    final partes = mesAnio.split('-');
    if (partes.length != 2) {
      log.d('Formato de fecha inválido: $mesAnio, usando precio base');
      return _precioAlquilerBase;
    }

    final mesNum = int.tryParse(partes[0]) ?? 0;
    final anioNum = int.tryParse(partes[1]) ?? 0;

    if (mesNum <= 0 || anioNum <= 0) {
      log.d('Números de mes/año inválidos: $mesAnio, usando precio base');
      return _precioAlquilerBase;
    }

    final fechaConsulta = DateTime(anioNum, mesNum, 1);

    // Buscar el período aplicable (el más reciente que sea anterior o igual a la fecha consultada)
    PeriodoPrecio? periodoAplicable;

    for (final periodo in periodosPrecio) {
      if (periodo.fechaInicio.isBefore(fechaConsulta) ||
          (periodo.fechaInicio.month == fechaConsulta.month &&
              periodo.fechaInicio.year == fechaConsulta.year)) {
        if (periodoAplicable == null ||
            periodo.fechaInicio.isAfter(periodoAplicable.fechaInicio)) {
          periodoAplicable = periodo;
        }
      }
    }

    if (periodoAplicable != null) {
      log.d(
          'Usando precio de período: ${periodoAplicable.fechaInicio.month}/${periodoAplicable.fechaInicio.year}: \$${periodoAplicable.precio}');
      return periodoAplicable.precio;
    }

    // Si no encontramos un período aplicable, verificar el mapa antiguo durante la migración
    if (preciosAlquilerPorMes.containsKey(mesAnio)) {
      return preciosAlquilerPorMes[mesAnio]!;
    }

    // Si no hay precio para este mes ni para meses anteriores, devolver el precio base
    log.d(
        'No se encontró precio aplicable para $mesAnio, usando precio base: $_precioAlquilerBase');
    return _precioAlquilerBase;
  }

  // Migrar datos del formato antiguo al nuevo sistema de períodos
  Inquilino migrarPreciosAPeriodos() {
    if (periodosPrecio.isNotEmpty || preciosAlquilerPorMes.isEmpty) {
      // Ya está migrado o no hay datos que migrar
      return this;
    }

    final nuevosPeriodos = <PeriodoPrecio>[];
    final fechas = preciosAlquilerPorMes.keys.toList();

    // Ordenar las fechas cronológicamente
    fechas.sort((a, b) {
      final partesA = a.split('-');
      final partesB = b.split('-');
      final fechaA = DateTime(int.parse(partesA[1]), int.parse(partesA[0]));
      final fechaB = DateTime(int.parse(partesB[1]), int.parse(partesB[0]));
      return fechaA.compareTo(fechaB);
    });

    // Convertir cada entrada a un período
    for (final fechaStr in fechas) {
      final partes = fechaStr.split('-');
      final mes = int.parse(partes[0]);
      final anio = int.parse(partes[1]);

      nuevosPeriodos.add(PeriodoPrecio(
        fechaInicio: DateTime(anio, mes, 1),
        precio: preciosAlquilerPorMes[fechaStr]!,
      ));
    }

    // Asegurar que haya al menos un período inicial con el precio base
    if (nuevosPeriodos.isEmpty ||
        nuevosPeriodos[0].fechaInicio.isAfter(DateTime(2020, 1, 1))) {
      nuevosPeriodos.insert(
          0,
          PeriodoPrecio(
            fechaInicio: DateTime(2020, 1, 1),
            precio: _precioAlquilerBase,
          ));
    }

    log.i(
        'Migrados ${nuevosPeriodos.length} períodos de precio para $nombre $apellido');

    // Crear una copia con los nuevos períodos
    return copyWith(
      periodosPrecio: nuevosPeriodos,
    );
  }

  // Aplicar un aumento de alquiler usando el sistema de períodos
  static Inquilino aplicarAumento(
      Inquilino inquilino, String mesActual, double nuevoPrecio) {
    log.i(
        'Aplicando aumento: ${inquilino._precioAlquilerBase} -> $nuevoPrecio a partir de $mesActual');

    // Asegurar que el inquilino tenga sus datos migrados al sistema de períodos
    Inquilino inquilinoMigrado = inquilino.migrarPreciosAPeriodos();

    // Crear una copia de los períodos existentes
    final nuevosPeriodos =
        List<PeriodoPrecio>.from(inquilinoMigrado.periodosPrecio);

    // Obtener mes y año del parámetro
    final partes = mesActual.split('-');
    if (partes.length != 2) {
      log.e('Formato de fecha inválido: $mesActual');
      return inquilino;
    }

    final mesActualNum = int.tryParse(partes[0]) ?? 0;
    final anioActualNum = int.tryParse(partes[1]) ?? 0;

    if (mesActualNum <= 0 || anioActualNum <= 0) {
      log.e('Números de mes/año inválidos: $mesActual');
      return inquilino;
    }

    final fechaAumento = DateTime(anioActualNum, mesActualNum, 1);

    // Añadir el nuevo período con el precio aumentado
    nuevosPeriodos.add(PeriodoPrecio(
      fechaInicio: fechaAumento,
      precio: nuevoPrecio,
    ));

    log.d(
        'Agregado nuevo período: ${DateFormat('MM-yyyy').format(fechaAumento)} con precio \$$nuevoPrecio');

    // Crear una nueva instancia con los períodos actualizados
    return inquilinoMigrado.copyWith(
      precioAlquiler:
          nuevoPrecio, // Actualizamos también el precio base para compatibilidad
      periodosPrecio: nuevosPeriodos,
    );
  }

  // Verifica si ha pagado tanto alquiler como expensas
  bool haPagado(String mesAnio) {
    return pagos[mesAnio] ?? false;
  }

  // Verifica si ha pagado el alquiler
  bool haPagadoAlquiler(String mesAnio) {
    log.d(
        'Verificando pago de alquiler para $mesAnio: ${pagosAlquiler[mesAnio] ?? false}');
    return pagosAlquiler[mesAnio] ?? false;
  }

  // Verifica si ha pagado las expensas
  bool haPagadoExpensas(String mesAnio) {
    log.d(
        'Verificando pago de expensas para $mesAnio: ${pagosExpensas[mesAnio] ?? false}');
    return pagosExpensas[mesAnio] ?? false;
  }

  // Obtener el monto pendiente para un mes específico
  double getMontoPendiente(String mesAnio) {
    log.d(
        'Obteniendo monto pendiente para $mesAnio: ${montosPendientes[mesAnio] ?? 0.0}');
    return montosPendientes[mesAnio] ?? 0.0;
  }

  // Obtener el método de pago para un mes específico
  MetodoPago getMetodoPago(String mesAnio) {
    return metodosPago[mesAnio] ?? MetodoPago.efectivo;
  }

  // Establecer el método de pago para un mes específico
  void setMetodoPago(String mesAnio, MetodoPago metodoPago) {
    metodosPago[mesAnio] = metodoPago;
    log.d('Establecido método de pago para $mesAnio: $metodoPago');
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
    pagos[mesAnio] =
        pagosAlquiler[mesAnio] == true && pagosExpensas[mesAnio] == true;
  }

  // Marcar pago de expensas
  void marcarPagoExpensas(String mesAnio, bool pagado) {
    pagosExpensas[mesAnio] = pagado;

    // Actualizar estado general
    pagos[mesAnio] =
        pagosAlquiler[mesAnio] == true && pagosExpensas[mesAnio] == true;
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
    final periodosJson = periodosPrecio.map((p) => p.toMap()).toList();

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
      'metodosPago':
          jsonEncode(metodosPago.map((k, v) => MapEntry(k, v.index))),
      'cuentasTransferencia': jsonEncode(cuentasTransferencia),
      'preciosAlquilerPorMes': jsonEncode(preciosAlquilerPorMes),
      'periodosPrecio': jsonEncode(periodosJson),
    };
  }

  factory Inquilino.fromMap(Map<String, dynamic> map) {
    try {
      // Función auxiliar para convertir JSON a Map<String, bool>
      Map<String, bool> parseBoolMap(String jsonStr) {
        final Map<String, dynamic> jsonMap =
            jsonDecode(jsonStr) as Map<String, dynamic>;
        return jsonMap.map((key, value) => MapEntry(key, value as bool));
      }

      // Función auxiliar para convertir JSON a Map<String, double>
      Map<String, double> parseDoubleMap(String jsonStr) {
        final Map<String, dynamic> jsonMap =
            jsonDecode(jsonStr) as Map<String, dynamic>;
        return jsonMap.map((key, value) {
          if (value is int) {
            return MapEntry(key, value.toDouble());
          }
          return MapEntry(key, value as double);
        });
      }

      // Función auxiliar para convertir JSON a Map<String, MetodoPago>
      Map<String, MetodoPago> parseMetodoPagoMap(String jsonStr) {
        final Map<String, dynamic> jsonMap =
            jsonDecode(jsonStr) as Map<String, dynamic>;
        return jsonMap.map(
            (key, value) => MapEntry(key, MetodoPago.values[value as int]));
      }

      // Función auxiliar para convertir JSON a Map<String, String>
      Map<String, String> parseStringMap(String jsonStr) {
        final Map<String, dynamic> jsonMap =
            jsonDecode(jsonStr) as Map<String, dynamic>;
        return jsonMap.map((key, value) => MapEntry(key, value as String));
      }

      // Función para parsear períodos de precio
      List<PeriodoPrecio> parsePeriodosPrecio(String? jsonStr) {
        if (jsonStr == null || jsonStr.isEmpty) return [];
        final List<dynamic> jsonList = jsonDecode(jsonStr) as List<dynamic>;
        return jsonList
            .map((json) => PeriodoPrecio.fromMap(json as Map<String, dynamic>))
            .toList();
      }

      // Precio base de alquiler
      final precioBase = (map['precioAlquiler'] is int)
          ? (map['precioAlquiler'] as int).toDouble()
          : map['precioAlquiler'] as double;

      // Intentar cargar los períodos de precio
      List<PeriodoPrecio> periodos = [];
      if (map.containsKey('periodosPrecio') && map['periodosPrecio'] != null) {
        periodos = parsePeriodosPrecio(map['periodosPrecio'] as String);
      }

      // Si no hay períodos, crear uno con el precio base
      if (periodos.isEmpty) {
        periodos = [
          PeriodoPrecio(
            fechaInicio: DateTime(2020, 1, 1),
            precio: precioBase,
          )
        ];
      }

      return Inquilino(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        apellido: map['apellido'] as String,
        departamento: map['departamento'] as String,
        precioAlquiler: precioBase,
        pagos: map.containsKey('pagos') && map['pagos'] != null
            ? parseBoolMap(map['pagos'] as String)
            : {},
        expensas: map.containsKey('expensas') && map['expensas'] != null
            ? parseDoubleMap(map['expensas'] as String)
            : {},
        pagosAlquiler:
            map.containsKey('pagosAlquiler') && map['pagosAlquiler'] != null
                ? parseBoolMap(map['pagosAlquiler'] as String)
                : {},
        pagosExpensas:
            map.containsKey('pagosExpensas') && map['pagosExpensas'] != null
                ? parseBoolMap(map['pagosExpensas'] as String)
                : {},
        montosPendientes: map.containsKey('montosPendientes') &&
                map['montosPendientes'] != null
            ? parseDoubleMap(map['montosPendientes'] as String)
            : {},
        metodosPago:
            map.containsKey('metodosPago') && map['metodosPago'] != null
                ? parseMetodoPagoMap(map['metodosPago'] as String)
                : {},
        cuentasTransferencia: map.containsKey('cuentasTransferencia') &&
                map['cuentasTransferencia'] != null
            ? parseStringMap(map['cuentasTransferencia'] as String)
            : {},
        preciosAlquilerPorMes: map.containsKey('preciosAlquilerPorMes') &&
                map['preciosAlquilerPorMes'] != null
            ? parseDoubleMap(map['preciosAlquilerPorMes'] as String)
            : {},
        periodosPrecio: periodos,
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

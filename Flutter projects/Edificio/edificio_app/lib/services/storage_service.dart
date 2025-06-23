import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inquilino.dart';
import '../models/tarea.dart';
import '../models/documento.dart';
import 'package:uuid/uuid.dart';
import '../models/cuenta_transferencia.dart';

class StorageService {
  static const String _inquilinosKey = 'inquilinos';
  static const String _expensasKey = 'expensas';
  static const String _tareasKey = 'tareas';
  static const String _inquilinosInicializadosKey = 'inquilinos_inicializados';
  static const String _cuentasTransferenciaKey = 'cuentas_transferencia';
  static const String _expensasComunesKey = 'expensas_comunes';
  static const String _documentosKey = 'documentos';

  // Método para guardar inquilinos (optimizado)
  Future<void> saveInquilinos(List<Inquilino> inquilinos) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convertir lista de inquilinos a JSON de manera eficiente
    final jsonInquilinos = inquilinos.map((i) {
      try {
        return jsonEncode(i.toMap());
      } catch (e) {
        print('Error al codificar inquilino: $e');
        return null;
      }
    }).where((json) => json != null).toList().cast<String>();
    
    // Guardar en SharedPreferences
    await prefs.setStringList(_inquilinosKey, jsonInquilinos);
  }

  // Método para cargar inquilinos (optimizado)
  Future<List<Inquilino>> loadInquilinos() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Verificar si hay inquilinos guardados
    final jsonInquilinos = prefs.getStringList(_inquilinosKey);
    
    // Verificar si los inquilinos ya se inicializaron
    final inquilinosInicializados = prefs.getBool(_inquilinosInicializadosKey) ?? false;
    
    if (jsonInquilinos == null || jsonInquilinos.isEmpty) {
      print('No se encontraron inquilinos guardados');
      
      // Si no hay inquilinos o la lista está vacía, crear inquilinos predefinidos
      if (!inquilinosInicializados) {
        print('Inicializando inquilinos predefinidos...');
        final predefinidos = _crearInquilinosPredefinidos();
        await saveInquilinos(predefinidos);
        
        // Marcar como inicializados
        await prefs.setBool(_inquilinosInicializadosKey, true);
        print('Inquilinos predefinidos inicializados: ${predefinidos.length}');
        
        return predefinidos;
      }
      
      return [];
    }
    
    // Convertir JSON a objetos Inquilino
    final inquilinos = <Inquilino>[];
    
    for (final jsonStr in jsonInquilinos) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final inquilino = Inquilino.fromMap(map);
        // Solo agregar inquilinos válidos
        if (inquilino.id.isNotEmpty) {
          inquilinos.add(inquilino);
        }
      } catch (e) {
        print('Error al decodificar inquilino: $e');
      }
    }
    
    return inquilinos;
  }

  // Inicializar inquilinos predefinidos
  Future<void> _inicializarInquilinosPredefinidos() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Crear inquilinos predefinidos
    final predefinidos = _crearInquilinosPredefinidos();
    
    // Convertir a JSON y guardar
    final inquilinosJson = predefinidos.map((i) => jsonEncode(i.toMap())).toList();
    await prefs.setStringList(_inquilinosKey, inquilinosJson);
    
    // Marcar como inicializados
    await prefs.setBool(_inquilinosInicializadosKey, true);
    
    print("Se han inicializado ${predefinidos.length} inquilinos predefinidos");
  }

  // Guardar expensas comunes para un mes específico
  Future<void> saveExpensas(String mesAnio, double monto) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Usar un enfoque completamente diferente, almacenando cada mes como una clave separada
      final clave = 'expensa_$mesAnio';
      
      // Guardar directamente como double
      await prefs.setDouble(clave, monto);
      
      print('Expensas guardadas exitosamente: $clave = $monto');
    } catch (e) {
      print('Error guardando expensas: $e');
      rethrow;
    }
  }

  // Método para cargar expensas de un mes específico
  Future<double> loadExpensas(String mesAnio) async {
    final prefs = await SharedPreferences.getInstance();
    final expensasMap = await loadExpensasComunes();
    return expensasMap[mesAnio] ?? 0.0;
  }
  
  // Método para cargar todas las expensas comunes
  Future<Map<String, double>> loadExpensasComunes() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Obtener JSON de expensas comunes
    final expensasJson = prefs.getString(_expensasComunesKey);
    if (expensasJson == null) {
      return {};
    }
    
    try {
      // Decodificar JSON
      final expensasMap = jsonDecode(expensasJson) as Map<String, dynamic>;
      
      // Convertir valores a double
      return expensasMap.map((key, value) {
        if (value is int) {
          return MapEntry(key, value.toDouble());
        } else if (value is double) {
          return MapEntry(key, value);
        } else {
          return MapEntry(key, (value as num).toDouble());
        }
      });
    } catch (e) {
      print('Error al cargar expensas comunes: $e');
      return {};
    }
  }
  
  // Guardar tareas
  Future<void> saveTareas(List<Tarea> tareas) async {
    final prefs = await SharedPreferences.getInstance();
    final tareasJson = tareas.map((t) => jsonEncode(t.toMap())).toList();
    await prefs.setStringList(_tareasKey, tareasJson);
  }
  
  // Cargar tareas
  Future<List<Tarea>> loadTareas() async {
    final prefs = await SharedPreferences.getInstance();
    final tareasJson = prefs.getStringList(_tareasKey) ?? [];
    return tareasJson
        .map((json) => Tarea.fromMap(jsonDecode(json)))
        .toList();
  }
  
  // Guardar una tarea específica
  Future<void> saveTarea(Tarea tarea, List<Tarea> tareas) async {
    // Buscar si la tarea ya existe
    final index = tareas.indexWhere((t) => t.id == tarea.id);
    
    if (index >= 0) {
      // Actualizar tarea existente
      tareas[index] = tarea;
    } else {
      // Agregar nueva tarea
      tareas.add(tarea);
    }
    
    // Guardar la lista completa
    await saveTareas(tareas);
  }
  
  // Eliminar una tarea
  Future<void> deleteTarea(String tareaId, List<Tarea> tareas) async {
    tareas.removeWhere((t) => t.id == tareaId);
    await saveTareas(tareas);
  }

  // Guardar cuentas de transferencia (optimizado)
  Future<void> saveCuentasTransferencia(List<CuentaTransferencia> cuentas) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convertir lista de cuentas a JSON de manera eficiente
    final jsonCuentas = cuentas.map((c) {
      try {
        return jsonEncode(c.toMap());
      } catch (e) {
        print('Error al codificar cuenta: $e');
        return null;
      }
    }).where((json) => json != null).toList().cast<String>();
    
    // Guardar en SharedPreferences
    await prefs.setStringList(_cuentasTransferenciaKey, jsonCuentas);
  }
  
  // Cargar cuentas de transferencia (optimizado)
  Future<List<CuentaTransferencia>> loadCuentasTransferencia() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Verificar si hay cuentas guardadas
    final jsonCuentas = prefs.getStringList(_cuentasTransferenciaKey);
    
    if (jsonCuentas == null || jsonCuentas.isEmpty) {
      return [];
    }
    
    // Convertir JSON a objetos CuentaTransferencia
    final cuentas = <CuentaTransferencia>[];
    
    for (final jsonStr in jsonCuentas) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final cuenta = CuentaTransferencia.fromMap(map);
        // Solo agregar cuentas válidas
        if (cuenta.id.isNotEmpty) {
          cuentas.add(cuenta);
        }
      } catch (e) {
        print('Error al decodificar cuenta: $e');
      }
    }
    
    return cuentas;
  }

  // Método para crear inquilinos predefinidos
  List<Inquilino> _crearInquilinosPredefinidos() {
    print("Creando inquilinos predefinidos...");
    
    // Generar IDs únicos
    return [
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Luciano',
        apellido: 'Campos',
        departamento: '1°A',
        precioAlquiler: 137000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Martina',
        apellido: 'Soto',
        departamento: '1°B',
        precioAlquiler: 156000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Emiliano',
        apellido: 'Alejandro',
        departamento: '1°C',
        precioAlquiler: 156000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Pablo',
        apellido: 'Flores',
        departamento: '1°D',
        precioAlquiler: 110000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Claudio',
        apellido: 'Segovia',
        departamento: '2°A',
        precioAlquiler: 137000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Jesús',
        apellido: 'Ampuero',
        departamento: '2°B',
        precioAlquiler: 156000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'David',
        apellido: 'Alba',
        departamento: '2°C',
        precioAlquiler: 156000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Bruno',
        apellido: 'Del Sancio',
        departamento: '2°D',
        precioAlquiler: 137000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Esteban',
        apellido: 'Luna',
        departamento: '2°E',
        precioAlquiler: 106000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Maria',
        apellido: 'Luz Alejandro',
        departamento: '2°F',
        precioAlquiler: 106000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Nicolas',
        apellido: 'Corvalan',
        departamento: '2°G',
        precioAlquiler: 125000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Marta',
        apellido: 'Vilte',
        departamento: '2°H',
        precioAlquiler: 200000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Daniel',
        apellido: 'Horacio Melucci',
        departamento: '3°A',
        precioAlquiler: 137000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Daniel',
        apellido: 'Chinchilla',
        departamento: '3°B',
        precioAlquiler: 156000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Lautaro',
        apellido: 'Romano',
        departamento: '3°C',
        precioAlquiler: 156000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Maria',
        apellido: 'Guadalupe Baldiviezo',
        departamento: '3°D',
        precioAlquiler: 137000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Angela',
        apellido: 'Ornella Defilippi',
        departamento: '3°E',
        precioAlquiler: 125000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Isaias',
        apellido: 'Manuel',
        departamento: '3°F',
        precioAlquiler: 106000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Martin',
        apellido: 'Castro',
        departamento: '3°G',
        precioAlquiler: 125000,
      ),
      Inquilino(
        id: const Uuid().v4(),
        nombre: 'Sebastian',
        apellido: 'Medina Nicolasi',
        departamento: '3°H',
        precioAlquiler: 200000,
      ),
    ];
  }

  // Guardar documentos
  Future<void> saveDocumentos(List<Documento> documentos) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convertir lista de documentos a JSON
    final jsonDocumentos = documentos.map((d) {
      try {
        return jsonEncode(d.toMap());
      } catch (e) {
        print('Error al codificar documento: $e');
        return null;
      }
    }).where((json) => json != null).toList().cast<String>();
    
    // Guardar en SharedPreferences
    await prefs.setStringList(_documentosKey, jsonDocumentos);
  }
  
  // Cargar documentos
  Future<List<Documento>> loadDocumentos() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Verificar si hay documentos guardados
    final jsonDocumentos = prefs.getStringList(_documentosKey);
    
    if (jsonDocumentos == null || jsonDocumentos.isEmpty) {
      return [];
    }
    
    // Convertir JSON a objetos Documento
    final documentos = <Documento>[];
    
    for (final jsonStr in jsonDocumentos) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final documento = Documento.fromMap(map);
        // Solo agregar documentos válidos
        if (documento.id.isNotEmpty && documento.inquilinoId.isNotEmpty) {
          documentos.add(documento);
        }
      } catch (e) {
        print('Error al decodificar documento: $e');
      }
    }
    
    return documentos;
  }
  
  // Guardar un documento específico
  Future<void> saveDocumento(Documento documento) async {
    // Cargar documentos existentes
    final documentos = await loadDocumentos();
    
    // Buscar si el documento ya existe
    final index = documentos.indexWhere((d) => d.id == documento.id);
    
    if (index >= 0) {
      // Actualizar documento existente
      documentos[index] = documento;
    } else {
      // Agregar nuevo documento
      documentos.add(documento);
    }
    
    // Guardar la lista completa
    await saveDocumentos(documentos);
  }
  
  // Eliminar un documento
  Future<void> deleteDocumento(String documentoId) async {
    final documentos = await loadDocumentos();
    documentos.removeWhere((d) => d.id == documentoId);
    await saveDocumentos(documentos);
  }
  
  // Obtener documentos por inquilino
  Future<List<Documento>> getDocumentosPorInquilino(String inquilinoId) async {
    final documentos = await loadDocumentos();
    return documentos.where((d) => d.inquilinoId == inquilinoId).toList();
  }
} 
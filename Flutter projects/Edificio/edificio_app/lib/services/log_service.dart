import 'package:logger/logger.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  
  factory LogService() => _instance;
  
  LogService._internal();
  
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,       // Número de métodos en el stack trace (0 para simplificar)
      errorMethodCount: 5,  // Número de métodos en caso de error
      lineLength: 80,       // Longitud máxima de línea
      colors: true,         // Colorear la salida
      printEmojis: true,    // Mostrar emojis
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,  // Formato de tiempo
    ),
    // Nivel de log en desarrollo, puedes cambiarlo a Level.nothing en producción
    level: Level.debug,
  );

  // Métodos para los diferentes niveles de log
  void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

// Instancia global para facilitar el uso en toda la app
final log = LogService(); 
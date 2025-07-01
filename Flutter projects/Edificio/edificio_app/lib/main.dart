import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'package:edificio_app/services/storage_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  
  try {
    // Inicializar el servicio de almacenamiento
    final storageService = StorageService();
    final prefs = await SharedPreferences.getInstance();
    
    // Verificar si es la primera ejecución
    bool primeraEjecucion = !(prefs.getBool('app_inicializada') ?? false);
    
    if (primeraEjecucion) {
      // Solo en la primera ejecución, inicializar datos
      log.i("Primera ejecución de la aplicación, inicializando datos...");
      
      // Eliminar la marca de inicialización para forzar la carga de inquilinos predefinidos
      await prefs.remove('inquilinos_inicializados');
      // Eliminar lista actual de inquilinos si existe
      await prefs.remove('inquilinos');
      
      // Marcar que la app ya se ha inicializado
      await prefs.setBool('app_inicializada', true);
      
      log.i("Configuración inicial completada");
    } else {
      log.i("Iniciando aplicación con datos existentes");
    }
    
    // Cargar inquilinos (esto ejecutará la inicialización si es necesario)
    final inquilinos = await storageService.loadInquilinos();
    log.i("Inicialización completa: ${inquilinos.length} inquilinos cargados");
    
    // Verificar que todos los inquilinos se hayan cargado correctamente
    if (inquilinos.isEmpty && primeraEjecucion) {
      log.w("ADVERTENCIA: No se cargaron inquilinos predefinidos");
    } else {
      for (int i = 0; i < inquilinos.length; i++) {
        final inquilino = inquilinos[i];
        if (inquilino.id.isEmpty || 
            inquilino.nombre.isEmpty ||
            inquilino.apellido.isEmpty ||
            inquilino.departamento.isEmpty) {
          log.e("ERROR: Inquilino ${i+1} tiene campos vacíos", null, StackTrace.current);
        }
      }
    }
  } catch (e, stackTrace) {
    log.e("ERROR durante la inicialización", e, stackTrace);
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Edificio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: MediaQuery.of(context).padding.copyWith(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
          ),
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
} 
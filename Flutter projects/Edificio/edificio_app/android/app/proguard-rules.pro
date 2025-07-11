# Reglas para shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Reglas generales para Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Ignora advertencias sobre archivos con rutas diferentes
-dontwarn java.lang.IllegalArgumentException 
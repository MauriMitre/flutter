import 'package:flutter/material.dart';
import 'package:flutter_application_1/presentation/screens/counter_screen.dart';
import 'package:flutter_application_1/presentation/screens/counter_functions_screen.dart';

void main() {
  runApp(MyApp());
  // This is a simple Dart program that prints "Hello, World!" to the console.
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme:ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent
      ),
      home: const CounterFunctionsScreen(),
    );
  }
}

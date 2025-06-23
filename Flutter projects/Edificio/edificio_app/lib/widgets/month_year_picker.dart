import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthYearPicker extends StatefulWidget {
  final DateTime initialDate;

  const MonthYearPicker({
    Key? key,
    required this.initialDate,
  }) : super(key: key);

  @override
  _MonthYearPickerState createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<MonthYearPicker> {
  late int _selectedYear;
  late int _selectedMonth;
  
  final List<String> _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];
  
  // Generar años desde 2025 hasta 2030
  final List<int> _years = List.generate(
    6, 
    (index) => 2025 + index
  );

  @override
  void initState() {
    super.initState();
    // Asegurarse de que el año seleccionado sea al menos 2025
    _selectedYear = widget.initialDate.year < 2025 ? 2025 : widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Mes y Año'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selector de año
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Año',
              border: OutlineInputBorder(),
            ),
            value: _selectedYear,
            items: _years.map((year) {
              return DropdownMenuItem<int>(
                value: year,
                child: Text(year.toString()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedYear = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          // Selector de mes
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Mes',
              border: OutlineInputBorder(),
            ),
            value: _selectedMonth,
            items: List.generate(12, (index) {
              return DropdownMenuItem<int>(
                value: index + 1,
                child: Text(_months[index]),
              );
            }),
            onChanged: (value) {
              setState(() {
                _selectedMonth = value!;
              });
            },
          ),
          const SizedBox(height: 8),
          // Mostrar fecha seleccionada
          Text(
            'Fecha seleccionada: ${_months[_selectedMonth - 1]} $_selectedYear',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final selectedDate = DateTime(_selectedYear, _selectedMonth, 1);
            Navigator.pop(context, selectedDate);
          },
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
} 
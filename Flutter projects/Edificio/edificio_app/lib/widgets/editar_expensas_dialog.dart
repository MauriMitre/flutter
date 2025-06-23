import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditarExpensasDialog extends StatefulWidget {
  final double expensasActuales;

  const EditarExpensasDialog({
    Key? key,
    required this.expensasActuales,
  }) : super(key: key);

  @override
  State<EditarExpensasDialog> createState() => _EditarExpensasDialogState();
}

class _EditarExpensasDialogState extends State<EditarExpensasDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _expensasController;

  @override
  void initState() {
    super.initState();
    _expensasController = TextEditingController(
      text: widget.expensasActuales.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _expensasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Expensas Comunes'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _expensasController,
          decoration: const InputDecoration(
            labelText: 'Monto de Expensas',
            border: OutlineInputBorder(),
            prefixText: '\$',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el monto';
            }
            if (double.tryParse(value) == null) {
              return 'Por favor ingrese un monto válido';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                double.parse(_expensasController.text),
              );
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
} 
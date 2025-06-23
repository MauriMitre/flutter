import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/inquilino.dart';
import '../screens/documentos_inquilino_screen.dart';

class EditarInquilinoDialog extends StatefulWidget {
  final Inquilino inquilino;

  const EditarInquilinoDialog({
    Key? key,
    required this.inquilino,
  }) : super(key: key);

  @override
  State<EditarInquilinoDialog> createState() => _EditarInquilinoDialogState();
}

class _EditarInquilinoDialogState extends State<EditarInquilinoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _departamentoController;
  late TextEditingController _precioController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.inquilino.nombre);
    _apellidoController = TextEditingController(text: widget.inquilino.apellido);
    _departamentoController = TextEditingController(text: widget.inquilino.departamento);
    _precioController = TextEditingController(
      text: widget.inquilino.precioAlquiler.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _departamentoController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Inquilino'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el apellido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departamentoController,
                decoration: const InputDecoration(
                  labelText: 'Departamento',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el departamento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio de Alquiler',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor ingrese un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentosInquilinoScreen(
                        inquilino: widget.inquilino,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.folder),
                label: const Text('Gestionar Documentos'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
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
              final inquilinoActualizado = Inquilino(
                id: widget.inquilino.id,
                nombre: _nombreController.text,
                apellido: _apellidoController.text,
                departamento: _departamentoController.text,
                precioAlquiler: double.parse(_precioController.text),
                pagos: widget.inquilino.pagos,
                expensas: widget.inquilino.expensas,
                pagosAlquiler: widget.inquilino.pagosAlquiler,
                pagosExpensas: widget.inquilino.pagosExpensas,
                montosPendientes: widget.inquilino.montosPendientes,
                metodosPago: widget.inquilino.metodosPago,
                cuentasTransferencia: widget.inquilino.cuentasTransferencia,
              );
              Navigator.pop(context, inquilinoActualizado);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
} 
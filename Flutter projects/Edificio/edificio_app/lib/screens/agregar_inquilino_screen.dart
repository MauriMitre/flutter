import 'package:flutter/material.dart';
import 'package:edificio_app/models/inquilino.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AgregarInquilinoScreen extends StatefulWidget {
  final Inquilino? inquilino;

  const AgregarInquilinoScreen({Key? key, this.inquilino}) : super(key: key);

  @override
  AgregarInquilinoScreenState createState() => AgregarInquilinoScreenState();
}

class AgregarInquilinoScreenState extends State<AgregarInquilinoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _precioAlquilerController = TextEditingController();
  bool _precioModificado = false;

  @override
  void initState() {
    super.initState();
    if (widget.inquilino != null) {
      _nombreController.text = widget.inquilino!.nombre;
      _apellidoController.text = widget.inquilino!.apellido;
      _departamentoController.text = widget.inquilino!.departamento;
      _precioAlquilerController.text = widget.inquilino!.precioAlquiler.toString();
      
      // Detectar cambios en el precio del alquiler
      _precioAlquilerController.addListener(() {
        if (widget.inquilino != null && 
            _precioAlquilerController.text.isNotEmpty &&
            double.tryParse(_precioAlquilerController.text) != widget.inquilino!.precioAlquiler) {
          setState(() {
            _precioModificado = true;
          });
        } else {
          setState(() {
            _precioModificado = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _departamentoController.dispose();
    _precioAlquilerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inquilino == null
            ? 'Agregar Inquilino'
            : 'Editar Inquilino'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ingrese el nombre',
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
                  hintText: 'Ingrese el apellido',
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
                  hintText: 'Ingrese el número o letra del departamento',
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
                controller: _precioAlquilerController,
                decoration: InputDecoration(
                  labelText: 'Precio del alquiler',
                  hintText: 'Ingrese el precio mensual',
                  prefixText: '\$',
                  border: const OutlineInputBorder(),
                  helperText: _precioModificado && widget.inquilino != null
                      ? 'El nuevo precio se aplicará desde el mes actual en adelante'
                      : null,
                  helperStyle: const TextStyle(color: Colors.blue),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor ingrese un valor numérico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardarInquilino,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(
                  widget.inquilino == null ? 'Agregar' : 'Guardar cambios',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _guardarInquilino() {
    if (_formKey.currentState!.validate()) {
      final double nuevoPrecio = double.parse(_precioAlquilerController.text);
      
      // Crear un mapa de precios de alquiler por mes
      Map<String, double> preciosAlquilerPorMes = {};
      
      // Si estamos editando un inquilino existente y el precio ha cambiado
      if (widget.inquilino != null && _precioModificado) {
        // Copiar los precios históricos existentes
        preciosAlquilerPorMes = Map.from(widget.inquilino!.preciosAlquilerPorMes);
        
        // Obtener el mes actual en formato MM-yyyy
        final mesActual = DateFormat('MM-yyyy').format(DateTime.now());
        
        // Guardar el nuevo precio para el mes actual
        preciosAlquilerPorMes[mesActual] = nuevoPrecio;
      }
      
      final inquilino = Inquilino(
        id: widget.inquilino?.id ?? const Uuid().v4(),
        nombre: _nombreController.text,
        apellido: _apellidoController.text,
        departamento: _departamentoController.text,
        precioAlquiler: nuevoPrecio,
        pagos: widget.inquilino?.pagos ?? {},
        expensas: widget.inquilino?.expensas ?? {},
        pagosAlquiler: widget.inquilino?.pagosAlquiler ?? {},
        pagosExpensas: widget.inquilino?.pagosExpensas ?? {},
        montosPendientes: widget.inquilino?.montosPendientes ?? {},
        metodosPago: widget.inquilino?.metodosPago ?? {},
        cuentasTransferencia: widget.inquilino?.cuentasTransferencia ?? {},
        preciosAlquilerPorMes: preciosAlquilerPorMes,
      );

      Navigator.pop(context, inquilino);
    }
  }
} 
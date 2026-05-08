import 'package:flutter/material.dart';
import 'package:frontend/models/medico.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/medico_location_sync_service.dart';
import 'package:frontend/services/medico_service.dart';
import 'package:frontend/services/user_service.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/widgets/common_appbar.dart';

class EditarMedicoPage extends StatefulWidget {
  final int id;

  const EditarMedicoPage({super.key, required this.id});

  @override
  State<EditarMedicoPage> createState() => _EditarMedicoPageState();
}

class _EditarMedicoPageState extends State<EditarMedicoPage> {
  final _formKey = GlobalKey<FormState>();
  final _medicoService = MedicoService();
  final _userService = UserService();

  // Campos editables para médico en esta vista
  final TextEditingController contrasenaController = TextEditingController();
  final TextEditingController valorConsultaController = TextEditingController();

  bool _loading = true;
  String? errorMessage;

  Medico? _medicoOriginal;

  @override
  void initState() {
    super.initState();
    _loadMedico();
  }

  Future<void> _loadMedico() async {
    try {
      final medico = await _medicoService.getMedicos().then(
            (medicos) => medicos.firstWhere((m) => m.id == widget.id),
          );

      if (!mounted) return;

      _medicoOriginal = medico;

      // Se deja vacía para que solo se envíe si se desea cambiar.
      contrasenaController.clear();
      valorConsultaController.text = medico.valorConsulta.toStringAsFixed(0);

      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Error al cargar los datos del medico';
        _loading = false;
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    if (_medicoOriginal == null) return;

    final valorConsulta = _parseNumber(valorConsultaController.text);
    if (valorConsulta == null || valorConsulta < 0) {
      setState(() {
        errorMessage =
            'Ingresa un valor de consulta valido (numero mayor o igual a 0)';
      });
      return;
    }

    final nuevaContrasena = contrasenaController.text.trim();
    if (nuevaContrasena.isNotEmpty && nuevaContrasena.length < 6) {
      setState(() {
        errorMessage = 'La contraseña debe tener mínimo 6 caracteres';
      });
      return;
    }

    final medicoEditado = Medico(
      id: widget.id,
      especialidad: _medicoOriginal!.especialidad,
      usuario: _medicoOriginal!.usuario,
      estado: _medicoOriginal!.estado,
      tarjetaProfe: _medicoOriginal!.tarjetaProfe,
      valorConsulta: valorConsulta,
      latitud: _medicoOriginal!.latitud,
      longitud: _medicoOriginal!.longitud,
      calificacion: _medicoOriginal!.calificacion,
    );

    final tarifaOk = await _medicoService.updateMedicos(medicoEditado);

    bool contrasenaOk = true;
    if (nuevaContrasena.isNotEmpty) {
      final userOriginal = _medicoOriginal!.usuario;
      final usuarioEditado = User(
        id: userOriginal.id,
        nombre: userOriginal.nombre,
        email: userOriginal.email,
        telefono: userOriginal.telefono,
        identificacion: userOriginal.identificacion,
        direccion: userOriginal.direccion,
        contrasena: nuevaContrasena,
        tipo_identificacion: userOriginal.tipo_identificacion,
        tipo_usuario: userOriginal.tipo_usuario,
        genero: userOriginal.genero,
        estado: userOriginal.estado,
        token_dispositivo: userOriginal.token_dispositivo,
      );

      contrasenaOk = await _userService.updateUsuario(
        usuarioEditado,
        incluirContrasena: true,
      );
    }

    if (tarifaOk && contrasenaOk && mounted) {
      if ((_medicoOriginal!.estado).toLowerCase() == 'activo') {
        await MedicoLocationSyncService.instance.start();
      } else {
        await MedicoLocationSyncService.instance.stop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tarifa y contraseña actualizadas correctamente')),
      );
      context.pop();
    } else {
      setState(() {
        errorMessage = 'Error al actualizar la tarifa o la contraseña';
      });
    }
  }

  @override
  void dispose() {
    contrasenaController.dispose();
    valorConsultaController.dispose();
    super.dispose();
  }

  Widget buildTextField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator ??
          (value) => value == null || value.isEmpty
              ? 'Este campo es obligatorio'
              : null,
    );
  }

  double? _parseNumber(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CommonAppBar(
          title: const Text('Actualizar tarifa y contraseña'),
          backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildTextField(
                valorConsultaController,
                'Valor consulta',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final parsed = _parseNumber(value ?? '');
                  if (parsed == null || parsed < 0) {
                    return 'Ingresa un valor valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              buildTextField(
                contrasenaController,
                'Nueva contraseña (opcional)',
                obscure: true,
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return null;
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (errorMessage != null)
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
                ),
                child: const Text(
                  'Guardar cambios',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

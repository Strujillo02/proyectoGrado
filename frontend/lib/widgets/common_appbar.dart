import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/medico_service.dart';
import 'package:frontend/models/medico.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/user_service.dart';

class CommonAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double elevation;

  /// Whether to show the logout icon in the app bar. Defaults to true.
  final bool showLogout;

  /// Whether to show the leading back arrow. Defaults to true.
  final bool showBack;

  /// Whether to show the medico 'Estado' switch (visible sólo para medicos).
  final bool showMedicoSwitch;

  /// Optional route to navigate to when there is no history to pop.
  final String? fallbackPath;

  const CommonAppBar({
    super.key,
    this.title,
    this.actions,
    this.backgroundColor,
    this.elevation = 0,
    this.fallbackPath,
    this.showLogout = true,
    this.showBack = true,
    this.showMedicoSwitch = false,
  });

  @override
  State<CommonAppBar> createState() => _CommonAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CommonAppBarState extends State<CommonAppBar> {
  bool _isMedico = false;
  bool _switchValue = false;
  bool _loadingSwitch = false;
  Medico? _medico;

  String _normalizeRole(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s.contains('admin')) return 'administrador';
    if (s.contains('medic')) return 'medico';
    if (s.contains('pacien')) return 'paciente';
    return s;
  }

  Future<String> _resolveHomePathForLoggedUser() async {
    final auth = AuthService();
    final user = await auth.getUser();
    final userType = _normalizeRole(user?.tipo_usuario);

    if (userType == 'administrador') return '/home/admin';
    if (userType == 'medico') return '/home/medico';
    if (userType == 'paciente') return '/home/paciente';

    // Fallback secundario por compatibilidad con implementaciones previas.
    final fallbackType = _normalizeRole(await auth.getUserType());
    if (fallbackType == 'administrador') return '/home/admin';
    if (fallbackType == 'medico') return '/home/medico';
    if (fallbackType == 'paciente') return '/home/paciente';

    if (widget.fallbackPath != null) return widget.fallbackPath!;
    // Evita enviar al login cuando la flecha de regreso no debe cerrar sesión.
    return '/home/paciente';
  }

  @override
  void initState() {
    super.initState();
    if (widget.showMedicoSwitch) _initMedicoState();
  }

  Future<void> _initMedicoState() async {
    try {
      final auth = AuthService();
      final User? user = await auth.getUser();
      if (user == null) {
        debugPrint('No user found for medico state init');
        return;
      }
      if (user.tipo_usuario.toLowerCase() != 'medico') {
        debugPrint('User is not medico: ${user.tipo_usuario}');
        return;
      }
      setState(() => _isMedico = true);

      try {
        final ms = MedicoService();
        final medicos = await ms.getMedicos();
        if (medicos.isEmpty) {
          debugPrint('No medicos found for user');
          return;
        }

        final found = medicos.firstWhere(
          (m) => m.usuario.id == user.id,
          orElse: () => throw Exception('Medico not found for user ${user.id}'),
        );

        _medico = found;
        final est = found.estado;
        final active = _estadoEsActivo(est);
        setState(() => _switchValue = active);
        debugPrint('Medico loaded: ${found.id}, estado: ${found.estado}');
      } catch (e) {
        debugPrint('Error finding medico for user: $e');
        setState(() => _isMedico = false);
      }
    } catch (e) {
      debugPrint('Error inicializando estado medico en AppBar: $e');
      setState(() => _isMedico = false);
    }
  }

  bool _estadoEsActivo(String? v) {
    if (v == null) return false;
    final s = v.toLowerCase();
    return s == 'activo' ||
        s == 'true' ||
        s == '1' ||
        s == 'habilitado' ||
        s == 'enabled';
  }

  Future<void> _onToggle(bool newVal) async {
    if (_medico == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No se pudo cargar los datos del médico. Recarga la página.')),
        );
      }
      return;
    }
    setState(() {
      _loadingSwitch = true;
      _switchValue = newVal;
    });
    try {
      final updated = Medico(
        id: _medico!.id,
        especialidad: _medico!.especialidad,
        usuario: _medico!.usuario,
        estado: newVal ? 'Activo' : 'Inactivo',
        tarjetaProfe: _medico!.tarjetaProfe,
        valorConsulta: _medico!.valorConsulta,
        latitud: _medico!.latitud,
        longitud: _medico!.longitud,
      );
      final ok = await MedicoService().updateMedicos(updated);
      if (!ok) {
        // Try to update the user record instead (some backends allow user self-update)
        try {
          final userService = UserService();
          final user = _medico!.usuario;
          final updatedUser = User(
            id: user.id,
            nombre: user.nombre,
            telefono: user.telefono,
            email: user.email,
            identificacion: user.identificacion,
            genero: user.genero,
            estado: newVal ? 'Activo' : 'Inactivo',
            tipo_identificacion: user.tipo_identificacion,
            contrasena: user.contrasena,
            tipo_usuario: user.tipo_usuario,
            direccion: user.direccion,
            token_dispositivo: user.token_dispositivo,
          );
          final okUser = await userService.updateUsuario(
            updatedUser,
            incluirContrasena: false,
          );
          if (okUser) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Estado actualizado (usuario): ${newVal ? 'Activo' : 'Inactivo'}')),
              );
            }
            setState(() {
              _medico = Medico(
                id: _medico!.id,
                especialidad: _medico!.especialidad,
                usuario: updatedUser,
                estado: newVal ? 'Activo' : 'Inactivo',
                tarjetaProfe: _medico!.tarjetaProfe,
                valorConsulta: _medico!.valorConsulta,
                latitud: _medico!.latitud,
                longitud: _medico!.longitud,
              );
            });
          } else {
            setState(() => _switchValue = !_switchValue);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('No se pudo actualizar estado del médico')),
              );
            }
          }
        } catch (e) {
          setState(() => _switchValue = !_switchValue);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('No se pudo actualizar estado del médico')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Estado actualizado: ${newVal ? 'Activo' : 'Inactivo'}')),
          );
        }
        setState(() => _medico = updated);
      }
    } catch (e) {
      debugPrint('Error actualizando estado medico: $e');
      setState(() => _switchValue = !_switchValue);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error actualizando estado del médico')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingSwitch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> effectiveActions = [];
    if (widget.actions != null) effectiveActions.addAll(widget.actions!);

    if (widget.showMedicoSwitch && _isMedico) {
      effectiveActions.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              const Text('Estado', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 6),
              _loadingSwitch
                  ? const SizedBox(
                      width: 40,
                      height: 24,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Switch(
                      value: _switchValue,
                      onChanged: (v) => _onToggle(v),
                      activeColor: Colors.white,
                    ),
            ],
          ),
        ),
      );
    }

    if (widget.showLogout) {
      effectiveActions.add(
        IconButton(
          tooltip: 'Cerrar sesión',
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () async {
            final router = GoRouter.of(context);

            final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content:
                        const Text('¿Estás seguro que deseas cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                ) ??
                false;

            if (!confirmed) return;

            try {
              await AuthService().logout();
            } catch (e) {
              debugPrint('Error during logout: $e');
            }

            router.goNamed('login');
          },
        ),
      );
    }

    return AppBar(
      title: widget.title,
      actions: effectiveActions,
      backgroundColor: widget.backgroundColor,
      elevation: widget.elevation,
      automaticallyImplyLeading: widget.showBack,
      leading: widget.showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {
                final router = GoRouter.of(context);
                final targetPath = await _resolveHomePathForLoggedUser();
                if (!mounted) return;
                router.go(targetPath);
              },
            )
          : null,
    );
  }
}

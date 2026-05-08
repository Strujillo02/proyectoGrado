import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/models/medico.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/medico_service.dart';

class MedicoLocationSyncService {
  MedicoLocationSyncService._();

  static final MedicoLocationSyncService instance =
      MedicoLocationSyncService._();

  final MedicoService _medicoService = MedicoService();

  Timer? _timer;
  bool _syncing = false;

  bool get isRunning => _timer != null;

  Future<void> start() async {
    if (_timer != null) return;

    _timer = Timer.periodic(const Duration(minutes: 3), (_) {
      _tick();
    });

    await _tick();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refreshForCurrentUser() async {
    final user = await AuthService().getUser();
    if (user == null || !_isMedicoRole(user.tipo_usuario)) {
      await stop();
      return;
    }

    final medico = await _getCurrentMedico();
    if (medico == null || !_estadoEsActivo(medico.estado)) {
      await stop();
      return;
    }

    await start();
  }

  Future<void> _tick() async {
    if (_syncing) return;

    _syncing = true;
    try {
      final user = await AuthService().getUser();
      if (user == null || !_isMedicoRole(user.tipo_usuario)) {
        await stop();
        return;
      }

      final medico = await _getCurrentMedico();
      if (medico == null || !_estadoEsActivo(medico.estado)) {
        await stop();
        return;
      }

      final permiso = await _ensureLocationPermission();
      if (!permiso) {
        debugPrint(
            'MedicoLocationSyncService: permiso de ubicación no concedido.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final actualizado = Medico(
        id: medico.id,
        especialidad: medico.especialidad,
        usuario: medico.usuario,
        estado: medico.estado,
        tarjetaProfe: medico.tarjetaProfe,
        valorConsulta: medico.valorConsulta,
        latitud: pos.latitude,
        longitud: pos.longitude,
        calificacion: medico.calificacion,
      );

      final ok = await _medicoService.updateMedicos(actualizado);
      if (!ok) {
        debugPrint(
            'MedicoLocationSyncService: no se pudo actualizar latitud/longitud del médico.');
      }
    } catch (e) {
      debugPrint('MedicoLocationSyncService error: $e');
    } finally {
      _syncing = false;
    }
  }

  Future<Medico?> _getCurrentMedico() async {
    try {
      final user = await AuthService().getUser();
      if (user?.id == null) return null;
      final medicos = await _medicoService.getMedicos();
      for (final medico in medicos) {
        if (medico.usuario.id == user!.id) return medico;
      }
      return null;
    } catch (e) {
      debugPrint(
          'MedicoLocationSyncService: error obteniendo médico actual: $e');
      return null;
    }
  }

  bool _isMedicoRole(String? raw) {
    final role = (raw ?? '').toLowerCase();
    return role.contains('medic');
  }

  bool _estadoEsActivo(String? estado) {
    final s = (estado ?? '').trim().toLowerCase();
    return s == 'activo' || s == '1' || s == 'true';
  }

  Future<bool> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}

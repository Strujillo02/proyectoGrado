import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePaciente extends StatelessWidget {
  const HomePaciente({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
        automaticallyImplyLeading: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 35, bottom: 1),
                  child: Text(
                    'Bienvenido Paciente',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(21, 99, 161, 1),
                    ),
                  ),
                ),
                const SizedBox(height: 90),
                Image.asset('assets/images/logo.png', height: 270),
                const SizedBox(height: 32),
                SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/solicitar/cita');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Solicitar cita',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/gestionar/especialidades');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Ver citas agendadas',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/usuario/editar/:id');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Actualizar datos personales',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

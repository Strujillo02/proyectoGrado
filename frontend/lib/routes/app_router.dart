import 'package:frontend/views/auth/login_page.dart';
import 'package:frontend/views/auth/register_page.dart';
import 'package:frontend/views/usuarios/home_admin.dart';
import 'package:frontend/views/usuarios/user_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/gestionar/usuarios',
      name: 'gestinarUsuarios',
      builder: (context, state) => const UserManagementPage(),
    ),
    /*
    GoRoute(
      path: '/gestionar/especialidades',
      name: 'gestinarEspecialidades',
      builder: (context, state) => const HomeAdmin(),
    ),*/
    GoRoute(
      path: '/home/admin',
      name: 'homeAdmin',
      builder: (context, state) => const HomeAdmin(),
    ),
  ],
);

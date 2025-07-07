import 'package:frontend/views/auth/login_page.dart';
import 'package:frontend/views/auth/register_page.dart';
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
  ]
);
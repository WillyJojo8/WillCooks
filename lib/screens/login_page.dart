import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text("Iniciar sesión con Google"),
          onPressed: () async {
            final user = await authService.signInWithGoogle();
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error en el login")),
              );
            }
          },
        ),
      ),
    );
  }
}

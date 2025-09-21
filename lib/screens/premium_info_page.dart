import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PremiumInfoPage extends StatelessWidget {
  const PremiumInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "WillCooks",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Bienvenido a WillCooks 👩‍🍳",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Text(
                "Con la versión Premium podrás:",
                style: TextStyle(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                "✅ Crear y guardar recetas\n"
                    "✅ Programar pedidos\n"
                    "✅ Gestionar inventario\n"
                    "✅ Ver menús personalizados",
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 40),
              Text(
                "Contacta con el administrador para activar tu cuenta Premium.",
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

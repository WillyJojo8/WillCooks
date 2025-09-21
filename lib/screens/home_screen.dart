import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'recipes/recipe_list_page.dart';
import 'premium_info_page.dart';
import 'menus/menu_list_page.dart'; // ✅ cambia aquí

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<bool> _getIsPremium() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc['isPremium'] ?? false;
  }

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
      body: FutureBuilder<bool>(
        future: _getIsPremium(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final isPremium = snapshot.data!;

          if (!isPremium) {
            // 🔹 Usuarios no premium → página informativa
            return const PremiumInfoPage();
          }

          // 🔹 Usuarios premium → navegación principal
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Bienvenido, ${FirebaseAuth.instance.currentUser!.displayName ?? "Usuario"}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // 🔹 Ver recetas
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RecipeListPage()),
                    );
                  },
                  child: const Text("Ver recetas"),
                ),
                const SizedBox(height: 20),

                // 🔹 Menú semanal
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MenuListPage()), // ✅ ir a lista de menús
                    );
                  },
                  child: const Text("Planificación semanal"),
                ),
                const SizedBox(height: 20),

                // 🔹 Programar pedido (futuro PDF)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    // TODO: ir a pantalla de generación de PDF del pedido
                  },
                  child: const Text("Generar pedido semanal"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

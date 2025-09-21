import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'ingredients/ingredient_base_list_page.dart'; // ✅ Importamos la lista de ingredientes base
import 'recipes/recipe_list_page.dart';
import 'premium_info_page.dart';
import 'menus/menu_list_page.dart';
import 'settings_page.dart'; // ✅ Importamos la nueva pantalla de ajustes

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<bool> _getIsPremium() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
          // ✅ Botón de Ajustes
          IconButton(
            icon: const Icon(Icons.settings, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
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
            return const PremiumInfoPage();
          }

          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔹 Logo en grande
                  Image.asset(
                    "assets/icon/lolaicon.png",
                    width: 160,
                    height: 160,
                  ),
                  const SizedBox(height: 15),

                  // 🔹 Nombre de la app
                  const Text(
                    "WillCooks",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🔹 Bienvenida al usuario
                  Text(
                    "Bienvenido, ${FirebaseAuth.instance.currentUser!.displayName ?? "Usuario"}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // 🔹 Botones principales
                  _buildMenuButton(
                    context,
                    label: "Ver recetas",
                    icon: Icons.restaurant_menu,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RecipeListPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildMenuButton(
                    context,
                    label: "Planificación semanal",
                    icon: Icons.calendar_month,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MenuListPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildMenuButton(
                    context,
                    label: "Inventario",
                    icon: Icons.inventory,
                    onPressed: () {
                      // TODO: ir a pantalla de Inventario
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildMenuButton(
                    context,
                    label: "Ingredientes base",
                    icon: Icons.kitchen,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => IngredientBaseListPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 🔹 Método helper para botones con icono
  Widget _buildMenuButton(BuildContext context,
      {required String label,
        required IconData icon,
        required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        textStyle:
        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 26),
      onPressed: onPressed,
      label: Text(label),
    );
  }
}

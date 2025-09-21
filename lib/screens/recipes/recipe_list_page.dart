import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/recipe_service.dart';
import '../../models/recipe.dart';
import 'new_recipe_page.dart';
import 'recipe_detail_page.dart';

class RecipeListPage extends StatelessWidget {
  final RecipeService _recipeService = RecipeService();
  final bool returnOnSelect; // 🔹 si true, devuelve la receta seleccionada

  RecipeListPage({super.key, this.returnOnSelect = false});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recetas", style: TextStyle(fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewRecipePage()),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<List<Recipe>>(
        stream: _recipeService.getRecipesByUser(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final recipes = snapshot.data!;
          if (recipes.isEmpty) {
            return const Center(child: Text("No hay recetas todavía"));
          }

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(recipe.name, style: const TextStyle(fontSize: 20)),
                  subtitle: Text("${recipe.ingredients.length} ingredientes"),
                  onTap: () {
                    if (returnOnSelect) {
                      // 🔹 Devolver receta seleccionada al menú semanal
                      Navigator.pop(context, recipe);
                    } else {
                      // 🔹 Abrir detalle de la receta
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailPage(recipe: recipe),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

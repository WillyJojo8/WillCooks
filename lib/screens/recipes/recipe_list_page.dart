import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/recipe_service.dart';
import '../../models/recipe.dart';
import 'new_recipe_page.dart';
import 'recipe_detail_page.dart';

class RecipeListPage extends StatelessWidget {
  final RecipeService _recipeService = RecipeService();
  final bool returnOnSelect;

  RecipeListPage({super.key, this.returnOnSelect = false});

  Future<void> _searchRecipeDialog(BuildContext context, String userId) async {
    String query = "";
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Buscar receta"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Buscar",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) =>
                        setState(() => query = val.toLowerCase()),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: StreamBuilder<List<Recipe>>(
                      stream: _recipeService.getRecipesByUser(userId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final filtered = snapshot.data!
                            .where((r) =>
                            r.name.toLowerCase().contains(query))
                            .toList();
                        if (filtered.isEmpty) {
                          return const Center(child: Text("No hay coincidencias"));
                        }
                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) {
                            final r = filtered[i];
                            return ListTile(
                              title: Text(r.name),
                              subtitle:
                              Text("${r.ingredients.length} ingredientes"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Eliminar receta"),
                                      content: Text(
                                          "¿Seguro que quieres eliminar '${r.name}'?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Cancelar"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Eliminar"),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await _recipeService.deleteRecipe(r.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Receta '${r.name}' eliminada")),
                                      );
                                    }
                                  }
                                },
                              ),
                              onTap: () {
                                if (returnOnSelect) {
                                  Navigator.pop(context);
                                  Navigator.pop(context, r);
                                } else {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RecipeDetailPage(recipe: r),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recetas", style: TextStyle(fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            onPressed: () => _searchRecipeDialog(context, userId),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewRecipePage()),
              );
            },
          ),
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
                margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(recipe.name,
                      style: const TextStyle(fontSize: 20)),
                  subtitle:
                  Text("${recipe.ingredients.length} ingredientes"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Eliminar receta"),
                          content: Text(
                              "¿Seguro que quieres eliminar '${recipe.name}'?"),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text("Cancelar"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text("Eliminar"),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _recipeService.deleteRecipe(recipe.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Receta '${recipe.name}' eliminada")),
                          );
                        }
                      }
                    },
                  ),
                  onTap: () {
                    if (returnOnSelect) {
                      Navigator.pop(context, recipe);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RecipeDetailPage(recipe: recipe),
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

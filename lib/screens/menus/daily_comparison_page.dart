import 'package:flutter/material.dart';
import '../../models/menu.dart';
import '../../models/recipe.dart';
import '../../services/recipe_service.dart';

class DailyComparisonPage extends StatelessWidget {
  final Menu menu;
  final String day;
  final RecipeService _recipeService = RecipeService();

  DailyComparisonPage({super.key, required this.menu, required this.day});

  String _formatDiff(double diff, String unit) {
    if (diff > 0) {
      return "FALTAN ${diff.toStringAsFixed(2)} $unit";
    } else if (diff < 0) {
      return "SOBRAN ${diff.abs().toStringAsFixed(2)} $unit";
    } else {
      return "JUSTO";
    }
  }

  @override
  Widget build(BuildContext context) {
    final estChildren = menu.estimatedChildrenPerDay[day] ?? 0;
    final actChildren = menu.actualChildrenPerDay[day] ?? 0;
    final recipeIds = menu.dailyRecipes[day] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text("Comparación $day")),
      body: recipeIds.isEmpty
          ? const Center(
        child: Text(
          "No hay recetas asignadas este día",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      )
          : StreamBuilder<List<Recipe>>(
        stream: _recipeService.getRecipesByUser(menu.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allRecipes = snapshot.data!;
          final recipes = allRecipes
              .where((r) => recipeIds.contains(r.id))
              .toList();

          final List<Map<String, dynamic>> comparison = [];
          for (final recipe in recipes) {
            for (final ing in recipe.ingredients) {
              comparison.add({
                'name': ing.name,
                'unit': ing.unit,
                'purchaseUnit': ing.purchaseUnit,
                'estimatedBase': ing.totalForChildren(estChildren),
                'actualBase': ing.totalForChildren(actChildren),
                'estimatedPurchase':
                ing.totalForChildrenInPurchaseUnit(estChildren),
                'actualPurchase':
                ing.totalForChildrenInPurchaseUnit(actChildren),
              });
            }
          }
          comparison.sort((a, b) => a['name'].compareTo(b['name']));

          if (comparison.isEmpty) {
            return const Center(
                child: Text("No hay ingredientes para este día"));
          }

          return ListView.builder(
            itemCount: comparison.length,
            itemBuilder: (context, index) {
              final item = comparison[index];
              final diffPurchase =
                  item['actualPurchase'] - item['estimatedPurchase'];

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Columna izquierda: nombre
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            Text("Unidad base: ${item['unit']}",
                                style: const TextStyle(fontSize: 16)),
                            Text("Unidad compra: ${item['purchaseUnit']}",
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                      // 🔹 Columna derecha: cantidades
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Pedido: ${item['estimatedBase'].toStringAsFixed(2)} ${item['unit']} "
                                  "(${item['estimatedPurchase'].toStringAsFixed(2)} ${item['purchaseUnit']})",
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              "Uso real: ${item['actualBase'].toStringAsFixed(2)} ${item['unit']} "
                                  "(${item['actualPurchase'].toStringAsFixed(2)} ${item['purchaseUnit']})",
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              _formatDiff(diffPurchase,
                                  item['purchaseUnit']),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

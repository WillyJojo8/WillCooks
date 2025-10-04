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
    final estInf = menu.estimatedChildrenInfantilPerDay[day] ?? 0;
    final estPrim = menu.estimatedChildrenPrimariaPerDay[day] ?? 0;
    final actInf = menu.actualChildrenInfantilPerDay[day] ?? 0;
    final actPrim = menu.actualChildrenPrimariaPerDay[day] ?? 0;
    final recipeIds = menu.dailyRecipes[day] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text("Comparación total - $day")),
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
          final recipes =
          allRecipes.where((r) => recipeIds.contains(r.id)).toList();

          final List<Map<String, dynamic>> comparison = [];

          for (final recipe in recipes) {
            for (final ing in recipe.ingredients) {
              final estInfCrudo = ing.totalCrudoInfantil(estInf);
              final estPrimCrudo = ing.totalCrudoPrimaria(estPrim);
              final actInfCrudo = ing.totalCrudoInfantil(actInf);
              final actPrimCrudo = ing.totalCrudoPrimaria(actPrim);

              final estInfCocinado = estInfCrudo * ing.cookingFactor;
              final estPrimCocinado = estPrimCrudo * ing.cookingFactor;
              final actInfCocinado = actInfCrudo * ing.cookingFactor;
              final actPrimCocinado = actPrimCrudo * ing.cookingFactor;

              comparison.add({
                'name': ing.name,
                'unit': ing.unit,
                'purchaseUnit': ing.purchaseUnit,
                'estInfCrudo': estInfCrudo,
                'actInfCrudo': actInfCrudo,
                'estInfCocinado': estInfCocinado,
                'actInfCocinado': actInfCocinado,
                'estPrimCrudo': estPrimCrudo,
                'actPrimCrudo': actPrimCrudo,
                'estPrimCocinado': estPrimCocinado,
                'actPrimCocinado': actPrimCocinado,
                'estInfCompra': ing.totalInfantilInPurchaseUnit(estInf),
                'actInfCompra': ing.totalInfantilInPurchaseUnit(actInf),
                'estPrimCompra': ing.totalPrimariaInPurchaseUnit(estPrim),
                'actPrimCompra': ing.totalPrimariaInPurchaseUnit(actPrim),
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
              final diffInfCompra =
                  item['actInfCompra'] - item['estInfCompra'];
              final diffPrimCompra =
                  item['actPrimCompra'] - item['estPrimCompra'];

              return Card(
                elevation: 3,
                margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'],
                          style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text("Unidad base: ${item['unit']}",
                          style: const TextStyle(
                              fontSize: 15, color: Colors.black54)),
                      Text("Unidad compra: ${item['purchaseUnit']}",
                          style: const TextStyle(
                              fontSize: 15, color: Colors.black54)),
                      const SizedBox(height: 10),

                      /// 🔹 BLOQUE INFANTIL
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(10),
                        margin:
                        const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("👶 Infantil",
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent)),
                            const SizedBox(height: 6),
                            Text(
                                "Pedido crudo: ${item['estInfCrudo'].toStringAsFixed(2)} ${item['unit']}",
                                style: const TextStyle(fontSize: 14)),
                            Text(
                                "Usado crudo: ${item['actInfCrudo'].toStringAsFixed(2)} ${item['unit']}",
                                style: const TextStyle(fontSize: 14)),
                            Text(
                                "Pedido cocinado: ${item['estInfCocinado'].toStringAsFixed(2)} ${item['unit']}",
                                style: const TextStyle(fontSize: 14)),
                            Text(
                                "Usado cocinado: ${item['actInfCocinado'].toStringAsFixed(2)} ${item['unit']}",
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              _formatDiff(diffInfCompra,
                                  item['purchaseUnit']),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                          ],
                        ),
                      ),

                      /// 🔹 BLOQUE PRIMARIA
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(10),
                        margin:
                        const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("🧒 Primaria",
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange)),
                            const SizedBox(height: 6),
                            Text(
                                "Pedido crudo: ${item['estPrimCrudo'].toStringAsFixed(2)} ${item['unit']}",
                                style: const TextStyle(fontSize: 14)),
                            Text(
                                "Usado crudo: ${item['actPrimCrudo'].toStringAsFixed(2)} ${item['unit']}",
                                style: const TextStyle(fontSize: 14)),
                            Text(
                                "Pedido cocinado: ${item['estPrimCocinado'].toStringAsFixed(2)} ${item['unit']}",
                                style: const TextStyle(fontSize: 14)),
                            Text(
                                "Usado cocinado: ${item['actPrimCocinado'].toStringAsFixed(2)} ${item['unit']}",
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              _formatDiff(diffPrimCompra,
                                  item['purchaseUnit']),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange),
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

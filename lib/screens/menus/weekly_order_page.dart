import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../services/menu_service.dart';
import '../../services/recipe_service.dart';
import '../../models/menu.dart';
import '../../models/recipe.dart';

class WeeklyOrderPage extends StatelessWidget {
  final DateTime weekStart;
  final MenuService _menuService = MenuService();
  final RecipeService _recipeService = RecipeService();

  WeeklyOrderPage({super.key, required this.weekStart});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pedido semanal"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Exportar a PDF",
            onPressed: () async {
              final pdf = await _generatePdf(userId);
              await Printing.layoutPdf(onLayout: (format) async => pdf.save());
            },
          ),
        ],
      ),
      body: StreamBuilder<Menu?>(
        stream: _menuService.getMenuForWeek(userId, weekStart),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final menu = snapshot.data;
          if (menu == null) {
            return const Center(child: Text("No hay menú planificado"));
          }

          return StreamBuilder<List<Recipe>>(
            stream: _recipeService.getRecipesByUser(userId),
            builder: (context, recipeSnapshot) {
              if (!recipeSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allRecipes = recipeSnapshot.data!;
              final totals = _calculateTotals(menu, allRecipes);

              if (totals.isEmpty) {
                return const Center(child: Text("No hay ingredientes esta semana"));
              }

              return ListView.builder(
                itemCount: totals.length,
                itemBuilder: (context, index) {
                  final item = totals[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.shopping_cart),
                      title: Text(item['name'], style: const TextStyle(fontSize: 18)),
                      subtitle: Text(
                        "Total: ${item['base'].toStringAsFixed(2)} ${item['unit']}\n"
                            "Pedido: ${item['compra'].toStringAsFixed(2)} ${item['purchaseUnit']}",
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 🔹 Normalizar nombres (quita tildes, símbolos y plurales simples)
  String _normalizeName(String name) {
    var n = name.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '') // quita símbolos
        .trim();
    if (n.endsWith('s')) {
      n = n.substring(0, n.length - 1); // quita plural simple
    }
    return n;
  }

  /// 🔹 Calcular totales consolidados
  List<Map<String, dynamic>> _calculateTotals(Menu menu, List<Recipe> allRecipes) {
    final Map<String, Map<String, dynamic>> totals = {};

    menu.dailyRecipes.forEach((day, recipeIds) {
      final numChildren = menu.estimatedChildrenPerDay[day] ?? 0;
      for (final recipeId in recipeIds) {
        final recipe = allRecipes.firstWhere(
              (r) => r.id == recipeId,
          orElse: () => Recipe(id: "", name: "?", ingredients: [], userId: menu.userId),
        );
        for (final ing in recipe.ingredients) {
          final key = "${_normalizeName(ing.name)}-${ing.unit}-${ing.purchaseUnit}";
          final totalBase = ing.totalForChildren(numChildren);
          final totalCompra = ing.totalForChildrenInPurchaseUnit(numChildren);

          if (totals.containsKey(key)) {
            totals[key]!['base'] += totalBase;
            totals[key]!['compra'] += totalCompra;
          } else {
            totals[key] = {
              'name': _normalizeName(ing.name),
              'unit': ing.unit,
              'purchaseUnit': ing.purchaseUnit,
              'base': totalBase,
              'compra': totalCompra,
            };
          }
        }
      }
    });

    // 🔹 Ordenamos alfabéticamente por nombre
    final list = totals.values.toList();
    list.sort((a, b) => a['name'].compareTo(b['name']));
    // 🔹 Capitalizamos
    return list.map((item) {
      return {
        ...item,
        'name': item['name'][0].toUpperCase() + item['name'].substring(1),
      };
    }).toList();
  }

  /// 🔹 Generar PDF con ingredientes por receta y totales consolidados
  Future<pw.Document> _generatePdf(String userId) async {
    final menu = await _menuService.getMenuForWeek(userId, weekStart).first;
    final pdf = pw.Document();

    if (menu == null) return pdf;

    final recipes = await _recipeService.getRecipesByUser(userId).first;
    final totals = _calculateTotals(menu, recipes);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(
              "Pedido semanal - ${weekStart.toLocal().toString().split(' ')[0]}",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),

            // 🔹 Ingredientes por receta y día
            ...menu.dailyRecipes.entries.expand((entry) {
              final day = entry.key;
              final recipeIds = entry.value;
              return recipeIds.map((recipeId) {
                final recipe = recipes.firstWhere((r) => r.id == recipeId,
                    orElse: () => Recipe(id: "", name: "?", ingredients: [], userId: menu.userId));
                final numChildren = menu.estimatedChildrenPerDay[day] ?? 0;

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${recipe.name} ($day)",
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    ...recipe.ingredients.map((ing) => pw.Text(
                      "- ${ing.name}: "
                          "${ing.totalForChildren(numChildren).toStringAsFixed(2)} ${ing.unit} "
                          "(${ing.totalForChildrenInPurchaseUnit(numChildren).toStringAsFixed(2)} ${ing.purchaseUnit})",
                      style: const pw.TextStyle(fontSize: 12),
                    )),
                    pw.SizedBox(height: 10),
                  ],
                );
              });
            }).toList(),

            pw.SizedBox(height: 20),
            pw.Text("Totales consolidados",
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),

            pw.TableHelper.fromTextArray(
              headers: ["Ingrediente", "Total base", "Unidad", "Total compra", "Unidad compra"],
              data: totals.map((item) {
                return [
                  item['name'],
                  item['base'].toStringAsFixed(2),
                  item['unit'],
                  item['compra'].toStringAsFixed(2),
                  item['purchaseUnit'],
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    return pdf;
  }
}

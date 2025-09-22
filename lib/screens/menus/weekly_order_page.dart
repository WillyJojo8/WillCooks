import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../services/menu_service.dart';
import '../../services/recipe_service.dart';
import '../../services/inventory_service.dart';
import '../../models/menu.dart';
import '../../models/recipe.dart';
import '../../models/inventory_item.dart';

class WeeklyOrderPage extends StatelessWidget {
  final DateTime weekStart;
  final MenuService _menuService = MenuService();
  final RecipeService _recipeService = RecipeService();
  final InventoryService _inventoryService = InventoryService();

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
              try {
                final pdf = await _generatePdf(userId);
                final bytes = await pdf.save();
                print("📄 PDF generado con ${bytes.length} bytes");
                await Printing.layoutPdf(onLayout: (format) async => bytes);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error al generar PDF: $e")),
                  );
                }
              }
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

              return StreamBuilder<List<InventoryItem>>(
                stream: _inventoryService.getInventory(userId),
                builder: (context, invSnapshot) {
                  if (!invSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final inventory = invSnapshot.data!;
                  final totals = _calculateTotals(menu, allRecipes, inventory);

                  if (totals.isEmpty) {
                    return const Center(child: Text("No hay ingredientes esta semana"));
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: totals.length,
                          itemBuilder: (context, index) {
                            final item = totals[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.shopping_cart),
                                title: Text(item['name'], style: const TextStyle(fontSize: 18)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Necesario: ${(item['compra'] as num).toDouble().toStringAsFixed(2)} ${item['purchaseUnit']}",
                                        style: const TextStyle(fontSize: 14)),
                                    Text("Inventario: ${(item['inventario'] as num).toDouble().toStringAsFixed(2)}",
                                        style: const TextStyle(fontSize: 14)),
                                    Text("Pedido: ${(item['pedido'] as num).toDouble().toStringAsFixed(2)} ${item['purchaseUnit']}",
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Confirmar pedido"),
                              content: const Text(
                                "¿Seguro que quieres realizar el pedido?\n\n"
                                    "Se eliminarán del inventario los ingredientes utilizados "
                                    "para este menú semanal.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancelar"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Confirmar"),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            final Map<String, double> consumido = {
                              for (final item in totals)
                                if ((item['compra'] as num).toDouble() > 0)
                                  (item['ingredientId'] as String): (item['compra'] as num).toDouble()
                            };

                            await _inventoryService.resetQuantities(userId, consumido);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Pedido realizado ✅")),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.check),
                        label: const Text("Pedido realizado"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 🔹 Normalizar nombres
  String _normalizeName(String name) {
    var n = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
    if (n.endsWith('s')) n = n.substring(0, n.length - 1);
    return n;
  }

  /// 🔹 Calcular totales con inventario
  List<Map<String, dynamic>> _calculateTotals(
      Menu menu,
      List<Recipe> allRecipes,
      List<InventoryItem> inventory,
      ) {
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
            final inv = inventory.firstWhere(
                  (i) => i.ingredientId == ing.ingredientId,
              orElse: () => InventoryItem(
                id: "",
                ingredientId: ing.ingredientId,
                name: ing.name,
                quantity: 0,
                unit: ing.purchaseUnit,
                lastUpdated: DateTime.now(),
                userId: menu.userId,
              ),
            );

            totals[key] = {
              'ingredientId': ing.ingredientId,
              'name': _normalizeName(ing.name),
              'unit': ing.unit,
              'purchaseUnit': ing.purchaseUnit,
              'base': totalBase,
              'compra': totalCompra,
              'inventario': (inv.quantity as num).toDouble(),
              'pedido': 0.0,
            };
          }
        }
      }
    });

    // calcular pedido = compra - inventario
    for (final item in totals.values) {
      final inventario = (item['inventario'] as num).toDouble();
      final compra = (item['compra'] as num).toDouble();
      item['pedido'] = (compra - inventario).clamp(0, double.infinity);
    }

    final list = totals.values.toList();
    list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return list.map((item) {
      final name = item['name'] as String;
      return {
        ...item,
        'name': name.isEmpty ? name : name[0].toUpperCase() + name.substring(1),
      };
    }).toList();
  }

  /// 🔹 Generar PDF con inventario
  Future<pw.Document> _generatePdf(String userId) async {
    final pdf = pw.Document();
    final menu = await _menuService.getMenuForWeek(userId, weekStart).first;

    if (menu == null) {
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Center(child: pw.Text("No hay menú esta semana")),
        ),
      );
      return pdf;
    }

    final recipes = await _recipeService.getRecipesByUser(userId).first;
    final inventory = await _inventoryService.getInventory(userId).first;
    final totals = _calculateTotals(menu, recipes, inventory);

    if (totals.isEmpty) {
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Center(child: pw.Text("No hay ingredientes para este pedido")),
        ),
      );
      return pdf;
    }

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

            // Ingredientes por receta y día
            ...menu.dailyRecipes.entries.expand((entry) {
              final day = entry.key;
              final recipeIds = entry.value;
              return recipeIds.map((recipeId) {
                final recipe = recipes.firstWhere(
                      (r) => r.id == recipeId,
                  orElse: () => Recipe(id: "", name: "?", ingredients: [], userId: menu.userId),
                );
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
            pw.Text("Totales consolidados (con inventario)",
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),

            pw.TableHelper.fromTextArray(
              headers: ["Ingrediente", "Base", "Unidad", "Compra", "Inventario", "Pedido", "Unidad compra"],
              data: totals.map((item) {
                return [
                  item['name'],
                  (item['base'] as num).toDouble().toStringAsFixed(2),
                  item['unit'],
                  (item['compra'] as num).toDouble().toStringAsFixed(2),
                  (item['inventario'] as num).toDouble().toStringAsFixed(2),
                  (item['pedido'] as num).toDouble().toStringAsFixed(2),
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

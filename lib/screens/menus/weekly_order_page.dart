import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

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
    final weekEnd = weekStart.add(const Duration(days: 6));
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');

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
                final startStr = dateFormat.format(weekStart).replaceAll('/', '-');
                final endStr = dateFormat.format(weekEnd).replaceAll('/', '-');

                await Printing.layoutPdf(
                  onLayout: (format) async => bytes,
                  name: "Pedido_${startStr}_a_${endStr}",
                );
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

                  return ListView.builder(
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
                              Text(
                                "Necesario: ${(item['compra'] as num).toDouble().toStringAsFixed(2)} ${item['purchaseUnit']}",
                              ),
                              Text(
                                "Inventario: ${(item['inventario'] as num).toDouble().toStringAsFixed(2)} ${item['purchaseUnit']}",
                              ),
                              Text(
                                "PEDIR: ${(item['pedido'] as num).toDouble().toStringAsFixed(2)} ${item['purchaseUnit']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ---- Helpers ----

  String _normalizeName(String name) {
    var n = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
    if (n.endsWith('s')) n = n.substring(0, n.length - 1);
    return n;
  }

  List<Map<String, dynamic>> _calculateTotals(
      Menu menu, List<Recipe> allRecipes, List<InventoryItem> inventory) {
    final Map<String, Map<String, dynamic>> totals = {};

    menu.dailyRecipes.forEach((day, recipeIds) {
      final estInf = menu.estimatedChildrenInfantilPerDay[day] ?? 0;
      final estPrim = menu.estimatedChildrenPrimariaPerDay[day] ?? 0;

      for (final recipeId in recipeIds) {
        final recipe = allRecipes.firstWhere(
              (r) => r.id == recipeId,
          orElse: () => Recipe(id: "", name: "?", ingredients: [], userId: menu.userId),
        );

        for (final ing in recipe.ingredients) {
          final key = "${_normalizeName(ing.name)}-${ing.unit}-${ing.purchaseUnit}";
          final totalInf = ing.totalInfantilInPurchaseUnit(estInf);
          final totalPrim = ing.totalPrimariaInPurchaseUnit(estPrim);
          final totalCompra = totalInf + totalPrim;

          if (totals.containsKey(key)) {
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
              'purchaseUnit': ing.purchaseUnit,
              'compra': totalCompra,
              'inventario': (inv.quantity as num).toDouble(),
              'pedido': 0.0,
            };
          }
        }
      }
    });

    for (final item in totals.values) {
      final inv = (item['inventario'] as num).toDouble();
      final compra = (item['compra'] as num).toDouble();
      item['pedido'] = (compra - inv).clamp(0, double.infinity);
    }

    final list = totals.values.toList();
    list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return list;
  }

  // ---- PDF ----

  Future<pw.Document> _generatePdf(String userId) async {
    final pdf = pw.Document();
    final dateFormatRange = DateFormat('dd/MM/yyyy', 'es_ES');
    final dateFormatDay = DateFormat("EEEE d 'de' MMMM", 'es_ES');
    final weekEnd = weekStart.add(const Duration(days: 6));

    final menu = await _menuService.getMenuForWeek(userId, weekStart).first;
    if (menu == null) {
      pdf.addPage(pw.Page(build: (_) => pw.Center(child: pw.Text("No hay menú esta semana"))));
      return pdf;
    }

    final recipes = await _recipeService.getRecipesByUser(userId).first;
    final inventory = await _inventoryService.getInventory(userId).first;
    final totals = _calculateTotals(menu, recipes, inventory);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          final totalDays = menu.feFin.difference(menu.feInicio).inDays + 1;
          final List<pw.Widget> dayWidgets = [];

          for (int i = 0; i < totalDays; i++) {
            final currentDate = menu.feInicio.add(Duration(days: i));
            final dayName = DateFormat('EEEE', 'es_ES').format(currentDate).capitalize();
            final recipeIds = menu.dailyRecipes[dayName] ?? [];
            if (recipeIds.isEmpty) continue;

            final estInf = menu.estimatedChildrenInfantilPerDay[dayName] ?? 0;
            final estPrim = menu.estimatedChildrenPrimariaPerDay[dayName] ?? 0;

            dayWidgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Text(
                  "$dayName (${dateFormatDay.format(currentDate)})",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.deepOrange800,
                  ),
                ),
              ),
            );

            for (final recipeId in recipeIds) {
              final recipe = recipes.firstWhere(
                    (r) => r.id == recipeId,
                orElse: () => Recipe(id: "", name: "?", ingredients: [], userId: menu.userId),
              );

              double totalCrudoInf = 0;
              double totalCocinadoInf = 0;
              double totalCrudoPrim = 0;
              double totalCocinadoPrim = 0;

              final ingredientWidgets = recipe.ingredients.map((ing) {
                final infCrudo = ing.amountPerChildInfantil;
                final infCocinado = ing.amountPerChildInfantil * ing.cookingFactor;
                final primCrudo = ing.amountPerChildPrimaria;
                final primCocinado = ing.amountPerChildPrimaria * ing.cookingFactor;

                totalCrudoInf += infCrudo;
                totalCocinadoInf += infCocinado;
                totalCrudoPrim += primCrudo;
                totalCocinadoPrim += primCocinado;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(left: 12, bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("• ${ing.name}", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                      pw.Text("   Infantil → Crudo: ${infCrudo.toStringAsFixed(1)}${ing.unit} | Cocinado: ${infCocinado.toStringAsFixed(1)}${ing.unit}",
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.purple800)),
                      pw.Text("   Primaria → Crudo: ${primCrudo.toStringAsFixed(1)}${ing.unit} | Cocinado: ${primCocinado.toStringAsFixed(1)}${ing.unit}",
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.blue800)),
                    ],
                  ),
                );
              }).toList();

              dayWidgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(left: 10, bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("- ${recipe.name}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      ...ingredientWidgets,
                      pw.SizedBox(height: 4),
                      pw.Text("TOTAL PESO INGREDIENTES CRUDOS (por niño)",
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                      pw.Text("   Infantil: ${totalCrudoInf.toStringAsFixed(1)} g"),
                      pw.Text("   Primaria: ${totalCrudoPrim.toStringAsFixed(1)} g"),
                      pw.SizedBox(height: 4),
                      pw.Text("GRAMAJE DE PLATO FINAL SERVIDO (por niño)",
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                      pw.Text("   Infantil: ${totalCocinadoInf.toStringAsFixed(1)} g"),
                      pw.Text("   Primaria: ${totalCocinadoPrim.toStringAsFixed(1)} g"),
                      pw.SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            }
          }

          return [
            pw.Center(
              child: pw.Text(
                "PEDIDO SEMANAL",
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
              ),
            ),
            pw.Center(
              child: pw.Text(
                "${dateFormatRange.format(weekStart)} - ${dateFormatRange.format(weekEnd)}",
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
            ),
            pw.SizedBox(height: 20),
            ...dayWidgets,
            pw.SizedBox(height: 20),
            pw.Text("Totales consolidados (con inventario)",
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ["Ingrediente", "Necesario", "Inventario", "PEDIR"],
              data: totals.map((item) {
                return [
                  item['name'],
                  "${(item['compra'] as num).toDouble().toStringAsFixed(2)} ${item['purchaseUnit']}",
                  "${(item['inventario'] as num).toDouble().toStringAsFixed(2)} ${item['purchaseUnit']}",
                  "${(item['pedido'] as num).toDouble().toStringAsFixed(2)} ${item['purchaseUnit']}",
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 11),
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
            ),
          ];
        },
      ),
    );

    return pdf;
  }
}

extension _Cap on String {
  String capitalize() => isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
}

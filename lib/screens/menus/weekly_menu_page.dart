import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/menu.dart';
import '../../models/recipe.dart';
import '../../services/menu_service.dart';
import '../recipes/recipe_detail_page.dart';
import '../menus/weekly_order_page.dart';
import '../menus/daily_comparison_page.dart';
import '../../services/recipe_service.dart';

class WeeklyMenuPage extends StatefulWidget {
  final Menu menu;

  const WeeklyMenuPage({super.key, required this.menu});

  @override
  State<WeeklyMenuPage> createState() => _WeeklyMenuPageState();
}

class _WeeklyMenuPageState extends State<WeeklyMenuPage> {
  final MenuService _menuService = MenuService();
  final RecipeService _recipeService = RecipeService();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  static const List<String> _days = [
    "Lunes", "Martes", "Miércoles", "Jueves", "Viernes"
  ];

  late DateTime weekStart;

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  void initState() {
    super.initState();
    weekStart = widget.menu.weekStart;
  }

  void _addRecipeDialog(String day) async {
    String query = "";
    final recipe = await showDialog<Recipe>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Añadir receta"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Buscar receta",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) =>
                        setState(() => query = val.toLowerCase()),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 250,
                    width: 300,
                    child: StreamBuilder<List<Recipe>>(
                      stream: _recipeService.getRecipesByUser(userId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final recipes = snapshot.data!
                            .where((r) => r.name.toLowerCase().contains(query))
                            .toList();

                        if (recipes.isEmpty) {
                          return const Center(child: Text("No hay coincidencias"));
                        }

                        return ListView.separated(
                          itemCount: recipes.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) {
                            final r = recipes[i];
                            return ListTile(
                              title: Text(r.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.add, color: Colors.green),
                                onPressed: () =>
                                    Navigator.pop(context, r),
                              ),
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

    if (recipe != null) {
      await _menuService.addRecipeIdToDay(
        userId: userId,
        weekStart: weekStart,
        day: day,
        recipeId: recipe.id,
      );
    }
  }

  void _editChildrenDialog(String day, int currentChildren,
      {bool isActual = false}) {
    final numCtrl = TextEditingController(
      text: currentChildren > 0 ? currentChildren.toString() : "",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActual
            ? "Editar nº de niños reales ($day)"
            : "Editar nº de niños estimados ($day)"),
        content: TextField(
          controller: numCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Número de niños"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final numChildren = int.tryParse(numCtrl.text) ?? 0;
              if (isActual) {
                await _menuService.updateActualChildren(
                  userId: userId,
                  weekStart: weekStart,
                  day: day,
                  numChildren: numChildren,
                );
              } else {
                await _menuService.updateEstimatedChildren(
                  userId: userId,
                  weekStart: weekStart,
                  day: day,
                  numChildren: numChildren,
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangoFechas =
        "${_formatDate(widget.menu.feInicio)} - ${_formatDate(widget.menu.feFin)}";

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.menu.name),
            Text(
              rangoFechas,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: "Ver pedido semanal",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WeeklyOrderPage(weekStart: weekStart),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Menu?>(
        stream: _menuService.getMenuForWeek(userId, weekStart),
        builder: (context, menuSnapshot) {
          if (!menuSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final menu = menuSnapshot.data;
          if (menu == null) {
            return const Center(child: Text("No hay menú creado para esta semana"));
          }

          return StreamBuilder<List<Recipe>>(
            stream: _recipeService.getRecipesByUser(userId),
            builder: (context, recipeSnapshot) {
              if (!recipeSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final allRecipes = recipeSnapshot.data!;

              return ListView(
                children: _days.map((day) {
                  final recipeIds = List<String>.from(menu.dailyRecipes[day] ?? []);
                  final recipes = allRecipes.where((r) => recipeIds.contains(r.id)).toList();

                  final estChildren = menu.estimatedChildrenPerDay[day] ?? 0;
                  final actChildren = menu.actualChildrenPerDay[day] ?? 0;

                  return ExpansionTile(
                    title: Text(day),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text("Estimados: $estChildren")),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _editChildrenDialog(day, estChildren, isActual: false),
                            ),
                            Expanded(child: Text("Reales: $actChildren")),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              onPressed: () => _editChildrenDialog(day, actChildren, isActual: true),
                            ),
                            IconButton(
                              icon: const Icon(Icons.bar_chart, color: Colors.blue),
                              tooltip: "Comparar día",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DailyComparisonPage(menu: menu, day: day),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recipes.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final recipe = recipes[i];
                          return ListTile(
                            title: Text(recipe.name, style: const TextStyle(fontSize: 18)),
                            subtitle: Text("${recipe.ingredients.length} ingredientes"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RecipeDetailPage(recipe: recipe),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _menuService.removeRecipeIdFromDay(
                                      userId: userId,
                                      weekStart: weekStart,
                                      day: day,
                                      recipeId: recipe.id,
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      TextButton.icon(
                        onPressed: () => _addRecipeDialog(day),
                        icon: const Icon(Icons.add),
                        label: const Text("Añadir receta"),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}

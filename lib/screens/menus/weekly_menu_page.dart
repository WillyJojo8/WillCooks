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

  /// 🔹 Diálogo para editar niños de un grupo
  void _editChildrenDialog(String day, int currentChildren, String grupo,
      {bool isActual = false}) {
    final numCtrl = TextEditingController(
      text: currentChildren > 0 ? currentChildren.toString() : "",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            "${isActual ? "Niños reales" : "Niños estimados"} ($grupo - $day)"),
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
              final numChildren = int.tryParse(numCtrl.text) ?? -1;

              if (numChildren < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Introduce un número válido de niños")),
                );
                return;
              }

              if (isActual) {
                await _menuService.updateActualChildren(
                  userId: userId,
                  weekStart: weekStart,
                  day: day,
                  grupo: grupo.toLowerCase(),
                  numChildren: numChildren,
                );
              } else {
                await _menuService.updateEstimatedChildren(
                  userId: userId,
                  weekStart: weekStart,
                  day: day,
                  grupo: grupo.toLowerCase(),
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

  /// 🔹 Diálogo para añadir receta
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
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final recipes = snapshot.data!
                            .where(
                                (r) => r.name.toLowerCase().contains(query))
                            .toList();

                        if (recipes.isEmpty) {
                          return const Center(
                              child: Text("No hay coincidencias"));
                        }

                        return ListView.separated(
                          itemCount: recipes.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) {
                            final r = recipes[i];
                            return ListTile(
                              title: Text(r.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.add,
                                    color: Colors.green),
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
            return const Center(
                child: Text("No hay menú creado para esta semana"));
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
                  final recipeIds =
                  List<String>.from(menu.dailyRecipes[day] ?? []);
                  final recipes = allRecipes
                      .where((r) => recipeIds.contains(r.id))
                      .toList();

                  final estInf =
                      menu.estimatedChildrenInfantilPerDay[day] ?? 0;
                  final estPrim =
                      menu.estimatedChildrenPrimariaPerDay[day] ?? 0;
                  final actInf =
                      menu.actualChildrenInfantilPerDay[day] ?? 0;
                  final actPrim =
                      menu.actualChildrenPrimariaPerDay[day] ?? 0;

                  return ExpansionTile(
                    title: Text(day,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// 🔹 Sección Infantil
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("👶 Infantil",
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueAccent)),
                                  Row(
                                    children: [
                                      Expanded(
                                          child:
                                          Text("Estimados: $estInf")),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.orange),
                                        onPressed: () => _editChildrenDialog(
                                            day, estInf, "Infantil",
                                            isActual: false),
                                      ),
                                      Expanded(
                                          child: Text("Reales: $actInf")),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.green),
                                        onPressed: () => _editChildrenDialog(
                                            day, actInf, "Infantil",
                                            isActual: true),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            /// 🔹 Sección Primaria
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("🧒 Primaria",
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange)),
                                  Row(
                                    children: [
                                      Expanded(
                                          child:
                                          Text("Estimados: $estPrim")),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.orange),
                                        onPressed: () => _editChildrenDialog(
                                            day, estPrim, "Primaria",
                                            isActual: false),
                                      ),
                                      Expanded(
                                          child: Text("Reales: $actPrim")),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.green),
                                        onPressed: () => _editChildrenDialog(
                                            day, actPrim, "Primaria",
                                            isActual: true),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            /// 🔹 Botón de comparación del día completo
                            Center(
                              child: IconButton(
                                icon: const Icon(Icons.bar_chart,
                                    color: Colors.blue, size: 30),
                                tooltip: "Comparar día completo",
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DailyComparisonPage(
                                          menu: menu, day: day),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 🔹 Listado de recetas del día
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recipes.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final recipe = recipes[i];
                          return ListTile(
                            title: Text(recipe.name,
                                style: const TextStyle(fontSize: 18)),
                            subtitle: Text(
                                "${recipe.ingredients.length} ingredientes"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RecipeDetailPage(
                                            recipe: recipe),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
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

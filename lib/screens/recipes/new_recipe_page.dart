import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../models/ingredient_base.dart';
import '../../services/recipe_service.dart';
import '../../services/ingredient_base_service.dart';
import '../../utils/units.dart';

class NewRecipePage extends StatefulWidget {
  const NewRecipePage({super.key});

  @override
  State<NewRecipePage> createState() => _NewRecipePageState();
}

class _NewRecipePageState extends State<NewRecipePage> {
  final _nameController = TextEditingController();
  final List<Ingredient> _ingredients = [];
  final RecipeService _recipeService = RecipeService();
  final IngredientBaseService _ingredientBaseService = IngredientBaseService();

  /// 🔹 Diálogo para añadir o editar un ingrediente (solo lupa para base)
  void _ingredientDialog({int? index, Ingredient? ing}) async {
    final bases = await _ingredientBaseService.getAll().first;

    IngredientBase? selectedBase;
    if (ing != null) {
      selectedBase = bases.firstWhere(
            (b) => b.id == ing.ingredientId,
        orElse: () => bases.first,
      );
    }

    final baseNameCtrl = TextEditingController(text: selectedBase?.name ?? "");
    final amountInfantilCtrl =
    TextEditingController(text: ing?.amountPerChildInfantil.toString() ?? "");
    final amountPrimariaCtrl =
    TextEditingController(text: ing?.amountPerChildPrimaria.toString() ?? "");
    final cookingFactorCtrl =
    TextEditingController(text: ing?.cookingFactor.toString() ?? "1");

    // Sigues guardando String en BD
    final unitCtrl =
    TextEditingController(text: ing?.unit ?? (selectedBase?.defaultUnit ?? "g"));
    final purchaseUnitCtrl = TextEditingController(
        text: ing?.purchaseUnit ?? (selectedBase?.purchaseUnit ?? "kg"));
    final factorCtrl =
    TextEditingController(text: ing?.conversionFactor.toString() ?? "");
    final densityCtrl =
    TextEditingController(text: ing?.density?.toString() ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          // estado local para selects
          Unit selectedUnit = parseUnit(unitCtrl.text) ?? Unit.g;
          Unit selectedPurchase = parseUnit(purchaseUnitCtrl.text) ?? Unit.kg;

          void refreshFactor() {
            final d = double.tryParse(densityCtrl.text);
            final f = computeConversionFactor(
              unit: selectedUnit,
              purchaseUnit: selectedPurchase,
              densityGPerMl: d,
            );
            factorCtrl.text = (f == null) ? "" : trimDouble(f);
          }

          if (factorCtrl.text.isEmpty) refreshFactor();
          final needsDensity = isCrossType(selectedUnit, selectedPurchase);

          return AlertDialog(
            title: Text(index == null ? "Nuevo ingrediente" : "Editar ingrediente"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔍 Solo buscador (sin dropdown de lista)
                  TextField(
                    controller: baseNameCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Ingrediente base",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        tooltip: "Buscar ingrediente",
                        onPressed: () async {
                          final picked = await showSearch<IngredientBase?>(
                            context: context,
                            delegate: _PickIngredientBaseDelegate(bases),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              selectedBase = picked;
                              baseNameCtrl.text = picked.name;
                              unitCtrl.text = picked.defaultUnit;
                              purchaseUnitCtrl.text = picked.purchaseUnit;
                              densityCtrl.text = picked.density?.toString() ?? "";
                              selectedUnit = parseUnit(unitCtrl.text) ?? Unit.g;
                              selectedPurchase =
                                  parseUnit(purchaseUnitCtrl.text) ?? Unit.kg;
                              refreshFactor();
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  // Cantidades por niño
                  TextField(
                    controller: amountInfantilCtrl,
                    decoration: const InputDecoration(
                      labelText: "Cantidad por niño Infantil (crudo)",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: amountPrimariaCtrl,
                    decoration: const InputDecoration(
                      labelText: "Cantidad por niño Primaria (crudo)",
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  // Rendimiento de cocción (renombrado)
                  TextField(
                    controller: cookingFactorCtrl,
                    decoration: const InputDecoration(
                      labelText: "Factor de conversión (cocinado)",
                      helperText: "Relación peso final / crudo. 1.0 = sin cambio",
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 8),

                  // Select: Unidad
                  DropdownButtonFormField<Unit>(
                    value: selectedUnit,
                    items: Unit.values
                        .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                        .toList(),
                    onChanged: (u) {
                      setStateDialog(() {
                        selectedUnit = u ?? selectedUnit;
                        unitCtrl.text = unitToString(selectedUnit); // guardas String
                        refreshFactor();
                      });
                    },
                    decoration: const InputDecoration(labelText: "Unidad"),
                  ),

                  // Select: Unidad de compra
                  DropdownButtonFormField<Unit>(
                    value: selectedPurchase,
                    items: Unit.values
                        .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                        .toList(),
                    onChanged: (u) {
                      setStateDialog(() {
                        selectedPurchase = u ?? selectedPurchase;
                        purchaseUnitCtrl.text = unitToString(selectedPurchase); // String
                        refreshFactor();
                      });
                    },
                    decoration: const InputDecoration(labelText: "Unidad de compra"),
                  ),

                  // Densidad solo si hay cruce masa↔volumen
                  if (needsDensity)
                    TextField(
                      controller: densityCtrl,
                      decoration: const InputDecoration(
                        labelText: "Densidad (g/ml)",
                        helperText: "Necesaria para masa↔volumen. Ej.: aceite ≈ 0.92",
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setStateDialog(() {
                        refreshFactor();
                      }),
                    ),

                  // Factor auto
                  TextField(
                    controller: factorCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Conversión Unidades",
                      helperText: "Cuántas “unidad” caben en 1 “unidad de compra”",
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
              ElevatedButton(
                onPressed: () {
                  if (selectedBase == null) return;
                  refreshFactor();

                  final newIngredient = Ingredient(
                    ingredientId: selectedBase!.id,
                    name: selectedBase!.name,
                    amountPerChildInfantil:
                    double.tryParse(amountInfantilCtrl.text) ?? 0,
                    amountPerChildPrimaria:
                    double.tryParse(amountPrimariaCtrl.text) ?? 0,
                    cookingFactor: double.tryParse(cookingFactorCtrl.text) ?? 1,
                    unit: unitCtrl.text,
                    purchaseUnit: purchaseUnitCtrl.text,
                    conversionFactor: double.tryParse(factorCtrl.text) ?? 1,
                    density: densityCtrl.text.isNotEmpty
                        ? double.tryParse(densityCtrl.text)
                        : null,
                  );

                  setState(() {
                    if (index == null) {
                      _ingredients.add(newIngredient);
                    } else {
                      _ingredients[index] = newIngredient;
                    }
                  });

                  Navigator.pop(context);
                },
                child: const Text("Guardar"),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _saveRecipe() async {
    if (_nameController.text.isEmpty || _ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Añade un nombre y al menos un ingrediente")),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final recipe = Recipe(
      id: const Uuid().v4(),
      name: _nameController.text,
      ingredients: _ingredients,
      userId: userId,
    );

    await _recipeService.addRecipe(recipe);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Receta")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nombre de la receta"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  final ing = _ingredients[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        "${ing.name} - Inf: ${ing.amountPerChildInfantil}${ing.unit}, "
                            "Prim: ${ing.amountPerChildPrimaria}${ing.unit}",
                      ),
                      subtitle: Text(
                        "Compra en ${ing.purchaseUnit}, "
                            "Conversión: ${ing.conversionFactor}, "
                            "Rendimiento: ${ing.cookingFactor}"
                            "${ing.density != null ? ", Densidad: ${ing.density}" : ""}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _ingredientDialog(index: index, ing: ing),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => _ingredients.removeAt(index)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FloatingActionButton(
                heroTag: "btnIngrediente",
                onPressed: () => _ingredientDialog(),
                child: const Icon(Icons.add),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveRecipe, child: const Text("Guardar receta")),
          ],
        ),
      ),
    );
  }
}

/// 🔎 Buscador de ingredientes base
class _PickIngredientBaseDelegate extends SearchDelegate<IngredientBase?> {
  final List<IngredientBase> bases;
  _PickIngredientBaseDelegate(this.bases);

  @override
  List<Widget>? buildActions(BuildContext context) =>
      [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(onPressed: () => close(context, null), icon: const Icon(Icons.arrow_back));

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final q = query.trim().toLowerCase();
    final items = bases.where((b) => b.name.toLowerCase().contains(q)).toList();
    if (items.isEmpty) {
      return const Center(child: Text("No hay coincidencias"));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final b = items[i];
        return ListTile(
          title: Text(b.name),
          subtitle: Text(
            "Unidad: ${b.defaultUnit}  •  Compra: ${b.purchaseUnit}"
                "${b.density != null ? "  •  dens: ${b.density}" : ""}",
          ),
          onTap: () => close(context, b),
        );
      },
    );
  }
}

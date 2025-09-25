import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../models/ingredient_base.dart';
import '../../services/recipe_service.dart';
import '../../services/ingredient_base_service.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final RecipeService _recipeService = RecipeService();
  final IngredientBaseService _ingredientBaseService = IngredientBaseService();

  late List<Ingredient> _ingredients;
  late String _recipeName;

  @override
  void initState() {
    super.initState();
    _ingredients = List.from(widget.recipe.ingredients);
    _recipeName = widget.recipe.name;
  }

  Future<void> _saveRecipe() async {
    final updatedRecipe = Recipe(
      id: widget.recipe.id,
      name: _recipeName,
      userId: widget.recipe.userId,
      ingredients: _ingredients,
    );
    await _recipeService.addRecipe(updatedRecipe);
  }

  /// 🔹 Diálogo añadir/editar ingrediente
  void _ingredientDialog({int? index, Ingredient? ing}) async {
    final bases = await _ingredientBaseService.getAll().first;

    IngredientBase? selectedBase;
    if (ing != null) {
      selectedBase = bases.firstWhere(
            (b) => b.id == ing.ingredientId,
        orElse: () => bases.first,
      );
    }

    final amountCtrl =
    TextEditingController(text: ing?.amountPerChild.toString() ?? "");
    final unitCtrl = TextEditingController(text: ing?.unit ?? "");
    final purchaseUnitCtrl =
    TextEditingController(text: ing?.purchaseUnit ?? "");
    final factorCtrl =
    TextEditingController(text: ing?.conversionFactor.toString() ?? "");
    final densityCtrl =
    TextEditingController(text: ing?.density?.toString() ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(index == null
                  ? "Nuevo ingrediente"
                  : "Editar ingrediente"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<IngredientBase>(
                      initialValue : selectedBase,
                      items: bases
                          .map((b) =>
                          DropdownMenuItem(value: b, child: Text(b.name)))
                          .toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedBase = val;
                          if (val != null) {
                            unitCtrl.text = val.defaultUnit;
                            purchaseUnitCtrl.text = val.purchaseUnit;
                            factorCtrl.text = val.conversionFactor.toString();
                            densityCtrl.text = val.density?.toString() ?? "";
                          }
                        });
                      },
                      decoration:
                      const InputDecoration(labelText: "Ingrediente base"),
                    ),
                    TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(
                          labelText: "Cantidad por niño"),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: unitCtrl,
                      decoration: const InputDecoration(labelText: "Unidad"),
                    ),
                    TextField(
                      controller: purchaseUnitCtrl,
                      decoration:
                      const InputDecoration(labelText: "Unidad de compra"),
                    ),
                    TextField(
                      controller: factorCtrl,
                      decoration: const InputDecoration(
                          labelText: "Factor de conversión"),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: densityCtrl,
                      decoration: const InputDecoration(
                          labelText: "Densidad (opcional)"),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedBase == null) return;

                    final newIngredient = Ingredient(
                      ingredientId: selectedBase!.id,
                      name: selectedBase!.name,
                      amountPerChild: double.tryParse(amountCtrl.text) ?? 0,
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

                    await _saveRecipe();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 🔹 Botón rápido: añadir Aceite
  void _addAceite() async {
    final aceite = Ingredient(
      ingredientId: "aceite",
      name: "Aceite",
      amountPerChild: 0,
      unit: "g",
      purchaseUnit: "L",
      conversionFactor: 920,
      density: 0.92,
    );

    setState(() => _ingredients.add(aceite));
    await _saveRecipe();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingrediente Aceite añadido ✅")),
      );
    }
  }

  void _deleteIngredient(int index) async {
    setState(() => _ingredients.removeAt(index));
    await _saveRecipe();
  }

  /// 🔹 Diálogo para renombrar receta
  Future<void> _renameRecipe() async {
    final controller = TextEditingController(text: _recipeName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Renombrar receta"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Nuevo nombre"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      setState(() => _recipeName = newName.trim());
      await _saveRecipe();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Receta renombrada a '$newName' ✅")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _recipeName,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Renombrar",
            onPressed: _renameRecipe,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  final ing = _ingredients[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                          "${ing.name} - ${ing.amountPerChild}${ing.unit}"),
                      subtitle: Text("Compra en ${ing.purchaseUnit}, "
                          "Factor: ${ing.conversionFactor}"
                          "${ing.density != null ? ", Densidad: ${ing.density}" : ""}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _ingredientDialog(index: index, ing: ing),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteIngredient(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  heroTag: "btnIngredienteDetalle",
                  onPressed: () => _ingredientDialog(),
                  child: const Icon(Icons.add),
                ),
                ElevatedButton(
                  onPressed: _addAceite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                  child: const Text("Aceite",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../models/ingredient_base.dart';
import '../../services/recipe_service.dart';
import '../../services/ingredient_base_service.dart';

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

  /// 🔹 Diálogo para añadir o editar un ingrediente
  void _ingredientDialog({int? index, Ingredient? ing}) async {
    final bases = await _ingredientBaseService.getAll().first;

    IngredientBase? selectedBase;
    if (ing != null) {
      // buscamos el base original si coincide
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
              title: Text(index == null ? "Nuevo ingrediente" : "Editar ingrediente"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<IngredientBase>(
                      value: selectedBase,
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
                      decoration: const InputDecoration(labelText: "Unidad de compra"),
                    ),
                    TextField(
                      controller: factorCtrl,
                      decoration: const InputDecoration(labelText: "Factor de conversión"),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: densityCtrl,
                      decoration: const InputDecoration(labelText: "Densidad (opcional)"),
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
                  onPressed: () {
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

                    Navigator.pop(context);
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
  void _addAceite() {
    setState(() {
      _ingredients.add(Ingredient(
        ingredientId: const Uuid().v4(),
        name: "Aceite",
        amountPerChild: 0,
        unit: "g",
        purchaseUnit: "L",
        conversionFactor: 920,
        density: 0.92,
      ));
    });
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
              decoration:
              const InputDecoration(labelText: "Nombre de la receta"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  final ing = _ingredients[index];
                  return Card(
                    child: ListTile(
                      title: Text("${ing.name} - ${ing.amountPerChild}${ing.unit}"),
                      subtitle: Text("Compra en ${ing.purchaseUnit}, "
                          "Factor: ${ing.conversionFactor}"
                          "${ing.density != null ? ", Densidad: ${ing.density}" : ""}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _ingredientDialog(index: index, ing: ing),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => _ingredients.removeAt(index)),
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
                  heroTag: "btnIngrediente",
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
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _saveRecipe, child: const Text("Guardar receta")),
          ],
        ),
      ),
    );
  }
}

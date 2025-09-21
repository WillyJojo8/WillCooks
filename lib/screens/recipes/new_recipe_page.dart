import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../services/recipe_service.dart';

class NewRecipePage extends StatefulWidget {
  const NewRecipePage({super.key});

  @override
  State<NewRecipePage> createState() => _NewRecipePageState();
}

class _NewRecipePageState extends State<NewRecipePage> {
  final _nameController = TextEditingController();
  final List<Ingredient> _ingredients = [];
  final RecipeService _recipeService = RecipeService();

  void _addIngredientDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final purchaseUnitCtrl = TextEditingController();
    final conversionCtrl = TextEditingController();
    final densityCtrl = TextEditingController(); // ✅ nuevo

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuevo ingrediente"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nombre")),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: "Cantidad por niño"), keyboardType: TextInputType.number),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: "Unidad (ej. g, ml)")),
              TextField(controller: purchaseUnitCtrl, decoration: const InputDecoration(labelText: "Unidad de compra (ej. kg, L)")),
              TextField(controller: conversionCtrl, decoration: const InputDecoration(labelText: "Factor de conversión (ej. 1000)"), keyboardType: TextInputType.number),
              TextField(controller: densityCtrl, decoration: const InputDecoration(labelText: "Densidad (opcional)"), keyboardType: TextInputType.number), // ✅ nuevo
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Añadir"),
            onPressed: () {
              if (nameCtrl.text.isEmpty || amountCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Completa al menos nombre y cantidad")),
                );
                return;
              }

              setState(() {
                _ingredients.add(Ingredient(
                  ingredientId: const Uuid().v4(),
                  name: nameCtrl.text,
                  amountPerChild: double.tryParse(amountCtrl.text) ?? 0,
                  unit: unitCtrl.text,
                  purchaseUnit: purchaseUnitCtrl.text,
                  conversionFactor: double.tryParse(conversionCtrl.text) ?? 1,
                  density: densityCtrl.text.isNotEmpty
                      ? double.tryParse(densityCtrl.text)
                      : null,
                ));
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _editIngredientDialog(int index, Ingredient ing) {
    final nameCtrl = TextEditingController(text: ing.name);
    final amountCtrl = TextEditingController(text: ing.amountPerChild.toString());
    final unitCtrl = TextEditingController(text: ing.unit);
    final purchaseUnitCtrl = TextEditingController(text: ing.purchaseUnit);
    final conversionCtrl = TextEditingController(text: ing.conversionFactor.toString());
    final densityCtrl = TextEditingController(text: ing.density?.toString() ?? ""); // ✅ nuevo

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar ingrediente"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nombre")),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: "Cantidad por niño"), keyboardType: TextInputType.number),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: "Unidad (ej. g, ml)")),
              TextField(controller: purchaseUnitCtrl, decoration: const InputDecoration(labelText: "Unidad de compra (ej. kg, L)")),
              TextField(controller: conversionCtrl, decoration: const InputDecoration(labelText: "Factor de conversión (ej. 1000)"), keyboardType: TextInputType.number),
              TextField(controller: densityCtrl, decoration: const InputDecoration(labelText: "Densidad (opcional)"), keyboardType: TextInputType.number), // ✅ nuevo
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Guardar cambios"),
            onPressed: () {
              setState(() {
                _ingredients[index] = Ingredient(
                  ingredientId: ing.ingredientId, // mantener el mismo ID
                  name: nameCtrl.text,
                  amountPerChild: double.tryParse(amountCtrl.text) ?? 0,
                  unit: unitCtrl.text,
                  purchaseUnit: purchaseUnitCtrl.text,
                  conversionFactor: double.tryParse(conversionCtrl.text) ?? 1,
                  density: densityCtrl.text.isNotEmpty
                      ? double.tryParse(densityCtrl.text)
                      : null,
                );
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Receta guardada con éxito 🎉")),
      );
      Navigator.pop(context);
    }
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
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(labelText: "Nombre de la receta"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  final ing = _ingredients[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text("${ing.name} - ${ing.amountPerChild}${ing.unit}"),
                      subtitle: Text(
                        "Compra en ${ing.purchaseUnit} (factor ${ing.conversionFactor})"
                            "${ing.density != null ? ", Densidad: ${ing.density}" : ""}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editIngredientDialog(index, ing),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _ingredients.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addIngredientDialog,
              child: const Text("Añadir ingrediente"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveRecipe,
              child: const Text("Guardar receta"),
            ),
          ],
        ),
      ),
    );
  }
}

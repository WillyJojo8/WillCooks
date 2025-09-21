import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../services/recipe_service.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final RecipeService _recipeService = RecipeService();
  late List<Ingredient> _ingredients;
  late String _recipeName;

  @override
  void initState() {
    super.initState();
    _ingredients = List.from(widget.recipe.ingredients); // copia editable
    _recipeName = widget.recipe.name;
  }

  /// 🔹 Guardar receta completa en Firestore
  Future<void> _saveRecipe() async {
    final updatedRecipe = Recipe(
      id: widget.recipe.id,
      name: _recipeName,
      userId: widget.recipe.userId,
      ingredients: _ingredients,
    );
    await _recipeService.addRecipe(updatedRecipe);
  }

  /// 🔹 Crear copia de la receta
  Future<void> _duplicateRecipe() async {
    final newRecipe = Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: "Copia de $_recipeName",
      userId: widget.recipe.userId,
      ingredients: List.from(_ingredients),
    );

    await _recipeService.addRecipe(newRecipe);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Copia creada: ${newRecipe.name} ✅")),
      );
    }
  }

  /// 🔹 Diálogo para añadir o editar un ingrediente
  void _ingredientDialog({int? index, Ingredient? ing}) {
    final nameCtrl = TextEditingController(text: ing?.name ?? "");
    final amountCtrl =
    TextEditingController(text: ing?.amountPerChild.toString() ?? "");
    final unitCtrl = TextEditingController(text: ing?.unit ?? "");
    final purchaseUnitCtrl = TextEditingController(text: ing?.purchaseUnit ?? "");
    final conversionCtrl =
    TextEditingController(text: ing?.conversionFactor.toString() ?? "");
    final densityCtrl =
    TextEditingController(text: ing?.density?.toString() ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? "Nuevo ingrediente" : "Editar ${ing!.name}"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nombre")),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: "Cantidad por niño"), keyboardType: TextInputType.number),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: "Unidad (ej: g, ml)")),
              TextField(controller: purchaseUnitCtrl, decoration: const InputDecoration(labelText: "Unidad de compra")),
              TextField(controller: conversionCtrl, decoration: const InputDecoration(labelText: "Factor de conversión"), keyboardType: TextInputType.number),
              TextField(controller: densityCtrl, decoration: const InputDecoration(labelText: "Densidad (opcional)"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final newIngredient = Ingredient(
                ingredientId: ing?.ingredientId ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim(),
                amountPerChild: double.tryParse(amountCtrl.text) ?? 0,
                unit: unitCtrl.text.trim(),
                purchaseUnit: purchaseUnitCtrl.text.trim(),
                conversionFactor: double.tryParse(conversionCtrl.text) ?? 1,
                density: densityCtrl.text.isNotEmpty ? double.tryParse(densityCtrl.text) : null,
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(index == null ? "Ingrediente añadido ✅" : "Ingrediente actualizado ✅")),
              );
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _deleteIngredient(int index) async {
    setState(() {
      _ingredients.removeAt(index);
    });
    await _saveRecipe();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingrediente eliminado ✅")),
      );
    }
  }

  Future<void> _deleteRecipe() async {
    await _recipeService.deleteRecipe(widget.recipe.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Receta eliminada ✅")),
      );
    }
  }

  /// 🔹 Editar nombre de la receta
  void _editRecipeName() {
    final nameCtrl = TextEditingController(text: _recipeName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar nombre de la receta"),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: "Nombre"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              setState(() => _recipeName = nameCtrl.text.trim());
              await _saveRecipe();

              if (context.mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Nombre de receta actualizado ✅")),
              );
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
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
          IconButton(icon: const Icon(Icons.copy, color: Colors.purple), tooltip: "Duplicar receta", onPressed: _duplicateRecipe),
          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: _editRecipeName),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteRecipe),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ingredientes", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  final ing = _ingredients[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.kitchen, size: 36),
                      title: Text(
                        "${ing.name} - ${ing.amountPerChild}${ing.unit} por niño",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Compra en ${ing.purchaseUnit}, Factor: ${ing.conversionFactor}"
                            "${ing.density != null ? ", Densidad: ${ing.density}" : ""}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _ingredientDialog(index: index, ing: ing)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteIngredient(index)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ingredientDialog(), // añadir ingrediente
        child: const Icon(Icons.add),
      ),
    );
  }
}

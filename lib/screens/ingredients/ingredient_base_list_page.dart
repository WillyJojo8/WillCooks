import 'package:flutter/material.dart';
import '../../models/ingredient_base.dart';
import '../../services/ingredient_base_service.dart';

class IngredientBaseListPage extends StatelessWidget {
  final IngredientBaseService _service = IngredientBaseService();

  IngredientBaseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ingredientes Base")),
      body: StreamBuilder<List<IngredientBase>>(
        stream: _service.getAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ingredients = snapshot.data!;
          if (ingredients.isEmpty) {
            return const Center(child: Text("No hay ingredientes base aún"));
          }
          return ListView.builder(
            itemCount: ingredients.length,
            itemBuilder: (context, i) {
              final ing = ingredients[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    ing.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Unidad: ${ing.defaultUnit}, Compra: ${ing.purchaseUnit}, "
                        "Factor: ${ing.conversionFactor}"
                        "${ing.density != null ? ", Densidad: ${ing.density}" : ""}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(context, ing),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, ing),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddDialog(context),
      ),
    );
  }

  /// 🔹 Crear nuevo ingrediente
  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final purchaseUnitCtrl = TextEditingController();
    final factorCtrl = TextEditingController();
    final densityCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nuevo ingrediente base"),
        content: _buildForm(
          nameCtrl: nameCtrl,
          unitCtrl: unitCtrl,
          purchaseUnitCtrl: purchaseUnitCtrl,
          factorCtrl: factorCtrl,
          densityCtrl: densityCtrl,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            child: const Text("Guardar"),
            onPressed: () async {
              final id = nameCtrl.text.toLowerCase().replaceAll(" ", "_");

              // 🔹 Verificamos si ya existe un ingrediente con ese ID
              final existing = await _service.getAll().first;
              final alreadyExists = existing.any((e) => e.id == id);

              if (alreadyExists) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("⚠️ Ya existe un ingrediente con el id '$id'"),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final ing = IngredientBase(
                id: id,
                name: nameCtrl.text,
                defaultUnit: unitCtrl.text,
                purchaseUnit: purchaseUnitCtrl.text,
                conversionFactor: double.tryParse(factorCtrl.text) ?? 1,
                density: densityCtrl.text.isNotEmpty ? double.tryParse(densityCtrl.text) : null,
              );
              await _service.addIngredientBase(ing);
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  /// 🔹 Editar ingrediente existente
  void _showEditDialog(BuildContext context, IngredientBase ing) {
    final nameCtrl = TextEditingController(text: ing.name);
    final unitCtrl = TextEditingController(text: ing.defaultUnit);
    final purchaseUnitCtrl = TextEditingController(text: ing.purchaseUnit);
    final factorCtrl = TextEditingController(text: ing.conversionFactor.toString());
    final densityCtrl = TextEditingController(text: ing.density?.toString() ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Editar ${ing.name}"),
        content: _buildForm(
          nameCtrl: nameCtrl,
          unitCtrl: unitCtrl,
          purchaseUnitCtrl: purchaseUnitCtrl,
          factorCtrl: factorCtrl,
          densityCtrl: densityCtrl,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            child: const Text("Guardar cambios"),
            onPressed: () async {
              final updated = IngredientBase(
                id: ing.id, // 🚨 No cambiamos el id
                name: nameCtrl.text,
                defaultUnit: unitCtrl.text,
                purchaseUnit: purchaseUnitCtrl.text,
                conversionFactor: double.tryParse(factorCtrl.text) ?? 1,
                density: densityCtrl.text.isNotEmpty ? double.tryParse(densityCtrl.text) : null,
              );
              await _service.updateIngredientBase(updated);
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  /// 🔹 Confirmar borrado
  void _confirmDelete(BuildContext context, IngredientBase ing) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar ingrediente"),
        content: Text("¿Seguro que quieres eliminar '${ing.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Eliminar"),
            onPressed: () async {
              await _service.deleteIngredientBase(ing.id);
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  /// 🔹 Formulario común (para crear/editar)
  Widget _buildForm({
    required TextEditingController nameCtrl,
    required TextEditingController unitCtrl,
    required TextEditingController purchaseUnitCtrl,
    required TextEditingController factorCtrl,
    required TextEditingController densityCtrl,
  }) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nombre")),
          TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: "Unidad base (g, ml)")),
          TextField(controller: purchaseUnitCtrl, decoration: const InputDecoration(labelText: "Unidad de compra (kg, L)")),
          TextField(controller: factorCtrl, decoration: const InputDecoration(labelText: "Factor conversión"), keyboardType: TextInputType.number),
          TextField(controller: densityCtrl, decoration: const InputDecoration(labelText: "Densidad (opcional)"), keyboardType: TextInputType.number),
        ],
      ),
    );
  }
}

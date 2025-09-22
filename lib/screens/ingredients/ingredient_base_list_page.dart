import 'package:flutter/material.dart';
import '../../models/ingredient_base.dart';
import '../../services/ingredient_base_service.dart';

class IngredientBaseListPage extends StatefulWidget {
  const IngredientBaseListPage({super.key});

  @override
  State<IngredientBaseListPage> createState() => _IngredientBaseListPageState();
}

class _IngredientBaseListPageState extends State<IngredientBaseListPage> {
  final IngredientBaseService _service = IngredientBaseService();
  String _query = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ingredientes Base"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch<String>(
                context: context,
                delegate: _IngredientBaseSearchDelegate(_service),
              );
              if (result != null) {
                setState(() => _query = result.toLowerCase());
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<IngredientBase>>(
        stream: _service.getAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ingredients = snapshot.data!
              .where((i) => i.name.toLowerCase().contains(_query))
              .toList();

          if (ingredients.isEmpty) {
            return const Center(child: Text("No hay ingredientes base aún"));
          }

          return ListView.builder(
            itemCount: ingredients.length,
            itemBuilder: (context, i) {
              final ing = ingredients[i];
              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    ing.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            child: const Text("Guardar"),
            onPressed: () async {
              final id = nameCtrl.text.toLowerCase().replaceAll(" ", "_");
              final existing = await _service.getAll().first;
              final alreadyExists = existing.any((e) => e.id == id);

              if (alreadyExists) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("⚠️ Ya existe un ingrediente con el id '$id'"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              final ing = IngredientBase(
                id: id,
                name: nameCtrl.text,
                defaultUnit: unitCtrl.text,
                purchaseUnit: purchaseUnitCtrl.text,
                conversionFactor: double.tryParse(factorCtrl.text) ?? 1,
                density: densityCtrl.text.isNotEmpty
                    ? double.tryParse(densityCtrl.text)
                    : null,
              );
              await _service.addIngredientBase(ing);
              if (context.mounted) Navigator.pop(context);
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
    final factorCtrl =
    TextEditingController(text: ing.conversionFactor.toString());
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            child: const Text("Guardar cambios"),
            onPressed: () async {
              final updated = IngredientBase(
                id: ing.id,
                name: nameCtrl.text,
                defaultUnit: unitCtrl.text,
                purchaseUnit: purchaseUnitCtrl.text,
                conversionFactor: double.tryParse(factorCtrl.text) ?? 1,
                density: densityCtrl.text.isNotEmpty
                    ? double.tryParse(densityCtrl.text)
                    : null,
              );
              await _service.updateIngredientBase(updated);
              if (context.mounted) Navigator.pop(context);
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Eliminar"),
            onPressed: () async {
              await _service.deleteIngredientBase(ing.id);
              if (context.mounted) Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  /// 🔹 Formulario común
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
          TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre")),
          TextField(
              controller: unitCtrl,
              decoration:
              const InputDecoration(labelText: "Unidad base (g, ml)")),
          TextField(
              controller: purchaseUnitCtrl,
              decoration: const InputDecoration(labelText: "Unidad de compra (kg, L)")),
          TextField(
              controller: factorCtrl,
              decoration: const InputDecoration(labelText: "Factor conversión"),
              keyboardType: TextInputType.number),
          TextField(
              controller: densityCtrl,
              decoration:
              const InputDecoration(labelText: "Densidad (opcional)"),
              keyboardType: TextInputType.number),
        ],
      ),
    );
  }
}

/// 🔎 SearchDelegate para Ingredientes Base
class _IngredientBaseSearchDelegate extends SearchDelegate<String> {
  final IngredientBaseService service;

  _IngredientBaseSearchDelegate(this.service);

  @override
  List<Widget>? buildActions(BuildContext context) =>
      [IconButton(onPressed: () => query = "", icon: const Icon(Icons.clear))];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(onPressed: () => close(context, ""), icon: const Icon(Icons.arrow_back));

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    return StreamBuilder<List<IngredientBase>>(
      stream: service.getAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data!
            .where((i) => i.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
        if (results.isEmpty) {
          return const Center(child: Text("No hay coincidencias"));
        }
        return ListView(
          children: results
              .map((i) => ListTile(
            title: Text(i.name),
            onTap: () => close(context, i.name),
          ))
              .toList(),
        );
      },
    );
  }
}

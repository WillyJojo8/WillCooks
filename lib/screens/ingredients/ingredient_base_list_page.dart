import 'package:flutter/material.dart';
import '../../models/ingredient_base.dart';
import '../../services/ingredient_base_service.dart';

import '../../utils/units.dart'; // <-- ajusta el path real

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
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    ing.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Unidad: ${ing.defaultUnit}, Compra: ${ing.purchaseUnit}, "
                        "Factor de conversión (auto): ${ing.conversionFactor}"
                        "${ing.density != null ? ", Densidad (g/ml): ${ing.density}" : ""}",
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

  /// 🔹 Crear nuevo ingrediente (con selects y factor auto)
  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();

    // Seguimos guardando como String en BD, pero en UI usamos enum Unit
    Unit selectedUnit = Unit.g;            // por defecto g (tu caso 99%)
    Unit selectedPurchase = Unit.kg;       // por defecto kg para compra
    final factorCtrl = TextEditingController();
    final densityCtrl = TextEditingController();

    // refresca el factor auto cada vez que cambian unidad/compra/densidad
    void refreshFactor() {
      final d = double.tryParse(densityCtrl.text);
      final f = computeConversionFactor(
        unit: selectedUnit,
        purchaseUnit: selectedPurchase,
        densityGPerMl: d,
      );
      factorCtrl.text = f == null ? '' : trimDouble(f);
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final needsDensity = isCrossType(selectedUnit, selectedPurchase);

          return AlertDialog(
            title: const Text("Nuevo ingrediente base"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Nombre"),
                  ),

                  const SizedBox(height: 12),
                  DropdownButtonFormField<Unit>(
                    value: selectedUnit,
                    items: Unit.values
                        .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                        .toList(),
                    onChanged: (u) {
                      setStateDialog(() {
                        selectedUnit = u ?? Unit.g;
                        refreshFactor();
                      });
                    },
                    decoration: const InputDecoration(labelText: "Unidad base (g, ml, ud)"),
                  ),

                  const SizedBox(height: 12),
                  DropdownButtonFormField<Unit>(
                    value: selectedPurchase,
                    items: Unit.values
                        .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                        .toList(),
                    onChanged: (u) {
                      setStateDialog(() {
                        selectedPurchase = u ?? Unit.kg;
                        refreshFactor();
                      });
                    },
                    decoration: const InputDecoration(labelText: "Unidad de compra (kg, L, ud)"),
                  ),

                  const SizedBox(height: 12),
                  if (needsDensity)
                    TextField(
                      controller: densityCtrl,
                      decoration: const InputDecoration(
                        labelText: "Densidad (g/ml)",
                        helperText: "Necesaria para masa↔volumen. Ej.: aceite ≈ 0.92",
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setStateDialog(() { refreshFactor(); }), // ✅
                    ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: factorCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Conversión Unidades",
                      helperText: "Cuántas unidades base caben en 1 unidad de compra",
                    ),
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
                child: const Text("Guardar"),
                onPressed: () async {
                  // validar densidad si hace falta
                  if (needsDensity && double.tryParse(densityCtrl.text) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Para masa↔volumen necesitas densidad (g/ml).")),
                    );
                    return;
                  }
                  // calcula por seguridad
                  refreshFactor();

                  final id = nameCtrl.text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), "_");
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
                    name: nameCtrl.text.trim(),
                    defaultUnit: unitToString(selectedUnit),      // String en BD
                    purchaseUnit: unitToString(selectedPurchase), // String en BD
                    conversionFactor: double.tryParse(factorCtrl.text) ?? 1,
                    density: double.tryParse(densityCtrl.text),   // null si no aplica
                  );
                  await _service.addIngredientBase(ing);
                  if (context.mounted) Navigator.pop(context);
                },
              )
            ],
          );
        },
      ),
    );
  }

  /// 🔹 Editar ingrediente existente (con selects y factor auto)
  void _showEditDialog(BuildContext context, IngredientBase ing) {
    final nameCtrl = TextEditingController(text: ing.name);
    Unit selectedUnit = parseUnit(ing.defaultUnit) ?? Unit.g;
    Unit selectedPurchase = parseUnit(ing.purchaseUnit) ?? Unit.kg;
    final densityCtrl = TextEditingController(text: ing.density?.toString() ?? "");
    final factorCtrl = TextEditingController();

    void refreshFactor() {
      final d = double.tryParse(densityCtrl.text);
      final f = computeConversionFactor(
        unit: selectedUnit,
        purchaseUnit: selectedPurchase,
        densityGPerMl: d,
      );
      factorCtrl.text = f == null ? '' : trimDouble(f);
    }

    // Inicializa factor según lo actual
    refreshFactor();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final needsDensity = isCrossType(selectedUnit, selectedPurchase);

          return AlertDialog(
            title: Text("Editar ${ing.name}"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Nombre"),
                  ),

                  const SizedBox(height: 12),
                  DropdownButtonFormField<Unit>(
                    value: selectedUnit,
                    items: Unit.values
                        .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                        .toList(),
                    onChanged: (u) {
                      setStateDialog(() {
                        selectedUnit = u ?? selectedUnit;
                        refreshFactor();
                      });
                    },
                    decoration: const InputDecoration(labelText: "Unidad base (g, ml, ud)"),
                  ),

                  const SizedBox(height: 12),
                  DropdownButtonFormField<Unit>(
                    value: selectedPurchase,
                    items: Unit.values
                        .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                        .toList(),
                    onChanged: (u) {
                      setStateDialog(() {
                        selectedPurchase = u ?? selectedPurchase;
                        refreshFactor();
                      });
                    },
                    decoration: const InputDecoration(labelText: "Unidad de compra (kg, L, ud)"),
                  ),

                  const SizedBox(height: 12),
                  if (needsDensity)
                    TextField(
                      controller: densityCtrl,
                      decoration: const InputDecoration(
                        labelText: "Densidad (g/ml)",
                        helperText: "Necesaria para masa↔volumen. Ej.: aceite ≈ 0.92",
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setStateDialog(() { refreshFactor(); }), // ✅
                    ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: factorCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Factor de conversión (auto)",
                      helperText: "Cuántas unidades base caben en 1 unidad de compra",
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar")),
              ElevatedButton(
                child: const Text("Guardar cambios"),
                onPressed: () async {
                  if (needsDensity && double.tryParse(densityCtrl.text) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Para masa↔volumen necesitas densidad (g/ml).")),
                    );
                    return;
                  }
                  refreshFactor();

                  final updated = IngredientBase(
                    id: ing.id,
                    name: nameCtrl.text.trim(),
                    defaultUnit: unitToString(selectedUnit),
                    purchaseUnit: unitToString(selectedPurchase),
                    conversionFactor: double.tryParse(factorCtrl.text) ?? 1,
                    density: double.tryParse(densityCtrl.text),
                  );
                  await _service.updateIngredientBase(updated);
                  if (context.mounted) Navigator.pop(context);
                },
              )
            ],
          );
        },
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

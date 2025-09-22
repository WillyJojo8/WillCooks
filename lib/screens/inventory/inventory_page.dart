import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/inventory_item.dart';
import '../../models/ingredient_base.dart';
import '../../services/inventory_service.dart';
import '../../services/ingredient_base_service.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryService _inventoryService = InventoryService();
  final IngredientBaseService _baseService = IngredientBaseService();
  String _query = "";

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch<String>(
                context: context,
                delegate: _InventorySearchDelegate(_baseService, _inventoryService, userId),
              );
              if (result != null) {
                setState(() => _query = result.toLowerCase());
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<IngredientBase>>(
        stream: _baseService.getAll(),
        builder: (context, baseSnap) {
          if (!baseSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final bases = baseSnap.data!;

          return StreamBuilder<List<InventoryItem>>(
            stream: _inventoryService.getInventory(userId),
            builder: (context, invSnap) {
              if (!invSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final invList = invSnap.data!;
              final invByIngredientId = {for (final i in invList) i.ingredientId: i};

              final filtered = bases
                  .where((b) => b.name.toLowerCase().contains(_query))
                  .toList();

              if (filtered.isEmpty) {
                return const Center(child: Text("No hay ingredientes base aún"));
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final base = filtered[i];
                  final current = invByIngredientId[base.id];

                  final qty = current?.quantity ?? 0.0;
                  final unit = current?.unit ?? base.purchaseUnit;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.inventory_2),
                      title: Text(
                        base.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text("Disponible: ${qty.toStringAsFixed(2)} $unit"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showEditDialog(context, userId, base, qty, unit),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, String userId, IngredientBase base, double qty, String unit) {
    final qtyCtrl = TextEditingController(text: qty == 0 ? "" : qty.toString());
    final unitCtrl = TextEditingController(text: unit);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Editar ${base.name}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Cantidad disponible"),
              ),
              TextField(
                controller: unitCtrl,
                decoration: const InputDecoration(labelText: "Unidad"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final newQty = double.tryParse(qtyCtrl.text) ?? 0;
              final newUnit =
              unitCtrl.text.trim().isEmpty ? base.purchaseUnit : unitCtrl.text.trim();

              await _inventoryService.setQuantity(
                userId: userId,
                ingredientId: base.id,
                name: base.name,
                unit: newUnit,
                quantity: newQty,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Inventario actualizado ✅")),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}

/// 🔎 SearchDelegate para Inventario
class _InventorySearchDelegate extends SearchDelegate<String> {
  final IngredientBaseService baseService;
  final InventoryService invService;
  final String userId;

  _InventorySearchDelegate(this.baseService, this.invService, this.userId);

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
      stream: baseService.getAll(),
      builder: (context, baseSnap) {
        if (!baseSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final bases = baseSnap.data!;

        return StreamBuilder<List<InventoryItem>>(
          stream: invService.getInventory(userId),
          builder: (context, invSnap) {
            if (!invSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final invList = invSnap.data!;
            final invByIngredientId = {for (final i in invList) i.ingredientId: i};

            final results = bases
                .where((b) => b.name.toLowerCase().contains(query.toLowerCase()))
                .toList();

            if (results.isEmpty) {
              return const Center(child: Text("No hay coincidencias"));
            }

            return ListView(
              children: results.map((b) {
                final current = invByIngredientId[b.id];
                final qty = current?.quantity ?? 0.0;
                final unit = current?.unit ?? b.purchaseUnit;
                return ListTile(
                  title: Text(b.name),
                  subtitle: Text("Disponible: ${qty.toStringAsFixed(2)} $unit"),
                  onTap: () => close(context, b.name),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

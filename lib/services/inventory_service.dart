import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';

class InventoryService {
  final _collection = FirebaseFirestore.instance.collection('inventory');

  /// 🔹 Stream de inventario por usuario
  Stream<List<InventoryItem>> getInventory(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => InventoryItem.fromMap(doc.data())).toList());
  }

  /// 🔹 Crear o actualizar item (docId = ingredientId)
  Future<void> addOrUpdateItem(InventoryItem item) async {
    await _collection.doc(item.ingredientId).set(item.toMap(), SetOptions(merge: true));
  }

  /// 🔹 Actualizar cantidad directa
  Future<void> updateQuantity(String ingredientId, double quantity) async {
    final newQty = quantity.clamp(0, double.infinity);
    await _collection.doc(ingredientId).update({
      'quantity': newQty,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  /// 🔹 Establecer cantidad (crear o sobrescribir)
  Future<void> setQuantity({
    required String userId,
    required String ingredientId,
    required String name,
    required String unit,
    required double quantity,
  }) async {
    await _collection.doc(ingredientId).set({
      'id': ingredientId,
      'ingredientId': ingredientId,
      'name': name,
      'quantity': quantity.clamp(0, double.infinity),
      'unit': unit,
      'lastUpdated': DateTime.now().toIso8601String(),
      'userId': userId,
    });
  }

  /// 🔹 Restar cantidades consumidas (en purchaseUnit) y hacer clamp a 0
  Future<void> resetQuantities(
      String userId, Map<String, double> consumed) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final entry in consumed.entries) {
      final docRef = _collection.doc(entry.key); // ingredientId
      final doc = await docRef.get();

      if (doc.exists) {
        final current = (doc['quantity'] as num).toDouble();
        final consumedQty = entry.value;
        final newQty = (current - consumedQty).clamp(0, double.infinity);

        print(
            "🔹 Restando ${consumedQty.toStringAsFixed(2)} a ${doc['name']} (antes: $current, después: $newQty)");

        batch.update(docRef, {
          'quantity': newQty,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      } else {
        print("⚠️ No existe inventario para ${entry.key}, no se descuenta.");
      }
    }

    await batch.commit();
  }

  /// 🔹 Eliminar item del inventario
  Future<void> deleteItem(String ingredientId) async {
    await _collection.doc(ingredientId).delete();
  }
}

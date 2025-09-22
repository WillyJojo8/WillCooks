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
    await _collection.doc(item.ingredientId).set(item.toMap());
  }

  /// 🔹 Actualizar cantidad directa
  Future<void> updateQuantity(String ingredientId, double quantity) async {
    await _collection.doc(ingredientId).update({
      'quantity': quantity,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  /// 🔹 Establecer cantidad
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
      'quantity': quantity,
      'unit': unit,
      'lastUpdated': DateTime.now().toIso8601String(),
      'userId': userId,
    });
  }


  /// 🔹 Restar cantidades consumidas (clamp a 0)
  Future<void> resetQuantities(
      String userId, Map<String, double> consumed) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final entry in consumed.entries) {
      final docRef = _collection.doc(entry.key); // usamos ingredientId
      final doc = await docRef.get();

      if (doc.exists) {
        final current = (doc['quantity'] as num).toDouble();
        final newQty = (current - entry.value).clamp(0, double.infinity);

        batch.update(docRef, {
          'quantity': newQty,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }
    }

    await batch.commit();
  }

  /// 🔹 Eliminar item del inventario
  Future<void> deleteItem(String ingredientId) async {
    await _collection.doc(ingredientId).delete();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ingredient_base.dart';

class IngredientBaseService {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('ingredientBase');

  Stream<List<IngredientBase>> getAll() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return IngredientBase.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addIngredientBase(IngredientBase ingredient) async {
    await _collection.doc(ingredient.id).set(ingredient.toMap());
  }

  Future<void> updateIngredientBase(IngredientBase ingredient) async {
    await _collection.doc(ingredient.id).update(ingredient.toMap());
  }

  Future<void> deleteIngredientBase(String id) async {
    await _collection.doc(id).delete();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class RecipeService {
  final CollectionReference recipesRef =
  FirebaseFirestore.instance.collection('recipes');

  /// 🔹 Crear o actualizar receta completa
  Future<void> addRecipe(Recipe recipe) async {
    await recipesRef.doc(recipe.id).set(recipe.toMap(), SetOptions(merge: true));
  }

  /// 🔹 Eliminar receta
  Future<void> deleteRecipe(String id) async {
    await recipesRef.doc(id).delete();
  }

  /// 🔹 Obtener todas las recetas
  Stream<List<Recipe>> getAllRecipes() {
    return recipesRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// 🔹 Obtener recetas por usuario
  Stream<List<Recipe>> getRecipesByUser(String userId) {
    return recipesRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// 🔹 Obtener receta individual por ID
  Future<Recipe?> getRecipeById(String id) async {
    final doc = await recipesRef.doc(id).get();
    if (!doc.exists) return null;
    return Recipe.fromMap(doc.data() as Map<String, dynamic>);
  }
}

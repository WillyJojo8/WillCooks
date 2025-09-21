import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class RecipeService {
  final CollectionReference recipesRef =
  FirebaseFirestore.instance.collection('recipes');

  Future<void> addRecipe(Recipe recipe) async {
    await recipesRef.doc(recipe.id).set(recipe.toMap());
  }

  Future<void> deleteRecipe(String id) async {
    await recipesRef.doc(id).delete();
  }

  Stream<List<Recipe>> getAllRecipes() {
    return recipesRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<Recipe>> getRecipesByUser(String userId) {
    return recipesRef.where('userId', isEqualTo: userId).snapshots().map(
            (snapshot) => snapshot.docs
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

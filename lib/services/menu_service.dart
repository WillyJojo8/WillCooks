import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu.dart';

class MenuService {
  final CollectionReference menusRef =
  FirebaseFirestore.instance.collection('menus');

  String _weekKey(DateTime weekStart, String userId) =>
      "$userId-${weekStart.year}-${weekStart.month}-${weekStart.day}";

  /// 🔹 Obtener menú en tiempo real
  Stream<Menu?> getMenuForWeek(String userId, DateTime weekStart) {
    return menusRef.doc(_weekKey(weekStart, userId)).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Menu.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  /// 🔹 Crear menú vacío
  Future<void> createEmptyMenu({
    required String userId,
    required DateTime weekStart,
    required String name,
    required DateTime feInicio,
    required DateTime feFin,
  }) async {
    final id = _weekKey(weekStart, userId);
    final days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"];

    final menu = Menu(
      id: id,
      weekStart: weekStart,
      feInicio: feInicio,
      feFin: feFin,
      name: name,
      userId: userId,
      dailyRecipes: {for (var d in days) d: <String>[]}, // 🔹 listas de IDs
      estimatedChildrenPerDay: {for (var d in days) d: 0},
      actualChildrenPerDay: {for (var d in days) d: 0},
    );

    await menusRef.doc(id).set(menu.toMap());
  }

  /// 🔹 Añadir receta (solo ID)
  Future<void> addRecipeIdToDay({
    required String userId,
    required DateTime weekStart,
    required String day,
    required String recipeId,
  }) async {
    final id = _weekKey(weekStart, userId);
    await menusRef.doc(id).update({
      "dailyRecipes.$day": FieldValue.arrayUnion([recipeId])
    });
  }

  /// 🔹 Eliminar receta (solo ID)
  Future<void> removeRecipeIdFromDay({
    required String userId,
    required DateTime weekStart,
    required String day,
    required String recipeId,
  }) async {
    final id = _weekKey(weekStart, userId);
    await menusRef.doc(id).update({
      "dailyRecipes.$day": FieldValue.arrayRemove([recipeId])
    });
  }

  /// 🔹 Actualizar niños reales
  Future<void> updateActualChildren({
    required String userId,
    required DateTime weekStart,
    required String day,
    required int numChildren,
  }) async {
    final id = _weekKey(weekStart, userId);
    await menusRef.doc(id).update({
      "actualChildrenPerDay.$day": numChildren,
    });
  }

  /// 🔹 Actualizar niños estimados
  Future<void> updateEstimatedChildren({
    required String userId,
    required DateTime weekStart,
    required String day,
    required int numChildren,
  }) async {
    final id = _weekKey(weekStart, userId);
    await menusRef.doc(id).update({
      "estimatedChildrenPerDay.$day": numChildren,
    });
  }
}

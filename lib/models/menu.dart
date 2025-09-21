import 'recipe.dart';

class Menu {
  final String id;
  final DateTime weekStart;
  final Map<String, List<Recipe>> dailyRecipes;      // {"Lunes": [receta1, receta2]}
  final Map<String, int> estimatedChildrenPerDay;    // {"Lunes": 50, "Martes": 60}
  final Map<String, int> actualChildrenPerDay;       // {"Lunes": 47, "Martes": 55}
  final String userId;

  Menu({
    required this.id,
    required this.weekStart,
    required this.dailyRecipes,
    required this.estimatedChildrenPerDay,
    required this.actualChildrenPerDay,
    required this.userId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'weekStart': weekStart.toIso8601String(),
    'userId': userId,
    'dailyRecipes': dailyRecipes.map((day, recipes) =>
        MapEntry(day, recipes.map((r) => r.toMap()).toList())),
    'estimatedChildrenPerDay': estimatedChildrenPerDay,
    'actualChildrenPerDay': actualChildrenPerDay,
  };

  factory Menu.fromMap(Map<String, dynamic> map) => Menu(
    id: map['id'],
    weekStart: DateTime.parse(map['weekStart']),
    userId: map['userId'],
    estimatedChildrenPerDay:
    Map<String, int>.from(map['estimatedChildrenPerDay']),
    actualChildrenPerDay:
    Map<String, int>.from(map['actualChildrenPerDay']),
    dailyRecipes: (map['dailyRecipes'] as Map<String, dynamic>).map(
          (day, recipes) => MapEntry(
        day,
        (recipes as List).map((r) => Recipe.fromMap(r)).toList(),
      ),
    ),
  );
}

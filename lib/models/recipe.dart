import 'ingredient.dart';

class Recipe {
  final String id;
  final String name;
  final List<Ingredient> ingredients;
  final String userId;

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.userId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'userId': userId,
    'ingredients': ingredients.map((i) => i.toMap()).toList(),
  };

  factory Recipe.fromMap(Map<String, dynamic> map) => Recipe(
    id: map['id'],
    name: map['name'],
    userId: map['userId'],
    ingredients: List<Ingredient>.from(
      (map['ingredients'] as List).map((i) => Ingredient.fromMap(i)),
    ),
  );
}

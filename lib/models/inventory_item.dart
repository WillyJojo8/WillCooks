class InventoryItem {
  final String id;
  final String ingredientId;  // referencia a IngredientBase
  final String name;
  final double quantity;      // cantidad disponible
  final String unit;          // unidad de compra (kg, L…)
  final DateTime lastUpdated;
  final String userId;

  InventoryItem({
    required this.id,
    required this.ingredientId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.lastUpdated,
    required this.userId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'ingredientId': ingredientId,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'lastUpdated': lastUpdated.toIso8601String(),
    'userId': userId,
  };

  factory InventoryItem.fromMap(Map<String, dynamic> map) => InventoryItem(
    id: map['id'],
    ingredientId: map['ingredientId'],
    name: map['name'],
    quantity: (map['quantity'] as num).toDouble(),
    unit: map['unit'],
    lastUpdated: DateTime.parse(map['lastUpdated']),
    userId: map['userId'],
  );
}

class Ingredient {
  final String ingredientId;      // referencia al IngredientBase
  final String name;
  final double amountPerChild;    // ej: 50 g por niño
  final String unit;              // ej: "g"
  final String purchaseUnit;      // ej: "kg"
  final double conversionFactor;  // ej: 1000
  final double? density;

  Ingredient({
    required this.ingredientId,
    required this.name,
    required this.amountPerChild,
    required this.unit,
    required this.purchaseUnit,
    required this.conversionFactor,
    this.density,
  });

  Map<String, dynamic> toMap() => {
    'ingredientId': ingredientId,
    'name': name,
    'amountPerChild': amountPerChild,
    'unit': unit,
    'purchaseUnit': purchaseUnit,
    'conversionFactor': conversionFactor,
    'density': density,
  };

  factory Ingredient.fromMap(Map<String, dynamic> map) => Ingredient(
    ingredientId: map['ingredientId'],
    name: map['name'],
    amountPerChild: (map['amountPerChild'] as num).toDouble(),
    unit: map['unit'],
    purchaseUnit: map['purchaseUnit'],
    conversionFactor: (map['conversionFactor'] as num).toDouble(),
    density: map['density'] != null
        ? (map['density'] as num).toDouble()
        : null,
  );

  /// total en unidad base (ej: g, ml)
  double totalForChildren(int numChildren) =>
      amountPerChild * numChildren;

  /// total en unidad de compra (ej: kg, L)
  double totalForChildrenInPurchaseUnit(int numChildren) {
    double total = totalForChildren(numChildren);

    if (unit == "g" && purchaseUnit == "L" && density != null) {
      return (total / density!) / conversionFactor;
    } else if (unit == "ml" && purchaseUnit == "kg" && density != null) {
      return (total * density!) / conversionFactor;
    } else {
      return total / conversionFactor;
    }
  }
}

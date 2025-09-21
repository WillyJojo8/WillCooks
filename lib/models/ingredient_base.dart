class IngredientBase {
  final String id;                // ej: "patata"
  final String name;              // ej: "Patata"
  final String defaultUnit;       // ej: "g"
  final String purchaseUnit;      // ej: "kg"
  final double conversionFactor;  // ej: 1000 (g->kg, ml->L)
  final double? density;          // ej: 0.92 g/ml para aceite

  IngredientBase({
    required this.id,
    required this.name,
    required this.defaultUnit,
    required this.purchaseUnit,
    required this.conversionFactor,
    this.density,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'defaultUnit': defaultUnit,
    'purchaseUnit': purchaseUnit,
    'conversionFactor': conversionFactor,
    'density': density,
  };

  factory IngredientBase.fromMap(Map<String, dynamic> map) => IngredientBase(
    id: map['id'],
    name: map['name'],
    defaultUnit: map['defaultUnit'],
    purchaseUnit: map['purchaseUnit'],
    conversionFactor: (map['conversionFactor'] as num).toDouble(),
    density: map['density'] != null
        ? (map['density'] as num).toDouble()
        : null,
  );
}

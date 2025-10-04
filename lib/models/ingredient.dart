class Ingredient {
  final String ingredientId;      // referencia al IngredientBase
  final String name;
  final double amountPerChildInfantil;  // g crudos por niño infantil
  final double amountPerChildPrimaria;  // g crudos por niño primaria
  final double cookingFactor;           // ej: 0.8 (queda 80% tras cocinar)
  final String unit;              // ej: "g"
  final String purchaseUnit;      // ej: "kg"
  final double conversionFactor;  // ej: 1000 (g->kg)
  final double? density;          // opcional, para g<->ml

  Ingredient({
    required this.ingredientId,
    required this.name,
    required this.amountPerChildInfantil,
    required this.amountPerChildPrimaria,
    required this.cookingFactor,
    required this.unit,
    required this.purchaseUnit,
    required this.conversionFactor,
    this.density,
  });

  // 🔹 Conversión a mapa (para Firestore)
  Map<String, dynamic> toMap() => {
    'ingredientId': ingredientId,
    'name': name,
    'amountPerChildInfantil': amountPerChildInfantil,
    'amountPerChildPrimaria': amountPerChildPrimaria,
    'cookingFactor': cookingFactor,
    'unit': unit,
    'purchaseUnit': purchaseUnit,
    'conversionFactor': conversionFactor,
    'density': density,
  };

  // 🔹 Constructor desde mapa (Firestore)
  factory Ingredient.fromMap(Map<String, dynamic> map) => Ingredient(
    ingredientId: map['ingredientId'] ?? '',
    name: map['name'] ?? '',
    amountPerChildInfantil:
    (map['amountPerChildInfantil'] ?? 0).toDouble(),
    amountPerChildPrimaria:
    (map['amountPerChildPrimaria'] ?? 0).toDouble(),
    cookingFactor: (map['cookingFactor'] ?? 1).toDouble(),
    unit: map['unit'] ?? '',
    purchaseUnit: map['purchaseUnit'] ?? '',
    conversionFactor: (map['conversionFactor'] ?? 1).toDouble(),
    density: map['density'] != null
        ? (map['density'] as num).toDouble()
        : null,
  );

  /// ---------------------------------------------------
  /// 📊 Métodos por grupo (Infantil / Primaria)
  /// ---------------------------------------------------

  // ---------- INFANTIL ----------
  double totalCrudoInfantil(int numChildren) =>
      amountPerChildInfantil * numChildren;

  double totalCocinadoInfantil(int numChildren) =>
      totalCrudoInfantil(numChildren) * cookingFactor;

  double totalInfantilInPurchaseUnit(int numChildren) =>
      _convertToPurchaseUnit(totalCrudoInfantil(numChildren));

  // ---------- PRIMARIA ----------
  double totalCrudoPrimaria(int numChildren) =>
      amountPerChildPrimaria * numChildren;

  double totalCocinadoPrimaria(int numChildren) =>
      totalCrudoPrimaria(numChildren) * cookingFactor;

  double totalPrimariaInPurchaseUnit(int numChildren) =>
      _convertToPurchaseUnit(totalCrudoPrimaria(numChildren));

  /// ---------------------------------------------------
  /// ⚙️ Métodos genéricos
  /// ---------------------------------------------------

  /// Devuelve el peso cocinado total, dado el total crudo.
  double totalCocinado(double totalCrudo) => totalCrudo * cookingFactor;

  /// Convierte una cantidad base (g o ml) a unidad de compra (kg o L)
  double _convertToPurchaseUnit(double totalBase) {
    if (unit == "g" && purchaseUnit == "L" && density != null) {
      return (totalBase / density!) / conversionFactor;
    } else if (unit == "ml" && purchaseUnit == "kg" && density != null) {
      return (totalBase * density!) / conversionFactor;
    } else {
      return totalBase / conversionFactor;
    }
  }
}

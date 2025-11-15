// lib/utils/units.dart
enum UnitType { mass, volume, count }

enum Unit {
  g(UnitType.mass),
  kg(UnitType.mass),
  mg(UnitType.mass),
  ml(UnitType.volume),
  l(UnitType.volume),
  ud(UnitType.count);

  final UnitType type;
  const Unit(this.type);
}

/// Base: g para masa, ml para volumen, ud para unidades
const Map<Unit, double> kUnitToBase = {
  Unit.g: 1.0,
  Unit.kg: 1000.0,
  Unit.mg: 0.001,
  Unit.ml: 1.0,
  Unit.l: 1000.0,
  Unit.ud: 1.0,
};

Unit? parseUnit(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'g': return Unit.g;
    case 'kg': return Unit.kg;
    case 'mg': return Unit.mg;
    case 'ml': return Unit.ml;
    case 'l': return Unit.l;
    case 'ud': return Unit.ud;
  }
  return null;
}

String unitToString(Unit u) => u.name;

bool isCrossType(Unit? a, Unit? b) =>
    a != null && b != null && a.type != b.type;

/// Devuelve cuántas "unit" hay en 1 "purchaseUnit".
/// - Si son del mismo tipo, usa mapa global.
/// - Si hay cruce masa↔volumen, requiere densidad (g/ml).
double? computeConversionFactor({
  required Unit? unit,
  required Unit? purchaseUnit,
  required double? densityGPerMl,
}) {
  if (unit == null || purchaseUnit == null) return null;

  if (unit.type == purchaseUnit.type) {
    return kUnitToBase[purchaseUnit]! / kUnitToBase[unit]!;
  }

  if (densityGPerMl == null) return null;

  if (unit.type == UnitType.mass && purchaseUnit.type == UnitType.volume) {
    final ml = kUnitToBase[purchaseUnit]!;
    final grams = ml * densityGPerMl;
    final gramsPerUnit = kUnitToBase[unit]!;
    return grams / gramsPerUnit;
  }

  if (unit.type == UnitType.volume && purchaseUnit.type == UnitType.mass) {
    final grams = kUnitToBase[purchaseUnit]!;
    final ml = grams / densityGPerMl;
    final mlPerUnit = kUnitToBase[unit]!;
    return ml / mlPerUnit;
  }

  return null;
}

/// Quita ceros sobrantes bonitamente
String trimDouble(double v, {int decimals = 4}) {
  final s = v.toStringAsFixed(decimals);
  return s.contains('.') ? s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '') : s;
}

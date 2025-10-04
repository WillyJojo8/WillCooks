import 'package:cloud_firestore/cloud_firestore.dart';

class Menu {
  final String id;
  final DateTime weekStart;
  final String name;
  final DateTime feInicio;
  final DateTime feFin;
  final Map<String, List<String>> dailyRecipes; // IDs de recetas
  final Map<String, int> estimatedChildrenInfantilPerDay;
  final Map<String, int> estimatedChildrenPrimariaPerDay;
  final Map<String, int> actualChildrenInfantilPerDay;
  final Map<String, int> actualChildrenPrimariaPerDay;
  final String userId;

  Menu({
    required this.id,
    required this.weekStart,
    required this.name,
    required this.feInicio,
    required this.feFin,
    required this.dailyRecipes,
    required this.estimatedChildrenInfantilPerDay,
    required this.estimatedChildrenPrimariaPerDay,
    required this.actualChildrenInfantilPerDay,
    required this.actualChildrenPrimariaPerDay,
    required this.userId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'weekStart': Timestamp.fromDate(weekStart),
    'name': name,
    'userId': userId,
    'feInicio': Timestamp.fromDate(feInicio),
    'feFin': Timestamp.fromDate(feFin),
    'dailyRecipes': dailyRecipes,
    'estimatedChildrenInfantilPerDay': estimatedChildrenInfantilPerDay,
    'estimatedChildrenPrimariaPerDay': estimatedChildrenPrimariaPerDay,
    'actualChildrenInfantilPerDay': actualChildrenInfantilPerDay,
    'actualChildrenPrimariaPerDay': actualChildrenPrimariaPerDay,
  };

  factory Menu.fromMap(Map<String, dynamic> map) => Menu(
    id: map['id'],
    weekStart: (map['weekStart'] as Timestamp).toDate(),
    name: map['name'] ?? "Menú sin nombre",
    userId: map['userId'],
    feInicio: (map['feInicio'] as Timestamp).toDate(),
    feFin: (map['feFin'] as Timestamp).toDate(),
    dailyRecipes: (map['dailyRecipes'] as Map<String, dynamic>? ?? {})
        .map((day, ids) =>
        MapEntry(day, List<String>.from(ids as List<dynamic>))),
    estimatedChildrenInfantilPerDay: Map<String, int>.from(
        map['estimatedChildrenInfantilPerDay'] ?? {}),
    estimatedChildrenPrimariaPerDay: Map<String, int>.from(
        map['estimatedChildrenPrimariaPerDay'] ?? {}),
    actualChildrenInfantilPerDay:
    Map<String, int>.from(map['actualChildrenInfantilPerDay'] ?? {}),
    actualChildrenPrimariaPerDay:
    Map<String, int>.from(map['actualChildrenPrimariaPerDay'] ?? {}),
  );
}

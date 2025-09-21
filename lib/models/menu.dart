import 'package:cloud_firestore/cloud_firestore.dart';

class Menu {
  final String id;
  final DateTime weekStart;
  final String name;
  final DateTime feInicio;
  final DateTime feFin;
  final Map<String, List<String>> dailyRecipes; // 🔹 solo IDs de recetas
  final Map<String, int> estimatedChildrenPerDay;
  final Map<String, int> actualChildrenPerDay;
  final String userId;

  Menu({
    required this.id,
    required this.weekStart,
    required this.name,
    required this.feInicio,
    required this.feFin,
    required this.dailyRecipes,
    required this.estimatedChildrenPerDay,
    required this.actualChildrenPerDay,
    required this.userId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'weekStart': Timestamp.fromDate(weekStart),
    'name': name,
    'userId': userId,
    'feInicio': Timestamp.fromDate(feInicio),
    'feFin': Timestamp.fromDate(feFin),
    'dailyRecipes': dailyRecipes, // 🔹 guardamos IDs directamente
    'estimatedChildrenPerDay': estimatedChildrenPerDay,
    'actualChildrenPerDay': actualChildrenPerDay,
  };

  factory Menu.fromMap(Map<String, dynamic> map) => Menu(
    id: map['id'],
    weekStart: (map['weekStart'] as Timestamp).toDate(),
    name: map['name'] ?? "Menú sin nombre",
    userId: map['userId'],
    feInicio: (map['feInicio'] as Timestamp).toDate(),
    feFin: (map['feFin'] as Timestamp).toDate(),
    estimatedChildrenPerDay:
    Map<String, int>.from(map['estimatedChildrenPerDay'] ?? {}),
    actualChildrenPerDay:
    Map<String, int>.from(map['actualChildrenPerDay'] ?? {}),
    dailyRecipes: (map['dailyRecipes'] as Map<String, dynamic>? ?? {})
        .map((day, ids) =>
        MapEntry(day, List<String>.from(ids as List<dynamic>))),
  );
}

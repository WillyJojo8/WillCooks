import 'package:flutter/material.dart';

class FontProvider with ChangeNotifier {
  double _scaleFactor = 1.0; // ⬅️ por defecto normal

  double get scaleFactor => _scaleFactor;

  void setScale(double factor) {
    _scaleFactor = factor;
    notifyListeners();
  }
}

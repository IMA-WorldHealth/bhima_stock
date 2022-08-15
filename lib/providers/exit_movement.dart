import 'package:flutter/material.dart';

class ExitMovement extends ChangeNotifier {
  DateTime date = DateTime.now();
  int totalItems = 0;
  final List lots = [];

  set setDate(DateTime value) {
    date = value;
    notifyListeners();
  }

  set setTotalItems(int value) {
    totalItems = value;
    notifyListeners();
  }

  void setLot(int index, String field, dynamic value) {
    if (lots[index] == null) {
      lots[index] = {};
      lots[index][field] = value;
    } else {
      lots[index][field] = value;
    }
  }

  dynamic getLotValue(int index, String field) {
    return lots[index] != null && lots[index][field] != null
        ? lots[index][field]
        : '';
  }

  void addLot(value) {
    lots.add(value);
  }

  void clear() {
    lots.clear();
  }

  void reset() {
    date = DateTime.now();
    totalItems = 0;
    lots.clear();
    notifyListeners();
  }

  @override
  String toString() {
    return 'Date: $date, Total Items: $totalItems';
  }
}

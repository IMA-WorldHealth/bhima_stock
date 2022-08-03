import 'package:flutter/material.dart';

class ExitMovement extends ChangeNotifier {
  String documentReference = '';
  DateTime date = DateTime.now();
  int totalItems = 0;
  var lots = [];

  set setDocumentReference(String value) {
    documentReference = value;
    notifyListeners();
  }

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

  void createLots() {
    lots = List.filled(totalItems, null, growable: false);
  }

  void reset() {
    documentReference = '';
    date = DateTime.now();
    totalItems = 0;
    lots = [];
    notifyListeners();
  }

  @override
  String toString() {
    return 'Reference: $documentReference, Date: $date, Total Items: $totalItems';
  }
}

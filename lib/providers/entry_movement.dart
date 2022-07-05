import 'package:flutter/material.dart';

class EntryMovement extends ChangeNotifier {
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
    if (lots[index] != null && lots[index][field] != null) {
      lots[index][field] = value;
      notifyListeners();
    }
  }

  void addLot() {
    lots.add({'inventory_uuid': '', 'lot_uuid': '', 'quantity': 0});
    notifyListeners();
  }

  void createLots() {
    lots = List.filled(totalItems, null, growable: false);
  }

  int lastIndex() {
    return lots.length - 1;
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

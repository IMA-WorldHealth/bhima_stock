import 'package:bhima_collect/models/depot.dart';
import 'package:flutter/material.dart';

class CurrentDepotProvider with ChangeNotifier {
  Depot? _current;

  Depot? get current => _current;

  void setCurrent(Depot givenDepot) {
    _current = givenDepot;
    notifyListeners();
  }
}

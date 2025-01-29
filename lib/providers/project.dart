import 'package:flutter/material.dart';

class Project extends ChangeNotifier {
  int projectId = 0;

  setProject(int value) {
    projectId = value;
    notifyListeners();
  }
}

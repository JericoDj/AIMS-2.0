import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool isAdmin = false;
  bool isUser = false;

  void loginAsAdmin() {
    isAdmin = true;
    notifyListeners();
  }

  void loginAsUser() {
    isUser = true;
    notifyListeners();
  }
}

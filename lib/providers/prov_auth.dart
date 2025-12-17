import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  Future<bool> login(String username, String password) async {
    // Mock login logic
    // Accept any login for now as long as it's not empty
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    if (username.isNotEmpty && password.isNotEmpty) {
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}

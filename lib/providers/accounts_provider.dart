import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/AccountModel.dart';
import '../utils/enums/role_enum.dart';

class AccountsProvider extends ChangeNotifier {
  final GetStorage _box = GetStorage();

  static const String _accountsKey = 'accounts';
  static const String _sessionKey = 'session';

  final List<Account> _accounts = [];
  Account? _currentUser;

  /// ---------------- GETTERS ----------------
  List<Account> get accounts => List.unmodifiable(_accounts);
  Account? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isUser => _currentUser?.isUser ?? false;

  /// ---------------- INIT ----------------
  AccountsProvider() {
    _loadAccounts();
    _loadSession();
  }

  /// ---------------- STORAGE ----------------
  void _loadAccounts() {
    final stored = _box.read<List>(_accountsKey) ?? [];

    _accounts
      ..clear()
      ..addAll(
        stored.map(
              (e) => Account.fromMap(Map<String, dynamic>.from(e)),
        ),
      );

    notifyListeners();
  }

  void _saveAccounts() {
    _box.write(
      _accountsKey,
      _accounts.map((e) => e.toMap()).toList(),
    );
  }

  void _loadSession() {
    final data = _box.read(_sessionKey);
    if (data != null) {
      _currentUser = Account.fromMap(Map<String, dynamic>.from(data));
      notifyListeners();
    }
  }

  void _saveSession(Account user) {
    _box.write(_sessionKey, user.toMap());
  }

  void _clearSession() {
    _box.remove(_sessionKey);
  }

  /// ---------------- CRUD ----------------
  Future<void> createAccount({
    required String fullName,
    required String email,
    required UserRole role,
    required String password,
  }) async {
    try {
      /// 1️⃣ Create user in Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      /// 2️⃣ Create Account model
      final account = Account(
        id: uid,
        fullName: fullName,
        email: email,
        role: role,
        image: 'assets/JericoDeJesus.png',
        createdAt: DateTime.now(),
      );

      /// 3️⃣ Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(account.toMap());

      /// 4️⃣ Update local state
      _accounts.add(account);
      // _saveAccounts();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw Exception((e));
    }
  }

  void removeAccount(String id) {
    _accounts.removeWhere((a) => a.id == id);

    if (_currentUser?.id == id) {
      logout();
    }

    _saveAccounts();
    notifyListeners();
  }

  /// ---------------- AUTH ----------------
  bool login(String accountId) {
    try {
      final user = _accounts.firstWhere((a) => a.id == accountId);
      _currentUser = user;
      _saveSession(user);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void loginAsAdmin() {
    final admin = Account(
      id: 'admin',
      fullName: 'Administrator',
      email: 'admin@app.local',
      role: UserRole.admin,
      image: 'assets/JericoDeJesus.png',
      createdAt: DateTime.now(),
    );

    _currentUser = admin;
    _saveSession(admin);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _clearSession();
    notifyListeners();
  }
}

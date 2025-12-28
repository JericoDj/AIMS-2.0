import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import '../models/AccountModel.dart';
import '../utils/enums/role_enum.dart';

class AccountsProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _box = GetStorage();

  static const String _currentUserKey = 'current_user';

  final List<Account> _accounts = [];
  Account? _currentUser;

  // ================= GETTERS =================
  List<Account> get accounts => List.unmodifiable(_accounts);
  Account? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isUser => _currentUser?.role == UserRole.user;

  // ================= INIT =================
  AccountsProvider() {
    _loadCurrentUser();
    fetchUsersFromFirestore();
  }


  void setCurrentUser(Account account) {
    _currentUser = account;
    _saveCurrentUser(account);
    notifyListeners();
  }

  // ================= CURRENT USER STORAGE =================
  void _loadCurrentUser() {
    final data = _box.read(_currentUserKey);
    if (data != null) {
      _currentUser = Account.fromMap(
        Map<String, dynamic>.from(data),
      );
      notifyListeners();
    }
  }

  void _saveCurrentUser(Account user) {
    _box.write(_currentUserKey, user.toMap());
  }

  void _clearCurrentUser() {
    _box.remove(_currentUserKey);
  }

  // ================= FIRESTORE USERS =================
  Future<void> fetchUsersFromFirestore() async {
    try {
      final snapshot = await _firestore.collection('users').get();

      final users = snapshot.docs
          .map((doc) => Account.fromMap(doc.data()))
          .toList();

      _accounts
        ..clear()
        ..addAll(users);

      // Ensure logged-in admin is visible
      if (_currentUser != null &&
          _currentUser!.role == UserRole.admin &&
          !_accounts.any((u) => u.id == _currentUser!.id)) {
        _accounts.insert(0, _currentUser!);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ fetchUsersFromFirestore failed: $e');
    }
  }

  // ================= AUTH =================
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw Exception('User record not found');
    }

    final account = Account.fromMap(doc.data()!);
    _currentUser = account;
    _saveCurrentUser(account);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _clearCurrentUser();
    notifyListeners();
  }

  // ================= CREATE ACCOUNT =================
  Future<void> createAccount({
    required String fullName,
    required String email,
    required UserRole role,
    required String password,
  }) async {
    final credential =
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final account = Account(
      id: uid,
      fullName: fullName,
      email: email,
      role: role,
      image: 'assets/JericoDeJesus.png',
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(uid)
        .set(account.toMap());

    _accounts.add(account);
    notifyListeners();
  }

  // ================= PASSWORD RESET =================
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ================= REMOVE ACCOUNT =================
  Future<void> removeAccount(String id) async {
    await _firestore.collection('users').doc(id).delete();

    _accounts.removeWhere((a) => a.id == id);

    if (_currentUser?.id == id) {
      logout();
    }

    notifyListeners();
  }

  // ================= ADMIN SHORTCUT (DEV ONLY) =================
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
    _saveCurrentUser(admin);
    notifyListeners();
  }
}

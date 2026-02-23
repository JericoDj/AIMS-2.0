import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/supabase_config.dart';

import '../models/AccountModel.dart';
import '../screens/user/StorageKeys.dart';
import '../utils/enums/role_enum.dart';

class AccountsProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final GetStorage _box = GetStorage();
  final GetStorage _box = GetStorage('current_user');

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
    print("loading current user");
    final data = _box.read(_currentUserKey);

    print(data);
    if (data != null) {
      _currentUser = Account.fromMap(Map<String, dynamic>.from(data));
      notifyListeners();
    } else {
      print("no current user found in storage");
    }
  }

  Future<void> _saveCurrentUser(Account user) async {
    debugPrint('💾 Saving current user to storage');
    final data = user.toMap();
    debugPrint(data.toString());

    await _box.write(_currentUserKey, data);

    // 🔍 VERIFY WRITE
    final verify = _box.read(_currentUserKey);
    if (verify == null) {
      debugPrint('❌ VERIFY FAILED: current_user NOT found after write');
    } else {
      debugPrint('✅ VERIFY SUCCESS: current_user saved');
      debugPrint(verify.toString());
    }
  }

  void _clearCurrentUser() {
    _box.remove(_currentUserKey);
  }

  Future<void> reauthenticateAdmin(String password) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw Exception("No authenticated admin");
    }

    // Re-authenticate to verify password
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    debugPrint('🔐 Starting re-authentication...');
    await user
        .reauthenticateWithCredential(credential)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception("Authentication timed out (15s)"),
        );
    debugPrint('✅ Re-authentication successful');
  }

  // ================= FIRESTORE USERS =================
  Future<void> fetchUsersFromFirestore() async {
    try {
      final snapshot = await _firestore.collection('users').get();

      final users =
          snapshot.docs.map((doc) {
            final data = doc.data();
            final account = Account.fromMap(data);

            // 🖨️ PRINT EACH USER (RAW)
            debugPrint('👤 USER DOCUMENT');
            debugPrint('• id        : ${account.id}');
            debugPrint('• fullName  : ${account.fullName}');
            debugPrint('• email     : ${account.email}');
            debugPrint('• role      : ${account.role}');
            debugPrint('• createdAt : ${account.createdAt}');
            debugPrint('---------------------------');

            return account;
          }).toList();

      _accounts
        ..clear()
        ..addAll(users);

      // Ensure logged-in admin is visible
      if (_currentUser != null &&
          _currentUser!.role == UserRole.admin &&
          !_accounts.any((u) => u.id == _currentUser!.id)) {
        _accounts.insert(0, _currentUser!);
      }

      // 🧾 SUMMARY LOG
      debugPrint('✅ TOTAL USERS FETCHED: ${_accounts.length}');
      debugPrint(
        'Admins: ${_accounts.where((u) => u.role == UserRole.admin).length}, '
        'Users: ${_accounts.where((u) => u.role == UserRole.user).length}',
      );

      notifyListeners();
    } catch (e, s) {
      debugPrint('❌ fetchUsersFromFirestore failed: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  // ================= AUTH =================
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    // ================= AUTH =================
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // ================= FETCH PROFILE =================
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw Exception('User record not found');
    }

    final account = Account.fromMap({
      ...doc.data()!,
      'id': doc.id, // ✅ REQUIRED
    });

    // ================= UPDATE MEMORY =================
    _currentUser = account;

    // ================= SAVE TO GETSTORAGE =================
    final box = GetStorage('current_user');
    box.write(
      StorageKeys.currentUser,
      account.toMap(), // 👈 FULL PROFILE SAVED
    );

    notifyListeners();
  }

  void logout() {
    // 🔥 Clear in-memory session
    _currentUser = null;

    // 🔥 Clear persistent session
    final box = GetStorage('current_user');
    box.remove(StorageKeys.currentUser);

    notifyListeners();
  }

  // ================= CREATE ACCOUNT =================
  Future<void> createAccount({
    required String fullName,
    required String email,
    required UserRole role,
    required String password,
  }) async {
    // ================= ADMIN LIMIT CHECK =================
    if (role == UserRole.admin) {
      final adminSnap =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: UserRole.admin.name)
              .get();

      if (adminSnap.docs.length >= 5) {
        throw Exception("Maximum of 5 admin accounts allowed");
      }
    }

    // =====================================================
    // ✅ CREATE USER WITHOUT LOGGING OUT ADMIN
    // =====================================================

    // 🔐 Create secondary Firebase app
    final secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryAuth',
      options: Firebase.app().options,
    );

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      // 🔥 Create auth user (DOES NOT AFFECT MAIN SESSION)
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      final account = Account(
        id: uid,
        fullName: fullName,
        email: email,
        role: role,
        photoUrl: null, // default avatar
        createdAt: DateTime.now(),
      );

      // ================= SAVE TO FIRESTORE =================
      await _firestore.collection('users').doc(uid).set(account.toMap());

      // ================= UPDATE LOCAL STATE =================
      _accounts.add(account);
      notifyListeners();
    } finally {
      // 🧹 CLEANUP (VERY IMPORTANT)
      await secondaryAuth.signOut();
      await secondaryApp.delete();
    }
  }

  // ================= PASSWORD RESET =================
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ================= REMOVE ACCOUNT =================

  Future<void> removeAccount(
    String id, {
    String? adminPassword, // kept only for UI confirmation
  }) async {
    // 🔐 LOAD CURRENT USER FROM GETSTORAGE
    final currentUser = _getCurrentUserFromStorage();

    if (currentUser.role != UserRole.admin) {
      throw Exception("Only admins can remove accounts");
    }

    if (currentUser.id == id) {
      throw Exception("You cannot remove your own account");
    }

    final target = _accounts.firstWhere(
      (a) => a.id == id,
      orElse: () => throw Exception("Account not found"),
    );

    final adminCount = _accounts.where((a) => a.role == UserRole.admin).length;

    if (target.role == UserRole.admin && adminCount <= 1) {
      throw Exception("Cannot remove the last admin account");
    }

    final adminUser = FirebaseAuth.instance.currentUser;
    if (adminUser == null) {
      throw Exception("Authentication expired. Please log in again.");
    }

    // ✅ DO NOT FORCE REFRESH
    debugPrint('🎫 Fetching admin ID token...');
    final idToken = await adminUser.getIdToken();

    debugPrint(
      '🚀 Sending delete request (Dio) to Cloud Function for UID: $id',
    );
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    try {
      final response = await dio.post(
        "https://deleteuseraccount-tekpv2phba-uc.a.run.app",
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $idToken",
          },
        ),
        data: {"uid": id},
      );

      debugPrint('📡 Response Status: ${response.statusCode}');
      debugPrint('📡 Response Body: ${response.data}');

      if (response.statusCode != 200) {
        throw Exception("Failed to delete user: ${response.data}");
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio Error: ${e.type} - ${e.message}');
      debugPrint('❌ Dio Response: ${e.response?.data}');

      String errorMessage = "Network error while deleting user.";
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            "Connection timed out. Please check your internet on Windows.";
      } else if (e.response != null) {
        errorMessage = "Server error: ${e.response?.data}";
      }
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('❌ Unexpected deletion error: $e');
      throw Exception("An unexpected error occurred: $e");
    }

    _accounts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Account _getCurrentUserFromStorage() {
    final box = GetStorage('current_user');
    final stored = box.read(StorageKeys.currentUser);

    debugPrint('🧪 RAW STORED USER: $stored');

    if (stored == null || stored is! Map) {
      throw Exception("Session expired. Please log in again.");
    }

    final user = Account.fromMap(Map<String, dynamic>.from(stored));

    debugPrint('🧪 PARSED USER ID: ${user.id}');
    debugPrint('🧪 PARSED USER ROLE: ${user.role}');
    debugPrint('🧪 ROLE TYPE: ${user.role.runtimeType}');

    return user;
  }

  // ================= ADMIN SHORTCUT (DEV ONLY) =================
  void loginAsAdmin() {
    final admin = Account(
      id: 'admin',
      fullName: 'Administrator',
      email: 'admin@app.local',
      role: UserRole.admin,
      photoUrl: 'assets/JericoDeJesus.png',
      createdAt: DateTime.now(),
    );

    _currentUser = admin;
    _saveCurrentUser(admin);
    notifyListeners();
  }

  Future<void> uploadProfileImage(File file) async {
    if (_currentUser == null) return;

    final uid = _currentUser!.id;

    try {
      final String fileName = '$uid.jpg';

      // 1. Upload to Supabase Storage (FORCE OVERWRITE)
      await Supabase.instance.client.storage
          .from(SupabaseConfig.profileBucket)
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      // 2. Get Public URL with cache busting
      final String publicUrl = Supabase.instance.client.storage
          .from(SupabaseConfig.profileBucket)
          .getPublicUrl(fileName);

      final String timestampedUrl =
          '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // 3. Update Firestore & Local State
      await updatePhoto(timestampedUrl);
    } catch (e) {
      debugPrint('❌ Profile Upload Error: $e');
      rethrow;
    }
  }

  Future<void> updatePhoto(String url) async {
    if (_currentUser == null) return;

    final uid = _currentUser!.id;

    await _firestore.collection('users').doc(uid).update({'photoUrl': url});

    // Update current user state
    _currentUser = _currentUser!.copyWith(photoUrl: url);
    _saveCurrentUser(_currentUser!);

    // Update in the accounts list if it exists
    final index = _accounts.indexWhere((acc) => acc.id == uid);
    if (index != -1) {
      _accounts[index] = _accounts[index].copyWith(photoUrl: url);
    }

    notifyListeners();
  }
}

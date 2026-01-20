import '../utils/enums/role_enum.dart';

class Account {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,


    this.photoUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: UserRoleX.fromString(map['role']),
      photoUrl: map['photoUrl'] ?? map['image'], //
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Account copyWith({
    String? fullName,
    String? email,
    UserRole? role,
    String? photoUrl,
  }) {
    return Account(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role.value,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isUser => role == UserRole.user;
}

import '../utils/enums/role_enum.dart';

class Account {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? image;
  final bool isActive;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.image,
    this.isActive = true,
    required this.createdAt,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: UserRoleX.fromString(map['role']),
      image: map['image'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role.value,
      'image': image,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isUser => role == UserRole.user;
}

class OfflineUser {
  final String? uid;
  final String? email;
  final String? name;

  OfflineUser({this.uid, this.email, this.name});

  factory OfflineUser.fromMap(Map<String, dynamic>? map) {
    if (map == null) return OfflineUser();
    return OfflineUser(
      uid: map['uid'],
      email: map['email'],
      name: map['name'],
    );
  }
}

import 'package:get_storage/get_storage.dart';

final box = GetStorage("current_user");

void saveOfflineUser({
  required String uid,
  required String email,
  required String name,
}) {
  box.write('offline_user', {
    'uid': uid,
    'email': email,
    'name': name,
  });
}

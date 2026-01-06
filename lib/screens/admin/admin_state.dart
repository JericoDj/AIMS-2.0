import 'package:get_storage/get_storage.dart';
import 'navigation/admin_menu.dart';

class AdminState {
  final bool forceOffline;
  final GetStorage box = GetStorage("current_user");

  int selectedIndex = 0;
  bool isOfflineMode = false;

  AdminState({required this.forceOffline}) {
    if (forceOffline) {
      isOfflineMode = true;
    }
  }

  List<Map<String, dynamic>> get menuItems =>
      isOfflineMode ? offlineMenu : onlineMenu;

  bool hasValidOfflineUser() {
    final data = box.read('offline_user');
    if (data is! Map) return false;

    return data['uid'] != null &&
        data['email'] != null &&
        data['name'] != null;
  }

  void toggleOfflineMode() {
    if (forceOffline) return;

    if (!isOfflineMode && !hasValidOfflineUser()) {
      throw Exception("No cached offline user");
    }

    isOfflineMode = !isOfflineMode;
    selectedIndex = 0;
  }
}

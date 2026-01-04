import 'package:flutter/material.dart';
import 'admin_state.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_topbar.dart';
import 'navigation/admin_content_router.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, this.forceOffline});
  final bool? forceOffline;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late final AdminState state;

  @override
  void initState() {
    super.initState();
    state = AdminState(forceOffline: widget.forceOffline ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = state.menuItems;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          AdminSidebar(
            state: state,
            onMenuSelect: (i) => setState(() => state.selectedIndex = i),
          ),
          Expanded(
            child: Column(
              children: [
                const AdminTopBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: AdminContentRouter(state: state),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

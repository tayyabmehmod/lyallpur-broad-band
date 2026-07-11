import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AdminSidebar extends StatelessWidget {
  final int currentIndex;
  final bool isDrawer;

  const AdminSidebar({
    super.key,
    required this.currentIndex,
    this.isDrawer = false,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) {
      if (isDrawer) Navigator.pop(context);
      return;
    }

    String routeName;
    switch (index) {
      case 0:
        routeName = '/dashboard';
        break;
      case 1:
        routeName = '/clients';
        break;
      case 2:
        routeName = '/area';
        break;
      case 3:
        routeName = '/new_client';
        break;
      case 4:
        routeName = '/history';
        break;
      default:
        routeName = '/dashboard';
    }

    if (isDrawer) {
      Navigator.pop(context); // Close drawer
    }
    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService = FirebaseService();

    Widget buildItem({
      required int index,
      required IconData icon,
      required IconData activeIcon,
      required String label,
    }) {
      final isSelected = index == currentIndex;
      return ListTile(
        selected: isSelected,
        selectedTileColor: theme.colorScheme.tertiary.withValues(alpha: 0.08),
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? theme.colorScheme.tertiary : Colors.grey[500],
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () => _onTap(context, index),
      );
    }

    final sidebarContent = Container(
      width: 250,
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo / Header
          Row(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 36,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.settings_input_antenna,
                    color: theme.colorScheme.tertiary,
                    size: 32,
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lyallpur Telecom',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Broadband Admin',
                      style: TextStyle(
                        color: theme.colorScheme.tertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: Color(0xFF30363D)),
          const SizedBox(height: 16),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                buildItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                ),
                const SizedBox(height: 4),
                buildItem(
                  index: 1,
                  icon: Icons.people_outlined,
                  activeIcon: Icons.people,
                  label: 'Clients',
                ),
                const SizedBox(height: 4),
                buildItem(
                  index: 2,
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map,
                  label: 'Areas',
                ),
                const SizedBox(height: 4),
                buildItem(
                  index: 3,
                  icon: Icons.person_add_alt_1_outlined,
                  activeIcon: Icons.person_add_alt_1,
                  label: 'New Client',
                ),
                const SizedBox(height: 4),
                buildItem(
                  index: 4,
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  label: 'History',
                ),
              ],
            ),
          ),

          // Logout Button
          const Divider(color: Color(0xFF30363D)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () async {
              if (isDrawer) Navigator.pop(context);
              await firebaseService.signOutAdmin();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );

    if (isDrawer) {
      return Drawer(
        child: sidebarContent,
      );
    }

    return sidebarContent;
  }
}

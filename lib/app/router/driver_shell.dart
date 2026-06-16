import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_icons.dart';
import '../../features/driver_app/presentation/components/driver_header.dart';
import '../theme/colors.dart';

/// The scoped Driver-app bottom-nav shell: Today · Schedule · Earnings · Profile.
///
/// The driver header (avatar + name/role + Online/Offline toggle) is rendered
/// once here, above [navigationShell], so it persists across every tab —
/// matching the shared header in the `DriverApp` shell of
/// `screen_driver_app.jsx`.
class DriverShell extends StatelessWidget {
  const DriverShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<NavItem> _items = [
    (icon: AppIcons.home, label: 'Today'),
    (icon: AppIcons.cal, label: 'Schedule'),
    (icon: AppIcons.wallet, label: 'Earnings'),
    (icon: AppIcons.users, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const DriverHeader(),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        items: _items,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_icons.dart';
import '../theme/colors.dart';

/// The admin bottom-nav shell: Dashboard · Bookings · Drivers · Customers.
/// Detail and module screens push over this shell (no nav bar), matching the
/// prototype.
class AdminShell extends StatelessWidget {
  const AdminShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<NavItem> _items = [
    (icon: AppIcons.home, label: 'Dashboard'),
    (icon: AppIcons.cal, label: 'Bookings'),
    (icon: AppIcons.car, label: 'Drivers'),
    (icon: AppIcons.users, label: 'Customers'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: navigationShell,
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

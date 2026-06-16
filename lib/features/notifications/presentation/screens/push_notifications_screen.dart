import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/top_bar.dart';

/// Push Notifications — "coming soon" placeholder screen.
///
/// A simple empty state with TopBar + back navigation.
class PushNotificationsScreen extends StatelessWidget {
  const PushNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: 'Push Notifications',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: EmptyState(
                icon: AppIcons.bell,
                title: 'Coming soon',
                body:
                    'Send targeted push notifications to customers and drivers. '
                    'This feature is coming in a future update.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

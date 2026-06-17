import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';

/// Screen that checks for existing session on app startup.
/// Redirects to login or home based on authentication status.
class AuthCheckScreen extends ConsumerStatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  ConsumerState<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends ConsumerState<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    ref.read(authStateProvider.notifier).checkCurrentSession();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, state) {
      if (!mounted) return;

      if (state is AuthSuccess) {
        // User is authenticated — redirect to appropriate screen
        if (state.user.role == 'driver') {
          context.go(Routes.driverToday);
        } else {
          context.go(Routes.dashboard);
        }
      } else if (state is AuthInitial || state is AuthError) {
        // No valid session — show login
        context.go(Routes.login);
      }
    });

    // Show splash/loading screen while checking auth
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.car,
              size: 56,
              color: AppColors.brandYellow,
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

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
  bool _navigationCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    // Add a timeout to prevent infinite loading screen
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_navigationCompleted) {
        debugPrint('Auth check timeout - navigating to login');
        context.go(Routes.login);
      }
    });
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    try {
      await ref.read(authStateProvider.notifier).checkCurrentSession();
    } catch (e) {
      debugPrint('Error during auth check: $e');
      if (mounted) {
        context.go(Routes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, state) {
      if (!mounted || _navigationCompleted) return;

      debugPrint('Auth state changed: ${state.runtimeType}');

      if (state is AuthSuccess) {
        // User is authenticated — redirect to appropriate screen
        _navigationCompleted = true;
        if (state.user.role == 'driver') {
          context.go(Routes.driverToday);
        } else {
          context.go(Routes.dashboard);
        }
      } else if (state is AuthInitial || state is AuthError) {
        // No valid session — show login
        _navigationCompleted = true;
        debugPrint('No valid session, navigating to login');
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

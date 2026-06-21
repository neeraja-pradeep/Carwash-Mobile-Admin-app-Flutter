import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';

/// Payout detail screen — placeholder for refactoring.
/// Note: The API doesn't have a separate detail endpoint.
/// Detail data should be passed via navigation parameters from the log/history view.
class PayoutDetailScreen extends StatelessWidget {
  const PayoutDetailScreen({required this.payoutId, super.key});

  final String payoutId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              title: 'Payout Detail',
              subtitle: 'ID: $payoutId',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.construction,
                        size: 64,
                        color: AppColors.fgMuted,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Payout Detail Refactoring',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This screen needs to be refactored to work with the new Payout Log API.\n\nThe API returns all payout details in the log list, so no separate detail endpoint is needed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.fgMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

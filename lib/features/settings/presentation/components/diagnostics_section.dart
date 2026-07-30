import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/monitoring/sentry_config.dart';
import '../../../../core/monitoring/sentry_smoke_test.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import 'settings_group_section.dart';
import 'settings_item.dart';

/// Debug-only group that proves the Sentry pipeline end to end.
///
/// Hidden in profile/release builds and whenever the DSN has been blanked out,
/// so operators never see it — it exists so a developer can confirm events
/// actually land in the project after changing the DSN or the transport.
class DiagnosticsSection extends StatelessWidget {
  const DiagnosticsSection({super.key});

  /// Whether this section renders at all — also used by the parent to skip the
  /// spacing below it.
  static bool get isVisible => kDebugMode && SentryConfig.isEnabled;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return SettingsGroupSection(
      label: 'Diagnostics (debug only)',
      children: [
        SettingsItem(
          icon: AppIcons.alert,
          title: 'Send test error to Sentry',
          sub: 'Handled event · ${SentryConfig.environment}',
          onTap: () async {
            final id = await sendSentryTestEvent();
            if (!context.mounted) return;
            AppToast.show(
              context,
              id == null
                  ? 'Sentry did not accept the event'
                  : 'Sent to Sentry · event $id',
            );
          },
        ),
        SettingsItem(
          icon: AppIcons.alert,
          title: 'Throw a test crash',
          sub: 'Unhandled error · verifies crash capture',
          danger: true,
          last: true,
          onTap: throwSentryTestCrash,
        ),
      ],
    );
  }
}

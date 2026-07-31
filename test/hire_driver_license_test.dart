import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/app/theme/dimens.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/features/drivers/domain/entities/field_driver.dart';
import 'package:new_flutter_project/features/drivers/presentation/screens/hire_driver_screen.dart';

/// Hire/Edit Driver must reject a licence number that is not in the standard
/// `SS-RR-YYYY-NNNNNNN` shape, rather than storing whatever was typed.
void main() {
  Future<void> pumpForm(WidgetTester tester, {FieldDriver? driver}) async {
    tester.view.physicalSize = const Size(1140, 3400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(Dimens.designWidth, Dimens.designHeight),
          builder: (_, __) => MaterialApp(
            home: HireDriverScreen(driver: driver),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder fieldFor(String hint) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint,
      );

  /// Fields live in a ListView, so a field below the fold has to be scrolled
  /// into the tree before it can be typed into.
  Future<void> enterInto(WidgetTester tester, String hint, String text) async {
    final field = fieldFor(hint);
    if (field.evaluate().isEmpty) {
      await tester.dragUntilVisible(
        field,
        find.byType(ListView),
        const Offset(0, -150),
      );
      await tester.pumpAndSettle();
    }
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  Future<void> fillRequired(WidgetTester tester, {required String license}) async {
    await enterInto(tester, 'As on license', 'Ramesh Kurup');
    // The field holds the national digits only — the +91 is a static prefix.
    await enterInto(tester, '98765 43210', '9876543210');
    await enterInto(tester, 'KL-07-2011-0001234', license);
  }

  bool ctaDisabled(WidgetTester tester) =>
      tester.widget<AppButton>(find.byType(AppButton).last).disabled;

  testWidgets('formats a licence number as it is typed', (tester) async {
    await pumpForm(tester);
    await fillRequired(tester, license: 'kl0720110001234');

    expect(
      tester.widget<TextField>(fieldFor('KL-07-2011-0001234')).controller?.text,
      'KL-07-2011-0001234',
    );
    expect(ctaDisabled(tester), isFalse);
  });

  testWidgets('blocks the CTA and explains an out-of-format number',
      (tester) async {
    await pumpForm(tester);
    await fillRequired(tester, license: 'kl39h12333');

    expect(find.textContaining('Use the format'), findsOneWidget);
    expect(ctaDisabled(tester), isTrue);
  });

  testWidgets('blocks a partially typed number', (tester) async {
    await pumpForm(tester);
    await fillRequired(tester, license: 'KL072011');

    expect(ctaDisabled(tester), isTrue);
  });

  testWidgets('rejects an unknown state code', (tester) async {
    await pumpForm(tester);
    await fillRequired(tester, license: 'XX0720110001234');

    expect(find.textContaining('not a valid state code'), findsOneWidget);
    expect(ctaDisabled(tester), isTrue);
  });

  testWidgets('edit mode flags a legacy value already on the record',
      (tester) async {
    await pumpForm(tester, driver: _driverWithLicense('kl39h12333'));
    await enterInto(tester, 'KL-07-2011-0001234', 'kl39h12333');

    // Shown as stored, flagged, and Save is blocked until it is corrected.
    expect(
      tester.widget<TextField>(fieldFor('KL-07-2011-0001234')).controller?.text,
      'kl39h12333',
    );
    expect(find.textContaining('Use the format'), findsOneWidget);
    expect(ctaDisabled(tester), isTrue);

    await enterInto(tester, 'KL-07-2011-0001234', 'KL3920110001234');
    expect(find.textContaining('Use the format'), findsNothing);
    expect(ctaDisabled(tester), isFalse);
  });
}

FieldDriver _driverWithLicense(String number) => FieldDriver(
      id: '1',
      name: 'Ramesh Kurup',
      phone: '9876543210',
      email: 'ramesh@example.com',
      status: DriverStatus.online,
      role: 'Wash + hire driver',
      subRole: 'wash_hire',
      joined: '17-Jun-2026',
      license: DriverLicense(number: number, expiry: '12-2027', verified: false),
      jobsDone: 4,
      vehicleClasses: const ['Sedan'],
      today: const DriverPeriodStat(jobs: 0, earnings: 0),
      week: const DriverPeriodStat(jobs: 0, earnings: 0),
      documents: const [],
    );

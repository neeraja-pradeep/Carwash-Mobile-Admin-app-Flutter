import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/app/theme/dimens.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/features/drivers/domain/entities/field_driver.dart';
import 'package:new_flutter_project/features/drivers/presentation/screens/hire_driver_screen.dart';

/// The hire form's phone field is the driver's OTP sign-in identity, so the
/// country code is fixed at +91 rather than typed, and the CTA stays disabled
/// until a complete Indian mobile number is present.
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

  Finder phoneField() => fieldFor('98765 43210');

  /// Fields live in a ListView. Unlike a straight top-to-bottom fill, these
  /// tests revisit the phone field after touching one below it, so rewind to
  /// the top before searching downward — otherwise the field is behind us.
  Future<void> enterInto(WidgetTester tester, String hint, String text) async {
    final field = fieldFor(hint);
    if (field.evaluate().isEmpty) {
      await tester.drag(find.byType(ListView), const Offset(0, 2000));
      await tester.pumpAndSettle();
    }
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

  bool ctaDisabled(WidgetTester tester) =>
      tester.widget<AppButton>(find.byType(AppButton).last).disabled;

  String phoneText(WidgetTester tester) =>
      tester.widget<TextField>(phoneField()).controller?.text ?? '';

  testWidgets('+91 is shown on the field and is not typed by the admin',
      (tester) async {
    await pumpForm(tester);
    expect(find.text('+91'), findsOneWidget);
  });

  testWidgets('a pasted country code is absorbed, not duplicated',
      (tester) async {
    await pumpForm(tester);
    await enterInto(tester, '98765 43210', '+91 98765 43210');

    // The field keeps the ten national digits; the prefix supplies the rest.
    expect(phoneText(tester), '9876543210');
  });

  testWidgets('the field will not hold more than ten digits', (tester) async {
    await pumpForm(tester);
    await enterInto(tester, '98765 43210', '98765432101234');

    expect(phoneText(tester), '9876543210');
  });

  testWidgets('an incomplete number blocks submission', (tester) async {
    await pumpForm(tester);
    await enterInto(tester, 'As on license', 'Ramesh Kurup');
    await enterInto(tester, 'KL-07-2011-0001234', 'KL-07-2011-0001234');

    await enterInto(tester, '98765 43210', '98765');
    expect(ctaDisabled(tester), isTrue);
    expect(find.text('Enter all 10 digits.'), findsOneWidget);

    await enterInto(tester, '98765 43210', '9876543210');
    expect(ctaDisabled(tester), isFalse);
  });

  testWidgets('a non-mobile ten-digit number is refused', (tester) async {
    await pumpForm(tester);
    await enterInto(tester, 'As on license', 'Ramesh Kurup');
    await enterInto(tester, 'KL-07-2011-0001234', 'KL-07-2011-0001234');
    await enterInto(tester, '98765 43210', '1234567890');

    expect(ctaDisabled(tester), isTrue);
    expect(
      find.text('Mobile numbers start with 6, 7, 8 or 9.'),
      findsOneWidget,
    );
  });

  testWidgets('edit mode strips the stored +91 back to ten digits',
      (tester) async {
    await pumpForm(tester, driver: _driver(phone: '+919746863592'));

    expect(phoneText(tester), '9746863592');
    expect(find.text('+91'), findsOneWidget);
  });
}

FieldDriver _driver({required String phone}) => FieldDriver(
      id: '2',
      name: 'Neeraja',
      phone: phone,
      email: 'n@d.test',
      status: DriverStatus.online,
      role: 'Hire driver',
      subRole: 'hire',
      joined: '2026-01-01',
      license: const DriverLicense(
        number: 'KL-07-2011-0001234',
        expiry: '01-2030',
        verified: true,
      ),
      jobsDone: 0,
      vehicleClasses: const ['Sedan'],
      today: const DriverPeriodStat(jobs: 0, earnings: 0),
      week: const DriverPeriodStat(jobs: 0, earnings: 0),
      documents: const [],
    );

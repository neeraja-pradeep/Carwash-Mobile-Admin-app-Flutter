import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/app/theme/dimens.dart';
import 'package:new_flutter_project/features/customers/domain/entities/customer.dart';
import 'package:new_flutter_project/features/customers/presentation/components/garage_tab_section.dart';

/// Renders the garage vehicle card under stress — a narrow device with a large
/// system font scale, the DEFAULT pill shown, and a full-length plate — the
/// exact combination that overflowed on the reporter's phone. A RenderFlex
/// overflow surfaces as an exception in tests, so `takeException()` must be null.
void main() {
  const vehicle = GarageVehicle(
    make: 'Suzuki',
    model: 'Swift',
    type: 'hatchback',
    plate: 'KL-04-AB-5230',
    isDefault: true,
    bookings: 1,
  );

  Future<void> pumpAt(WidgetTester tester, {required double width, required double textScale}) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(Dimens.designWidth, Dimens.designHeight),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: Padding(
                // Mirrors the customer-detail page horizontal padding.
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const GarageTabSection(vehicles: [vehicle]),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('no overflow on a narrow phone at normal font scale', (tester) async {
    await pumpAt(tester, width: 360, textScale: 1.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow on a narrow phone at large font scale', (tester) async {
    await pumpAt(tester, width: 320, textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow at extreme accessibility font scale', (tester) async {
    await pumpAt(tester, width: 320, textScale: 1.6);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/app/theme/dimens.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/features/bookings/presentation/components/customer_picker.dart';
import 'package:new_flutter_project/features/settings/presentation/components/edit_field_sheet.dart';
import 'package:new_flutter_project/features/shops/presentation/screens/shop_form_screen.dart';

/// Every phone input in the console is an Indian mobile: the +91 is a fixed
/// prefix the admin cannot type over, the field holds the ten national digits,
/// and what reaches the API is always E.164.
///
/// The hire form and login screen have their own suites; this covers the rest —
/// the shop form, the booking customer picker and the settings edit sheet.
void main() {
  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1140, 3400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(Dimens.designWidth, Dimens.designHeight),
          builder: (_, __) => MaterialApp(home: home),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder fieldFor(String hint) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint,
      );

  String textIn(WidgetTester tester, String hint) =>
      tester.widget<TextField>(fieldFor(hint)).controller?.text ?? '';

  group('shop form', () {
    /// Fields live in a scroll view — rewind to the top, then walk down.
    Future<void> enterInto(
      WidgetTester tester,
      String hint,
      String text,
    ) async {
      final field = fieldFor(hint);
      final scroller = find.byType(Scrollable).first;
      if (field.evaluate().isEmpty) {
        await tester.dragUntilVisible(field, scroller, const Offset(0, -150));
        await tester.pumpAndSettle();
      }
      await tester.enterText(field, text);
      await tester.pumpAndSettle();
    }

    testWidgets('+91 fronts both phone fields and is not typed', (tester) async {
      await pump(tester, const ShopFormScreen());

      // Owner phone and shop phone each carry the prefix.
      expect(find.text('+91'), findsNWidgets(2));
    });

    testWidgets('a pasted country code is absorbed, not duplicated',
        (tester) async {
      await pump(tester, const ShopFormScreen());
      await enterInto(tester, '98765 43210', '+91 98765 43210');

      expect(textIn(tester, '98765 43210'), '9876543210');
    });

    testWidgets('the owner phone will not hold more than ten digits',
        (tester) async {
      await pump(tester, const ShopFormScreen());
      await enterInto(tester, '98765 43210', '98765432101234');

      expect(textIn(tester, '98765 43210'), '9876543210');
    });

    testWidgets('an incomplete owner number blocks the save', (tester) async {
      await pump(tester, const ShopFormScreen());
      await enterInto(tester, 'e.g. SparkleWash Mullackal', 'Sparkle Motors');

      await enterInto(tester, '98765 43210', '98765');
      expect(find.text('Enter all 10 digits.'), findsOneWidget);
      expect(_ctaDisabled(tester), isTrue);

      await enterInto(tester, '98765 43210', '9876543210');
      expect(_ctaDisabled(tester), isFalse);
    });

    testWidgets('a half-typed optional shop phone still blocks the save',
        (tester) async {
      await pump(tester, const ShopFormScreen());
      await enterInto(tester, 'e.g. SparkleWash Mullackal', 'Sparkle Motors');
      await enterInto(tester, '98765 43210', '9876543210');
      expect(_ctaDisabled(tester), isFalse);

      // Optional means "leave it empty", not "leave it broken" — a partial
      // number would reach the API as an empty string.
      await enterInto(tester, 'Number drivers see', '987');
      expect(_ctaDisabled(tester), isTrue);

      await enterInto(tester, 'Number drivers see', '');
      expect(_ctaDisabled(tester), isFalse);
    });

    testWidgets('a non-mobile ten-digit number is refused', (tester) async {
      await pump(tester, const ShopFormScreen());
      await enterInto(tester, '98765 43210', '1234567890');

      expect(
        find.text('Mobile numbers start with 6, 7, 8 or 9.'),
        findsOneWidget,
      );
      expect(_ctaDisabled(tester), isTrue);
    });
  });

  group('booking customer picker', () {
    Future<void> openAddNew(WidgetTester tester) async {
      await tester.tap(find.text('Select or add customer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add new'));
      await tester.pumpAndSettle();
    }

    testWidgets('+91 fronts the mobile field', (tester) async {
      await pump(tester, CustomerPicker(onChanged: (_) {}));
      await openAddNew(tester);

      expect(find.text('+91'), findsOneWidget);
    });

    testWidgets('a pasted country code is absorbed, not duplicated',
        (tester) async {
      await pump(tester, CustomerPicker(onChanged: (_) {}));
      await openAddNew(tester);

      await tester.enterText(fieldFor('98765 43210'), '+91 98765 43210');
      await tester.pumpAndSettle();

      expect(textIn(tester, '98765 43210'), '9876543210');
    });

    testWidgets('the picked customer carries the E.164 number', (tester) async {
      CustomerPick? picked;
      await pump(tester, CustomerPicker(onChanged: (p) => picked = p));
      await openAddNew(tester);

      await tester.enterText(fieldFor('Customer name'), 'Ramesh Kurup');
      await tester.pumpAndSettle();
      await tester.enterText(fieldFor('98765 43210'), '9876543210');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add without OTP (override)'));
      await tester.pumpAndSettle();

      // The field held ten digits; downstream sees the dial code too.
      expect(picked?.phone, '+919876543210');
    });

    testWidgets('an incomplete number cannot be added', (tester) async {
      CustomerPick? picked;
      await pump(tester, CustomerPicker(onChanged: (p) => picked = p));
      await openAddNew(tester);

      await tester.enterText(fieldFor('Customer name'), 'Ramesh Kurup');
      await tester.pumpAndSettle();
      await tester.enterText(fieldFor('98765 43210'), '98765');
      await tester.pumpAndSettle();

      expect(find.text('Enter all 10 digits.'), findsOneWidget);
      await tester.tap(find.text('Add without OTP (override)'));
      await tester.pumpAndSettle();

      expect(picked, isNull);
    });
  });

  group('settings edit sheet', () {
    /// Opens the sheet the way the settings screen does, and hands back
    /// whatever `onSaved` received.
    Future<List<String>> openPhoneSheet(
      WidgetTester tester, {
      String? initialValue,
    }) async {
      final saved = <String>[];
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showEditFieldSheet(
                  context,
                  title: 'Support phone',
                  label: 'Support phone',
                  phone: true,
                  initialValue: initialValue,
                  onSaved: (v) async => saved.add(v),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return saved;
    }

    Finder sheetField() => find.byType(TextField);

    testWidgets('+91 fronts the field and the stored number unpacks',
        (tester) async {
      await openPhoneSheet(tester, initialValue: '+919746863592');

      expect(find.text('+91'), findsOneWidget);
      expect(
        tester.widget<TextField>(sheetField()).controller?.text,
        '9746863592',
      );
    });

    testWidgets('the saved value is E.164', (tester) async {
      final saved = await openPhoneSheet(tester);

      await tester.enterText(sheetField(), '9876543210');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved, ['+919876543210']);
    });

    testWidgets('a half-typed number cannot be saved', (tester) async {
      final saved = await openPhoneSheet(tester);

      await tester.enterText(sheetField(), '98765');
      await tester.pumpAndSettle();

      expect(find.text('Enter all 10 digits.'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Saving a partial number would hand the API an empty string and wipe
      // the support contact.
      expect(saved, isEmpty);
    });

    testWidgets('a pasted country code is absorbed, not duplicated',
        (tester) async {
      final saved = await openPhoneSheet(tester);

      await tester.enterText(sheetField(), '+91 98765 43210');
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(sheetField()).controller?.text,
        '9876543210',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved, ['+919876543210']);
    });
  });
}

/// The form's primary action is the last button on the screen.
bool _ctaDisabled(WidgetTester tester) =>
    tester.widget<AppButton>(find.byType(AppButton).last).disabled;

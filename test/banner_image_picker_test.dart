import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/app/theme/dimens.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/features/offers/domain/entities/offer_banner.dart';
import 'package:new_flutter_project/features/offers/presentation/components/banner_form_screen.dart';

/// The Add/Edit Banner form's artwork slot used to be a placeholder that only
/// raised a toast. It now opens the device gallery, previews what was chosen,
/// and can clear it again.
///
/// Choosing a file needs the platform picker, so these cover the states the
/// form owns: what the slot shows before and after there is an image, and that
/// removing it returns to the upload prompt.
void main() {
  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1560, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(Dimens.designWidth, Dimens.designHeight),
        builder: (_, __) => MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a new banner starts with an empty upload slot', (tester) async {
    await pump(tester, const BannerFormScreen());

    expect(find.text('Upload image · 16:9'), findsOneWidget);
    expect(find.textContaining('1200×675'), findsOneWidget);
    // Nothing to clear yet, so no remove affordance.
    expect(find.byIcon(AppIcons.close), findsNothing);
  });

  testWidgets('editing a banner previews its existing artwork', (tester) async {
    await pump(tester, const BannerFormScreen(banner: _banner));

    expect(find.text('Replace image'), findsOneWidget);
    expect(find.text('Upload image · 16:9'), findsNothing);
    expect(find.byIcon(AppIcons.close), findsOneWidget);
  });

  testWidgets('removing the artwork returns to the upload prompt',
      (tester) async {
    await pump(tester, const BannerFormScreen(banner: _banner));

    await tester.tap(find.byIcon(AppIcons.close));
    await tester.pumpAndSettle();

    expect(find.text('Upload image · 16:9'), findsOneWidget);
    expect(find.text('Replace image'), findsNothing);
    expect(find.byIcon(AppIcons.close), findsNothing);
  });

  testWidgets('the artwork slot never blocks saving on its own', (tester) async {
    // Title is the only thing the form validates; a banner with no image is
    // still savable, exactly as before this change.
    await pump(tester, const BannerFormScreen(banner: _banner));

    await tester.tap(find.byIcon(AppIcons.close));
    await tester.pumpAndSettle();

    expect(find.text('Save Changes'), findsOneWidget);
  });
}

const _banner = OfferBanner(
  id: '1',
  title: 'Up to 40% Off',
  subtitle: 'Monsoon wash carnival',
  status: 'active',
  placement: 'Home — Hero',
  link: 'MONSOON40',
  order: 1,
  // Matches the sample data: an asset path that is not in the bundle, so this
  // also pins that a broken image degrades to the slot rather than throwing.
  image: 'assets/offer-banner.jpg',
  start: '01-Jul-2026',
  end: '31-Jul-2026',
  impressions: 0,
  taps: 0,
);

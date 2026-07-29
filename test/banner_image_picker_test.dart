import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/app/theme/dimens.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/features/offers/application/providers/offers_providers.dart';
import 'package:new_flutter_project/features/offers/domain/entities/coupon.dart';
import 'package:new_flutter_project/features/offers/domain/entities/offer_banner.dart';
import 'package:new_flutter_project/features/offers/domain/repositories/offers_repository.dart';
import 'package:new_flutter_project/features/offers/presentation/components/banner_form_screen.dart';

/// The Add/Edit Banner form used to be a dead end: the artwork slot only raised
/// a toast, and saving discarded everything. It now picks artwork from the
/// gallery and writes to `/api/shop/v1/promotions/`, uploading the file as a
/// multipart `image`.
///
/// Choosing a file needs the platform picker, so these cover what the form
/// owns: the artwork slot's states, and the payload that reaches the
/// repository — including which of the three image intents it signals.
void main() {
  late _StubOffersRepository repo;

  /// Pushes [screen] onto a host route rather than making it `home`, because a
  /// successful save pops — as it does in the app, where the form is always
  /// pushed from the Offers screen.
  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1560, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [offersRepositoryProvider.overrideWithValue(repo)],
        child: ScreenUtilInit(
          designSize: const Size(Dimens.designWidth, Dimens.designHeight),
          builder: (_, __) => const MaterialApp(home: Scaffold()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final host = tester.element(find.byType(Scaffold));
    unawaited(Navigator.of(host).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    ));
    await tester.pumpAndSettle();
  }

  /// Saves, then lets the confirmation toast's ~2.8s timer expire so it does
  /// not outlive the widget tree.
  Future<void> tapSave(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
  }

  setUp(() => repo = _StubOffersRepository());

  group('artwork slot', () {
    testWidgets('a new banner starts empty', (tester) async {
      await pump(tester, const BannerFormScreen());

      expect(find.text('Upload image · 16:9'), findsOneWidget);
      expect(find.textContaining('1200×675'), findsOneWidget);
      // Nothing to clear yet, so no remove affordance.
      expect(find.byIcon(AppIcons.close), findsNothing);
    });

    testWidgets('editing previews the banner\'s CDN artwork', (tester) async {
      await pump(tester, BannerFormScreen(banner: _banner));

      expect(find.text('Replace image'), findsOneWidget);
      expect(find.text('Upload image · 16:9'), findsNothing);
      expect(find.byIcon(AppIcons.close), findsOneWidget);
    });

    testWidgets('removing returns to the upload prompt', (tester) async {
      await pump(tester, BannerFormScreen(banner: _banner));

      await tester.tap(find.byIcon(AppIcons.close));
      await tester.pumpAndSettle();

      expect(find.text('Upload image · 16:9'), findsOneWidget);
      expect(find.text('Replace image'), findsNothing);
    });
  });

  group('saving', () {
    testWidgets('an edit sends the window and placement to the API',
        (tester) async {
      await pump(tester, BannerFormScreen(banner: _banner));

      await tapSave(tester, 'Save Changes');

      expect(repo.updatedId, '1');
      final body = repo.updatedBody!;
      expect(body['title'], 'Up to 40% Off');
      expect(body['badge_text'], 'SPECIAL OFFER');
      expect(body['placement'], 'home_hero');
      expect(body['is_active'], isTrue);
      expect(body['display_order'], 2);
      // Sent as UTC instants, which is what the serializer stores.
      expect(body['starts_at'], endsWith('Z'));
      expect(body['ends_at'], endsWith('Z'));
      // `coupon` is omitted so an existing link is not cleared.
      expect(body.containsKey('coupon'), isFalse);
    });

    testWidgets('leaving the artwork alone keeps it', (tester) async {
      await pump(tester, BannerFormScreen(banner: _banner));

      await tapSave(tester, 'Save Changes');

      // Neither replace nor remove — the server leaves image_url untouched.
      expect(repo.updatedImagePath, isNull);
      expect(repo.updatedRemoveImage, isFalse);
    });

    testWidgets('clearing the artwork asks the server to delete it',
        (tester) async {
      await pump(tester, BannerFormScreen(banner: _banner));

      await tester.tap(find.byIcon(AppIcons.close));
      await tester.pumpAndSettle();
      await tapSave(tester, 'Save Changes');

      expect(repo.updatedRemoveImage, isTrue);
      expect(repo.updatedImagePath, isNull);
    });

    testWidgets('a new banner without dates is rejected before any request',
        (tester) async {
      await pump(tester, const BannerFormScreen());

      await tester.enterText(find.byType(TextField).first, 'Monsoon Sale');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Banner'));
      await tester.pumpAndSettle();

      // starts_at / ends_at are required by the serializer — catch it locally
      // rather than spending a round trip on a 400. Asserted before the toast's
      // own timer clears it.
      expect(find.text('Please set both validity dates.'), findsOneWidget);
      expect(repo.createdBody, isNull);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('deleting', () {
    testWidgets('is offered when editing', (tester) async {
      await pump(tester, BannerFormScreen(banner: _banner));

      // It sits at the bottom of the form, past the viewport.
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(find.text('Delete banner'), findsOneWidget);
    });

    testWidgets('is not offered when creating', (tester) async {
      await pump(tester, const BannerFormScreen());

      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(find.text('Delete banner'), findsNothing);
    });
  });

  group('OfferBanner', () {
    test('linkLabel prefers the deep link, then the coupon', () {
      expect(_banner.linkLabel, 'Screen: Referrals');
      expect(
        _banner.copyForTest(deepLink: null, couponId: 7).linkLabel,
        'Coupon #7',
      );
      expect(
        _banner.copyForTest(deepLink: null).linkLabel,
        'No link',
      );
    });

    test('expired is its own badge, not lumped in with inactive', () {
      expect(_banner.copyForTest(lifecycle: 'expired').statusDisplay.$1,
          'Expired');
      expect(_banner.copyForTest(lifecycle: 'inactive').statusDisplay.$1,
          'Inactive');
      expect(_banner.copyForTest(lifecycle: 'scheduled').statusDisplay.$1,
          'Scheduled');
    });
  });
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _banner = OfferBanner(
  id: '1',
  title: 'Up to 40% Off',
  subtitle: 'Monsoon wash carnival',
  badgeText: 'SPECIAL OFFER',
  placement: 'home_hero',
  isActive: true,
  displayOrder: 2,
  lifecycleStatus: 'active',
  impressionCount: 3240,
  tapCount: 412,
  imageUrl: 'https://cdn.example.com/promotions/ab12.webp',
  deepLink: 'Screen: Referrals',
  startsAt: DateTime(2026, 7, 1),
  endsAt: DateTime(2026, 7, 31, 23, 59, 59),
);

extension _BannerCopy on OfferBanner {
  OfferBanner copyForTest({
    String? deepLink,
    int? couponId,
    String? lifecycle,
  }) =>
      OfferBanner(
        id: id,
        title: title,
        subtitle: subtitle,
        badgeText: badgeText,
        placement: placement,
        isActive: isActive,
        displayOrder: displayOrder,
        lifecycleStatus: lifecycle ?? lifecycleStatus,
        impressionCount: impressionCount,
        tapCount: tapCount,
        imageUrl: imageUrl,
        deepLink: deepLink,
        couponId: couponId,
        startsAt: startsAt,
        endsAt: endsAt,
      );
}

/// Records what the form asked the repository to write.
class _StubOffersRepository implements OffersRepository {
  Map<String, dynamic>? createdBody;
  String? createdImagePath;

  String? updatedId;
  Map<String, dynamic>? updatedBody;
  String? updatedImagePath;
  bool? updatedRemoveImage;

  @override
  Future<OfferBanner> createBanner(
    Map<String, dynamic> body, {
    String? imagePath,
  }) async {
    createdBody = body;
    createdImagePath = imagePath;
    return _banner;
  }

  @override
  Future<OfferBanner> updateBanner(
    String id,
    Map<String, dynamic> body, {
    String? imagePath,
    bool removeImage = false,
  }) async {
    updatedId = id;
    updatedBody = body;
    updatedImagePath = imagePath;
    updatedRemoveImage = removeImage;
    return _banner;
  }

  @override
  Future<BannerPage> fetchBanners({
    String? search,
    String? placement,
    String? lifecycle,
    String? ordering,
    int page = 1,
  }) async =>
      BannerPage(banners: [_banner], count: 1);

  @override
  Future<CouponPage> fetchCoupons({
    String? search,
    String? lifecycle,
    String? ordering,
    int page = 1,
  }) async =>
      const CouponPage(coupons: <Coupon>[], count: 0);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/app/theme/dimens.dart';
import 'package:new_flutter_project/features/refunds/application/providers/refunds_providers.dart';
import 'package:new_flutter_project/features/refunds/domain/entities/refund.dart';
import 'package:new_flutter_project/features/refunds/domain/repositories/refunds_repository.dart';
import 'package:new_flutter_project/features/refunds/presentation/screens/refunds_screen.dart';
import 'package:new_flutter_project/features/reviews/application/providers/reviews_providers.dart';
import 'package:new_flutter_project/features/reviews/domain/entities/review.dart';
import 'package:new_flutter_project/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:new_flutter_project/features/reviews/presentation/screens/reviews_screen.dart';

/// Reviews and Refunds used to load behind a date window the admin never chose
/// (the API defaults to 7 days / 30 days), which hid older rows and produced a
/// "try clearing your filters" dead end. Both now open on all time and both
/// offer a Date filter that defaults to "All time" and counts as a chip once
/// narrowed — chosen by the admin, never assumed.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget screen,
    List<Override> overrides,
  ) async {
    tester.view.physicalSize = const Size(1560, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: ScreenUtilInit(
          designSize: const Size(Dimens.designWidth, Dimens.designHeight),
          builder: (_, __) => MaterialApp(home: screen),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Reviews', () {
    testWidgets('opens on all time rather than the API default 7-day window',
        (tester) async {
      final repo = _StubReviewsRepository(all: [_review]);
      await pump(tester, const ReviewsScreen(),
          [reviewsRepositoryProvider.overrideWithValue(repo)]);

      expect(repo.dates, ['all']);
      expect(find.text('Priya Menon'), findsOneWidget);
      expect(find.text('All time'), findsOneWidget);
    });

    testWidgets('filtering does not re-introduce a window', (tester) async {
      final repo = _StubReviewsRepository(all: [_review]);
      await pump(tester, const ReviewsScreen(),
          [reviewsRepositoryProvider.overrideWithValue(repo)]);

      await tester.enterText(find.byType(TextField).first, 'nobody');
      await tester.pumpAndSettle();

      expect(repo.dates.toSet(), {'all'});
      expect(find.text('No reviews match'), findsOneWidget);
      expect(find.text('Reset filters'), findsOneWidget);
    });

    testWidgets('an empty list with no filter reads as "no reviews yet"',
        (tester) async {
      final repo = _StubReviewsRepository();
      await pump(tester, const ReviewsScreen(),
          [reviewsRepositoryProvider.overrideWithValue(repo)]);

      expect(find.text('No reviews yet'), findsOneWidget);
      expect(find.textContaining('clearing your search'), findsNothing);
      expect(find.text('Reset filters'), findsNothing);
    });

    testWidgets('the filter sheet offers the date scope, defaulting to all time',
        (tester) async {
      final repo = _StubReviewsRepository(all: [_review]);
      await pump(tester, const ReviewsScreen(),
          [reviewsRepositoryProvider.overrideWithValue(repo)]);

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      expect(find.text('DATE'), findsOneWidget);
      expect(find.text('All time'), findsWidgets);
      expect(find.text('Last 7 days'), findsOneWidget);
      expect(find.text('Last 30 days'), findsOneWidget);
    });

    testWidgets('the sheet offers only server-backed filters', (tester) async {
      final repo = _StubReviewsRepository(all: [_review]);
      await pump(tester, const ReviewsScreen(),
          [reviewsRepositoryProvider.overrideWithValue(repo)]);

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      // Rating / Date / Content map to `rating`, `date` and `has_comment`.
      expect(find.text('RATING'), findsOneWidget);
      expect(find.text('DATE'), findsOneWidget);
      expect(find.text('CONTENT'), findsOneWidget);
      // Shop was filtered locally over the fetched page only — it is gone,
      // along with its chip built from the loaded rows.
      expect(find.text('SHOP'), findsNothing);
      expect(find.text('BubbleJet'), findsNothing);
    });

    testWidgets('choosing a window narrows the request and shows a chip',
        (tester) async {
      final repo = _StubReviewsRepository(all: [_review]);
      await pump(tester, const ReviewsScreen(),
          [reviewsRepositoryProvider.overrideWithValue(repo)]);

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 7 days'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();

      // The window reached the API, and it is visible as a removable chip.
      expect(repo.dates.last, '7d');
      expect(find.text('Last 7 days'), findsWidgets);
      // Rows outside the window are gone, and Reset filters widens again.
      expect(find.text('No reviews match'), findsOneWidget);
      await tester.tap(find.text('Reset filters'));
      await tester.pumpAndSettle();
      expect(repo.dates.last, 'all');
      expect(find.text('Priya Menon'), findsOneWidget);
    });
  });

  group('Refunds', () {
    testWidgets('asks the API for all time, never a 30-day window',
        (tester) async {
      final repo = _StubRefundsRepository(all: [_refund]);
      await pump(tester, const RefundsScreen(),
          [refundsRepositoryProvider.overrideWithValue(repo)]);

      expect(repo.days, [0]);
      expect(find.text('Priya Menon'), findsOneWidget);
      expect(find.text('All time'), findsOneWidget);
    });

    testWidgets('an empty list with no filter reads as "no refunds yet"',
        (tester) async {
      final repo = _StubRefundsRepository();
      await pump(tester, const RefundsScreen(),
          [refundsRepositoryProvider.overrideWithValue(repo)]);

      expect(find.text('No refunds yet'), findsOneWidget);
      expect(find.text('Reset filters'), findsNothing);
    });

    testWidgets('the filter sheet offers the date scope, defaulting to all time',
        (tester) async {
      final repo = _StubRefundsRepository(all: [_refund]);
      await pump(tester, const RefundsScreen(),
          [refundsRepositoryProvider.overrideWithValue(repo)]);

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      expect(find.text('DATE'), findsOneWidget);
      expect(find.text('All time'), findsWidgets);
      expect(find.text('Last 7 days'), findsOneWidget);
      expect(find.text('Last 30 days'), findsOneWidget);
      // The window the admin has not narrowed is still all time.
      expect(repo.days, [0]);
    });

    testWidgets('choosing a window narrows the request and shows a chip',
        (tester) async {
      final repo = _StubRefundsRepository(all: [_refund]);
      await pump(tester, const RefundsScreen(),
          [refundsRepositoryProvider.overrideWithValue(repo)]);

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 7 days'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();

      // The window reached the API, and it is visible as a removable chip.
      expect(repo.days.last, 7);
      expect(find.text('Last 7 days'), findsWidgets);
      // Rows outside the window are gone, and Reset filters widens again.
      expect(find.text('No refunds match'), findsOneWidget);
      await tester.tap(find.text('Reset filters'));
      await tester.pumpAndSettle();
      expect(repo.days.last, 0);
      expect(find.text('Priya Menon'), findsOneWidget);
    });

    testWidgets('typing in search does not refetch behind a new window',
        (tester) async {
      final repo = _StubRefundsRepository(all: [_refund]);
      await pump(tester, const RefundsScreen(),
          [refundsRepositoryProvider.overrideWithValue(repo)]);

      await tester.enterText(find.byType(TextField).first, 'Priya');
      await tester.pumpAndSettle();

      // Search is applied locally; only the date window drives a refetch.
      expect(repo.days, [0]);
      expect(find.text('Priya Menon'), findsOneWidget);
    });
  });
}

// ── Stubs ─────────────────────────────────────────────────────────────────────

const _review = Review(
  id: '1',
  rating: 5,
  customer: 'Priya Menon',
  phone: '+919876543210',
  shop: 'BubbleJet Express',
  date: '18-Jun-2026',
  time: '10:30 AM',
  bookingId: 'DT-0618-0001',
  drivers: ['Ramesh'],
  text: 'Spotless.',
);

const _refund = Refund(
  id: '1',
  reference: 'RF-1001',
  amount: 450,
  status: 'requested',
  bookingId: '1',
  customer: RefundCustomer(name: 'Priya Menon', phone: '+919876543210'),
  tier: 'full',
  reason: 'service_quality_issue',
  notes: '',
  createdAt: '22-Jun-2026',
  utr: '',
  proof: false,
);

/// Records every `date` the screen asks for; the rows are old enough that a
/// 7-day window would have excluded them.
class _StubReviewsRepository implements ReviewsRepository {
  _StubReviewsRepository({this.all = const []});

  final List<Review> all;
  final List<String?> dates = [];

  @override
  Future<ReviewsPage> fetchReviews({
    String? search,
    String? rating,
    int? shop,
    String? date,
    bool? hasComment,
    String? sort,
    int page = 1,
    int pageSize = 20,
  }) async {
    dates.add(date);
    var rows = date == 'all' ? all : const <Review>[];
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      rows = rows
          .where((r) =>
              r.customer.toLowerCase().contains(q) ||
              r.shop.toLowerCase().contains(q))
          .toList();
    }
    return ReviewsPage(reviews: rows, count: rows.length);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

/// Records every `days` window the screen asks for; only `0` returns rows.
class _StubRefundsRepository implements RefundsRepository {
  _StubRefundsRepository({this.all = const []});

  final List<Refund> all;
  final List<int> days = [];

  @override
  Future<List<Refund>> fetchRefunds({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? status,
    String? reason,
    String? sort,
    int days = 30,
  }) async {
    this.days.add(days);
    return days == 0 ? all : const <Refund>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

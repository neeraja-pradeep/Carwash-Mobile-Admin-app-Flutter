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

/// Reviews and Refunds both load behind a date window the admin never chose
/// (7 and 30 days). When that window is what empties the list, the screen must
/// say so and offer a way out — not "try clearing your filters" plus a reset
/// that re-applies the very same window.
void main() {
  Future<void> pump(WidgetTester tester, Widget screen, List<Override> overrides) async {
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
    testWidgets('names the date window instead of blaming filters',
        (tester) async {
      final repo = _StubReviewsRepository();
      await pump(tester, const ReviewsScreen(),
          [reviewsRepositoryProvider.overrideWithValue(repo)]);

      expect(find.text('No reviews in the last 7 days'), findsOneWidget);
      expect(find.textContaining('clearing your search'), findsNothing);
      expect(find.text('Reset filters'), findsNothing);
      expect(repo.lastDate, '7d');
    });

    testWidgets('"Show all time" widens the window and refetches',
        (tester) async {
      final repo = _StubReviewsRepository(allTime: [_review]);
      await pump(tester, const ReviewsScreen(),
          [reviewsRepositoryProvider.overrideWithValue(repo)]);

      await tester.tap(find.text('Show all time'));
      await tester.pumpAndSettle();

      expect(repo.lastDate, 'all');
      expect(find.text('Priya Menon'), findsOneWidget);
      // The top bar reflects the widened scope.
      expect(find.text('All time'), findsOneWidget);
    });

    testWidgets('still blames the filter when the admin set one',
        (tester) async {
      final repo = _StubReviewsRepository();
      await pump(tester, const ReviewsScreen(),
          [reviewsRepositoryProvider.overrideWithValue(repo)]);

      await tester.enterText(find.byType(TextField).first, 'nobody');
      await tester.pumpAndSettle();

      expect(find.text('No reviews match'), findsOneWidget);
      expect(find.text('Reset filters'), findsOneWidget);
    });

    testWidgets('says "no reviews yet" when all time is also empty',
        (tester) async {
      final repo = _StubReviewsRepository();
      await pump(tester, const ReviewsScreen(),
          [reviewsRepositoryProvider.overrideWithValue(repo)]);

      await tester.tap(find.text('Show all time'));
      await tester.pumpAndSettle();

      expect(find.text('No reviews yet'), findsOneWidget);
      expect(find.text('Show all time'), findsNothing);
    });
  });

  group('Refunds', () {
    testWidgets('names the date window instead of blaming filters',
        (tester) async {
      final repo = _StubRefundsRepository();
      await pump(tester, const RefundsScreen(),
          [refundsRepositoryProvider.overrideWithValue(repo)]);

      expect(find.text('No refunds in the last 30 days'), findsOneWidget);
      expect(find.text('Reset filters'), findsNothing);
      expect(repo.lastDays, 30);
    });

    testWidgets('"Show all time" drops the window and refetches',
        (tester) async {
      final repo = _StubRefundsRepository(allTime: [_refund]);
      await pump(tester, const RefundsScreen(),
          [refundsRepositoryProvider.overrideWithValue(repo)]);

      await tester.tap(find.text('Show all time'));
      await tester.pumpAndSettle();

      expect(repo.lastDays, 0);
      expect(find.text('All time'), findsOneWidget);
      // The row itself is rendered (the card leads with customer + amount).
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

/// Empty inside the 7/30-day window; returns [allTime] only for `date=all`.
class _StubReviewsRepository implements ReviewsRepository {
  _StubReviewsRepository({this.allTime = const []});

  final List<Review> allTime;
  String? lastDate;

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
    lastDate = date;
    final rows = date == 'all' ? allTime : const <Review>[];
    return ReviewsPage(reviews: rows, count: rows.length);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

/// Empty inside the 30-day window; returns [allTime] only for `days=0`.
class _StubRefundsRepository implements RefundsRepository {
  _StubRefundsRepository({this.allTime = const []});

  final List<Refund> allTime;
  int? lastDays;

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
    lastDays = days;
    return days == 0 ? allTime : const <Refund>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

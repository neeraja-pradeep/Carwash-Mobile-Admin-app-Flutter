import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/app/theme/dimens.dart';
import 'package:new_flutter_project/features/payouts/application/providers/payouts_providers.dart';
import 'package:new_flutter_project/features/payouts/domain/repositories/payouts_repository.dart';
import 'package:new_flutter_project/features/payouts/presentation/screens/payouts_screen.dart';
import 'package:new_flutter_project/features/shops/application/providers/shops_providers.dart';

/// The Payout Log's date window used to be a fixed 90 days baked into the
/// screen (only visible as a top-bar subtitle). It is now a filter the admin
/// picks in the sheet, defaulting to all time.
void main() {
  Future<void> pump(WidgetTester tester, _StubPayoutsRepository repo) async {
    tester.view.physicalSize = const Size(1560, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          payoutsRepositoryProvider.overrideWithValue(repo),
          shopsProvider.overrideWith((ref) async => []),
        ],
        child: ScreenUtilInit(
          designSize: const Size(Dimens.designWidth, Dimens.designHeight),
          builder: (_, __) => const MaterialApp(home: PayoutsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on all time, not the API default 90-day window',
      (tester) async {
    final repo = _StubPayoutsRepository();
    await pump(tester, repo);

    // 36500 = all time; `days=0` would mean an empty window on this API.
    expect(repo.days, [36500]);
    expect(find.text('All time'), findsOneWidget);
  });

  testWidgets('the filter sheet carries the date scope', (tester) async {
    final repo = _StubPayoutsRepository();
    await pump(tester, repo);
    await openSheet(tester);

    expect(find.text('DATE'), findsOneWidget);
    expect(find.text('All time'), findsWidgets);
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.text('Last 90 days'), findsOneWidget);
  });

  testWidgets('choosing a window narrows the request and shows a chip',
      (tester) async {
    final repo = _StubPayoutsRepository();
    await pump(tester, repo);
    await openSheet(tester);

    await tester.tap(find.text('Last 30 days'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(repo.days.last, 30);
    // Shown both as the top-bar scope and as a removable chip; removing the
    // chip widens back to all time.
    expect(find.text('Last 30 days'), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();
    expect(repo.days.last, 36500);
  });

  testWidgets('a status chip can be deselected again', (tester) async {
    final repo = _StubPayoutsRepository();
    await pump(tester, repo);
    await openSheet(tester);

    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();
    expect(repo.statuses.last, 'pending');

    // Tapping the active chip clears it — copyWith must treat an explicit
    // null as "clear", not as "unchanged". `.last` is the sheet's chip; the
    // screen's active-filter row now carries one with the same label.
    await tester.tap(find.text('Pending').last);
    await tester.pumpAndSettle();
    expect(repo.statuses.last, isNull);
  });
}

final _payout = PayoutLogItem(
  id: 1,
  reference: 'PO-20260617-001',
  shop: 4,
  shopName: 'SparkleWash Mullackal',
  grossAmount: 2320,
  commissionAmount: 232,
  refundsTotal: 0,
  otherAdjustments: 0,
  totalAmount: 2088,
  bookingCount: 6,
  status: 'pending',
  periodStart: '2026-06-01',
  periodEnd: '2026-06-15',
  createdBy: 5,
  createdByName: 'Admin0',
  createdAt: DateTime(2026, 6, 17),
  items: const [],
);

/// Records the window and status every request asks for. Always returns one
/// row so the list (and with it the Filter control) renders.
class _StubPayoutsRepository implements PayoutsRepository {
  final List<int?> days = [];
  final List<String?> statuses = [];

  @override
  Future<PayoutsPage> fetchPayoutLog({
    String? search,
    String? status,
    String? shop,
    String? sort,
    int? days,
    int page = 1,
    int pageSize = 10,
  }) async {
    this.days.add(days);
    statuses.add(status);
    return PayoutsPage(items: [_payout], total: 1, hasNextPage: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

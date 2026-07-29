import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/app/theme/dimens.dart';
import 'package:new_flutter_project/features/payouts/presentation/screens/new_payout_screen.dart';
import 'package:new_flutter_project/features/shops/application/providers/shops_providers.dart';
import 'package:new_flutter_project/features/shops/domain/entities/shop.dart';
import 'package:new_flutter_project/features/shops/domain/repositories/shops_repository.dart';
import 'package:new_flutter_project/features/shops/infrastructure/data_sources/local/shops_local_ds.dart';

/// "Create Payout" used to be a stub — it showed a toast and popped without
/// calling anything, so the payout never existed and never appeared in the log.
/// It must POST to the settlement endpoint and surface the real net.
void main() {
  late List<Shop> shops;

  setUpAll(() async {
    shops = await const ShopsLocalDs().fetchShops();
  });

  Future<void> pump(WidgetTester tester, _StubShopsRepository repo) async {
    tester.view.physicalSize = const Size(1560, 3000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shopsRepositoryProvider.overrideWithValue(repo),
          shopsProvider.overrideWith((ref) async => shops),
        ],
        child: ScreenUtilInit(
          designSize: const Size(Dimens.designWidth, Dimens.designHeight),
          builder: (_, __) => MaterialApp(
            home: NewPayoutScreen(prefillShopId: shops.first.id),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder cta() => find.textContaining('Create Payout ·');

  /// The toast holds a 2.8s timer; let it expire so the tree can be disposed
  /// without a pending-timer assertion.
  Future<void> settleToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the real pending net, not a locally invented one',
      (tester) async {
    final repo = _StubShopsRepository(netPayable: 2088, count: 3);
    await pump(tester, repo);

    expect(repo.pendingRequestedFor, [shops.first.id]);
    expect(find.text('₹2,088'), findsOneWidget);
    expect(find.textContaining('Settles all 3 pending'), findsOneWidget);
    expect(find.text('Create Payout · ₹2,088'), findsOneWidget);
  });

  testWidgets('the CTA posts the payout for the selected shop', (tester) async {
    final repo = _StubShopsRepository(netPayable: 2088, count: 3);
    await pump(tester, repo);

    await tester.tap(cta());
    await tester.pumpAndSettle();

    expect(repo.createdFor, [shops.first.id]);
    await settleToast(tester);
  });

  testWidgets('nothing pending disables the CTA instead of faking a payout',
      (tester) async {
    final repo = _StubShopsRepository(netPayable: 0, count: 0);
    await pump(tester, repo);

    expect(find.textContaining('Nothing pending'), findsOneWidget);
    await tester.tap(find.text('Create Payout'));
    await tester.pumpAndSettle();
    expect(repo.createdFor, isEmpty);
  });

  testWidgets('a rejected payout surfaces the server message and stays put',
      (tester) async {
    final repo = _StubShopsRepository(
      netPayable: 2088,
      count: 3,
      createError: Exception('No pending settlements for this shop.'),
    );
    await pump(tester, repo);

    await tester.tap(cta());
    await tester.pumpAndSettle();

    expect(find.text('No pending settlements for this shop.'), findsOneWidget);
    // Still on the form — the CTA is back, not popped away.
    expect(cta(), findsOneWidget);
    await settleToast(tester);
  });
}

/// Records what the screen asked the settlement endpoints for.
class _StubShopsRepository implements ShopsRepository {
  _StubShopsRepository({
    required this.netPayable,
    required this.count,
    this.createError,
  });

  final double netPayable;
  final int count;
  final Object? createError;

  final List<String> pendingRequestedFor = [];
  final List<String> createdFor = [];

  @override
  Future<SettlementPending> fetchPendingSettlements(String shopId) async {
    pendingRequestedFor.add(shopId);
    return SettlementPending(
      shopId: int.tryParse(shopId.replaceAll(RegExp(r'\D'), '')) ?? 0,
      count: count,
      netPayable: netPayable,
      pendingTotal: netPayable,
      lifetimePaid: 0,
      items: const [],
    );
  }

  @override
  Future<SettlementPayout> createPayout(
    String shopId, {
    String? utr,
    String? notes,
  }) async {
    if (createError != null) throw createError!;
    createdFor.add(shopId);
    return SettlementPayout(
      id: 88,
      shop: 1,
      grossAmount: 2320,
      commissionAmount: 232,
      totalAmount: netPayable,
      bookingCount: count,
      status: 'paid',
      periodStart: '2026-05-27',
      periodEnd: '2026-05-29',
      createdBy: 1,
      createdByName: 'Super Admin',
      createdAt: DateTime(2026, 7, 29),
      items: const [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

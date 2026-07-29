import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/app/theme/dimens.dart';
import 'package:new_flutter_project/features/bookings/application/providers/bookings_providers.dart';
import 'package:new_flutter_project/features/refunds/application/providers/refunds_providers.dart';
import 'package:new_flutter_project/features/refunds/domain/entities/refund.dart';
import 'package:new_flutter_project/features/refunds/domain/repositories/refunds_repository.dart';
import 'package:new_flutter_project/features/refunds/presentation/screens/refund_detail_screen.dart';

/// The refunds list mixes two kinds of row: real `BookingRefund` rows
/// (`kind: "refund"`) and entries the API *synthesizes* for bookings sitting in
/// `refund_requested` (`kind: "request"`). Only the first kind exists behind
/// `GET /refunds/detail/{id_or_reference}/` — opening a request row used to ask
/// for it anyway and land on "Refund not found.", which is every row an admin
/// most needs to act on.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget screen,
    RefundsRepository repo,
  ) async {
    tester.view.physicalSize = const Size(1560, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          refundsRepositoryProvider.overrideWithValue(repo),
          // The screen also looks up the underlying booking to decide whether
          // the row links through to it. Unrelated to this fix, and its local
          // fallback leaves a pending timer — stub it out.
          bookingByIdProvider.overrideWith((ref, id) => null),
        ],
        child: ScreenUtilInit(
          designSize: const Size(Dimens.designWidth, Dimens.designHeight),
          builder: (_, __) => MaterialApp(home: screen),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('a synthesized request row', () {
    testWidgets('renders from the list row instead of 404-ing', (tester) async {
      final repo = _StubRefundsRepository();
      await pump(
        tester,
        // `refundId` is what the list had to fall back to — not a refund id.
        const RefundDetailScreen(refundId: '4', seed: _request),
        repo,
      );

      expect(find.text('Refund not found.'), findsNothing);
      expect(find.text('neeraja'), findsOneWidget);
      // The detail endpoint has nothing for this row, so it is never asked.
      expect(repo.detailCalls, isEmpty);
    });

    testWidgets('offers Approve and Decline', (tester) async {
      await pump(
        tester,
        const RefundDetailScreen(refundId: '4', seed: _request),
        _StubRefundsRepository(),
      );

      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('shows a stepper stopped at Requested', (tester) async {
      await pump(
        tester,
        const RefundDetailScreen(refundId: '4', seed: _request),
        _StubRefundsRepository(),
      );

      expect(find.text('Requested'), findsWidgets);
      expect(find.text('Approved'), findsWidgets);
      expect(find.text('Paid'), findsWidgets);
    });
  });

  group('a real refund row', () {
    testWidgets('still resolves against the detail endpoint', (tester) async {
      final repo = _StubRefundsRepository();
      await pump(
        tester,
        const RefundDetailScreen(refundId: 'RF-1001', seed: _paid),
        repo,
      );

      expect(repo.detailCalls, ['RF-1001']);
      expect(find.text('Arjun Kapoor'), findsOneWidget);
    });
  });

  group('Refund entity', () {
    test('isRequestOnly keys off kind, not the missing reference', () {
      expect(_request.isRequestOnly, isTrue);
      expect(_paid.isRequestOnly, isFalse);
    });

    test('a request derives the stepper the API never sent', () {
      final steps = _request.displaySteps;

      expect(steps.map((s) => s.key), ['requested', 'approved', 'paid']);
      expect(steps.first.done, isTrue);
      expect(steps.first.at, _request.createdAt);
      expect(steps.skip(1).every((s) => s.done), isFalse);
      expect(_request.displayNextAction, 'approve');
    });

    test('a real row keeps whatever the API sent', () {
      // Empty `steps` on a real row means the API sent none — do not invent any.
      expect(_paid.displaySteps, isEmpty);
      expect(_paid.displayNextAction, isNull);
    });
  });
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

/// A booking awaiting a decision. The API echoes the booking id as `id` and
/// leaves `reference` null, so `detailKey` falls back to a non-refund id.
const _request = Refund(
  id: '4',
  reference: null,
  kind: 'request',
  amount: 739,
  status: 'requested',
  bookingId: '4',
  bookingReference: 'SR-DR-20260618-002',
  bookingType: 'driver_inspection',
  customer: RefundCustomer(name: 'neeraja', phone: '+919746863592'),
  tier: 'N/A',
  reason: 'cancellation_by_customer',
  notes: '',
  createdAt: '18-Jun-2026',
  utr: '',
  proof: false,
);

const _paid = Refund(
  id: '1',
  reference: 'RF-1001',
  kind: 'refund',
  amount: 100,
  status: 'paid',
  bookingId: '40',
  bookingReference: 'DT-0040-26',
  bookingType: 'carwash',
  customer: RefundCustomer(name: 'Arjun Kapoor', phone: '+919876543210'),
  tier: '100%',
  reason: 'cancellation_by_customer',
  notes: '',
  createdAt: '22-Jun-2026',
  utr: '',
  proof: false,
);

/// Records every detail lookup so a test can assert one never happened.
class _StubRefundsRepository implements RefundsRepository {
  final List<String> detailCalls = [];

  @override
  Future<Refund?> getRefundDetail(String idOrReference) async {
    detailCalls.add(idOrReference);
    // Mirrors the server: only real rows resolve.
    if (idOrReference == 'RF-1001') return _paid;
    throw Exception('Refund not found.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

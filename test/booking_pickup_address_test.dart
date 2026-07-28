import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/app/theme/dimens.dart';
import 'package:new_flutter_project/features/bookings/presentation/screens/new_booking_screen.dart';
import 'package:new_flutter_project/features/customers/application/providers/customers_providers.dart';
import 'package:new_flutter_project/features/customers/domain/entities/customer.dart';
import 'package:new_flutter_project/features/customers/domain/repositories/customers_repository.dart';
import 'package:new_flutter_project/features/shops/application/providers/shops_providers.dart';

/// New Booking step 5 (Pickup) must offer the selected customer's saved
/// addresses instead of a bare text box, and lock the box when they have none.
void main() {
  const customer = Customer(
    id: '3',
    name: 'Arjun Nair',
    phone: '+919876543210',
    email: 'arjun@example.com',
    joined: '17-Jun-2026',
    blocked: false,
    blockedReason: '',
    notes: '',
    bookings: 0,
    spend: 0,
    lastBooking: '',
    accountAge: '1 month',
    addresses: [],
    vehicles: [],
    history: [],
  );

  const addresses = [
    SavedAddress(
      id: 7,
      label: 'home',
      text: 'H8CP+GJH, Mannanchery, 688538',
      isDefault: true,
      latitude: 9.570718196797932,
      longitude: 76.33691091203626,
    ),
    SavedAddress(
      id: 4,
      label: 'work',
      text: '259, Near Thathampally Junction, Alappuzha, Kerala, 688009',
      isDefault: false,
    ),
  ];

  Future<void> pumpForm(
    WidgetTester tester, {
    List<SavedAddress> saved = addresses,
  }) async {
    tester.view.physicalSize = const Size(1140, 4000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customersRepositoryProvider.overrideWithValue(
            _StubCustomersRepository(
              customers: const [customer],
              addresses: saved,
            ),
          ),
          // The shop step is irrelevant here and would otherwise hit the network.
          shopsProvider.overrideWith((ref) async => []),
        ],
        child: ScreenUtilInit(
          designSize: const Size(Dimens.designWidth, Dimens.designHeight),
          builder: (_, __) => const MaterialApp(home: NewBookingScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectCustomer(WidgetTester tester) async {
    await tester.tap(find.text('Select or add customer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arjun Nair').last);
    await tester.pumpAndSettle();
  }

  testWidgets('pickup address becomes a dropdown over saved addresses',
      (tester) async {
    await pumpForm(tester);

    // Free text until a customer is chosen.
    expect(
      find.widgetWithText(TextField, 'Pickup address'),
      findsOneWidget,
    );
    expect(find.text('Select saved address'), findsNothing);

    await selectCustomer(tester);
    expect(find.text('Select saved address'), findsOneWidget);

    final dropdown = find.byType(DropdownButton<SavedAddress>);
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.text('work'), findsOneWidget);
    expect(find.text('DEFAULT'), findsOneWidget);

    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
    expect(find.text(addresses[0].text), findsOneWidget);
  });

  testWidgets('a customer with no saved addresses gets a disabled pickup box',
      (tester) async {
    await pumpForm(tester, saved: const []);
    await selectCustomer(tester);

    expect(find.text('Select saved address'), findsNothing);
    expect(
      find.text('This customer has no saved addresses. Ask them to save one '
          'in the Drivey app, then create the booking.'),
      findsOneWidget,
    );

    final pickup = tester.widget<TextField>(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText == 'No saved address to pick',
      ),
    );
    expect(pickup.enabled, isFalse);
  });
}

/// Minimal [CustomersRepository] stub — only the paths the booking form walks.
class _StubCustomersRepository implements CustomersRepository {
  _StubCustomersRepository({required this.customers, required this.addresses});

  final List<Customer> customers;
  final List<SavedAddress> addresses;

  @override
  Future<List<Customer>> fetchCustomers({
    String? search,
    String? status,
    String? joined,
    String? bookingCount,
    String? sort,
  }) async =>
      customers;

  @override
  Future<List<SavedAddress>> fetchSavedAddresses(String customerId) async =>
      addresses;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

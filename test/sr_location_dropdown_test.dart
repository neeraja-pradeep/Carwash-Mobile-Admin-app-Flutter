import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/app/theme/dimens.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/features/customers/application/providers/customers_providers.dart';
import 'package:new_flutter_project/features/customers/domain/entities/customer.dart';
import 'package:new_flutter_project/features/customers/domain/repositories/customers_repository.dart';
import 'package:new_flutter_project/features/service_requests/domain/entities/service_request.dart';
import 'package:new_flutter_project/features/service_requests/presentation/screens/new_service_request_screen.dart';

/// The New Driver Hire form must turn its free-text Location box into a picker
/// over the selected customer's saved addresses. These tests drive the real
/// screen with a stubbed repository standing in for
/// `/api/accounts/v1/addresses/?user_id=…`.
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
    Object? addressesError,
  }) async {
    tester.view.physicalSize = const Size(1140, 3200);
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
              addressesError: addressesError,
            ),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(Dimens.designWidth, Dimens.designHeight),
          builder: (_, __) => const MaterialApp(
            home: NewServiceRequestScreen(kind: SrKind.driver),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Walks the customer picker: open the sheet, tap the only customer.
  Future<void> selectCustomer(WidgetTester tester) async {
    await tester.tap(find.text('Select or add customer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arjun Nair').last);
    await tester.pumpAndSettle();
  }

  /// The Location control sits below the fold on a phone-sized surface, so it
  /// has to be scrolled into view before it can be tapped.
  Future<void> openAddressMenu(WidgetTester tester) async {
    final dropdown = find.byType(DropdownButton<SavedAddress>);
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
  }

  testWidgets('saved addresses become a dropdown once a customer is picked',
      (tester) async {
    await pumpForm(tester);

    // Before a customer is chosen the location stays free text.
    expect(find.text('Select saved address'), findsNothing);

    await selectCustomer(tester);

    expect(find.text('Select saved address'), findsOneWidget);

    // Open the menu — both saved addresses are offered, default flagged.
    await openAddressMenu(tester);
    expect(find.text('home'), findsOneWidget);
    expect(find.text('work'), findsOneWidget);
    expect(find.text('DEFAULT'), findsOneWidget);
    expect(find.text('Type a different address'), findsWidgets);

    // Picking one collapses the menu onto that address.
    await tester.tap(find.text('work'));
    await tester.pumpAndSettle();
    expect(find.text(addresses[1].text), findsOneWidget);
    expect(find.text('Select saved address'), findsNothing);
  });

  testWidgets('"type a different address" reopens the free-text field',
      (tester) async {
    await pumpForm(tester);
    await selectCustomer(tester);

    await openAddressMenu(tester);
    await tester.tap(find.text('Type a different address').last);
    await tester.pumpAndSettle();

    // The dropdown stays put, with a free-text "Address" box underneath it.
    expect(find.byType(DropdownButton<SavedAddress>), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Pick-up / inspection address'),
      findsOneWidget,
    );
  });

  testWidgets('a customer with no saved addresses gets a disabled field',
      (tester) async {
    await pumpForm(tester, saved: const []);
    await selectCustomer(tester);

    expect(find.text('Select saved address'), findsNothing);
    expect(
      find.text('This customer has no saved addresses. Ask them to save one '
          'in the Drivey app, then create the request.'),
      findsOneWidget,
    );

    // The box is locked, so the request can't be created without an address.
    final location = tester.widget<TextField>(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'No saved address to pick',
      ),
    );
    expect(location.enabled, isFalse);

    // The submit button lives at the bottom of the ListView, so it has to be
    // scrolled into existence before it can be inspected.
    await tester.dragUntilVisible(
      find.byType(AppButton),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<AppButton>(find.byType(AppButton)).disabled, isTrue);
  });

  testWidgets('a failed address fetch degrades to free-text entry',
      (tester) async {
    await pumpForm(tester, addressesError: Exception('boom'));
    await selectCustomer(tester);

    expect(find.text('Select saved address'), findsNothing);
    expect(
      find.text("Couldn't load saved addresses — type the address instead."),
      findsOneWidget,
    );
  });
}

/// Minimal [CustomersRepository] stub — only the paths the create form walks.
class _StubCustomersRepository implements CustomersRepository {
  _StubCustomersRepository({
    required this.customers,
    required this.addresses,
    this.addressesError,
  });

  final List<Customer> customers;
  final List<SavedAddress> addresses;
  final Object? addressesError;

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
  Future<List<SavedAddress>> fetchSavedAddresses(String customerId) async {
    if (addressesError != null) throw addressesError!;
    return addresses;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

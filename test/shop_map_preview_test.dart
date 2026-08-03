import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:new_flutter_project/features/shops/application/providers/shops_providers.dart';
import 'package:new_flutter_project/features/shops/domain/entities/holiday.dart';
import 'package:new_flutter_project/features/shops/domain/entities/shop.dart';
import 'package:new_flutter_project/features/shops/presentation/components/info_section.dart';

/// The Info tab's map preview shows the shop where it actually is. It used to be
/// a painted gradient that never plotted anything, so a shop's real coordinates
/// were invisible on the way to the external map app.
void main() {
  Shop shopAt({double lat = 0, double lng = 0}) => Shop(
        id: '1',
        name: 'Test Car Shop',
        area: 'Vyasapuram, Alappuzha',
        ownerName: 'Neeraja Owner',
        ownerPhone: '+919467375421',
        shopPhone: '+916437216457',
        address: 'G8HQ+5PX, Vyasapuram, Alappuzha, Kerala',
        rating: 0,
        reviews: 0,
        todayBookings: 0,
        cap: 20,
        avgServiceMin: 30,
        active: true,
        vehicleTypes: const ['Hatchback'],
        commission: const Commission(mode: CommissionMode.percentage, pct: 15),
        bank: const BankDetails(
          accName: '',
          accNo: '',
          ifsc: '',
          upi: '',
          gstin: '',
          pan: '',
        ),
        hours: const [],
        photos: const <ShopPhoto>[],
        onboarded: const EditMeta(date: '2026-07-31', by: ''),
        lastEdited: const EditMeta(date: '2026-07-31', by: ''),
        services: const [],
        settlement: const Settlement(
          lastSettled: '',
          lifetimePaid: 0,
          pending: [],
          history: [],
        ),
        weekly: const [],
        slotCapacityEnabled: false,
        slotCap: 20,
        pincode: '688006',
        latitude: lat,
        longitude: lng,
      );

  /// Wider than a phone, and the design size is pinned to it so ScreenUtil
  /// scales 1:1. Under `flutter test` the real fonts are never loaded and the
  /// fallback draws every glyph as a fixed-width box far wider than Figtree, so
  /// laying the Info tab out at the true design width overflows rows that are
  /// comfortable on a device.
  const viewport = Size(900, 3000);

  Future<void> pumpInfo(WidgetTester tester, Shop shop) async {
    tester.view.physicalSize = viewport * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Holidays are fetched over the network by the Info tab; nothing here
          // depends on them.
          shopHolidaysProvider(shop.id).overrideWith((ref) async => <Holiday>[]),
        ],
        child: ScreenUtilInit(
          designSize: viewport,
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: InfoSection(
                  shop: shop,
                  active: shop.active,
                  onActiveChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Not pumpAndSettle: the tile layer keeps retrying its (unreachable) network
    // requests for the whole test, so the tree never goes quiet.
    await tester.pump();
  }

  testWidgets('a pinned shop gets a real map centred on its coordinates',
      (tester) async {
    await pumpInfo(tester, shopAt(lat: 9.497206995598628, lng: 76.34321476102275));

    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter.latitude, closeTo(9.4972069, 1e-6));
    expect(map.options.initialCenter.longitude, closeTo(76.3432147, 1e-6));

    expect(find.text('No location pinned'), findsNothing);
  });

  testWidgets('the pin is plotted at the shop, not at the map centre by default',
      (tester) async {
    await pumpInfo(tester, shopAt(lat: 9.497206995598628, lng: 76.34321476102275));

    final layer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(layer.markers, hasLength(1));
    expect(
      layer.markers.single.point,
      isA<LatLng>()
          .having((p) => p.latitude, 'lat', closeTo(9.4972069, 1e-6))
          .having((p) => p.longitude, 'lng', closeTo(76.3432147, 1e-6)),
    );
    // Bottom edge on the point, so the pin's tip marks the spot.
    expect(layer.markers.single.alignment, Alignment.topCenter);
  });

  testWidgets('a shop with no coordinates says so instead of mapping 0,0',
      (tester) async {
    await pumpInfo(tester, shopAt());

    expect(find.byType(FlutterMap), findsNothing);
    expect(find.text('No location pinned'), findsOneWidget);
  });

  testWidgets('the View location affordance is on the preview either way',
      (tester) async {
    await pumpInfo(tester, shopAt(lat: 9.4972, lng: 76.3432));
    expect(find.text('View location'), findsOneWidget);

    await pumpInfo(tester, shopAt());
    expect(find.text('View location'), findsOneWidget);
  });
}

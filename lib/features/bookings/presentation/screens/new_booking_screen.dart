import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_dialog.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import 'package:new_flutter_project/features/customers/application/providers/customers_providers.dart';
import 'package:new_flutter_project/features/customers/domain/entities/customer.dart';
import 'package:new_flutter_project/features/shops/application/providers/shop_services_providers.dart';
import 'package:new_flutter_project/features/shops/application/providers/shops_providers.dart';
import 'package:new_flutter_project/features/shops/domain/entities/shop.dart';

import '../../application/providers/bookings_providers.dart';
import '../../infrastructure/models/manual_booking_models.dart';
import '../components/customer_picker.dart';

/// New Booking screen — full-screen carwash manual booking form.
///
/// Steps: Customer → Vehicle → Shop → Services → Pickup → Drop → Coupon →
/// Payment. Confirm creates the booking (demo: toast + pop).
class NewBookingScreen extends ConsumerStatefulWidget {
  const NewBookingScreen({super.key});

  @override
  ConsumerState<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends ConsumerState<NewBookingScreen> {
  // Step 1: Customer
  CustomerPick? _customer;
  Customer? _customerData; // resolved when picking an existing customer

  // Step 2: Vehicle
  int? _vehIdx;

  // Vehicle for "new customer" flow OR "add new vehicle" inline.
  final _f0makeCtrl = TextEditingController();
  final _f0plateCtrl = TextEditingController();

  // When true, show the inline add-new-vehicle fields for an existing customer.
  bool _addingVehicle = false;

  // Step 3: Shop
  String? _shopId;

  // Step 4: Services (ids)
  List<String> _picked = [];

  // Step 5: Pickup
  final _pickAddrCtrl = TextEditingController();

  // Step 6: Drop
  bool _dropSame = true;
  final _dropAddrCtrl = TextEditingController();

  // Step 7: Coupon
  final _couponCtrl = TextEditingController();

  // Step 8: Payment
  String _pay = 'pending';

  // Resolved slot for the pickup time (start_slot id).
  SlotOption? _slot;

  // Coupon preview after validate-coupon.
  CouponPreview? _coupon;
  bool _validatingCoupon = false;

  // Booking submission in-flight.
  bool _submitting = false;

  /// Appointment date — defaults to today (the New Booking flow has no date
  /// picker; manual phone-in bookings are same-day).
  String get _appointmentDate {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  bool get _dirty => _customer != null || _shopId != null || _picked.isNotEmpty;

  bool get _valid =>
      _customer != null &&
      _shopId != null &&
      _picked.isNotEmpty &&
      _slot != null;

  @override
  void dispose() {
    _f0makeCtrl.dispose();
    _f0plateCtrl.dispose();
    _pickAddrCtrl.dispose();
    _dropAddrCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  void _onCustomerChanged(CustomerPick? pick) {
    setState(() {
      _customer = pick;
      _vehIdx = null;
      _customerData = null;
      _shopId = null;
      _picked = [];
      _addingVehicle = false;
      _slot = null;
      _coupon = null;
    });

    if (pick?.id != null) {
      // Resolve the customer data from the provider to get vehicles/addresses
      final customersAsync = ref.read(
        // Use read here — we don't need to rebuild, just fetch synchronously
        // from the already-loaded cache.
        // We can do this because customersProvider is not autoDispose.
        // Cast is safe given the provider definition.
        customersProvider,
      );
      customersAsync.whenData((customers) {
        final found = customers.where((c) => c.id == pick!.id);
        if (found.isNotEmpty) {
          final c = found.first;
          setState(() {
            _customerData = c;
            // Auto-select default vehicle
            final defIdx = c.vehicles.indexWhere((v) => v.isDefault);
            _vehIdx = defIdx >= 0 ? defIdx : (c.vehicles.isNotEmpty ? 0 : null);
          });
        }
      });
    }
  }

  String get _vehicleType {
    if (_customerData != null &&
        _vehIdx != null &&
        _vehIdx! < _customerData!.vehicles.length) {
      return _customerData!.vehicles[_vehIdx!].type;
    }
    return 'Sedan';
  }

  /// Compute price and minutes for a service given the vehicle type.
  ({int price, int minutes})? _svcPrice(ShopService sv) {
    if (sv.samePrice) {
      return (price: sv.flatPrice ?? 0, minutes: sv.flatMinutes ?? 0);
    }
    try {
      final p = sv.pricing.firstWhere(
        (p) => p.type == _vehicleType && p.active,
      );
      return (price: p.price, minutes: p.minutes);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(shopsProvider);
    // Services aren't included in the shop list/detail payloads, so fetch them
    // for the selected shop from the dedicated shop-services endpoint.
    final servicesAsync = _shopId != null
        ? ref.watch(shopServicesProvider(_shopId!))
        : const AsyncValue<List<ShopService>>.data(<ShopService>[]);

    return shopsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (_, __) => Scaffold(
        body: Center(child: Text('Failed to load shops')),
      ),
      data: (allShops) {
        final activeShops = allShops.where((s) => s.active).toList();
        final shop = _shopId != null
            ? allShops.firstWhereOrNull((s) => s.id == _shopId)
            : null;

        final shopServices = servicesAsync.asData?.value ?? <ShopService>[];
        final availServices = shop != null
            ? shopServices
                .where((sv) => sv.active && _svcPrice(sv) != null)
                .toList()
            : <ShopService>[];

        final chosen =
            availServices.where((sv) => _picked.contains(sv.id)).toList();
        final total =
            chosen.fold(0, (s, sv) => s + (_svcPrice(sv)?.price ?? 0));
        final totalMin =
            chosen.fold(0, (s, sv) => s + (_svcPrice(sv)?.minutes ?? 0));

        return Scaffold(
          backgroundColor: AppColors.bgPage,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                TopBar(
                  title: 'New Booking',
                  subtitle: 'Manual / phone-in',
                  onBack: () {
                    if (_dirty) {
                      _showExitDialog(context);
                    } else {
                      context.pop();
                    }
                  },
                ),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                    children: [
                      // ── 1. Customer ──────────────────────────────────
                      _FormCard(
                        label: '1 · Customer',
                        child: CustomerPicker(
                          value: _customer,
                          onChanged: _onCustomerChanged,
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // ── 2. Vehicle ───────────────────────────────────
                      if (_customer != null) ...[
                        _FormCard(
                          label: '2 · Vehicle',
                          child: (_customerData != null && !_addingVehicle)
                              ? _VehicleSelector(
                                  vehicles: _customerData!.vehicles,
                                  selectedIdx: _vehIdx,
                                  onSelect: (i) {
                                    setState(() {
                                      _vehIdx = i;
                                      _picked =
                                          []; // reset services when vehicle changes
                                    });
                                  },
                                  onAddNew: () => setState(() {
                                    _addingVehicle = true;
                                    _vehIdx = null;
                                    _picked = [];
                                    _f0makeCtrl.clear();
                                    _f0plateCtrl.clear();
                                  }),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _TextField(
                                      label: 'Make & model',
                                      controller: _f0makeCtrl,
                                      placeholder: 'e.g. Maruti Swift',
                                    ),
                                    SizedBox(height: 10.h),
                                    _TextField(
                                      label: 'Plate',
                                      controller: _f0plateCtrl,
                                      placeholder: 'KL-04-…',
                                    ),
                                    if (_customerData != null &&
                                        _addingVehicle) ...[
                                      SizedBox(height: 10.h),
                                      GestureDetector(
                                        onTap: () => setState(() {
                                          _addingVehicle = false;
                                          final defIdx = _customerData!.vehicles
                                              .indexWhere((v) => v.isDefault);
                                          _vehIdx = defIdx >= 0
                                              ? defIdx
                                              : (_customerData!
                                                      .vehicles.isNotEmpty
                                                  ? 0
                                                  : null);
                                        }),
                                        child: Text(
                                          'Use a saved vehicle instead',
                                          style: AppText.figtree(
                                            size: 12.5,
                                            weight: FontWeight.w600,
                                            color: AppColors.fgSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                        SizedBox(height: 14.h),
                      ],

                      // ── 3. Shop ──────────────────────────────────────
                      _FormCard(
                        label: '3 · Shop',
                        child: Column(
                          children: [
                            for (final s in activeShops)
                              Padding(
                                padding: EdgeInsets.only(bottom: 8.h),
                                child: _SelectRow(
                                  active: _shopId == s.id,
                                  title: s.name,
                                  sub: s.area,
                                  onTap: () => setState(() {
                                    _shopId = s.id;
                                    _picked = [];
                                    _slot = null;
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // ── 4. Services ──────────────────────────────────
                      if (shop != null) ...[
                        _FormCard(
                          label: '4 · Services',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prices shown for $_vehicleType',
                                style: AppText.figtree(
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: AppColors.fgTertiary,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              if (servicesAsync.isLoading)
                                Text(
                                  'Loading services…',
                                  style: AppText.figtree(
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: AppColors.fgMuted,
                                  ),
                                )
                              else if (availServices.isEmpty)
                                Text(
                                  'No services for $_vehicleType at this shop.',
                                  style: AppText.figtree(
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: AppColors.fgMuted,
                                  ),
                                )
                              else
                                for (final sv in availServices)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 8.h),
                                    child: _CheckRow(
                                      active: _picked.contains(sv.id),
                                      title: sv.name,
                                      sub:
                                          'est. ${_svcPrice(sv)?.minutes ?? 0} min',
                                      right: Formatters.money(
                                          _svcPrice(sv)?.price ?? 0),
                                      onTap: () => setState(() {
                                        if (_picked.contains(sv.id)) {
                                          _picked = _picked
                                              .where((x) => x != sv.id)
                                              .toList();
                                        } else {
                                          _picked = [..._picked, sv.id];
                                        }
                                      }),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),
                      ],

                      // ── 5. Pickup ─────────────────────────────────────
                      _FormCard(
                        label: '5 · Pickup',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TextField(
                              label: 'Address',
                              controller: _pickAddrCtrl,
                              placeholder: 'Pickup address',
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'Scheduled time',
                              style: AppText.figtree(
                                size: 12.5,
                                weight: FontWeight.w600,
                                color: AppColors.fgSecondary,
                              ),
                            ),
                            SizedBox(height: 7.h),
                            if (shop == null)
                              Text(
                                'Select a shop first.',
                                style: AppText.figtree(
                                  size: 13,
                                  weight: FontWeight.w500,
                                  color: AppColors.fgMuted,
                                ),
                              )
                            else
                              _SlotPicker(
                                shopId: int.tryParse(shop.id) ?? 0,
                                date: _appointmentDate,
                                vehicleType: _vehicleType,
                                selected: _slot,
                                onSelect: (s) => setState(() => _slot = s),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // ── 6. Drop ──────────────────────────────────────
                      _FormCard(
                        label: '6 · Drop',
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Same as pickup',
                                  style: AppText.figtree(
                                    size: 13.5,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                _Toggle(
                                  on: _dropSame,
                                  onTap: () =>
                                      setState(() => _dropSame = !_dropSame),
                                ),
                              ],
                            ),
                            if (!_dropSame) ...[
                              SizedBox(height: 10.h),
                              _TextField(
                                label: 'Drop address',
                                controller: _dropAddrCtrl,
                                placeholder: 'Drop address',
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // ── 7. Coupon ─────────────────────────────────────
                      _FormCard(
                        label: '7 · Coupon',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TextField(
                              label: 'Coupon code',
                              controller: _couponCtrl,
                              placeholder: 'Optional',
                              optional: true,
                              onChanged: (v) {
                                final up = v.toUpperCase();
                                if (up != v) {
                                  _couponCtrl.value = _couponCtrl.value
                                      .copyWith(text: up);
                                }
                                if (_coupon != null) {
                                  setState(() => _coupon = null);
                                }
                              },
                            ),
                            SizedBox(height: 10.h),
                            AppButton(
                              label: _validatingCoupon
                                  ? 'Checking…'
                                  : 'Apply coupon',
                              full: true,
                              disabled: _validatingCoupon ||
                                  _couponCtrl.text.trim().isEmpty ||
                                  total <= 0,
                              onPressed: (_validatingCoupon ||
                                      _couponCtrl.text.trim().isEmpty ||
                                      total <= 0)
                                  ? null
                                  : () => _applyCoupon(total),
                            ),
                            if (_coupon != null && _coupon!.valid) ...[
                              SizedBox(height: 10.h),
                              Text(
                                'Discount −${Formatters.money(_coupon!.discount)}'
                                ' · pay ${Formatters.money(_coupon!.finalAmount)}',
                                style: AppText.figtree(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: AppColors.greenFg,
                                ),
                              ),
                            ] else if (_coupon != null && !_coupon!.valid) ...[
                              SizedBox(height: 10.h),
                              Text(
                                _coupon!.message ?? 'Coupon not valid',
                                style: AppText.figtree(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: AppColors.redFg,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // ── 8. Payment ────────────────────────────────────
                      _FormCard(
                        label: '8 · Payment',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL${totalMin > 0 ? " · ~$totalMin min" : ""}',
                                      style: AppText.figtree(
                                        size: 11,
                                        weight: FontWeight.w700,
                                        color: AppColors.fgTertiary,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      Formatters.money(_payable(total)),
                                      style: AppText.figtree(
                                        size: 26,
                                        weight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                    if (_coupon != null && _coupon!.valid)
                                      Text(
                                        '${Formatters.money(total)} − coupon',
                                        style: AppText.figtree(
                                          size: 12,
                                          weight: FontWeight.w600,
                                          color: AppColors.fgTertiary,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              'Payment status',
                              style: AppText.figtree(
                                size: 12.5,
                                weight: FontWeight.w600,
                                color: AppColors.fgSecondary,
                              ),
                            ),
                            SizedBox(height: 9.h),
                            Row(
                              children: [
                                for (final opt in [
                                  ('pending', 'Pending'),
                                  ('paid', 'Paid'),
                                ])
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: opt.$1 == 'pending' ? 4.w : 0,
                                        left: opt.$1 == 'paid' ? 4.w : 0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _pay = opt.$1),
                                        child: Container(
                                          height: 46.h,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: _pay == opt.$1
                                                ? AppColors.fgPrimary
                                                : AppColors.bgCard,
                                            borderRadius:
                                                BorderRadius.circular(11.r),
                                            border: Border.all(
                                              color: _pay == opt.$1
                                                  ? AppColors.fgPrimary
                                                  : AppColors.borderDefault,
                                            ),
                                          ),
                                          child: Text(
                                            opt.$2,
                                            style: AppText.figtree(
                                              size: 13.5,
                                              weight: FontWeight.w700,
                                              color: _pay == opt.$1
                                                  ? AppColors.fgOnDark
                                                  : AppColors.fgSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 80.h),
                    ],
                  ),
                ),

                // ── Sticky footer CTA ────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.bgCard,
                    border:
                        Border(top: BorderSide(color: AppColors.borderSoft)),
                  ),
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                  child: SafeArea(
                    top: false,
                    child: AppButton(
                      label: _submitting
                          ? 'Creating booking…'
                          : 'Confirm Booking · ${Formatters.money(_payable(total))}',
                      full: true,
                      disabled: !_valid || _submitting,
                      onPressed: (_valid && !_submitting)
                          ? () => _confirm(shop)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The amount the customer pays (display only — the server computes the
  /// authoritative amount). Applies the coupon preview discount if valid.
  int _payable(int total) {
    if (_coupon != null && _coupon!.valid) {
      return _coupon!.finalAmount;
    }
    return total;
  }

  /// Validate the typed coupon against the current order total (preview only).
  Future<void> _applyCoupon(int total) async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty || total <= 0) return;
    setState(() => _validatingCoupon = true);
    try {
      final preview = await ref.read(bookingsRepositoryProvider).validateCoupon(
            code: code,
            orderAmount: total,
          );
      if (!mounted) return;
      setState(() => _coupon = preview);
      if (!preview.valid && context.mounted) {
        AppToast.show(context, preview.message ?? 'Coupon not valid');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _coupon = null);
      if (context.mounted) {
        AppToast.show(context, _errorText(e));
      }
    } finally {
      if (mounted) setState(() => _validatingCoupon = false);
    }
  }

  /// Gather the 8 steps, resolve the `car` id, and POST the manual booking.
  Future<void> _confirm(Shop? shop) async {
    if (!_valid || shop == null) return;

    final customerIdStr = _customer?.id;
    final customerId = int.tryParse(customerIdStr ?? '');
    if (customerId == null) {
      AppToast.show(
        context,
        'Save the new customer first, then create the booking.',
      );
      return;
    }

    final shopId = int.tryParse(shop.id);
    final serviceId = int.tryParse(_picked.first);
    final startSlot = _slot?.id;
    if (shopId == null || serviceId == null || startSlot == null) {
      AppToast.show(context, 'Missing shop, service, or time slot.');
      return;
    }

    setState(() => _submitting = true);
    final repo = ref.read(bookingsRepositoryProvider);

    try {
      // Resolve the vehicle (car) id. A saved vehicle already carries its
      // backing `Cars` id — reuse it. Only the inline "add new vehicle" path
      // (or a saved row missing its id) registers a new car via the documented
      // "add vehicle then pass car" flow.
      final GarageVehicle? savedVehicle = (!_addingVehicle &&
              _customerData != null &&
              _vehIdx != null &&
              _vehIdx! < _customerData!.vehicles.length)
          ? _customerData!.vehicles[_vehIdx!]
          : null;

      final int carId;
      if (savedVehicle?.carId != null) {
        carId = savedVehicle!.carId!;
      } else {
        final brandModel = savedVehicle != null
            ? '${savedVehicle.make} ${savedVehicle.model}'.trim()
            : _f0makeCtrl.text.trim();
        final registration = savedVehicle != null
            ? savedVehicle.plate
            : _f0plateCtrl.text.trim();

        if (brandModel.isEmpty || registration.isEmpty) {
          if (mounted) setState(() => _submitting = false);
          AppToast.show(context, 'Add a vehicle (make/model and plate).');
          return;
        }

        final vehicle = await repo.createVehicle(
          userId: customerId,
          brandModel: brandModel,
          registration: registration,
          carType: _vehicleType,
        );
        carId = vehicle.id;
      }

      final couponCode =
          _couponCtrl.text.trim().isNotEmpty ? _couponCtrl.text.trim() : null;

      await repo.createManualBooking(
        customerId: customerId,
        car: carId,
        shopId: shopId,
        serviceId: serviceId,
        vehicleType: _vehicleType,
        appointmentDate: _appointmentDate,
        startSlot: startSlot,
        pickupAddressText: _pickAddrCtrl.text.trim().isNotEmpty
            ? _pickAddrCtrl.text.trim()
            : null,
        sameAsPickup: _dropSame,
        // The screen captures drop as free text; there is no saved-address
        // picker, so a separate drop address id is not available. When the
        // toggle is off we still send same_as_pickup=false; the backend
        // creates the drop from pickup text. (Deviation noted in summary.)
        dropAddress: null,
        couponCode: couponCode,
        paymentStatus: _pay,
      );

      // Refresh the bookings list so the new booking shows up.
      ref.invalidate(bookingsProvider);

      if (!mounted) return;
      AppToast.show(
        context,
        'Booking created${_pay == 'paid' ? ' · marked Paid' : ' · payment Pending'}',
      );
      if (context.mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (context.mounted) {
        AppToast.show(context, _errorText(e));
      }
    }
  }

  /// Strip the "Exception: " prefix from a thrown error for display.
  String _errorText(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Discard this booking?',
      body: 'Your entered details will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      context.pop();
    }
  }
}

// ── Form widgets ──────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppText.eyebrow,
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.active,
    required this.title,
    required this.onTap,
    this.sub,
  });

  final bool active;
  final String title;
  final String? sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: active ? AppColors.brandYellow : AppColors.bgCard,
          borderRadius: BorderRadius.circular(11.r),
          border: Border.all(
            color: active ? AppColors.brandYellowDeep : AppColors.borderSoft,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20.r,
              height: 20.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppColors.fgPrimary : Colors.transparent,
                border: active
                    ? null
                    : Border.all(
                        color: AppColors.borderStrong,
                        width: 2,
                      ),
              ),
              child: active
                  ? Icon(
                      AppIcons.check,
                      size: 13.sp,
                      color: AppColors.brandYellow,
                    )
                  : null,
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.figtree(
                      size: 13.5,
                      weight: FontWeight.w600,
                    ),
                  ),
                  if (sub != null)
                    Text(
                      sub!,
                      style: AppText.figtree(
                        size: 12,
                        weight: FontWeight.w500,
                        color: active
                            ? const Color(0x99000000)
                            : AppColors.fgTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.active,
    required this.title,
    required this.onTap,
    this.sub,
    this.right,
  });

  final bool active;
  final String title;
  final String? sub;
  final String? right;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: active ? const Color(0x25FAD93A) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(11.r),
          border: Border.all(
            color: active ? AppColors.brandYellowDeep : AppColors.borderSoft,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22.r,
              height: 22.r,
              decoration: BoxDecoration(
                color: active ? AppColors.fgPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(6.r),
                border: active
                    ? null
                    : Border.all(
                        color: AppColors.borderStrong,
                        width: 2,
                      ),
              ),
              child: active
                  ? Icon(
                      AppIcons.check,
                      size: 14.sp,
                      color: AppColors.brandYellow,
                    )
                  : null,
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.figtree(
                      size: 13.5,
                      weight: FontWeight.w600,
                    ),
                  ),
                  if (sub != null)
                    Text(
                      sub!,
                      style: AppText.figtree(
                        size: 12,
                        weight: FontWeight.w500,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                ],
              ),
            ),
            if (right != null)
              Text(
                right!,
                style: AppText.figtree(
                  size: 13.5,
                  weight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.optional = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final bool optional;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w600,
                color: AppColors.fgSecondary,
              ),
            ),
            if (optional)
              Text(
                ' · optional',
                style: AppText.figtree(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: AppColors.fgMuted,
                ),
              ),
          ],
        ),
        SizedBox(height: 7.h),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppText.figtree(
              size: 14,
              weight: FontWeight.w400,
              color: AppColors.fgMuted,
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.r),
              borderSide: const BorderSide(color: AppColors.brandYellowDeep),
            ),
          ),
          style: AppText.figtree(size: 14, weight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44.w,
        height: 26.h,
        decoration: BoxDecoration(
          color: on ? AppColors.fgPrimary : AppColors.borderDefault,
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(3.r),
          child: Align(
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20.r,
              height: 20.r,
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleSelector extends StatelessWidget {
  const _VehicleSelector({
    required this.vehicles,
    required this.selectedIdx,
    required this.onSelect,
    required this.onAddNew,
  });

  final List<GarageVehicle> vehicles;
  final int? selectedIdx;
  final void Function(int) onSelect;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < vehicles.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _SelectRow(
              active: selectedIdx == i,
              title: '${vehicles[i].make} ${vehicles[i].model}',
              sub: '${vehicles[i].type} · ${vehicles[i].plate}',
              onTap: () => onSelect(i),
            ),
          ),
        GestureDetector(
          onTap: onAddNew,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(11.r),
              border: Border.all(
                color: AppColors.borderDefault,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  AppIcons.plus,
                  size: 16.sp,
                  color: AppColors.fgSecondary,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Add new vehicle',
                  style: AppText.figtree(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.fgSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Loads available slots for the shop/date/vehicle and lets the admin pick one,
/// resolving the typed time to a `start_slot` id.
class _SlotPicker extends ConsumerWidget {
  const _SlotPicker({
    required this.shopId,
    required this.date,
    required this.vehicleType,
    required this.selected,
    required this.onSelect,
  });

  final int shopId;
  final String date;
  final String vehicleType;
  final SlotOption? selected;
  final void Function(SlotOption) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(
      availableSlotsProvider(
        (shopId: shopId, date: date, vehicleType: vehicleType),
      ),
    );

    return slotsAsync.when(
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: const Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (e, __) => Text(
        'Could not load slots. Tap to retry.',
        style: AppText.figtree(
          size: 13,
          weight: FontWeight.w500,
          color: AppColors.redFg,
        ),
      ),
      data: (slots) {
        final available = slots.where((s) => s.available).toList();
        if (available.isEmpty) {
          return Text(
            'No available slots for this date.',
            style: AppText.figtree(
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.fgMuted,
            ),
          );
        }
        return Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final s in available)
              GestureDetector(
                onTap: () => onSelect(s),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 13.w, vertical: 9.h),
                  decoration: BoxDecoration(
                    color: selected?.id == s.id
                        ? AppColors.fgPrimary
                        : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: selected?.id == s.id
                          ? AppColors.fgPrimary
                          : AppColors.borderDefault,
                    ),
                  ),
                  child: Text(
                    s.label.isNotEmpty ? s.label : s.time,
                    style: AppText.figtree(
                      size: 13,
                      weight: FontWeight.w700,
                      color: selected?.id == s.id
                          ? AppColors.fgOnDark
                          : AppColors.fgSecondary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Extension to safely find the first matching element.
extension _IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

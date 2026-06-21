import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/constants/app_options.dart';
import 'package:new_flutter_project/core/widgets/widgets.dart';

import '../../application/providers/shop_services_providers.dart';
import '../../application/providers/shops_providers.dart';
import '../../domain/entities/shop.dart';

/// Add / Edit service form screen.
/// [shopId] is required; [serviceId] is null when adding.
/// Mirrors `ServiceForm` in `screen_shopforms.jsx`.
class ServiceFormScreen extends ConsumerWidget {
  const ServiceFormScreen({
    required this.shopId,
    this.serviceId,
    super.key,
  });

  final String shopId;
  final String? serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopDetailProvider(shopId));

    return shopAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgPage,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SafeArea(
          child: Column(
            children: [
              TopBar(title: 'Service', onBack: () => context.pop()),
              Expanded(
                child: ErrorView(
                  onRetry: () => ref.invalidate(shopDetailProvider(shopId)),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (shop) {
        // Only fetch services if editing (serviceId is not null)
        if (serviceId == null) {
          return _ServiceFormBody(
            shop: shop,
            existing: null,
          );
        }

        // Fetch services sequentially (not in parallel) to avoid connection pool exhaustion
        final servicesAsync = ref.watch(shopServicesProvider(shopId));
        return servicesAsync.when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.bgPage,
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Scaffold(
            backgroundColor: AppColors.bgPage,
            body: SafeArea(
              child: Column(
                children: [
                  TopBar(title: 'Service', onBack: () => context.pop()),
                  Expanded(
                    child: ErrorView(
                      onRetry: () =>
                          ref.invalidate(shopServicesProvider(shopId)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (services) {
            final existing = services.cast<ShopService?>().firstWhere(
                (sv) => sv != null && sv.id == serviceId,
                orElse: () => null);
            return _ServiceFormBody(
              shop: shop,
              existing: existing,
            );
          },
        );
      },
    );
  }
}

class _ServiceFormBody extends ConsumerStatefulWidget {
  const _ServiceFormBody({required this.shop, this.existing});
  final Shop shop;
  final ShopService? existing;

  @override
  ConsumerState<_ServiceFormBody> createState() => _ServiceFormBodyState();
}

class _ServiceFormBodyState extends ConsumerState<_ServiceFormBody> {
  late String _name;
  late String _desc;
  late bool _samePrice;
  late String _flatPrice;
  late String _flatMin;
  late bool _active;
  late List<_PricingRow> _rows;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _name = ex?.name ?? '';
    _desc = ex?.description ?? '';
    _samePrice = ex?.samePrice ?? false;
    _flatPrice = (ex?.flatPrice != null) ? '${ex!.flatPrice}' : '';
    _flatMin = (ex?.flatMinutes != null) ? '${ex!.flatMinutes}' : '';
    _active = ex?.active ?? true;
    _rows = kVehicleTypes.map((t) {
      final found = (ex != null && !ex.samePrice)
          ? ex.pricing.firstWhere(
              (p) => p.type == t,
              orElse: () => ServicePricing(
                type: t,
                price: 0,
                minutes: 0,
                active: widget.shop.vehicleTypes.contains(t),
              ),
            )
          : null;
      return _PricingRow(
        type: t,
        price: found != null && found.price > 0 ? '${found.price}' : '',
        min: found != null && found.minutes > 0 ? '${found.minutes}' : '',
        active: found?.active ?? widget.shop.vehicleTypes.contains(t),
      );
    }).toList();
  }

  bool get _dirty =>
      _name.isNotEmpty ||
      _desc.isNotEmpty ||
      _flatPrice.isNotEmpty ||
      _rows.any((r) => r.price.isNotEmpty);

  bool get _valid {
    if (_name.trim().isEmpty) return false;
    if (_samePrice) return _flatPrice.trim().isNotEmpty;
    return _rows.any((r) => r.active && r.price.trim().isNotEmpty);
  }

  void _setRow(String type, {String? price, String? min, bool? active}) {
    setState(() {
      _rows = _rows.map((r) {
        if (r.type != type) return r;
        return _PricingRow(
          type: r.type,
          price: price ?? r.price,
          min: min ?? r.min,
          active: active ?? r.active,
        );
      }).toList();
    });
  }

  void _toast(String msg) => AppToast.show(context, msg);

  /// Prompts to discard unsaved edits before leaving (matches the design's
  /// edit-mode discard pattern). Pops only when confirmed or when not dirty.
  Future<void> _handleBack() async {
    if (!_dirty) {
      context.pop();
      return;
    }
    final discard = await showConfirmDialog(
      context: context,
      title: 'Discard changes?',
      body: 'Your edits to this service will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (discard && mounted) context.pop();
  }

  /// Save service to API (add or edit).
  Future<void> _handleSave() async {
    try {
      final repository = ref.read(shopsRepositoryProvider);

      // Parse inclusions from comma/newline separated text
      final inclusions = _desc
          .split(RegExp(r'[,\n]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (_samePrice) {
        // Uniform pricing
        final price = int.tryParse(_flatPrice) ?? 0;
        final minutes = int.tryParse(_flatMin) ?? 30;

        if (_isEdit && widget.existing != null) {
          await repository.updateService(
            int.parse(widget.existing!.id),
            _name,
            inclusions,
            true,
            true,
            price,
            minutes ~/ 30,
            null,
          );
        } else {
          await repository.createService(
            widget.shop.id,
            _name,
            inclusions,
            true,
            true,
            price,
            minutes ~/ 30,
            null,
          );
        }
      } else {
        // Per-vehicle pricing
        final variants = _rows
            .where((r) => r.active && r.price.isNotEmpty)
            .map((r) => (
                  type: r.type,
                  price: int.tryParse(r.price) ?? 0,
                  minutes: int.tryParse(r.min) ?? 30,
                  active: r.active,
                ))
            .toList();

        if (_isEdit && widget.existing != null) {
          await repository.updateService(
            int.parse(widget.existing!.id),
            _name,
            inclusions,
            false,
            true,
            null,
            null,
            variants,
          );
        } else {
          await repository.createService(
            widget.shop.id,
            _name,
            inclusions,
            false,
            true,
            null,
            null,
            variants,
          );
        }
      }

      ref.invalidate(shopServicesProvider(widget.shop.id));
      _toast(_isEdit ? 'Service updated' : 'Service added');
      if (mounted) context.pop();
    } catch (e) {
      _toast('Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: _isEdit ? 'Edit Service' : 'Add Service',
              subtitle: widget.shop.name,
              onBack: _handleBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service name + description
                    _FCard(
                      label: 'Service',
                      children: [
                        _FInput(
                          label: 'Service name',
                          value: _name,
                          placeholder: 'e.g. Exterior Wash',
                          onChanged: (v) => setState(() => _name = v),
                        ),
                        _FArea(
                          label: 'Description',
                          value: _desc,
                          placeholder: 'What\'s included…',
                          optional: true,
                          onChanged: (v) => setState(() => _desc = v),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),

                    // Pricing mode toggle
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Same price for all vehicle types',
                                      style: AppText.figtree(
                                        size: 14,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      _samePrice
                                          ? 'One price applies to every supported type'
                                          : 'Set price & time per vehicle type',
                                      style: AppText.figtree(
                                        size: 12,
                                        weight: FontWeight.w400,
                                        color: AppColors.fgTertiary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _AppToggle(
                                on: _samePrice,
                                onChanged: (v) =>
                                    setState(() => _samePrice = v),
                              ),
                            ],
                          ),
                          if (_samePrice) ...[
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _FInput(
                                    label: 'Price',
                                    value: _flatPrice,
                                    prefix: '₹',
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) =>
                                        setState(() => _flatPrice = v),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: _FInput(
                                    label: 'Est. time',
                                    value: _flatMin,
                                    suffix: 'min',
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) =>
                                        setState(() => _flatMin = v),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            SizedBox(height: 16.h),
                            // Matrix header
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2.w),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 14,
                                    child: Text(
                                      'VEHICLE',
                                      style: AppText.figtree(
                                        size: 10,
                                        weight: FontWeight.w700,
                                        color: AppColors.fgTertiary,
                                        letterSpacing: 0.06,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 10,
                                    child: Text(
                                      'PRICE ₹',
                                      textAlign: TextAlign.center,
                                      style: AppText.figtree(
                                        size: 10,
                                        weight: FontWeight.w700,
                                        color: AppColors.fgTertiary,
                                        letterSpacing: 0.06,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 10,
                                    child: Text(
                                      'MINS',
                                      textAlign: TextAlign.center,
                                      style: AppText.figtree(
                                        size: 10,
                                        weight: FontWeight.w700,
                                        color: AppColors.fgTertiary,
                                        letterSpacing: 0.06,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40.w,
                                    child: Text(
                                      'ON',
                                      textAlign: TextAlign.center,
                                      style: AppText.figtree(
                                        size: 10,
                                        weight: FontWeight.w700,
                                        color: AppColors.fgTertiary,
                                        letterSpacing: 0.06,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10.h),
                            // Matrix rows
                            ...List.generate(_rows.length, (i) {
                              final r = _rows[i];
                              final supported =
                                  widget.shop.vehicleTypes.contains(r.type);
                              return Padding(
                                padding: EdgeInsets.only(bottom: 10.h),
                                child: Opacity(
                                  opacity: r.active ? 1.0 : 0.5,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 14,
                                        child: Text(
                                          r.type,
                                          style: AppText.figtree(
                                            size: 12.5,
                                            weight: FontWeight.w600,
                                            color: supported
                                                ? AppColors.fgPrimary
                                                : AppColors.fgMuted,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 10,
                                        child: _MatrixCell(
                                          value: r.price,
                                          onChanged: (v) =>
                                              _setRow(r.type, price: v),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        flex: 10,
                                        child: _MatrixCell(
                                          value: r.min,
                                          onChanged: (v) =>
                                              _setRow(r.type, min: v),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      SizedBox(
                                        width: 40.w,
                                        child: _SmallToggle(
                                          on: r.active,
                                          onTap: () => _setRow(
                                            r.type,
                                            active: !r.active,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Service active toggle
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service active',
                                  style: AppText.figtree(
                                    size: 14,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Text(
                                  'Master on/off for this service',
                                  style: AppText.figtree(
                                    size: 12,
                                    weight: FontWeight.w400,
                                    color: AppColors.fgTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _AppToggle(
                            on: _active,
                            onChanged: (v) => setState(() => _active = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Save bar
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border: Border(top: BorderSide(color: AppColors.borderSoft)),
              ),
              child: AppButton(
                label: _isEdit ? 'Save Changes' : 'Add Service',
                full: true,
                disabled: !_valid,
                onPressed: _valid ? _handleSave : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _FInput extends StatelessWidget {
  const _FInput({
    required this.label,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.keyboardType,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final String? prefix;
  final String? suffix;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.figtree(
            size: 12.5,
            weight: FontWeight.w600,
            color: AppColors.fgSecondary,
          ),
        ),
        SizedBox(height: 7.h),
        Container(
          height: 50.h,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              SizedBox(width: 13.w),
              if (prefix != null) ...[
                Text(
                  prefix!,
                  style: AppText.figtree(
                    size: 15,
                    weight: FontWeight.w600,
                    color: AppColors.fgTertiary,
                  ),
                ),
                SizedBox(width: 6.w),
              ],
              Expanded(
                child: TextFormField(
                  initialValue: value,
                  onChanged: onChanged,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: placeholder,
                    hintStyle: AppText.figtree(
                      size: 15,
                      weight: FontWeight.w500,
                      color: AppColors.fgMuted,
                    ),
                  ),
                  style: AppText.figtree(size: 15, weight: FontWeight.w500),
                ),
              ),
              if (suffix != null) ...[
                SizedBox(width: 6.w),
                Text(
                  suffix!,
                  style: AppText.figtree(
                    size: 13,
                    weight: FontWeight.w500,
                    color: AppColors.fgTertiary,
                  ),
                ),
              ],
              SizedBox(width: 13.w),
            ],
          ),
        ),
      ],
    );
  }
}

class _FArea extends StatelessWidget {
  const _FArea({
    required this.label,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.optional = false,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final bool optional;

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
            if (optional) ...[
              SizedBox(width: 6.w),
              Text(
                '· optional',
                style: AppText.figtree(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: AppColors.fgMuted,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 7.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: TextFormField(
            initialValue: value,
            onChanged: onChanged,
            maxLines: 2,
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 13.w, vertical: 12.h),
              border: InputBorder.none,
              hintText: placeholder,
              hintStyle: AppText.figtree(
                size: 15,
                weight: FontWeight.w500,
                color: AppColors.fgMuted,
              ),
            ),
            style: AppText.figtree(size: 15, weight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _FCard extends StatelessWidget {
  const _FCard({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 0.1,
            ),
          ),
          SizedBox(height: 14.h),
          ...children.expand((w) => [w, SizedBox(height: 14.h)]).toList()
            ..removeLast(),
        ],
      ),
    );
  }
}

class _MatrixCell extends StatelessWidget {
  const _MatrixCell({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(9.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '—',
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.fgPrimary,
        ),
      ),
    );
  }
}

class _AppToggle extends StatelessWidget {
  const _AppToggle({required this.on, required this.onChanged});
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 46.w,
        height: 28.h,
        decoration: BoxDecoration(
          color: on ? AppColors.success : AppColors.borderDefault,
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            width: 22.r,
            height: 22.r,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 3.r,
                  offset: Offset(0, 1.h),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallToggle extends StatelessWidget {
  const _SmallToggle({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40.w,
        height: 24.h,
        decoration: BoxDecoration(
          color: on ? AppColors.success : AppColors.borderDefault,
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2.5.w),
            width: 19.r,
            height: 19.r,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 2.r,
                  offset: Offset(0, 1.h),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Value classes ────────────────────────────────────────────────────────────

class _PricingRow {
  const _PricingRow({
    required this.type,
    required this.price,
    required this.min,
    required this.active,
  });

  final String type;
  final String price;
  final String min;
  final bool active;
}

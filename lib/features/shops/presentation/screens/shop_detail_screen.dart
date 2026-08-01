import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/router/app_router.dart';
import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/widgets.dart';

import '../../application/providers/shop_services_providers.dart';
import '../../application/providers/shops_providers.dart';
import '../../domain/entities/shop.dart';
import '../components/info_section.dart';
import '../components/services_section.dart';
import '../components/settlement_section.dart';

/// Shop detail screen — Info / Services / Settlement tabs, 3-dot menu.
/// Mirrors `ShopDetailScreen` in `screen_shopdetail.jsx`.
class ShopDetailScreen extends ConsumerStatefulWidget {
  const ShopDetailScreen({required this.shopId, super.key});

  final String shopId;

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  int _tab = 0; // 0=Info, 1=Services, 2=Settlement
  bool _menuOpen = false;

  // Local overrides that survive tab switching (mirrors JSX live state)
  bool? _activeOverride;
  List<ShopService>? _servicesOverride;

  static const List<String> _tabLabels = ['Info', 'Services', 'Settlement'];

  void _toast(String msg) => AppToast.show(context, msg);

  @override
  void didUpdateWidget(ShopDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.shopId != widget.shopId) {
      _tab = 0;
      _activeOverride = null;
      _servicesOverride = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(shopDetailProvider(widget.shopId));

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
              TopBar(title: 'Shop', onBack: () => context.pop()),
              Expanded(
                child: ErrorView(
                  onRetry: () =>
                      ref.invalidate(shopDetailProvider(widget.shopId)),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (shop) {
        // With the new provider, shop is never null
        final isActive = _activeOverride ?? shop.active;
        final services = _servicesOverride ?? shop.services;
        final live = _buildLiveShop(shop, isActive, services);

        return Scaffold(
          backgroundColor: AppColors.bgPage,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTopBar(context, shop),
                    _buildTabBar(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(shopDetailProvider(widget.shopId));
                          ref.invalidate(shopServicesProvider(widget.shopId));
                          await ref.read(
                            shopDetailProvider(widget.shopId).future,
                          );
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
                          child:
                              _buildTabBody(context, live, services, isActive),
                        ),
                      ),
                    ),
                  ],
                ),
                // Menu overlay - positioned above entire screen content
                if (_menuOpen) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _menuOpen = false),
                      behavior: HitTestBehavior.opaque,
                      child: const ColoredBox(color: Colors.transparent),
                    ),
                  ),
                  Positioned(
                    top: 52.h,
                    right: 16.w,
                    child: _ContextMenu(
                      onEditShop: () {
                        setState(() => _menuOpen = false);
                        context.push(Routes.editShop(shop.id));
                      },
                      onManageHours: () {
                        setState(() => _menuOpen = false);
                        context.push(Routes.shopHours(shop.id));
                      },
                      onDuplicate: () {
                        setState(() => _menuOpen = false);
                        context.push(Routes.addShop, extra: shop);
                      },
                      onExport: () {
                        setState(() => _menuOpen = false);
                        _toast('Export (CSV)');
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Rebuilds a Shop with locally overridden active + services.
  Shop _buildLiveShop(Shop base, bool active, List<ShopService> services) {
    return Shop(
      id: base.id,
      name: base.name,
      area: base.area,
      ownerName: base.ownerName,
      ownerPhone: base.ownerPhone,
      shopPhone: base.shopPhone,
      address: base.address,
      rating: base.rating,
      reviews: base.reviews,
      todayBookings: base.todayBookings,
      cap: base.cap,
      avgServiceMin: base.avgServiceMin,
      active: active,
      vehicleTypes: base.vehicleTypes,
      commission: base.commission,
      bank: base.bank,
      hours: base.hours,
      photos: base.photos,
      onboarded: base.onboarded,
      lastEdited: base.lastEdited,
      services: services,
      settlement: base.settlement,
      weekly: base.weekly,
      slotCapacityEnabled: base.slotCapacityEnabled,
      slotCap: base.slotCap,
      // Must be carried over — they default to 0/0, and the Info tab's
      // "View location" would open the map at null island instead of the shop.
      latitude: base.latitude,
      longitude: base.longitude,
    );
  }

  Widget _buildTopBar(BuildContext context, Shop shop) {
    return TopBar(
      title: shop.name,
      onBack: () => context.pop(),
      actions: [
        AppIconButton(
          icon: AppIcons.more,
          semanticLabel: 'More actions',
          onTap: () => setState(() => _menuOpen = !_menuOpen),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: List.generate(_tabLabels.length, (i) {
          final on = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: Container(
                padding: EdgeInsets.fromLTRB(0, 13.h, 0, 11.h),
                decoration: on
                    ? BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.brandYellowDeep,
                            width: 2.5.h,
                          ),
                        ),
                      )
                    : null,
                child: Text(
                  _tabLabels[i],
                  textAlign: TextAlign.center,
                  style: AppText.figtree(
                    size: 14,
                    weight: on ? FontWeight.w700 : FontWeight.w600,
                    color: on ? AppColors.fgPrimary : AppColors.fgTertiary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabBody(
    BuildContext context,
    Shop live,
    List<ShopService> services,
    bool isActive,
  ) {
    switch (_tab) {
      case 0:
        return InfoSection(
          shop: live,
          active: isActive,
          onActiveChanged: (v) => setState(() => _activeOverride = v),
        );
      case 1:
        return _ServicesTabBody(
          shopId: live.id,
          onAddService: () => context.push(Routes.addService(live.id)),
          onEditService: (svId) =>
              context.push(Routes.editService(live.id, svId)),
          onToast: _toast,
        );
      case 2:
      default:
        return SettlementSection(
          shop: live,
          onCreatePayout: () => context.push(Routes.payouts, extra: live.id),
        );
    }
  }
}

/// 3-dot context menu dropdown — mirrors the JSX inline dropdown.
class _ContextMenu extends StatelessWidget {
  const _ContextMenu({
    required this.onEditShop,
    required this.onManageHours,
    required this.onDuplicate,
    required this.onExport,
  });

  final VoidCallback onEditShop;
  final VoidCallback onManageHours;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final items = [
      (AppIcons.edit, 'Edit shop details', onEditShop),
      (AppIcons.clock, 'Manage hours & slots', onManageHours),
      (AppIcons.copy, 'Duplicate shop', onDuplicate),
      (AppIcons.share, 'Export (CSV)', onExport),
    ];

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 200.w,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(items.length, (i) {
            final (icon, label, action) = items[i];
            return GestureDetector(
              onTap: action,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 13.h,
                ),
                decoration: i > 0
                    ? const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.borderSoft),
                        ),
                      )
                    : null,
                child: Row(
                  children: [
                    Icon(icon, size: 17.sp, color: AppColors.fgSecondary),
                    SizedBox(width: 11.w),
                    Expanded(
                      child: Text(
                        label,
                        style: AppText.figtree(
                          size: 13.5,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Services tab — fetches from API and handles toggle/copy/price-change.
class _ServicesTabBody extends ConsumerStatefulWidget {
  const _ServicesTabBody({
    required this.shopId,
    required this.onAddService,
    required this.onEditService,
    required this.onToast,
  });

  final String shopId;
  final VoidCallback onAddService;
  final ValueChanged<String> onEditService;
  final void Function(String) onToast;

  @override
  ConsumerState<_ServicesTabBody> createState() => _ServicesTabBodyState();
}

class _ServicesTabBodyState extends ConsumerState<_ServicesTabBody> {
  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(shopServicesProvider(widget.shopId));

    return servicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => ErrorView(
        onRetry: () => ref.invalidate(shopServicesProvider(widget.shopId)),
      ),
      data: (services) {
        return ServicesSection(
          services: services,
          onToggleService: (id) => _onToggleService(int.parse(id)),
          onAddService: widget.onAddService,
          onEditService: widget.onEditService,
          onToast: _handleBulkAction,
        );
      },
    );
  }

  /// Toggle service active status via API.
  Future<void> _onToggleService(int serviceId) async {
    final servicesAsync = ref.read(shopServicesProvider(widget.shopId));
    final services = servicesAsync.value;
    if (services == null) return;

    final service = services.cast<ShopService?>().firstWhere(
        (s) => s != null && int.parse(s.id) == serviceId,
        orElse: () => null);
    if (service == null) return;

    final newActive = !service.active;
    try {
      final repository = ref.read(shopsRepositoryProvider);
      await repository.toggleService(serviceId, newActive);
      ref.invalidate(shopServicesProvider(widget.shopId));
      widget.onToast(
        newActive ? 'Service activated' : 'Service deactivated',
      );
    } catch (e) {
      widget.onToast('Error: ${e.toString()}');
    }
  }

  /// Handle bulk actions (copy or price change).
  void _handleBulkAction(String action) {
    if (action.contains('Copy')) {
      _showCopyServicesDialog();
    } else if (action.contains('price')) {
      _showPriceChangeDialog();
    }
  }

  /// Show dialog to copy services from another shop.
  void _showCopyServicesDialog() {
    final sourceController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Copy Services'),
        content: TextField(
          controller: sourceController,
          decoration: const InputDecoration(
            hintText: 'Enter source shop ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _copyServices(int.tryParse(sourceController.text) ?? 0);
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  /// Copy services from another shop.
  Future<void> _copyServices(int sourceShopId) async {
    try {
      final repository = ref.read(shopsRepositoryProvider);
      final result = await repository.copyServices(
        sourceShopId,
        int.parse(widget.shopId),
      );
      ref.invalidate(shopServicesProvider(widget.shopId));
      widget.onToast(
        'Copied ${result.copied} services, skipped ${result.skipped}',
      );
    } catch (e) {
      widget.onToast('Error: ${e.toString()}');
    }
  }

  /// Show dialog to apply percentage price change.
  void _showPriceChangeDialog() {
    final percentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apply Price Change'),
        content: TextField(
          controller: percentController,
          keyboardType: const TextInputType.numberWithOptions(
              signed: true, decimal: false),
          decoration: const InputDecoration(
            hintText: 'Enter percent (e.g., 10 or -5)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _applyPriceChange(
                double.tryParse(percentController.text) ?? 0,
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  /// Apply percentage price change to all services.
  Future<void> _applyPriceChange(double percent) async {
    if (percent <= -100) {
      widget.onToast('Percent must be > -100');
      return;
    }
    try {
      final repository = ref.read(shopsRepositoryProvider);
      final result = await repository.applyPriceChange(widget.shopId, percent);
      ref.invalidate(shopServicesProvider(widget.shopId));
      widget.onToast(
        'Updated ${result.servicesUpdated} services, ${result.variantsUpdated} variants',
      );
    } catch (e) {
      widget.onToast('Error: ${e.toString()}');
    }
  }
}

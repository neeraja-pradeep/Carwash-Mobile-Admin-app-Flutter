import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/router/app_router.dart';
import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/widgets.dart';

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
    final shopAsync = ref.watch(shopByIdProvider(widget.shopId));

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
                      ref.invalidate(shopByIdProvider(widget.shopId)),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (shop) {
        if (shop == null) {
          return Scaffold(
            backgroundColor: AppColors.bgPage,
            body: SafeArea(
              child: Column(
                children: [
                  TopBar(title: 'Shop', onBack: () => context.pop()),
                  const Expanded(
                    child: EmptyState(
                      title: 'Shop not found',
                      body: 'This shop may have been removed.',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final isActive = _activeOverride ?? shop.active;
        final services = _servicesOverride ?? shop.services;
        final live = _buildLiveShop(shop, isActive, services);

        return Scaffold(
          backgroundColor: AppColors.bgPage,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildTopBar(context, shop),
                _buildTabBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
                    child: _buildTabBody(context, live, services, isActive),
                  ),
                ),
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
    );
  }

  Widget _buildTopBar(BuildContext context, Shop shop) {
    return Stack(
      children: [
        TopBar(
          title: shop.name,
          onBack: () => context.pop(),
          actions: [
            AppIconButton(
              icon: AppIcons.more,
              semanticLabel: 'More actions',
              onTap: () => setState(() => _menuOpen = !_menuOpen),
            ),
          ],
        ),
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
            right: 8.w,
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
                _toast('Duplicate shop');
              },
              onExport: () {
                setState(() => _menuOpen = false);
                _toast('Export (CSV)');
              },
            ),
          ),
        ],
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
          onManageHours: () => context.push(Routes.shopHours(live.id)),
        );
      case 1:
        return ServicesSection(
          services: services,
          onToggleService: (id) {
            final updated = services.map((sv) {
              if (sv.id != id) return sv;
              return ShopService(
                id: sv.id,
                name: sv.name,
                description: sv.description,
                samePrice: sv.samePrice,
                active: !sv.active,
                flatPrice: sv.flatPrice,
                flatMinutes: sv.flatMinutes,
                pricing: sv.pricing,
              );
            }).toList();
            setState(() => _servicesOverride = updated);
          },
          onAddService: () => context.push(Routes.addService(live.id)),
          onEditService: (svId) =>
              context.push(Routes.editService(live.id, svId)),
          onToast: _toast,
        );
      case 2:
      default:
        return SettlementSection(
          shop: live,
          onCreatePayout: () => context.push(Routes.payouts),
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
                  horizontal: 14.w, vertical: 13.h,
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

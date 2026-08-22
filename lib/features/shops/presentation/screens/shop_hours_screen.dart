import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/widgets.dart';

import '../../application/providers/shop_hours_providers.dart';
import '../../application/providers/shops_providers.dart';
import '../../domain/entities/holiday.dart';
import '../../domain/entities/shop.dart';
import '../components/shop_card.dart';

/// Hours & Slots screen for a shop.
///
/// Weekly schedule, slot breaks, slot-level-capacity toggle, and holidays are
/// backed by real endpoints (see `docs/api_admin.md` §3.4). Per-slot
/// capacity *numbers* have no backend endpoint yet, so that control is not
/// shown here — only the on/off toggle, which is a real `Shop` field.
class ShopHoursScreen extends ConsumerStatefulWidget {
  const ShopHoursScreen({required this.shopId, super.key});

  final String shopId;

  @override
  ConsumerState<ShopHoursScreen> createState() => _ShopHoursScreenState();
}

class _ShopHoursScreenState extends ConsumerState<ShopHoursScreen> {
  // Local mutable slot-day config
  List<_DayState>? _days;
  bool? _slotCapEnabled;
  String? _expandedDay;
  bool _saving = false;

  void _init(List<WeeklyDay> weekly, bool slotCapEnabled) {
    if (_days != null) return;
    _slotCapEnabled = slotCapEnabled;
    _days = weekly.map((w) {
      return _DayState(
        day: w.day,
        weekday: w.weekday,
        closed: w.closed,
        open: w.open,
        close: w.close,
        slots: _buildSlots(w.open, w.close, w.offSlots),
      );
    }).toList();
    _expandedDay =
        _days!.firstWhere((d) => !d.closed, orElse: () => _days!.first).day;
  }

  List<_SlotState> _buildSlots(int open, int close, List<int> offSlots) {
    return List.generate(
      close - open,
      (i) {
        final h = open + i;
        return _SlotState(h: h, off: offSlots.contains(h));
      },
    );
  }

  void _rebuildSlots(int dayIdx) {
    final d = _days![dayIdx];
    final newSlots = _buildSlots(d.open, d.close, const []);
    // Preserve off-state from existing slots
    final merged = newSlots.map((s) {
      final existing = d.slots.firstWhere(
        (e) => e.h == s.h,
        orElse: () => s,
      );
      return _SlotState(h: s.h, off: existing.off);
    }).toList();
    setState(() => _days![dayIdx] = d.copyWith(slots: merged));
  }

  void _patch(int i, _DayState Function(_DayState) fn) {
    setState(() => _days![i] = fn(_days![i]));
  }

  void _toast(String msg) => AppToast.show(context, msg);

  void _showError(String title, Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave(Shop shop) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final days = _days!
          .map((d) => WeeklyDay(
                day: d.day,
                weekday: d.weekday,
                closed: d.closed,
                open: d.open,
                close: d.close,
                offSlots: d.slots.where((s) => s.off).map((s) => s.h).toList(),
              ))
          .toList();
      final capChanged = _slotCapEnabled != shop.slotCapacityEnabled;

      await ref.read(saveShopHoursProvider)(
        widget.shopId,
        days: days,
        useSlotLevelCapacity: capChanged ? _slotCapEnabled : null,
      );

      if (!mounted) return;
      _toast('Hours & slots saved');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Failed to save hours & slots', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(shopDetailProvider(widget.shopId));
    final weeklyAsync = ref.watch(shopWeeklyScheduleProvider(widget.shopId));

    if (shopAsync.hasError || weeklyAsync.hasError) {
      return Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SafeArea(
          child: Column(
            children: [
              TopBar(title: 'Hours & Slots', onBack: () => context.pop()),
              Expanded(
                child: ErrorView(
                  onRetry: () {
                    ref.invalidate(shopDetailProvider(widget.shopId));
                    ref.invalidate(shopWeeklyScheduleProvider(widget.shopId));
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    final shop = shopAsync.valueOrNull;
    final weekly = weeklyAsync.valueOrNull;
    if (shop == null || weekly == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgPage,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _init(weekly, shop.slotCapacityEnabled);

    final holidaysAsync = ref.watch(shopHolidaysProvider(widget.shopId));
    final holidays = holidaysAsync.valueOrNull ?? <Holiday>[];
    final allShops = ref.watch(shopsProvider).valueOrNull ?? <Shop>[];

    final days = _days!;
    final slotCapEnabled = _slotCapEnabled ?? shop.slotCapacityEnabled;
    final firstWorking = days.isNotEmpty
        ? days.firstWhere(
            (d) => !d.closed,
            orElse: () => days.first,
          )
        : null;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: 'Hours & Slots',
              subtitle: shop.name,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.blueBg,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            AppIcons.alert,
                            size: 18.sp,
                            color: AppColors.blueFg,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Slots are auto-generated hourly from each day\'s opening hours. Turn off individual slots for breaks.',
                              style: AppText.figtree(
                                size: 12.5,
                                weight: FontWeight.w500,
                                color: AppColors.blueFg,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Slot capacity master card
                    AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Slot-level capacity',
                                  style: AppText.figtree(
                                    size: 14,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Text(
                                  slotCapEnabled
                                      ? 'On — per-slot capacity governs how many cars each slot can take'
                                      : 'Off — daily cap of ${shop.slotCap} applies',
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
                            on: slotCapEnabled,
                            onChanged: (v) =>
                                setState(() => _slotCapEnabled = v),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Weekly schedule section
                    Row(
                      children: [
                        Text(
                          'WEEKLY SCHEDULE',
                          style: AppText.figtree(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.fgSecondary,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const Spacer(),
                        if (firstWorking != null && !firstWorking.closed)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _days = _days!.map((d) {
                                  if (d.closed) return d;
                                  return d.copyWith(
                                    open: firstWorking.open,
                                    close: firstWorking.close,
                                    slots: firstWorking.slots
                                        .map((s) => _SlotState(
                                              h: s.h,
                                              off: s.off,
                                            ))
                                        .toList(),
                                  );
                                }).toList();
                              });
                              _toast(
                                'Copied ${firstWorking.day}\'s hours to all working days',
                              );
                            },
                            child: Row(
                              children: [
                                Icon(AppIcons.copy,
                                    size: 14.sp,
                                    color: AppColors.fgSecondary),
                                SizedBox(width: 5.w),
                                Text(
                                  'Copy ${firstWorking.day} to all',
                                  style: AppText.figtree(
                                    size: 12.5,
                                    weight: FontWeight.w600,
                                    color: AppColors.fgSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    ...List.generate(days.length, (i) {
                      final d = days[i];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: _DayCard(
                          d: d,
                          expanded: _expandedDay == d.day,
                          onToggleExpand: () => setState(() {
                            _expandedDay =
                                _expandedDay == d.day ? null : d.day;
                          }),
                          onSetClosed: (closed) =>
                              _patch(i, (d) => d.copyWith(closed: closed)),
                          onSetOpen: (v) {
                            _patch(i, (d) => d.copyWith(open: v));
                            _rebuildSlots(i);
                          },
                          onSetClose: (v) {
                            _patch(i, (d) => d.copyWith(close: v));
                            _rebuildSlots(i);
                          },
                          onToggleSlot: (h) => _patch(
                            i,
                            (d) => d.copyWith(
                              slots: d.slots
                                  .map((s) => s.h == h
                                      ? _SlotState(h: s.h, off: !s.off)
                                      : s)
                                  .toList(),
                            ),
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 4.h),

                    // Holidays section
                    Row(
                      children: [
                        Text(
                          'UPCOMING HOLIDAYS',
                          style: AppText.figtree(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.fgSecondary,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (holidays.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Center(
                                child: Text(
                                  'No holidays marked.',
                                  style: AppText.figtree(
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: AppColors.fgMuted,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...List.generate(holidays.length, (i) {
                              final h = holidays[i];
                              return Container(
                                padding:
                                    EdgeInsets.symmetric(vertical: 11.h),
                                decoration: i < holidays.length - 1
                                    ? const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              color: AppColors.borderSoft),
                                        ),
                                      )
                                    : null,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38.r,
                                      height: 38.r,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.amberBg,
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                      ),
                                      child: Icon(
                                        AppIcons.calendar,
                                        size: 18.sp,
                                        color: AppColors.amberFg,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fmtHolidayDate(h.date),
                                            style: AppText.figtree(
                                              size: 13.5,
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            '${h.label} · ${h.shopIds.length} shop${h.shopIds.length == 1 ? '' : 's'}',
                                            style: AppText.figtree(
                                              size: 12,
                                              weight: FontWeight.w500,
                                              color: AppColors.fgTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        final confirmed =
                                            await showConfirmDialog(
                                          context: context,
                                          title: 'Remove this holiday?',
                                          body:
                                              '${fmtHolidayDate(h.date)} · ${h.label} will no longer close ${h.shopIds.length} shop${h.shopIds.length == 1 ? '' : 's'}.',
                                          confirmLabel: 'Remove',
                                          destructive: true,
                                        );
                                        if (!confirmed || !mounted) return;
                                        try {
                                          await ref
                                              .read(holidayEditorProvider)
                                              .delete(h.id,
                                                  shopIds: h.shopIds);
                                          if (!mounted) return;
                                          _toast('Holiday removed');
                                        } catch (e) {
                                          if (!mounted) return;
                                          _showError(
                                              'Failed to remove holiday', e);
                                        }
                                      },
                                      child: Container(
                                        width: 30.r,
                                        height: 30.r,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppColors.bgCard,
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                          border: Border.all(
                                              color:
                                                  AppColors.borderDefault),
                                        ),
                                        child: Icon(
                                          AppIcons.close,
                                          size: 16.sp,
                                          color: AppColors.fgTertiary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          SizedBox(
                              height: holidays.isNotEmpty ? 12.h : 4.h),
                          GestureDetector(
                            onTap: () =>
                                _showMarkHolidayModal(context, allShops),
                            child: Container(
                              height: 44.h,
                              alignment: Alignment.center,
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
                                  Icon(AppIcons.plus,
                                      size: 16.sp,
                                      color: AppColors.fgSecondary),
                                  SizedBox(width: 7.w),
                                  Text(
                                    'Mark a holiday',
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
                border:
                    Border(top: BorderSide(color: AppColors.borderSoft)),
              ),
              child: AppButton(
                label: 'Save Changes',
                full: true,
                disabled: _saving,
                onPressed: () => _handleSave(shop),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkHolidayModal(BuildContext context, List<Shop> allShops) {
    showAppModal<void>(
      context: context,
      builder: (modalCtx) => _HolidayModalBody(
        currentShopId: widget.shopId,
        allShopIds: allShops.map((s) => s.id).toList(),
        allShopNames: {for (final s in allShops) s.id: s.name},
        onSave: (date, label, shopIds) async {
          Navigator.of(modalCtx).pop();
          try {
            await ref.read(holidayEditorProvider).create(
                  date: date,
                  label: label,
                  shopIds: shopIds,
                );
            if (!mounted) return;
            _toast(
              'Holiday marked for ${shopIds.length} shop${shopIds.length == 1 ? '' : 's'}',
            );
          } catch (e) {
            if (!mounted) return;
            _showError('Failed to mark holiday', e);
          }
        },
        onBack: () => Navigator.of(modalCtx).pop(),
      ),
    );
  }
}

// ─── Holiday modal body ───────────────────────────────────────────────────────

class _HolidayModalBody extends StatefulWidget {
  const _HolidayModalBody({
    required this.currentShopId,
    required this.allShopIds,
    required this.allShopNames,
    required this.onSave,
    required this.onBack,
  });

  final String currentShopId;
  final List<String> allShopIds;
  final Map<String, String> allShopNames;
  final Future<void> Function(String date, String label, List<String> shopIds)
      onSave;
  final VoidCallback onBack;

  @override
  State<_HolidayModalBody> createState() => _HolidayModalBodyState();
}

class _HolidayModalBodyState extends State<_HolidayModalBody> {
  String _date = '2026-06-07';
  String _label = '';
  late List<String> _ids;

  @override
  void initState() {
    super.initState();
    _ids = [widget.currentShopId];
  }

  void _toggleId(String id) {
    setState(() {
      _ids = _ids.contains(id)
          ? _ids.where((x) => x != id).toList()
          : [..._ids, id];
    });
  }

  @override
  Widget build(BuildContext context) {
    final allOn = widget.allShopIds.isNotEmpty &&
        _ids.length == widget.allShopIds.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mark a holiday',
          style: AppText.figtree(size: 19, weight: FontWeight.w700),
        ),
        SizedBox(height: 6.h),
        Text(
          'Closes the selected shops for the whole day. Apply to many at once — handy when a festival hits most shops.',
          style: AppText.figtree(
            size: 13,
            weight: FontWeight.w400,
            color: AppColors.fgSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: 18.h),
        Text(
          'Date',
          style: AppText.figtree(
            size: 12.5,
            weight: FontWeight.w600,
            color: AppColors.fgSecondary,
          ),
        ),
        SizedBox(height: 7.h),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() {
                _date = picked.toIso8601String().substring(0, 10);
              });
            }
          },
          child: Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 13.w),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              _date,
              style: AppText.figtree(size: 15, weight: FontWeight.w500),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          'Label',
          style: AppText.figtree(
            size: 12.5,
            weight: FontWeight.w600,
            color: AppColors.fgSecondary,
          ),
        ),
        SizedBox(height: 7.h),
        Container(
          height: 50.h,
          padding: EdgeInsets.symmetric(horizontal: 13.w),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: TextField(
            onChanged: (v) => setState(() => _label = v),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'e.g. Onam, Maintenance',
              hintStyle: AppText.figtree(
                size: 15,
                weight: FontWeight.w500,
                color: AppColors.fgMuted,
              ),
            ),
            style: AppText.figtree(size: 15, weight: FontWeight.w500),
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Text(
              'Apply to shops',
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w600,
                color: AppColors.fgSecondary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() {
                _ids = allOn ? [] : [...widget.allShopIds];
              }),
              child: Text(
                allOn ? 'Clear all' : 'All shops',
                style: AppText.figtree(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: AppColors.fgSecondary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: widget.allShopIds.map((id) {
            return AppChip(
              label: widget.allShopNames[id] ?? id,
              active: _ids.contains(id),
              onTap: () => _toggleId(id),
            );
          }).toList(),
        ),
        SizedBox(height: 22.h),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Back',
                kind: AppButtonKind.secondary,
                full: true,
                onPressed: widget.onBack,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: AppButton(
                label: 'Mark Holiday',
                full: true,
                disabled: _date.isEmpty || _ids.isEmpty,
                onPressed: () => widget.onSave(
                  _date,
                  _label.trim().isEmpty ? 'Holiday' : _label.trim(),
                  _ids,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── DayCard ──────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.d,
    required this.expanded,
    required this.onToggleExpand,
    required this.onSetClosed,
    required this.onSetOpen,
    required this.onSetClose,
    required this.onToggleSlot,
  });

  final _DayState d;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<bool> onSetClosed;
  final ValueChanged<int> onSetOpen;
  final ValueChanged<int> onSetClose;
  final ValueChanged<int> onToggleSlot;

  @override
  Widget build(BuildContext context) {
    final liveSlots = d.slots.where((s) => !s.off).length;
    return AppCard(
      padded: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: d.closed ? null : onToggleExpand,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 38.w,
                          child: Text(
                            d.day,
                            style: AppText.figtree(
                              size: 14.5,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (d.closed)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 9.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgPage,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'OFF DAY',
                              style: AppText.figtree(
                                size: 11,
                                weight: FontWeight.w600,
                                color: AppColors.fgMuted,
                                letterSpacing: 0.04,
                              ),
                            ),
                          )
                        else ...[
                          Text(
                            '${fmtHour(d.open)} – ${fmtHour(d.close)}',
                            style: AppText.figtree(
                              size: 12.5,
                              weight: FontWeight.w500,
                              color: AppColors.fgSecondary,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '· $liveSlots slots',
                            style: AppText.figtree(
                              size: 12.5,
                              weight: FontWeight.w500,
                              color: AppColors.fgTertiary,
                            ),
                          ),
                          const Spacer(),
                          AnimatedRotation(
                            turns: expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              AppIcons.chevDown,
                              size: 18.sp,
                              color: AppColors.fgTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                _AppToggle(
                  on: !d.closed,
                  onChanged: (v) => onSetClosed(!v),
                ),
              ],
            ),
          ),
          if (!d.closed && expanded)
            Container(
              padding: EdgeInsets.fromLTRB(14.w, 2.h, 14.w, 16.h),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderSoft)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Opens stepper
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    child: Row(
                      children: [
                        Text(
                          'Opens',
                          style: AppText.figtree(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: AppColors.fgSecondary,
                          ),
                        ),
                        const Spacer(),
                        _Stepper(
                          value: d.open,
                          min: 0,
                          max: d.close - 1,
                          onChange: onSetOpen,
                          fmt: fmtHour,
                          width: 96,
                        ),
                      ],
                    ),
                  ),
                  // Closes stepper
                  Padding(
                    padding: EdgeInsets.only(bottom: 14.h),
                    child: Row(
                      children: [
                        Text(
                          'Closes',
                          style: AppText.figtree(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: AppColors.fgSecondary,
                          ),
                        ),
                        const Spacer(),
                        _Stepper(
                          // Capped at 23: the server's slot grid runs
                          // 00:00–23:30, so there is no slot to represent a
                          // literal midnight (24) close time.
                          value: d.close,
                          min: d.open + 1,
                          max: 23,
                          onChange: onSetClose,
                          fmt: fmtHour,
                          width: 96,
                        ),
                      ],
                    ),
                  ),
                  // Slots label
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Text(
                      'TIME SLOTS · TAP TO TURN OFF FOR BREAKS',
                      style: AppText.figtree(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: AppColors.fgTertiary,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: d.slots.map((s) {
                      return GestureDetector(
                        onTap: () => onToggleSlot(s.h),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 11.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: s.off
                                ? AppColors.bgPage
                                : AppColors.brandYellow,
                            borderRadius: BorderRadius.circular(9.r),
                            border: Border.all(
                              color: s.off
                                  ? AppColors.borderDefault
                                  : AppColors.brandYellowDeep,
                            ),
                          ),
                          child: Text(
                            fmtHour(s.h),
                            style: AppText.figtree(
                              size: 12,
                              weight: FontWeight.w600,
                              color: s.off
                                  ? AppColors.fgMuted
                                  : AppColors.fgPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Stepper ──────────────────────────────────────────────────────────────────

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChange,
    this.fmt,
    this.width = 96,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChange;
  final String Function(int)? fmt;
  final double width;

  @override
  Widget build(BuildContext context) {
    final canDec = value > min;
    final canInc = value < max;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepBtn(
          label: '−',
          enabled: canDec,
          onTap: () => onChange(value - 1),
        ),
        SizedBox(
          width: width.w,
          child: Text(
            fmt != null ? fmt!(value) : '$value',
            textAlign: TextAlign.center,
            style: AppText.figtree(size: 13.5, weight: FontWeight.w700),
          ),
        ),
        _StepBtn(
          label: '+',
          enabled: canInc,
          onTap: () => onChange(value + 1),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn(
      {required this.label, required this.enabled, required this.onTap});
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30.r,
        height: 30.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppColors.bgCard : AppColors.bgPage,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Text(
          label,
          style: AppText.figtree(
            size: 16,
            weight: FontWeight.w700,
            color: enabled ? AppColors.fgPrimary : AppColors.fgMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Toggle ───────────────────────────────────────────────────────────────────

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
                  color: Colors.black.withValues(alpha: 0.25),
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

// ─── Value classes ────────────────────────────────────────────────────────────

class _SlotState {
  const _SlotState({required this.h, required this.off});
  final int h;
  final bool off;
}

class _DayState {
  const _DayState({
    required this.day,
    required this.weekday,
    required this.closed,
    required this.open,
    required this.close,
    required this.slots,
  });

  final String day;
  final int weekday;
  final bool closed;
  final int open;
  final int close;
  final List<_SlotState> slots;

  _DayState copyWith({
    String? day,
    bool? closed,
    int? open,
    int? close,
    List<_SlotState>? slots,
  }) {
    return _DayState(
      day: day ?? this.day,
      weekday: weekday,
      closed: closed ?? this.closed,
      open: open ?? this.open,
      close: close ?? this.close,
      slots: slots ?? this.slots,
    );
  }
}

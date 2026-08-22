import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:new_flutter_project/app/router/app_router.dart';
import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/status/booking_status.dart';
import 'package:new_flutter_project/core/status/payment_status.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/core/utils/map_launcher.dart';
import 'package:new_flutter_project/core/widgets/app_bottom_sheet.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_dialog.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/avatar.dart';
import 'package:new_flutter_project/core/widgets/collapsible.dart';
import 'package:new_flutter_project/core/widgets/skeleton_card.dart';
import 'package:new_flutter_project/core/widgets/status_badge.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import 'package:new_flutter_project/features/shops/application/providers/shops_providers.dart';
import 'package:new_flutter_project/features/shops/domain/entities/shop.dart';
import 'package:new_flutter_project/features/drivers/application/providers/drivers_providers.dart';
import 'package:new_flutter_project/features/refunds/presentation/screens/new_refund_screen.dart'
    show RefundPrefill;

import '../../application/providers/bookings_providers.dart';
import '../../domain/entities/booking.dart';
import '../components/assign_sheet.dart';
import '../components/damage_check_sheet.dart';
import '../components/status_update_block.dart';

/// Full booking detail screen. Reached by pushing [Routes.bookingDetail(id)].
/// Requires [bookingId] — no back button on the shell.
class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  // Mutable local UI state that the user can advance (mirrors JSX useState)
  BookingStatus? _status;
  String? _driverId;
  String? _assigneeName;
  List<TimelineEntry>? _timeline;
  String? _notes;
  bool _menuOpen = false;

  /// The provider value the state above was last seeded from — see
  /// [_initFromBooking].
  Booking? _syncedFrom;

  /// Today's date stamp for new log entries.
  String _nowStamp() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final amPm = now.hour < 12 ? 'AM' : 'PM';
    return '29 May, $h:$m $amPm';
  }

  /// Re-seed the mutable state above whenever the provider yields *new* server
  /// data.
  ///
  /// Identity is the test, not field equality. The provider hands back the same
  /// [Booking] instance on every rebuild until a refetch completes, so comparing
  /// fields would undo a local edit on the very next frame — `setState` itself
  /// triggers the rebuild that would revert it. Conversely `_timeline` used to
  /// be seeded with `??=`, which pinned it to the first load: a refetch updated
  /// every other field while the timeline stayed stale.
  void _initFromBooking(Booking b) {
    if (identical(_syncedFrom, b)) return;
    _syncedFrom = b;

    _status = b.status;
    _timeline = List.from(b.timeline);
    _notes = b.notes;
    if (_driverId != b.driverId) {
      _driverId = b.driverId;
      debugPrint('🔄 Updated driverId: $_driverId');
    }
    if (_assigneeName != b.assigneeName) {
      _assigneeName = b.assigneeName;
      debugPrint('🔄 Updated assigneeName: $_assigneeName');
    }
  }

  void _advance(BookingAction action, Booking base) {
    if (action.damage != null) {
      // Open damage check sheet first, then commit
      showDamageCheckSheet(
        context: context,
        phase: action.damage!,
        onSave: (_) => _commit(action, base),
      );
      return;
    }
    _commit(action, base);
  }

  Future<void> _commit(BookingAction action, Booking base) async {
    final next = action.to;
    final intId = int.tryParse(widget.bookingId);
    final wireKey = kWashingStatusWireKeys[next];

    final message = next == BookingStatus.completed
        ? 'Booking completed'
        : 'Updated → ${next.label}';

    // Car-wash bookings persist through the API, then re-read the server's own
    // status and timeline. Without this the tap only moved local state, which
    // the next rebuild reverted — the step appeared to advance and snap back.
    if (intId != null && wireKey != null) {
      try {
        await ref
            .read(bookingsRepositoryProvider)
            .updateWashingStatus(intId, wireKey);
      } catch (e) {
        if (mounted) {
          AppToast.show(
            context,
            'Could not update: ${e.toString().replaceFirst('Exception: ', '')}',
          );
        }
        return;
      }
      if (!mounted) return;
      ref.invalidate(bookingByIdProvider(widget.bookingId));
      ref.invalidate(bookingsProvider);
      AppToast.show(context, message);
      return;
    }

    // Sample and driver-hire bookings this screen also renders have no such
    // endpoint, so they stay local-only.
    setState(() {
      _status = next;
      _timeline = [
        ..._timeline!,
        TimelineEntry(
          status: next,
          at: _nowStamp(),
          by: 'Anand',
        ),
      ];
    });
    AppToast.show(context, message);
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _assignMeCarwash(
      BuildContext context, WidgetRef ref, int bookingId) async {
    try {
      await ref.read(bookingsRepositoryProvider).assignMe(bookingId);
      if (context.mounted) {
        AppToast.show(context, 'Assigned to you');
        // Invalidate both the detail provider and the list so the bookings
        // list reflects the new assignee immediately.
        ref.invalidate(bookingByIdProvider(bookingId.toString()));
        ref.invalidate(bookingsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(context, e.toString());
      }
    }
  }

  void _showAssignDriverSheet(
      BuildContext context, WidgetRef ref, int? bookingId) {
    if (bookingId == null) {
      // Use old mock assign sheet for driver & inspection bookings
      showAssignSheet(
        context: context,
        ref: ref,
        currentDriverId: _driverId,
        onPick: (id, name) {
          setState(() {
            _driverId = id;
            if (_status == BookingStatus.created) {
              _status = BookingStatus.assigned;
              _timeline = [
                ..._timeline!,
                TimelineEntry(
                  status: BookingStatus.assigned,
                  at: _nowStamp(),
                  by: name,
                ),
              ];
            }
          });
          AppToast.show(
            context,
            _status == BookingStatus.created
                ? 'Assigned to $name'
                : 'Reassigned to $name',
          );
        },
      );
    } else {
      // Use API-integrated assign sheet for carwash bookings
      showAppBottomSheet(
        context: context,
        title: 'Assign driver',
        maxHeightFactor: 0.72,
        builder: (_) => _CarwashAssignDriverBody(
          bookingId: bookingId,
          ref: ref,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingByIdProvider(widget.bookingId));

    return bookingAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              TopBar(
                title: 'Booking',
                onBack: () => context.pop(),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: 5,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, __) => const SkeletonCard(),
                ),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SafeArea(
          child: Column(
            children: [
              TopBar(title: 'Booking', onBack: () => context.pop()),
              const Expanded(
                child: Center(child: Text('Booking not found')),
              ),
            ],
          ),
        ),
      ),
      data: (booking) {
        if (booking == null) {
          return Scaffold(
            backgroundColor: AppColors.bgPage,
            body: SafeArea(
              child: Column(
                children: [
                  TopBar(title: 'Booking', onBack: () => context.pop()),
                  const Expanded(
                    child: Center(child: Text('Booking not found')),
                  ),
                ],
              ),
            ),
          );
        }

        // Seed mutable state from the loaded booking (first time only)
        _initFromBooking(booking);

        // For carwash bookings, get the int ID
        final intId = int.tryParse(widget.bookingId);

        final status = _status!;
        final driverId = _driverId;
        final timeline = _timeline!;
        final notes = _notes ?? '';

        final totalMin = booking.estimatedMinutes;

        final canCancel = status != BookingStatus.completed &&
            status != BookingStatus.refundRequested &&
            status != BookingStatus.refunded;
        final canRefund = status != BookingStatus.pending &&
            status != BookingStatus.refundRequested &&
            status != BookingStatus.refunded;
        final canReassign = status != BookingStatus.completed &&
            status != BookingStatus.refundRequested &&
            status != BookingStatus.refunded &&
            status != BookingStatus.cancelled &&
            status != BookingStatus.pending;

        // Damage summary
        final dmgPickup = booking.damage.pickup;
        final dmgDrop = booking.damage.drop;
        final dmgSummary = (dmgPickup == null && dmgDrop == null)
            ? 'Not checked yet'
            : [
                if (dmgPickup != null)
                  'Pickup: ${dmgPickup.issues ? "Issues noted" : "Clean"}',
                if (dmgDrop != null)
                  'Drop: ${dmgDrop.issues ? "Issues noted" : "Clean"}',
              ].join(' · ');

        final issueList = [
          if (dmgPickup != null && dmgPickup.issues) ('pickup', dmgPickup),
          if (dmgDrop != null && dmgDrop.issues) ('drop', dmgDrop),
        ];

        return Scaffold(
          backgroundColor: AppColors.bgPage,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // TopBar with 3-dot menu
                TopBar(
                  title: 'Booking',
                  onBack: () => context.pop(),
                  actions: [
                    Consumer(
                      builder: (_, WidgetRef consumerRef, __) => _MenuButton(
                        open: _menuOpen,
                        onToggle: () => setState(() => _menuOpen = !_menuOpen),
                        onShare: () {
                          setState(() => _menuOpen = false);
                          AppToast.show(context, 'Share booking');
                        },
                        onCopyId: () {
                          setState(() => _menuOpen = false);
                          Clipboard.setData(ClipboardData(text: booking.id));
                          AppToast.show(context, 'Booking ID copied');
                        },
                        onAddNote: () {
                          setState(() => _menuOpen = false);
                          _showNoteModal(context, notes);
                        },
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(bookingByIdProvider(widget.bookingId));
                      await ref
                          .read(bookingByIdProvider(widget.bookingId).future);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
                      children: [
                        // ── Hero header ──────────────────────────────────────
                        AppCard(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  StatusBadge(
                                    label: status.label,
                                    tone: status.tone,
                                  ),
                                  Text(
                                    booking.id,
                                    style: AppText.figtree(
                                      size: 12,
                                      weight: FontWeight.w500,
                                      color: AppColors.fgTertiary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 14.h),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TOTAL',
                                        style: AppText.figtree(
                                          size: 10.5,
                                          weight: FontWeight.w700,
                                          color: AppColors.fgTertiary,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      SizedBox(height: 5.h),
                                      Text(
                                        Formatters.money(booking.total),
                                        style: AppText.figtree(
                                          size: 30,
                                          weight: FontWeight.w800,
                                          letterSpacing: -1,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  _PaymentPill(payment: booking.payment),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),

                        // ── Customer ─────────────────────────────────────────
                        AppCard(
                          child: _SectionLabel(
                            icon: AppIcons.users,
                            label: 'Customer',
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking.customer.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.figtree(
                                          size: 16,
                                          weight: FontWeight.w700,
                                          height: 1.25,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        booking.customer.phone,
                                        style: AppText.figtree(
                                          size: 13,
                                          weight: FontWeight.w500,
                                          color: AppColors.fgTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _ActionPill(
                                  icon: AppIcons.phone,
                                  label: 'Call customer',
                                  onTap: () =>
                                      _makePhoneCall(booking.customer.phone),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 14.h),

                        // ── Vehicle ──────────────────────────────────────────
                        AppCard(
                          child: _SectionLabel(
                            icon: AppIcons.car,
                            label: 'Vehicle',
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking.vehicle.title,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.figtree(
                                          size: 15,
                                          weight: FontWeight.w700,
                                          height: 1.25,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        booking.vehicle.type,
                                        style: AppText.figtree(
                                          size: 13,
                                          weight: FontWeight.w500,
                                          color: AppColors.fgTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (booking.vehicle.plate != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 11.w,
                                      vertical: 7.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgPage,
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                          color: AppColors.borderSoft),
                                    ),
                                    child: Text(
                                      booking.vehicle.plate!,
                                      style: AppText.figtree(
                                        size: 13,
                                        weight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 14.h),

                        // ── Journey (pickup → shop → drop) ────────────────────
                        _JourneyCard(
                          booking: booking,
                          onToast: (msg) => AppToast.show(context, msg),
                        ),
                        SizedBox(height: 14.h),

                        // ── Services ─────────────────────────────────────────
                        AppCard(
                          child: _SectionLabel(
                            icon: AppIcons.droplet,
                            label: 'Services',
                            right: Text(
                              '~$totalMin min',
                              style: AppText.figtree(
                                size: 11.5,
                                weight: FontWeight.w600,
                                color: AppColors.fgTertiary,
                              ),
                            ),
                            child: Column(
                              children: [
                                for (final sv in booking.services)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 11.h),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sv.name,
                                              style: AppText.figtree(
                                                size: 14,
                                                weight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              'est. ${sv.minutes} min',
                                              style: AppText.figtree(
                                                size: 12,
                                                weight: FontWeight.w500,
                                                color: AppColors.fgTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          Formatters.money(sv.price),
                                          style: AppText.figtree(
                                            size: 14,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const Divider(
                                  color: AppColors.borderSoft,
                                  height: 1,
                                ),
                                SizedBox(height: 11.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total',
                                      style: AppText.figtree(
                                        size: 14,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      Formatters.money(booking.total),
                                      style: AppText.figtree(
                                        size: 16,
                                        weight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 14.h),

                        // ── Driver ───────────────────────────────────────────
                        _DriverCard(
                          driverId: driverId,
                          assigneeName: _assigneeName,
                          carwashBookingId: intId,
                          onAssign: () =>
                              _showAssignDriverSheet(context, ref, intId),
                          onCall: (name) =>
                              AppToast.show(context, 'Calling $name…'),
                        ),
                        SizedBox(height: 14.h),

                        // ── Status Update ─────────────────────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 2.w, bottom: 10.h),
                              child: Text(
                                'UPDATE STATUS',
                                style: AppText.eyebrow,
                              ),
                            ),
                            StatusUpdateBlock(
                              status: status,
                              timeline: timeline,
                              onAdvance: (action) => _advance(action, booking),
                              carwashBookingId: intId,
                              onAssignMe: intId != null
                                  ? () => _assignMeCarwash(context, ref, intId)
                                  : null,
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),

                        // ── Damage & Issues ───────────────────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 2.w, bottom: 10.h),
                              child: Text(
                                'DAMAGE & ISSUES',
                                style: AppText.eyebrow,
                              ),
                            ),
                            _DamageSection(
                              issueList: issueList,
                              pickup: booking.damage.pickup,
                              drop: booking.damage.drop,
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),

                        // ── Collapsibles ──────────────────────────────────────
                        Collapsible(
                          title: 'Status Timeline',
                          leading: Icon(
                            AppIcons.clock,
                            size: 17.sp,
                            color: AppColors.fgSecondary,
                          ),
                          summary:
                              '${timeline.length} updates · now ${status.label}',
                          child: Column(
                            children: [
                              for (int i = 0; i < timeline.length; i++)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 9.r,
                                          height: 9.r,
                                          margin: EdgeInsets.only(top: 5.h),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: i == timeline.length - 1
                                                ? AppColors.brandYellowDeep
                                                : AppColors.borderStrong,
                                          ),
                                        ),
                                        if (i < timeline.length - 1)
                                          Container(
                                            width: 0,
                                            height: 36.h,
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                left: BorderSide(
                                                  color: AppColors.borderSoft,
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(bottom: 14.h),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              timeline[i].status.label,
                                              style: AppText.figtree(
                                                size: 13.5,
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              '${timeline[i].at} · ${timeline[i].by}',
                                              style: AppText.figtree(
                                                size: 12,
                                                weight: FontWeight.w500,
                                                color: AppColors.fgTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),

                        Collapsible(
                          title: 'Damage Check',
                          leading: Icon(
                            AppIcons.checkCircle,
                            size: 17.sp,
                            color: AppColors.fgSecondary,
                          ),
                          summary: dmgSummary,
                          child: Row(
                            children: [
                              for (final phase in ['pickup', 'drop'])
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: phase == 'pickup' ? 6.w : 0,
                                      left: phase == 'drop' ? 6.w : 0,
                                    ),
                                    child: _DamagePhaseTile(
                                      phase: phase,
                                      check: phase == 'pickup'
                                          ? booking.damage.pickup
                                          : booking.damage.drop,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),

                        Collapsible(
                          title: 'Notes',
                          leading: Icon(
                            AppIcons.note,
                            size: 17.sp,
                            color: AppColors.fgSecondary,
                          ),
                          initiallyOpen: notes.isNotEmpty,
                          summary: notes.isNotEmpty ? '1 note' : 'No notes',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              notes.isNotEmpty
                                  ? Text(
                                      notes,
                                      style: AppText.figtree(
                                        size: 13.5,
                                        weight: FontWeight.w400,
                                        color: AppColors.fgSecondary,
                                        height: 1.5,
                                      ),
                                    )
                                  : Text(
                                      'No notes yet.',
                                      style: AppText.figtree(
                                        size: 13,
                                        weight: FontWeight.w500,
                                        color: AppColors.fgMuted,
                                      ),
                                    ),
                              SizedBox(height: 12.h),
                              GestureDetector(
                                onTap: () => _showNoteModal(context, notes),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      AppIcons.edit,
                                      size: 14.sp,
                                      color: AppColors.fgSecondary,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      notes.isNotEmpty
                                          ? 'Edit note'
                                          : 'Add note',
                                      style: AppText.figtree(
                                        size: 12.5,
                                        weight: FontWeight.w700,
                                        color: AppColors.fgSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 100.h),
                      ],
                    ),
                  ),
                ),

                // ── Sticky footer ─────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.bgCard,
                    border: Border(
                      top: BorderSide(color: AppColors.borderSoft),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        _FooterBtn(
                          label: 'Cancel',
                          icon: AppIcons.close,
                          enabled: canCancel,
                          danger: true,
                          onTap: () async {
                            final confirmed = await showConfirmDialog(
                              context: context,
                              title: 'Cancel this booking?',
                              body:
                                  'The customer will be notified and a refund may be required.',
                              confirmLabel: 'Yes, cancel',
                              destructive: true,
                            );
                            if (!confirmed || !context.mounted) return;
                            try {
                              final intId = int.tryParse(booking.id);
                              if (intId == null) {
                                AppToast.show(context, 'Invalid booking ID');
                                return;
                              }
                              await ref
                                  .read(bookingsRepositoryProvider)
                                  .cancelBooking(intId);
                              if (context.mounted) {
                                AppToast.show(context, 'Booking cancelled');
                                // Invalidate both the detail provider and the
                                // list so the cancellation shows immediately.
                                ref.invalidate(bookingByIdProvider(booking.id));
                                ref.invalidate(bookingsProvider);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppToast.show(context, e.toString());
                              }
                            }
                          },
                        ),
                        _FooterBtn(
                          label: 'Refund',
                          icon: AppIcons.receipt,
                          enabled: canRefund,
                          onTap: () {
                            context.push(
                              Routes.refunds,
                              extra: RefundPrefill(
                                bookingId: booking.id,
                                bookingReference: booking.reference.isNotEmpty
                                    ? booking.reference
                                    : null,
                                customerName: booking.customer.name,
                                total: booking.total,
                                status: status.key,
                              ),
                            );
                          },
                        ),
                        _FooterBtn(
                          label: 'Reassign',
                          icon: AppIcons.refresh,
                          enabled: canReassign,
                          onTap: () =>
                              _showAssignDriverSheet(context, ref, intId),
                        ),
                      ],
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

  void _showNoteModal(BuildContext context, String currentNotes) {
    final ctrl = TextEditingController(text: currentNotes);
    showAppModal<void>(
      context: context,
      builder: (modalCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentNotes.isNotEmpty ? 'Edit note' : 'Add note',
            style: AppText.figtree(size: 19, weight: FontWeight.w700),
          ),
          SizedBox(height: 6.h),
          Text(
            'Internal note for this booking — visible to founders only.',
            style: AppText.figtree(
              size: 13,
              weight: FontWeight.w400,
              color: AppColors.fgSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: ctrl,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Type a note…',
              hintStyle: AppText.figtree(
                size: 14,
                weight: FontWeight.w400,
                color: AppColors.fgMuted,
              ),
              contentPadding: EdgeInsets.all(12.r),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.brandYellowDeep),
              ),
            ),
            style: AppText.figtree(size: 14, weight: FontWeight.w400),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _ModalBtn(
                  label: 'Cancel',
                  secondary: true,
                  onTap: () => Navigator.of(modalCtx).pop(),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _ModalBtn(
                  label: 'Save',
                  onTap: () {
                    final trimmed = ctrl.text.trim();
                    setState(() => _notes = trimmed);
                    Navigator.of(modalCtx).pop();
                    AppToast.show(
                      context,
                      trimmed.isNotEmpty ? 'Note saved' : 'Note cleared',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Journey card ───────────────────────────────────────────────────────────────

class _JourneyCard extends ConsumerWidget {
  const _JourneyCard({required this.booking, required this.onToast});

  final Booking booking;
  final void Function(String) onToast;

  Future<void> _navigateToAddress(String address) async {
    if (address.trim().isEmpty) {
      onToast('No address available');
      return;
    }
    if (!await launchMapPin(address: address, label: address)) {
      onToast('Cannot open maps');
    }
  }

  Future<void> _navigateToShop(Shop shop) async {
    // Coordinates pin exactly; the address is the geocoded fallback for a shop
    // that was never placed on the map.
    final opened = await launchMapPin(
      latitude: shop.latitude,
      longitude: shop.longitude,
      label: shop.name,
      address: shop.address.isNotEmpty ? shop.address : shop.area,
    );
    if (!opened) {
      onToast('No location available for this shop');
    }
  }

  Future<void> _callShop(Shop shop) async {
    final phone =
        shop.shopPhone.trim().isNotEmpty ? shop.shopPhone : shop.ownerPhone;
    if (phone.trim().isEmpty) {
      onToast('No phone number for this shop');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      onToast('Cannot open dialer for $phone');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopByIdProvider(booking.shopId));

    return AppCard(
      child: _SectionLabel(
        icon: AppIcons.nav,
        label: 'Journey',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ladder
            Column(
              children: [
                SizedBox(height: 5.h),
                Container(
                  width: 10.r,
                  height: 10.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandYellowDeep,
                    border: Border.all(color: AppColors.brandYellow, width: 2),
                  ),
                ),
                Container(
                  width: 0,
                  height: 52.h,
                  decoration: const BoxDecoration(
                    border: Border(
                      left:
                          BorderSide(color: AppColors.borderDefault, width: 2),
                    ),
                  ),
                ),
                Container(
                  width: 18.r,
                  height: 18.r,
                  decoration: const BoxDecoration(
                    color: AppColors.fgPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.store,
                    size: 11.sp,
                    color: AppColors.fgOnDark,
                  ),
                ),
                Container(
                  width: 0,
                  height: 52.h,
                  decoration: const BoxDecoration(
                    border: Border(
                      left:
                          BorderSide(color: AppColors.borderDefault, width: 2),
                    ),
                  ),
                ),
                Container(
                  width: 10.r,
                  height: 10.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgCard,
                    border: Border.all(color: AppColors.borderStrong, width: 2),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                children: [
                  // Pickup
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PICKUP · ${booking.pickup.time}',
                              style: AppText.figtree(
                                size: 10.5,
                                weight: FontWeight.w600,
                                color: AppColors.fgTertiary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              booking.pickup.address,
                              style: AppText.figtree(
                                size: 13,
                                weight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ActionPill(
                        icon: AppIcons.nav,
                        label: 'Navigate',
                        onTap: () => _navigateToAddress(booking.pickup.address),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),

                  // Shop
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: shopAsync.when(
                          loading: () => const SizedBox(height: 36),
                          error: (_, __) => const SizedBox(height: 36),
                          data: (shop) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SHOP',
                                style: AppText.figtree(
                                  size: 10.5,
                                  weight: FontWeight.w600,
                                  color: AppColors.fgTertiary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                shop?.name ?? booking.shopId,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.figtree(
                                  size: 13.5,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              if (shop?.area != null)
                                Text(
                                  shop!.area,
                                  style: AppText.figtree(
                                    size: 12.5,
                                    weight: FontWeight.w500,
                                    color: AppColors.fgTertiary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _ActionPill(
                            icon: AppIcons.phone,
                            label: 'Call shop',
                            onTap: () {
                              final shop = shopAsync.asData?.value;
                              if (shop == null) {
                                onToast('Shop not loaded yet');
                                return;
                              }
                              _callShop(shop);
                            },
                          ),
                          SizedBox(width: 7.w),
                          _ActionPill(
                            icon: AppIcons.nav,
                            label: 'Navigate',
                            onTap: () {
                              final shop = shopAsync.asData?.value;
                              if (shop == null) {
                                onToast('Shop not loaded yet');
                                return;
                              }
                              _navigateToShop(shop);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),

                  // Drop
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DROP · ${booking.drop.time}',
                        style: AppText.figtree(
                          size: 10.5,
                          weight: FontWeight.w600,
                          color: AppColors.fgTertiary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        booking.drop.sameAsPickup
                            ? 'Same as pickup'
                            : booking.drop.address,
                        style: AppText.figtree(
                          size: 13,
                          weight: FontWeight.w500,
                          color: AppColors.fgSecondary,
                        ),
                      ),
                    ],
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

// ── Driver card ────────────────────────────────────────────────────────────────

class _DriverCard extends ConsumerWidget {
  const _DriverCard({
    required this.driverId,
    required this.onAssign,
    required this.onCall,
    this.carwashBookingId,
    this.assigneeName,
  });

  final String? driverId;
  final String? assigneeName;
  final VoidCallback onAssign;
  final void Function(String name) onCall;
  final int? carwashBookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint(
        '🎭 _DriverCard.build() - driverId: $driverId, assigneeName: $assigneeName, carwashBookingId: $carwashBookingId');

    // For carwash bookings with no driver, show custom assign UI
    if (carwashBookingId != null && driverId == null && assigneeName == null) {
      debugPrint('📍 Branch: Carwash with no driver - showing assign button');
      return AppCard(
        child: _SectionLabel(
          icon: AppIcons.car,
          label: 'Driver',
          child: GestureDetector(
            onTap: onAssign,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.brandYellowLight,
                    AppColors.brandYellow,
                    AppColors.brandYellowDeep,
                  ],
                  stops: [0, 0.55, 1],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Assign driver',
                    style: AppText.figtree(
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // If assigneeName is available but no driverId, show driver card with assignee name
    if (assigneeName != null && driverId == null) {
      debugPrint(
          '📍 Branch: AssigneeName without driverId - showing $assigneeName');
      return AppCard(
        child: _SectionLabel(
          icon: AppIcons.car,
          label: 'Driver',
          child: Row(
            children: [
              Avatar(name: assigneeName!, size: 38),
              SizedBox(width: 11.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assigneeName!,
                      style: AppText.figtree(
                        size: 14.5,
                        weight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Driver',
                      style: AppText.figtree(
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _ActionPill(
                icon: AppIcons.phone,
                label: 'Call driver',
                onTap: () => onCall(assigneeName!),
              ),
            ],
          ),
        ),
      );
    }

    // If driverId is available, fetch driver details
    if (driverId != null) {
      debugPrint(
          '📍 Branch: DriverID available - fetching details for $driverId');
      return AppCard(
        child: _SectionLabel(
          icon: AppIcons.car,
          label: 'Driver',
          child: ref.watch(assigneeByIdProvider(driverId!)).when(
                loading: () =>
                    SizedBox(height: 40.h, child: const SizedBox.shrink()),
                error: (_, __) {
                  // Show assignee name if driver fetch fails
                  if (assigneeName != null) {
                    return Row(
                      children: [
                        Avatar(name: assigneeName!, size: 38),
                        SizedBox(width: 11.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assigneeName!,
                                style: AppText.figtree(
                                  size: 14.5,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Driver',
                                style: AppText.figtree(
                                  size: 12.5,
                                  weight: FontWeight.w500,
                                  color: AppColors.fgTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _ActionPill(
                          icon: AppIcons.phone,
                          label: 'Call driver',
                          onTap: () => onCall(assigneeName!),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
                data: (driver) {
                  if (driver == null) {
                    // Show assignee name if driver is null
                    if (assigneeName != null) {
                      return Row(
                        children: [
                          Avatar(name: assigneeName!, size: 38),
                          SizedBox(width: 11.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assigneeName!,
                                  style: AppText.figtree(
                                    size: 14.5,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Driver',
                                  style: AppText.figtree(
                                    size: 12.5,
                                    weight: FontWeight.w500,
                                    color: AppColors.fgTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _ActionPill(
                            icon: AppIcons.phone,
                            label: 'Call driver',
                            onTap: () => onCall(assigneeName!),
                          ),
                        ],
                      );
                    }
                    return _assignButton(onAssign);
                  }
                  return Row(
                    children: [
                      Avatar(name: driver.name, size: 38),
                      SizedBox(width: 11.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.name,
                              style: AppText.figtree(
                                size: 14.5,
                                weight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${driver.role} · ${driver.phone}',
                              style: AppText.figtree(
                                size: 12.5,
                                weight: FontWeight.w500,
                                color: AppColors.fgTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ActionPill(
                        icon: AppIcons.phone,
                        label: 'Call driver',
                        onTap: () => onCall(driver.name),
                      ),
                    ],
                  );
                },
              ),
        ),
      );
    }

    // No driver or assignee name - show assign button
    debugPrint('📍 Branch: No driver or assignee name - showing assign button');
    return AppCard(
      child: _SectionLabel(
        icon: AppIcons.car,
        label: 'Driver',
        child: _assignButton(onAssign),
      ),
    );
  }

  Widget _assignButton(VoidCallback onAssign) {
    return GestureDetector(
      onTap: onAssign,
      child: Container(
        width: double.infinity,
        height: 46.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.brandYellowLight,
              AppColors.brandYellow,
              AppColors.brandYellowDeep,
            ],
            stops: [0, 0.55, 1],
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Assign driver',
              style: AppText.figtree(
                size: 14,
                weight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(AppIcons.arrowRight, size: 16.sp),
          ],
        ),
      ),
    );
  }
}

// ── Damage section ─────────────────────────────────────────────────────────────

class _DamageSection extends StatelessWidget {
  const _DamageSection({
    required this.issueList,
    required this.pickup,
    required this.drop,
  });

  final List<(String, DamageCheck)> issueList;
  final DamageCheck? pickup;
  final DamageCheck? drop;

  @override
  Widget build(BuildContext context) {
    if (issueList.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.redFg),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: AppColors.redBg,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
              child: Row(
                children: [
                  Icon(
                    AppIcons.alert,
                    size: 18.sp,
                    color: AppColors.redFg,
                  ),
                  SizedBox(width: 9.w),
                  Text(
                    '${issueList.length} issue${issueList.length == 1 ? "" : "s"} noted',
                    style: AppText.figtree(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.redFg,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 6.h),
              child: Column(
                children: [
                  for (int i = 0; i < issueList.length; i++)
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 11.h),
                      decoration: BoxDecoration(
                        border: i < issueList.length - 1
                            ? const Border(
                                bottom: BorderSide(color: AppColors.borderSoft),
                              )
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                issueList[i].$1[0].toUpperCase() +
                                    issueList[i].$1.substring(1),
                                style: AppText.figtree(
                                  size: 12.5,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Logged by driver',
                                style: AppText.figtree(
                                  size: 11.5,
                                  weight: FontWeight.w500,
                                  color: AppColors.fgTertiary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            issueList[i].$2.note,
                            style: AppText.figtree(
                              size: 13,
                              weight: FontWeight.w400,
                              color: AppColors.fgSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // No issues card
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: (pickup != null || drop != null)
                  ? AppColors.greenBg
                  : AppColors.bgPage,
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: Icon(
              (pickup != null || drop != null)
                  ? AppIcons.checkCircle
                  : AppIcons.clock,
              size: 18.sp,
              color: (pickup != null || drop != null)
                  ? AppColors.greenFg
                  : AppColors.fgTertiary,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (pickup != null || drop != null)
                      ? 'No issues reported'
                      : 'Not checked yet',
                  style: AppText.figtree(
                    size: 13.5,
                    weight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  (pickup != null || drop != null)
                      ? 'Vehicle inspected — all clear'
                      : 'Damage check happens at pickup & drop',
                  style: AppText.figtree(
                    size: 12,
                    weight: FontWeight.w400,
                    color: AppColors.fgTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DamagePhaseTile extends StatelessWidget {
  const _DamagePhaseTile({required this.phase, required this.check});

  final String phase;
  final DamageCheck? check;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.bgPage,
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            phase.toUpperCase(),
            style: AppText.figtree(
              size: 10.5,
              weight: FontWeight.w600,
              color: AppColors.fgTertiary,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 7.h),
          check != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          check!.issues ? AppIcons.alert : AppIcons.check,
                          size: 14.sp,
                          color: check!.issues
                              ? AppColors.redFg
                              : AppColors.greenFg,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          check!.issues ? 'Issues noted' : 'Clean',
                          style: AppText.figtree(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: check!.issues
                                ? AppColors.redFg
                                : AppColors.greenFg,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      check!.note,
                      style: AppText.figtree(
                        size: 12,
                        weight: FontWeight.w400,
                        color: AppColors.fgSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Not checked yet',
                  style: AppText.figtree(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: AppColors.fgMuted,
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.child,
    this.right,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15.sp, color: AppColors.fgTertiary),
            SizedBox(width: 7.w),
            Text(
              label.toUpperCase(),
              style: AppText.figtree(
                size: 11,
                weight: FontWeight.w700,
                color: AppColors.fgSecondary,
                letterSpacing: 1.0,
              ),
            ),
            if (right != null) ...[
              const Spacer(),
              right!,
            ],
          ],
        ),
        SizedBox(height: 8.h),
        child,
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Icon(icon, size: 18.sp, color: AppColors.fgSecondary),
      ),
    );
  }
}

class _PaymentPill extends StatelessWidget {
  const _PaymentPill({required this.payment});

  final PaymentStatus payment;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (payment) {
      case PaymentStatus.paid:
        bg = AppColors.greenBg;
        fg = AppColors.greenFg;
      case PaymentStatus.refunded:
        bg = AppColors.redBg;
        fg = AppColors.redFg;
      case PaymentStatus.pending:
        bg = AppColors.amberBg;
        fg = AppColors.amberFg;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.r,
            height: 6.r,
            decoration: BoxDecoration(shape: BoxShape.circle, color: fg),
          ),
          SizedBox(width: 6.w),
          Text(
            payment.label,
            style: AppText.figtree(
              size: 12.5,
              weight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterBtn extends StatelessWidget {
  const _FooterBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color bg = !enabled
        ? AppColors.bgPage
        : danger
            ? AppColors.redBg
            : AppColors.bgPage;
    final Color fg = !enabled
        ? AppColors.fgMuted
        : danger
            ? AppColors.redFg
            : AppColors.fgPrimary;

    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19.sp, color: fg),
              SizedBox(height: 3.h),
              Text(
                label,
                style: AppText.figtree(
                  size: 11.5,
                  weight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends ConsumerStatefulWidget {
  const _MenuButton({
    required this.open,
    required this.onToggle,
    required this.onShare,
    required this.onCopyId,
    required this.onAddNote,
  });

  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onShare;
  final VoidCallback onCopyId;
  final VoidCallback onAddNote;

  @override
  ConsumerState<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends ConsumerState<_MenuButton> {
  OverlayEntry? _menuOverlay;
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void didUpdateWidget(_MenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle menu opening/closing with overlay
    if (widget.open && !oldWidget.open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showMenuOverlay();
        }
      });
    } else if (!widget.open && oldWidget.open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _hideMenuOverlay();
        }
      });
    }
  }

  void _showMenuOverlay() {
    // Get button position for menu positioning
    final RenderBox? renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _menuOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent backdrop to close menu when tapped outside
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onToggle,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // Menu positioned at button location
          Positioned(
            right: MediaQuery.of(context).size.width - (offset.dx + size.width),
            top: offset.dy + size.height + 6.h,
            child: Material(
              color: Colors.transparent,
              elevation: 24,
              child: Container(
                width: 190.w,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.borderSoft),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x40000000),
                      offset: Offset(0, 10.h),
                      blurRadius: 30.r,
                      spreadRadius: -6.r,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MenuItem(
                      label: 'Share booking',
                      icon: AppIcons.share,
                      first: true,
                      onTap: widget.onShare,
                    ),
                    _MenuItem(
                      label: 'Copy booking ID',
                      icon: AppIcons.copy,
                      onTap: widget.onCopyId,
                    ),
                    _MenuItem(
                      label: 'Add note',
                      icon: AppIcons.note,
                      onTap: widget.onAddNote,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_menuOverlay!);
  }

  void _hideMenuOverlay() {
    _menuOverlay?.remove();
    _menuOverlay = null;
  }

  @override
  void dispose() {
    _hideMenuOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: Container(
        key: _buttonKey,
        width: 36.r,
        height: 36.r,
        alignment: Alignment.center,
        child: Icon(
          AppIcons.more,
          size: 22.sp,
          color: AppColors.fgSecondary,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.first = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: !first
              ? const Border(
                  top: BorderSide(color: AppColors.borderSoft),
                )
              : null,
        ),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        child: Row(
          children: [
            Icon(icon, size: 17.sp, color: AppColors.fgSecondary),
            SizedBox(width: 11.w),
            Text(
              label,
              style: AppText.figtree(size: 13.5, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalBtn extends StatelessWidget {
  const _ModalBtn({
    required this.label,
    required this.onTap,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: secondary ? AppColors.bgCard : AppColors.brandYellow,
          borderRadius: BorderRadius.circular(12.r),
          border: secondary
              ? Border.all(color: AppColors.borderDefault)
              : Border.all(color: AppColors.brandYellowDeep),
        ),
        child: Text(
          label,
          style: AppText.figtree(size: 15, weight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Carwash Assign Driver Body ──────────────────────────────────────────

class _CarwashAssignDriverBody extends ConsumerStatefulWidget {
  const _CarwashAssignDriverBody({
    required this.bookingId,
    required this.ref,
  });

  final int bookingId;
  final WidgetRef ref;

  @override
  ConsumerState<_CarwashAssignDriverBody> createState() =>
      _CarwashAssignDriverBodyState();
}

class _CarwashAssignDriverBodyState
    extends ConsumerState<_CarwashAssignDriverBody> {
  @override
  void initState() {
    super.initState();
    // Delay API call to avoid concurrent requests on app startup
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.invalidate(assignableDriversProvider(widget.bookingId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(assignableDriversProvider(widget.bookingId));

    return driversAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
      error: (_, __) => Center(
        child: Text('Failed to load drivers'),
      ),
      data: (response) {
        if (response.items.isEmpty) {
          return Center(
            child: Text('No drivers available'),
          );
        }

        return Column(
          children: [
            for (final driver in response.items)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: GestureDetector(
                  onTap: (driver.available ?? false)
                      ? () async {
                          try {
                            await ref
                                .read(bookingsRepositoryProvider)
                                .assignDriver(widget.bookingId, driver.id);
                            if (context.mounted) {
                              AppToast.show(
                                context,
                                'Assigned to ${driver.name}',
                              );
                              // Invalidate both the detail provider and the
                              // list so the new assignee shows immediately.
                              ref.invalidate(bookingByIdProvider(
                                  widget.bookingId.toString()));
                              ref.invalidate(bookingsProvider);
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AppToast.show(context, e.toString());
                            }
                          }
                        }
                      : null,
                  child: Container(
                    padding: EdgeInsets.all(13.r),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(13.r),
                      border: Border.all(
                        color: AppColors.borderSoft,
                      ),
                    ),
                    child: Row(
                      children: [
                        Opacity(
                          opacity: (driver.available ?? false) ? 1.0 : 0.45,
                          child: Avatar(name: driver.name, size: 40),
                        ),
                        SizedBox(width: 13.w),
                        Expanded(
                          child: Opacity(
                            opacity: (driver.available ?? false) ? 1.0 : 0.45,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      driver.name,
                                      style: AppText.figtree(
                                        size: 14.5,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    if (!(driver.available ?? false)) ...[
                                      SizedBox(width: 8.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 7.w,
                                          vertical: 2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.redBg,
                                          borderRadius:
                                              BorderRadius.circular(99.r),
                                        ),
                                        child: Text(
                                          'Busy',
                                          style: AppText.figtree(
                                            size: 10.5,
                                            weight: FontWeight.w600,
                                            color: AppColors.redFg,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${driver.title ?? 'Driver'} · ${driver.phone ?? 'N/A'}',
                                  style: AppText.figtree(
                                    size: 12,
                                    weight: FontWeight.w500,
                                    color: AppColors.fgTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

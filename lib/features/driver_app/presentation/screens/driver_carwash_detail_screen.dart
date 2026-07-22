import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../application/providers/carwash_provider.dart';
import '../../application/providers/schedule_provider.dart';
import '../../application/states/carwash_state.dart';
import '../../domain/entities/carwash_booking.dart' show WashingStatusStep;

/// Carwash job detail screen with washing status progression.
class DriverCarwashDetailScreen extends ConsumerStatefulWidget {
  const DriverCarwashDetailScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<DriverCarwashDetailScreen> createState() =>
      _DriverCarwashDetailScreenState();
}

class _DriverCarwashDetailScreenState extends ConsumerState<DriverCarwashDetailScreen> {
  bool _initialized = false;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _initialized = false;
  }

  Future<void> _loadBooking() async {
    if (!mounted) return;
    try {
      // Load booking with summary fallback for completed jobs
      await ref.read(carwashStateProvider(widget.bookingId).notifier)
          .loadBookingWithSummaryFallback();

      // If booking is completed, also load summary for the UI
      final state = ref.read(carwashStateProvider(widget.bookingId));
      if (state is CarwashSuccess && state.booking.washingStatus == 'completed') {
        await _loadSummary();
      }
    } catch (e) {
      debugPrint('Error loading carwash: $e');
    }
  }

  Future<void> _loadSummary() async {
    if (!mounted) return;
    try {
      final summaryData = await ref
          .read(carwashStateProvider(widget.bookingId).notifier)
          .loadSummary();
      if (mounted) {
        setState(() {
          _summary = summaryData;
        });
      }
    } catch (e) {
      // Summary loading failed, but that's ok - we'll use booking data
      debugPrint('Error loading summary: $e');
    }
  }

  Future<void> _advanceWashingStatus() async {
    final state = ref.read(carwashStateProvider(widget.bookingId));
    if (state is! CarwashSuccess) return;

    final nextStatus = WashingStatusStep.nextStatus(state.booking.washingStatus);
    if (nextStatus == null) return;

    try {
      await ref
          .read(carwashStateProvider(widget.bookingId).notifier)
          .advanceWashingStatus(nextStatus);
      if (mounted) {
        AppToast.show(context, 'Status updated');
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        AppToast.show(context, errorMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize data only once on first build
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBooking();
      });
    }

    final carwashState = ref.watch(carwashStateProvider(widget.bookingId));

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: carwashState.when(
          initial: () => _buildLoading(),
          loading: () => _buildLoading(),
          success: (booking) => _buildContent(context, booking),
          error: (error) => _buildError(context, error.message),
        ),
      ),
    );
  }

  void _handleBack() {
    // Refresh schedule when returning from detail screen
    ref.invalidate(scheduleStateProvider);
    Navigator.of(context).pop();
  }

  Future<void> _launchPhone(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint('Could not launch phone: $e');
    }
  }

  Future<void> _launchMaps(double latitude, double longitude) async {
    if (latitude == 0 && longitude == 0) return;
    final Uri launchUri = Uri(
      scheme: 'geo',
      path: '$latitude,$longitude',
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint('Could not launch maps: $e');
    }
  }

  Widget _buildLoading() {
    return Column(
      children: [
        TopBar(title: 'Carwash', onBack: _handleBack),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(16.r),
            itemCount: 3,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (_, __) => const SkeletonCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Column(
      children: [
        TopBar(title: 'Carwash', onBack: _handleBack),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.alert, size: 48.sp, color: AppColors.danger),
                SizedBox(height: 16.h),
                Text(
                  'Could not load carwash',
                  style: AppText.figtree(size: 16, weight: FontWeight.w600),
                ),
                SizedBox(height: 8.h),
                Text(
                  message,
                  style: AppText.figtree(size: 14, color: AppColors.fgMuted),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                AppButton(
                  label: 'Retry',
                  onPressed: _loadBooking,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, CarwashSuccess state) {
    final booking = state.booking;
    final isCompleted = booking.washingStatus == 'completed';

    return Column(
      children: [
        TopBar(
          title: 'Carwash',
          subtitle: '${booking.appointmentDate} · ${booking.washingStatus.toUpperCase()}',
          onBack: _handleBack,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadBooking,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
              children: [
                // Customer info card - Match driver hire design
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.customerName,
                                  style: AppText.figtree(size: 16, weight: FontWeight.w700),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  booking.vehicleText,
                                  style: AppText.figtree(
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: AppColors.fgSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Call button
                              GestureDetector(
                                onTap: () => _launchPhone(booking.customerPhone),
                                child: Container(
                                  padding: EdgeInsets.all(10.r),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgPage,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    AppIcons.phone,
                                    size: 18.sp,
                                    color: AppColors.fgPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              // Location button
                              GestureDetector(
                                onTap: () => _launchMaps(0, 0),
                                child: Container(
                                  padding: EdgeInsets.all(10.r),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandYellow,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    AppIcons.nav,
                                    size: 18.sp,
                                    color: AppColors.fgPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
  
                // Location details card
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            AppIcons.cal,
                            size: 16.sp,
                            color: AppColors.brandYellow,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SERVICE LOCATION',
                                  style: AppText.figtree(
                                    size: 11,
                                    weight: FontWeight.w500,
                                    color: AppColors.fgSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  booking.address.isNotEmpty
                                      ? booking.address
                                      : 'Shop Location',
                                  style: AppText.figtree(
                                    size: 13,
                                    weight: FontWeight.w600,
                                    color: AppColors.fgPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
  
                // Show different content based on completion status
                if (!isCompleted) ...[
                  // In Progress: Show washing status flow
                  _WashingStatusFlow(
                    currentStatus: booking.washingStatus,
                  ),
                  SizedBox(height: 16.h),
  
                  // Amount card for in-progress
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount',
                          style: AppText.figtree(
                            size: 14,
                            weight: FontWeight.w500,
                            color: AppColors.fgSecondary,
                          ),
                        ),
                        Text(
                          Formatters.money(
                            (double.tryParse(booking.amount) ?? 0).toInt(),
                          ),
                          style: AppText.figtree(size: 16, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
  
                  // Action button for in-progress jobs
                  AppButton(
                    label: 'Advance Status',
                    full: true,
                    disabled: state.isUpdating,
                    onPressed: _advanceWashingStatus,
                  ),
                ] else ...[
                  // Completed: Show status and payout
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppIcons.checkCircle,
                          size: 20.sp,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STATUS',
                                style: AppText.figtree(
                                  size: 11,
                                  weight: FontWeight.w500,
                                  color: AppColors.fgSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Completed',
                                style: AppText.figtree(
                                  size: 16,
                                  weight: FontWeight.w700,
                                  color: AppColors.fgPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'YOUR PAYOUT',
                              style: AppText.figtree(
                                size: 11,
                                weight: FontWeight.w500,
                                color: AppColors.fgSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              Formatters.money(
                                (double.tryParse(booking.amount) ?? 0).toInt(),
                              ),
                              style: AppText.figtree(
                                size: 16,
                                weight: FontWeight.w700,
                                color: AppColors.fgPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
  
                  // Completed: Show summary view
                  _buildCompletedSummary(booking, _summary),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedSummary(dynamic booking, Map<String, dynamic>? summary) {
    // Use summary data if available, otherwise use booking data
    final baseFare = double.tryParse(summary?['base_fare'].toString() ?? booking.amount) ?? 0;
    final total = double.tryParse(summary?['total'].toString() ?? booking.amount) ?? 0;
    final balanceDue = double.tryParse(summary?['balance_due'].toString() ?? '0.00') ?? 0;

    return Column(
      children: [
        AppCard(
          accent: AppColors.success,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Icon(AppIcons.receipt, size: 16.sp, color: AppColors.fgSecondary),
                  SizedBox(width: 8.w),
                  Text(
                    'Job Summary'.toUpperCase(),
                    style: AppText.figtree(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.fgSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Base fare
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Base fare',
                    style: AppText.figtree(
                      size: 14,
                      weight: FontWeight.w500,
                      color: AppColors.fgSecondary,
                    ),
                  ),
                  Text(
                    Formatters.money(baseFare.toInt()),
                    style: AppText.figtree(size: 14, weight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Total with border separator
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.borderDefault)),
                ),
                padding: EdgeInsets.only(top: 11.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppText.figtree(size: 14, weight: FontWeight.w700),
                    ),
                    Text(
                      Formatters.money(total.toInt()),
                      style: AppText.figtree(size: 18, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),

              // Balance or success message
              if (balanceDue > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.amberBg,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.alert, size: 15.sp, color: AppColors.amberFg),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Collect extra ${Formatters.money(balanceDue.toInt())} from customer',
                          style: AppText.figtree(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: AppColors.amberFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Icon(AppIcons.checkCircle, size: 14.sp, color: AppColors.greenFg),
                    SizedBox(width: 6.w),
                    Text(
                      'Nothing extra to collect',
                      style: AppText.figtree(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AppColors.greenFg,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
      ],
    );
  }
}

// ── Washing Status Flow ──────────────────────────────────────────────────────

class _WashingStatusFlow extends StatelessWidget {
  const _WashingStatusFlow({required this.currentStatus});

  final String currentStatus;

  static const List<String> steps = [
    'Confirmed',
    'Washing',
    'Drying',
    'Quality Check',
    'Payment Collected',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = steps.indexOf(currentStatus.replaceAll('_', ' ').toTitleCase());

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Washing Progress',
            style: AppText.figtree(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 16.h),
          ...List.generate(steps.length, (index) {
            final isCompleted = index < currentIndex;
            final isCurrent = index == currentIndex;

            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.success
                            : isCurrent
                                ? AppColors.brandYellow
                                : AppColors.bgPage,
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.brandYellow
                              : AppColors.borderDefault,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(AppIcons.check, size: 16.sp, color: AppColors.bgCard)
                            : Text(
                                '${index + 1}',
                                style: AppText.figtree(
                                  size: 12,
                                  weight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        steps[index],
                        style: AppText.figtree(
                          size: 14,
                          weight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent ? AppColors.fgPrimary : AppColors.fgMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1)
                  Padding(
                    padding: EdgeInsets.only(left: 15.5.w, top: 4.h, bottom: 4.h),
                    child: Container(
                      width: 2.w,
                      height: 20.h,
                      color: isCompleted ? AppColors.success : AppColors.borderSoft,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

extension on String {
  String toTitleCase() {
    return split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

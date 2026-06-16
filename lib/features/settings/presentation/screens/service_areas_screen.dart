import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../application/providers/settings_providers.dart';
import '../../domain/entities/app_settings.dart';

/// Service Areas sub-screen: Carwash & Hire coverage areas.
///
/// Mirrors `ServiceAreasScreen` in `screen_settings.jsx` (lines 106–154).
/// State is local (mutable copy seeded from settings); in the API phase
/// mutations go through the repository.
class ServiceAreasScreen extends ConsumerStatefulWidget {
  const ServiceAreasScreen({super.key});

  @override
  ConsumerState<ServiceAreasScreen> createState() => _ServiceAreasScreenState();
}

class _ServiceAreasScreenState extends ConsumerState<ServiceAreasScreen> {
  String _seg = 'carwash'; // 'carwash' | 'hire'
  List<ServiceArea>? _carwash;
  List<ServiceArea>? _hire;

  List<ServiceArea> get _currentList => _seg == 'carwash' ? _carwash! : _hire!;

  void _init(AppSettings settings) {
    _carwash ??= List<ServiceArea>.from(settings.serviceAreas.carwash);
    _hire ??= List<ServiceArea>.from(settings.serviceAreas.hire);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(appSettingsProvider);

    final subtitle = _seg == 'carwash'
        ? 'Carwash coverage'
        : 'Driver & Inspection coverage';

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: 'Service Areas',
              subtitle: subtitle,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: async.when(
                loading: () => ListView(
                  padding: EdgeInsets.all(16.r),
                  children: [
                    const SkeletonCard(),
                    SizedBox(height: 12.h),
                    const SkeletonCard(),
                  ],
                ),
                error: (_, __) => const Center(
                  child: Text('Failed to load service areas'),
                ),
                data: (settings) {
                  _init(settings);
                  return Column(
                    children: [
                      _SegmentBar(
                        seg: _seg,
                        onChanged: (v) => setState(() => _seg = v),
                      ),
                      Expanded(
                        child: _AreaList(
                          areas: _currentList,
                          seg: _seg,
                          onEdit: (area) => _openSheet(context, area: area),
                          onAdd: () => _openSheet(context, area: null),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, {required ServiceArea? area}) async {
    await _AreaSheet.show(
      context,
      area: area,
      kind: _seg,
      onSave: (name, pincode, radius) {
        setState(() {
          final list = _currentList;
          if (area != null) {
            final idx = list.indexWhere((a) => a.id == area.id);
            if (idx >= 0) {
              list[idx] = ServiceArea(
                id: area.id,
                name: name,
                pincode: pincode,
                radiusKm: radius,
              );
            }
          } else {
            list.add(ServiceArea(
              id: 'a${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              pincode: pincode,
              radiusKm: radius,
            ));
          }
        });
        AppToast.show(context, area != null ? 'Area updated' : 'Area added');
      },
      onDelete: area != null
          ? () {
              setState(() => _currentList.removeWhere((a) => a.id == area.id));
              AppToast.show(context, 'Area removed');
            }
          : null,
    );
  }
}

// ── Segment bar ───────────────────────────────────────────────────────────────

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.seg, required this.onChanged});

  final String seg;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          _SegBtn(label: 'Carwash', value: 'carwash', current: seg, onTap: onChanged),
          SizedBox(width: 8.w),
          _SegBtn(label: 'Hire', value: 'hire', current: seg, onTap: onChanged),
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  const _SegBtn({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final on = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 9.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.brandYellow : AppColors.bgCard,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: on ? AppColors.brandYellowDeep : AppColors.borderDefault,
            ),
          ),
          child: Text(
            label,
            style: AppText.figtree(
              size: 13,
              weight: on ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Area list ─────────────────────────────────────────────────────────────────

class _AreaList extends StatelessWidget {
  const _AreaList({
    required this.areas,
    required this.seg,
    required this.onEdit,
    required this.onAdd,
  });

  final List<ServiceArea> areas;
  final String seg;
  final void Function(ServiceArea area) onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      children: [
        // Info banner
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.blueBg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: Icon(AppIcons.pin, size: 18.sp, color: AppColors.blueFg),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Customers can only book '
                  '${seg == 'carwash' ? 'carwash' : 'driver / inspection'} '
                  'in these areas. Each area is a name, pincode and a coverage '
                  'radius around a pinned point.',
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
        SizedBox(height: 12.h),

        // Area cards
        for (final area in areas) ...[
          AppCard(
            padding: EdgeInsets.all(14.r),
            child: Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.bgPage,
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(AppIcons.pin, size: 19.sp, color: AppColors.fgSecondary),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        area.name,
                        style: AppText.figtree(size: 14.5, weight: FontWeight.w700),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${area.pincode} · ${area.radiusKm} km radius',
                        style: AppText.figtree(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: AppColors.fgTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => onEdit(area),
                  child: Container(
                    width: 34.r,
                    height: 34.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(9.r),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Icon(AppIcons.edit, size: 16.sp, color: AppColors.fgSecondary),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
        ],

        if (areas.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(
              'No areas yet — add the first.',
              textAlign: TextAlign.center,
              style: AppText.figtree(
                size: 13,
                weight: FontWeight.w500,
                color: AppColors.fgMuted,
              ),
            ),
          ),

        // Add button (dashed border via `CustomPaint` approximated with solid)
        GestureDetector(
          onTap: onAdd,
          child: Container(
            height: 50.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.plus, size: 18.sp, color: AppColors.fgSecondary),
                SizedBox(width: 8.w),
                Text(
                  'Add Area',
                  style: AppText.figtree(
                    size: 14,
                    weight: FontWeight.w700,
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

// ── Area sheet (bottom sheet with internal state) ────────────────────────────

/// Self-contained bottom sheet that owns its form state. Resolves when done.
class _AreaSheet extends StatefulWidget {
  const _AreaSheet({
    this.area,
    required this.kind,
    required this.onSave,
    this.onDelete,
  });

  final ServiceArea? area;
  final String kind;
  final void Function(String name, String pincode, int radius) onSave;
  final VoidCallback? onDelete;

  static Future<void> show(
    BuildContext context, {
    ServiceArea? area,
    required String kind,
    required void Function(String name, String pincode, int radius) onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.bgOverlay,
      builder: (_) => _AreaSheet(
        area: area,
        kind: kind,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<_AreaSheet> createState() => _AreaSheetState();
}

class _AreaSheetState extends State<_AreaSheet> {
  late final TextEditingController _name;
  late final TextEditingController _pincode;
  late double _radius;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.area?.name ?? '');
    _pincode = TextEditingController(text: widget.area?.pincode ?? '');
    _radius = (widget.area?.radiusKm ?? 5).toDouble();
  }

  @override
  void dispose() {
    _name.dispose();
    _pincode.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty && _pincode.text.trim().length >= 4;

  void _save() {
    if (!_valid) return;
    Navigator.of(context).pop();
    widget.onSave(
      _name.text.trim(),
      _pincode.text.trim(),
      _radius.round(),
    );
  }

  Future<void> _delete() async {
    Navigator.of(context).pop();
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Remove this service area?',
      body: "Customers won't be able to book in this area. This can't be undone.",
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed) widget.onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: EdgeInsets.only(top: 10.h, bottom: 2.h),
            child: Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
            ),
          ),
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 12.h),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.area != null ? 'Edit area' : 'Add area',
                    style: AppText.figtree(size: 17, weight: FontWeight.w700),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 30.r,
                    height: 30.r,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.bgPage,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(AppIcons.close, size: 18.sp, color: AppColors.fgSecondary),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20.w,
                16.h,
                20.w,
                16.h + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: _buildBody(),
            ),
          ),
          // Footer
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Row(
              children: [
                if (widget.onDelete != null) ...[
                  Expanded(
                    child: AppButton(
                      label: 'Delete',
                      kind: AppButtonKind.secondary,
                      full: true,
                      onPressed: _delete,
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],
                Expanded(
                  flex: widget.onDelete != null ? 2 : 1,
                  child: ListenableBuilder(
                    listenable: Listenable.merge([_name, _pincode]),
                    builder: (_, __) => AppButton(
                      label: 'Save area',
                      full: true,
                      disabled: !_valid,
                      onPressed: _valid ? _save : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Map placeholder
        GestureDetector(
          onTap: () => AppToast.show(
            context,
            'Google Maps search — pin the service-area center',
          ),
          child: Container(
            width: double.infinity,
            height: 140.h,
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE9EFE7), Color(0xFFDFE6EA)],
              ),
            ),
            child: Stack(
              children: [
                // Grid overlay
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CustomPaint(
                    painter: _GridPainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
                // Search bar placeholder
                Positioned(
                  top: 12.h,
                  left: 12.w,
                  right: 12.w,
                  child: Container(
                    height: 40.h,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x33000000),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(AppIcons.search, size: 16.sp, color: AppColors.fgSecondary),
                        SizedBox(width: 8.w),
                        Text(
                          'Search location on map…',
                          style: AppText.figtree(
                            size: 13,
                            weight: FontWeight.w500,
                            color: AppColors.fgTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Pin icon
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20.h),
                    child: Icon(AppIcons.pin, size: 30.sp, color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Name field
        _FieldLabel('Area / locality name'),
        SizedBox(height: 7.h),
        _FormField(controller: _name, hint: 'e.g. Mullackal'),
        SizedBox(height: 14.h),

        // Pincode + radius row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Pincode'),
                  SizedBox(height: 7.h),
                  _FormField(
                    controller: _pincode,
                    hint: '688011',
                    numeric: true,
                    maxLength: 6,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Radius (km)'),
                  SizedBox(height: 7.h),
                  StatefulBuilder(
                    builder: (_, setLocal) => Container(
                      height: 50.h,
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.brandYellowDeep,
                                thumbColor: AppColors.brandYellowDeep,
                                inactiveTrackColor: AppColors.borderDefault,
                                overlayShape: SliderComponentShape.noOverlay,
                                thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: 8.r,
                                ),
                                trackHeight: 3.h,
                              ),
                              child: Slider(
                                value: _radius,
                                min: 1,
                                max: 20,
                                divisions: 19,
                                onChanged: (v) {
                                  setLocal(() => _radius = v);
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${_radius.round()} km',
                            style: AppText.figtree(
                              size: 13.5,
                              weight: FontWeight.w700,
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
        SizedBox(height: 10.h),

        Text(
          'Applies to ${widget.kind == 'carwash' ? 'Carwash' : 'Hire (Driver & Inspection)'} bookings.',
          style: AppText.figtree(
            size: 11.5,
            weight: FontWeight.w500,
            color: AppColors.fgMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ── Local helpers ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppText.figtree(
        size: 12.5,
        weight: FontWeight.w600,
        color: AppColors.fgSecondary,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.hint,
    this.numeric = false,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hint;
  final bool numeric;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: TextField(
        controller: controller,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        maxLength: maxLength,
        style: AppText.figtree(size: 14, weight: FontWeight.w500),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
          isDense: true,
          counterText: '',
          hintText: hint,
          hintStyle: AppText.figtree(
            size: 14,
            weight: FontWeight.w400,
            color: AppColors.fgMuted,
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0A000000)
      ..strokeWidth = 1;
    const step = 22.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

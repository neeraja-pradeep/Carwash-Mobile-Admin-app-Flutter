import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../domain/entities/offer_banner.dart';
import 'form_helpers.dart';

/// Add / Edit banner form — pushed intra-module via Navigator.
class BannerFormScreen extends StatefulWidget {
  const BannerFormScreen({this.banner, super.key});

  /// Null when creating a new banner.
  final OfferBanner? banner;

  @override
  State<BannerFormScreen> createState() => _BannerFormScreenState();
}

class _BannerFormScreenState extends State<BannerFormScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _orderCtrl;
  late String _placement;
  late bool _active;

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _subtitleCtrl = TextEditingController(text: b?.subtitle ?? '');
    _linkCtrl = TextEditingController(text: b?.link ?? '');
    _orderCtrl = TextEditingController(text: b != null ? '${b.order}' : '1');
    _placement =
        (b != null && b.placement.contains('Strip')) ? 'strip' : 'hero';
    _active = b?.status == 'active';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _linkCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _titleCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.banner != null;
    final b = widget.banner;
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: isEdit ? 'Edit Banner' : 'Add Banner',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  OfferFCard(
                    label: 'Image',
                    children: [
                      GestureDetector(
                        onTap: () => AppToast.show(
                            context, 'Upload banner image (16:9)'),
                        child: Container(
                          width: double.infinity,
                          height: 130.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            border: b == null
                                ? Border.all(
                                    color: AppColors.borderDefault,
                                  )
                                : null,
                            color: b == null
                                ? AppColors.bgCard
                                : AppColors.fgPrimary.withOpacity(0.1),
                            image: b != null
                                ? DecorationImage(
                                    image: AssetImage(b.image),
                                    fit: BoxFit.cover,
                                    onError: (_, __) {},
                                  )
                                : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (b != null)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    color: const Color(0x4D000000),
                                  ),
                                ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    AppIcons.plus,
                                    size: 24.sp,
                                    color: b != null
                                        ? AppColors.fgOnDark
                                        : AppColors.fgTertiary,
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    b != null
                                        ? 'Replace image'
                                        : 'Upload image · 16:9',
                                    style: AppText.figtree(
                                      size: 12.5,
                                      weight: FontWeight.w600,
                                      color: b != null
                                          ? AppColors.fgOnDark
                                          : AppColors.fgTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  OfferFCard(
                    label: 'Content',
                    children: [
                      OfferFInput(
                        label: 'Title',
                        controller: _titleCtrl,
                        placeholder: 'e.g. Up to 40% Off',
                        onChanged: (_) => setState(() {}),
                      ),
                      SizedBox(height: 14.h),
                      OfferFInput(
                        label: 'Subtitle',
                        controller: _subtitleCtrl,
                        placeholder: 'Short supporting line',
                        optional: true,
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  OfferFCard(
                    label: 'Placement & Link',
                    children: [
                      Text(
                        'Placement',
                        style: AppText.figtree(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: AppColors.fgSecondary,
                        ),
                      ),
                      SizedBox(height: 9.h),
                      OfferSegControl(
                        value: _placement,
                        options: const [
                          ('hero', 'Home — Hero'),
                          ('strip', 'Home — Strip'),
                        ],
                        onChanged: (v) => setState(() => _placement = v),
                      ),
                      SizedBox(height: 14.h),
                      OfferFInput(
                        label: 'Links to',
                        controller: _linkCtrl,
                        placeholder: 'Coupon, service, or screen',
                        optional: true,
                      ),
                      SizedBox(height: 14.h),
                      OfferFInput(
                        label: 'Display order',
                        controller: _orderCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active',
                                style: AppText.figtree(
                                  size: 13.5,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                _active ? 'Visible in app' : 'Hidden',
                                style: AppText.figtree(
                                  size: 12,
                                  color: AppColors.fgTertiary,
                                ),
                              ),
                            ],
                          ),
                          OfferToggle(
                            on: _active,
                            onTap: () => setState(() => _active = !_active),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            border: Border(top: BorderSide(color: AppColors.borderSoft)),
          ),
          child: AppButton(
            label: isEdit ? 'Save Changes' : 'Create Banner',
            full: true,
            disabled: !_valid,
            onPressed: _valid
                ? () {
                    AppToast.show(
                      context,
                      isEdit ? 'Banner saved' : 'Banner created',
                    );
                    Navigator.of(context).pop();
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

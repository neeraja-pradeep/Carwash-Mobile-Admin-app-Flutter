import 'package:flutter/material.dart';

/// Semantic icon set for the app (mirrors the Lucide-style set in `icons.jsx`).
///
/// Mapped onto built-in Material glyphs (outlined/rounded variants to match the
/// thin stroke style) behind a stable indirection, so the whole set can be
/// re-pointed at a Lucide font later without touching call sites.
class AppIcons {
  const AppIcons._();

  static const IconData back = Icons.chevron_left;
  static const IconData chevDown = Icons.keyboard_arrow_down_rounded;
  static const IconData chevRight = Icons.chevron_right;
  static const IconData chevUp = Icons.keyboard_arrow_up_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData sliders = Icons.tune_rounded;
  static const IconData logout = Icons.logout_rounded;
  static const IconData plus = Icons.add_rounded;
  static const IconData bell = Icons.notifications_none_rounded;
  static const IconData phone = Icons.call_outlined;
  static const IconData nav = Icons.navigation_rounded;
  static const IconData pin = Icons.location_on_outlined;
  static const IconData star = Icons.star_rounded;
  static const IconData starOutline = Icons.star_border_rounded;
  static const IconData more = Icons.more_vert_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData checkCircle = Icons.check_circle_outline_rounded;
  static const IconData alert = Icons.warning_amber_rounded;
  static const IconData clock = Icons.schedule_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData car = Icons.directions_car_outlined;
  static const IconData home = Icons.home_outlined;
  static const IconData cal = Icons.calendar_today_rounded;
  static const IconData store = Icons.storefront_outlined;
  static const IconData users = Icons.people_alt_outlined;
  static const IconData droplet = Icons.water_drop_outlined;
  static const IconData receipt = Icons.receipt_long_outlined;
  static const IconData rupee = Icons.currency_rupee_rounded;
  static const IconData wallet = Icons.account_balance_wallet_outlined;
  static const IconData tag = Icons.local_offer_outlined;
  static const IconData chart = Icons.bar_chart_rounded;
  static const IconData message = Icons.chat_bubble_outline_rounded;
  static const IconData gear = Icons.settings_outlined;
  static const IconData edit = Icons.edit_outlined;
  static const IconData note = Icons.sticky_note_2_outlined;
  static const IconData inbox = Icons.inbox_outlined;
  static const IconData play = Icons.play_arrow_rounded;
  static const IconData copy = Icons.content_copy_rounded;
  static const IconData share = Icons.ios_share_rounded;
  static const IconData download = Icons.file_download_outlined;
  static const IconData sort = Icons.swap_vert_rounded;
  static const IconData arrowRight = Icons.arrow_forward_rounded;
  static const IconData cloudOff = Icons.cloud_off_outlined;
  static const IconData dot = Icons.circle;
  static const IconData mail = Icons.mail_outline_rounded;
  static const IconData calendar = Icons.calendar_month_outlined;
  static const IconData doc = Icons.description_outlined;
  static const IconData shield = Icons.verified_user_outlined;
  static const IconData upload = Icons.upload_file_outlined;
  static const IconData trash = Icons.delete_outline_rounded;
  static const IconData power = Icons.power_settings_new_rounded;
}

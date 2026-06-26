import 'package:flutter/foundation.dart';

import '../../domain/entities/app_settings.dart';
import 'json_helpers.dart';

/// `OrgInfo` singleton from GET /api/accounts/v1/org-info/ (`OrgInfoSerializer`).
///
/// Feeds the Settings screen's [BusinessInfo] (support contact) and
/// [DefaultCommission] rows.
class OrgInfoModel {
  final String legalName;
  final String? gstin;
  final String? registeredAddress;
  final String? supportEmail;
  final String? supportPhone;
  final String? supportHours;
  final int cancellationWindowMinutes;
  final int cancellationFeePercent;
  final String? refundEtaDays;
  final int defaultCommissionPercent;

  OrgInfoModel({
    required this.legalName,
    this.gstin,
    this.registeredAddress,
    this.supportEmail,
    this.supportPhone,
    this.supportHours,
    required this.cancellationWindowMinutes,
    required this.cancellationFeePercent,
    this.refundEtaDays,
    required this.defaultCommissionPercent,
  });

  factory OrgInfoModel.fromJson(Map<String, dynamic> json) {
    try {
      return OrgInfoModel(
        legalName: asString(json['legal_name']),
        gstin: asStringOrNull(json['gstin']),
        registeredAddress: asStringOrNull(json['registered_address']),
        supportEmail: asStringOrNull(json['support_email']),
        supportPhone: asStringOrNull(json['support_phone']),
        supportHours: asStringOrNull(json['support_hours']),
        cancellationWindowMinutes: asInt(json['cancellation_window_minutes']),
        cancellationFeePercent: asInt(json['cancellation_fee_percent']),
        refundEtaDays: asStringOrNull(json['refund_eta_days']),
        defaultCommissionPercent: asInt(json['default_commission_percent']),
      );
    } catch (e) {
      debugPrint('Error parsing OrgInfoModel: $e');
      rethrow;
    }
  }

  BusinessInfo toBusinessInfo() {
    return BusinessInfo(
      name: legalName,
      city: registeredAddress ?? '',
      gstin: gstin ?? '',
      support: supportPhone ?? '',
      email: supportEmail ?? '',
    );
  }

  DefaultCommission toDefaultCommission() {
    return DefaultCommission(mode: 'percentage', pct: defaultCommissionPercent);
  }
}

/// Builds the PATCH /org-info/ payload (`OrgSettingsSerializer`).
///
/// All fields optional — only the changed ones are sent. Percentages go as
/// decimal strings to match the serializer.
Map<String, dynamic> buildOrgInfoPayload({
  String? legalName,
  String? gstin,
  String? registeredAddress,
  String? supportEmail,
  String? supportPhone,
  String? supportHours,
  int? defaultCommissionPercent,
}) {
  return {
    if (legalName != null) 'legal_name': legalName,
    if (gstin != null) 'gstin': gstin,
    if (registeredAddress != null) 'registered_address': registeredAddress,
    if (supportEmail != null) 'support_email': supportEmail,
    if (supportPhone != null) 'support_phone': supportPhone,
    if (supportHours != null) 'support_hours': supportHours,
    if (defaultCommissionPercent != null)
      'default_commission_percent': defaultCommissionPercent.toString(),
  };
}

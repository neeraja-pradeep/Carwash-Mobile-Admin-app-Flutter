class JobDetail {
  final String id;
  final String reference;
  final String requestType;
  final String customerName;
  final String customerPhone;
  final String? carLabel;
  final String vehicleText;
  final String appointmentDate;
  final String startTime;
  final String durationLabel;
  final String addressText;
  final String? dropAddressText;
  final double? dropLatitude;
  final double? dropLongitude;
  final String estimatedFee;
  final String quotedFee;
  final String status;

  /// Upfront booking payment.
  final bool isPaid;
  final String? paidAt;

  /// Post-job settlement — `balancePaid` answers "has the customer paid the
  /// final amount", which is separate from the upfront [isPaid].
  final String additionalCharges;
  final String finalTotal;
  final String balanceDue;
  final bool balancePaid;
  final String? balancePaidAt;
  final int? actualHours;

  final String? startOtpVerifiedAt;
  final String? endOtpVerifiedAt;

  JobDetail({
    required this.id,
    required this.reference,
    required this.requestType,
    required this.customerName,
    required this.customerPhone,
    this.carLabel,
    required this.vehicleText,
    required this.appointmentDate,
    required this.startTime,
    required this.durationLabel,
    required this.addressText,
    this.dropAddressText,
    this.dropLatitude,
    this.dropLongitude,
    required this.estimatedFee,
    required this.quotedFee,
    required this.isPaid,
    this.paidAt,
    required this.status,
    required this.additionalCharges,
    required this.finalTotal,
    required this.balanceDue,
    this.balancePaid = false,
    this.balancePaidAt,
    this.actualHours,
    this.startOtpVerifiedAt,
    this.endOtpVerifiedAt,
  });

  /// Returns a copy with the payment/settlement fields replaced, keeping
  /// everything else. Used after collect-cash, which answers with only this
  /// slice of the job rather than the full payload.
  JobDetail copyWithSettlement({
    String? status,
    bool? isPaid,
    String? balanceDue,
    bool? balancePaid,
    String? balancePaidAt,
  }) {
    return JobDetail(
      id: id,
      reference: reference,
      requestType: requestType,
      customerName: customerName,
      customerPhone: customerPhone,
      carLabel: carLabel,
      vehicleText: vehicleText,
      appointmentDate: appointmentDate,
      startTime: startTime,
      durationLabel: durationLabel,
      addressText: addressText,
      dropAddressText: dropAddressText,
      dropLatitude: dropLatitude,
      dropLongitude: dropLongitude,
      estimatedFee: estimatedFee,
      quotedFee: quotedFee,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt,
      status: status ?? this.status,
      additionalCharges: additionalCharges,
      finalTotal: finalTotal,
      balanceDue: balanceDue ?? this.balanceDue,
      balancePaid: balancePaid ?? this.balancePaid,
      balancePaidAt: balancePaidAt ?? this.balancePaidAt,
      actualHours: actualHours,
      startOtpVerifiedAt: startOtpVerifiedAt,
      endOtpVerifiedAt: endOtpVerifiedAt,
    );
  }
}

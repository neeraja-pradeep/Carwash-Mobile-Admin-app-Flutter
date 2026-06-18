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
  final bool isPaid;
  final String status;
  final String additionalCharges;
  final String finalTotal;
  final String balanceDue;
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
    required this.status,
    required this.additionalCharges,
    required this.finalTotal,
    required this.balanceDue,
    this.startOtpVerifiedAt,
    this.endOtpVerifiedAt,
  });
}

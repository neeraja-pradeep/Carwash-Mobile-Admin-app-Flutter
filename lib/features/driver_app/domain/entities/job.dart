class Job {
  final int id;
  final String source;
  final String kind;
  final String label;
  final bool started;
  final String reference;
  final String status;
  final String? washingStatus;
  final String appointmentDate;
  final String startTime;
  final String customerName;
  final String customerPhone;
  final String vehicle;
  final String pickupAddress;
  final String dropAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String payout;
  final bool isPaid;
  final String? balanceDue;

  Job({
    required this.id,
    required this.source,
    required this.kind,
    required this.label,
    required this.started,
    required this.reference,
    required this.status,
    this.washingStatus,
    required this.appointmentDate,
    required this.startTime,
    required this.customerName,
    required this.customerPhone,
    required this.vehicle,
    required this.pickupAddress,
    required this.dropAddress,
    this.pickupLat,
    this.pickupLng,
    required this.payout,
    required this.isPaid,
    this.balanceDue,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      source: json['source'],
      kind: json['kind'],
      label: json['label'],
      started: json['started'] ?? false,
      reference: json['reference'],
      status: json['status'],
      washingStatus: json['washing_status'],
      appointmentDate: json['appointment_date'],
      startTime: json['start_time'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      vehicle: json['vehicle'],
      pickupAddress: json['pickup_address'],
      dropAddress: json['drop_address'],
      pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
      pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
      payout: json['payout'],
      isPaid: json['is_paid'] ?? false,
      balanceDue: json['balance_due'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'kind': kind,
    'label': label,
    'started': started,
    'reference': reference,
    'status': status,
    'washing_status': washingStatus,
    'appointment_date': appointmentDate,
    'start_time': startTime,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'vehicle': vehicle,
    'pickup_address': pickupAddress,
    'drop_address': dropAddress,
    'pickup_lat': pickupLat,
    'pickup_lng': pickupLng,
    'payout': payout,
    'is_paid': isPaid,
    'balance_due': balanceDue,
  };
}

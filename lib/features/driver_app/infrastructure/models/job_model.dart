import '../../domain/entities/job.dart';

class JobModel extends Job {
  JobModel({
    required super.id,
    required super.source,
    required super.kind,
    required super.label,
    required super.started,
    required super.reference,
    required super.status,
    super.washingStatus,
    required super.appointmentDate,
    required super.startTime,
    required super.customerName,
    required super.customerPhone,
    required super.vehicle,
    required super.pickupAddress,
    required super.dropAddress,
    required super.payout,
    required super.isPaid,
    super.balanceDue,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
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
      payout: json['payout'],
      isPaid: json['is_paid'] ?? false,
      balanceDue: json['balance_due'],
    );
  }

  Job toEntity() => Job(
    id: id,
    source: source,
    kind: kind,
    label: label,
    started: started,
    reference: reference,
    status: status,
    washingStatus: washingStatus,
    appointmentDate: appointmentDate,
    startTime: startTime,
    customerName: customerName,
    customerPhone: customerPhone,
    vehicle: vehicle,
    pickupAddress: pickupAddress,
    dropAddress: dropAddress,
    payout: payout,
    isPaid: isPaid,
    balanceDue: balanceDue,
  );
}

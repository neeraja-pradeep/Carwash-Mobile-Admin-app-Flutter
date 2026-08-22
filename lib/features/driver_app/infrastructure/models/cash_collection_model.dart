import '../../domain/entities/cash_collection.dart';

class CashCollectionModel extends CashCollection {
  const CashCollectionModel({
    required super.id,
    required super.reference,
    required super.status,
    required super.isPaid,
    required super.balanceDue,
    required super.balancePaid,
    super.balancePaidAt,
  });

  factory CashCollectionModel.fromJson(Map<String, dynamic> json) {
    return CashCollectionModel(
      id: json['id'].toString(),
      reference: (json['reference'] ?? '').toString(),
      status: json['status'] ?? 'completed',
      isPaid: json['is_paid'] ?? false,
      balanceDue: (json['balance_due'] ?? '0').toString(),
      balancePaid: json['balance_paid'] ?? false,
      balancePaidAt: json['balance_paid_at'],
    );
  }

  CashCollection toEntity() => CashCollection(
        id: id,
        reference: reference,
        status: status,
        isPaid: isPaid,
        balanceDue: balanceDue,
        balancePaid: balancePaid,
        balancePaidAt: balancePaidAt,
      );
}

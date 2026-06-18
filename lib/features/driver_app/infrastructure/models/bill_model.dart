import '../../domain/entities/bill.dart';

class BillModel extends Bill {
  BillModel({
    required super.advancePaid,
    required super.additionalCharges,
    required super.finalTotal,
    required super.balanceDue,
    required super.balancePaid,
    super.actualHours,
    super.committedHours,
    required super.breakdown,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    final breakdownList = (json['breakdown'] as List<dynamic>?)
            ?.map((item) => BillLineItemModel.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return BillModel(
      advancePaid: json['advance_paid'].toString(),
      additionalCharges: json['additional_charges'].toString(),
      finalTotal: json['final_total'].toString(),
      balanceDue: json['balance_due'].toString(),
      balancePaid: json['balance_paid'] ?? false,
      actualHours: json['actual_hours']?.toString(),
      committedHours: json['committed_hours']?.toString(),
      breakdown: breakdownList,
    );
  }

  Bill toEntity() => Bill(
    advancePaid: advancePaid,
    additionalCharges: additionalCharges,
    finalTotal: finalTotal,
    balanceDue: balanceDue,
    balancePaid: balancePaid,
    actualHours: actualHours,
    committedHours: committedHours,
    breakdown: breakdown,
  );
}

class BillLineItemModel extends BillLineItem {
  BillLineItemModel({required super.label, required super.amount});

  factory BillLineItemModel.fromJson(Map<String, dynamic> json) {
    return BillLineItemModel(
      label: json['label'],
      amount: json['amount'].toString(),
    );
  }
}

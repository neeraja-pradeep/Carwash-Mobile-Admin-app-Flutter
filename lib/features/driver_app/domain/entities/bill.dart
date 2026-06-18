class Bill {
  final String advancePaid;
  final String additionalCharges;
  final String finalTotal;
  final String balanceDue;
  final bool balancePaid;
  final String? actualHours;
  final String? committedHours;
  final List<BillLineItem> breakdown;

  Bill({
    required this.advancePaid,
    required this.additionalCharges,
    required this.finalTotal,
    required this.balanceDue,
    required this.balancePaid,
    this.actualHours,
    this.committedHours,
    required this.breakdown,
  });
}

class BillLineItem {
  final String label;
  final String amount;

  BillLineItem({required this.label, required this.amount});
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import '../../domain/repositories/payouts_repository.dart';

/// Payout detail screen — displays full payout details from the log.
/// The API returns all detail data in the log list, so no separate endpoint is needed.
class PayoutDetailScreen extends StatelessWidget {
  const PayoutDetailScreen({required this.payout, super.key});

  final PayoutLogItem payout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              title: 'Payout Detail',
              subtitle: payout.reference,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    _buildBreakdownCard(),
                    const SizedBox(height: 24),
                    _buildDetailsCard(),
                    if (payout.items.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildItemsCard(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.borderSoft),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payout', style: TextStyle(fontSize: 14, color: AppColors.fgTertiary)),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '₹${payout.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.fgPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shop', style: TextStyle(fontSize: 12, color: AppColors.fgTertiary)),
                    Text(payout.shopName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Bookings', style: TextStyle(fontSize: 12, color: AppColors.fgTertiary)),
                    Text('${payout.bookingCount}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isPaid = payout.status.toLowerCase() == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade100 : Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        payout.status.replaceFirst(payout.status[0], payout.status[0].toUpperCase()),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }

  Widget _buildBreakdownCard() {
    final gross = payout.grossAmount;
    final commission = payout.commissionAmount;
    final refunds = payout.refundsTotal;
    final adjustments = payout.otherAdjustments;
    final total = payout.totalAmount;

    return Card(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.borderSoft),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _buildBreakdownRow('Gross Amount', gross),
            _buildBreakdownRow('Commission', -commission, isNegative: true),
            if (refunds > 0) _buildBreakdownRow('Refunds', -refunds, isNegative: true),
            if (adjustments != 0) _buildBreakdownRow('Other Adjustments', adjustments, isNegative: adjustments < 0),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: AppColors.borderSoft),
            ),
            _buildBreakdownRow('Total Payout', total, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, {bool isNegative = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.fgSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          Text(
            '${isNegative && amount != 0 ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              color: isBold ? AppColors.fgPrimary : (isNegative ? AppColors.fgTertiary : AppColors.fgPrimary),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.borderSoft),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _buildDetailRow('Period', '${DateFormat('dd MMM yyyy').format(DateTime.parse(payout.periodStart))} — ${DateFormat('dd MMM yyyy').format(DateTime.parse(payout.periodEnd))}'),
            _buildDetailRow('Reference', payout.reference),
            if (payout.utr != null) _buildDetailRow('UTR', payout.utr!),
            if (payout.notes != null && payout.notes!.isNotEmpty) _buildDetailRow('Notes', payout.notes!),
            _buildDetailRow('Created By', payout.createdByName),
            _buildDetailRow('Created At', DateFormat('dd MMM yyyy, HH:mm').format(payout.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.fgTertiary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.fgSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items (${payout.items.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Card(
          color: AppColors.bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.borderSoft),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payout.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderSoft),
            itemBuilder: (_, i) => _buildItemRow(payout.items[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(PayoutItemData item) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.reference, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(
                      DateFormat('dd MMM yyyy').format(DateTime.parse(item.appointmentDate)),
                      style: TextStyle(fontSize: 11, color: AppColors.fgTertiary),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${item.gross.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.fgPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commission', style: TextStyle(fontSize: 11, color: AppColors.fgTertiary)),
              Text(
                '-₹${item.commission.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 11, color: AppColors.fgTertiary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.fgSecondary)),
              Text(
                '₹${item.net.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.fgSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

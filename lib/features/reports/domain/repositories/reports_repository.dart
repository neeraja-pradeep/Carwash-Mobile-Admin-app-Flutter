import '../entities/daily_summary.dart';

/// Abstract contract — implemented in infrastructure; called from application.
abstract interface class ReportsRepository {
  Future<DailySummary> fetchDailySummary();
}

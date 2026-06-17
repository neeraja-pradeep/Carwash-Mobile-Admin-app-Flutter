import '../../domain/entities/stats.dart';

class StatsModel extends Stats {
  StatsModel({
    required super.period,
    required super.start,
    required super.end,
    required super.earnings,
    required super.jobs,
    required super.pending,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      period: json['period'] ?? 'today',
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      earnings: json['earnings'] ?? '0.00',
      jobs: json['jobs'] ?? 0,
      pending: json['pending'] ?? '0.00',
    );
  }

  Stats toEntity() => Stats(
    period: period,
    start: start,
    end: end,
    earnings: earnings,
    jobs: jobs,
    pending: pending,
  );
}

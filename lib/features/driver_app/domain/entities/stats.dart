class Stats {
  final String period;
  final String start;
  final String end;
  final String earnings;
  final int jobs;
  final String pending;

  Stats({
    required this.period,
    required this.start,
    required this.end,
    required this.earnings,
    required this.jobs,
    required this.pending,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      period: json['period'] ?? 'today',
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      earnings: json['earnings'] ?? '0.00',
      jobs: json['jobs'] ?? 0,
      pending: json['pending'] ?? '0.00',
    );
  }

  Map<String, dynamic> toJson() => {
    'period': period,
    'start': start,
    'end': end,
    'earnings': earnings,
    'jobs': jobs,
    'pending': pending,
  };
}

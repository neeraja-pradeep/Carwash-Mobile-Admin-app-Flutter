import 'job.dart';

class JobFeed {
  final List<Job> activeNow;
  final List<Job> upNext;
  final int count;

  JobFeed({
    required this.activeNow,
    required this.upNext,
    required this.count,
  });

  factory JobFeed.fromJson(Map<String, dynamic> json) {
    final activeNowList = (json['active_now'] as List<dynamic>)
        .map((e) => Job.fromJson(e as Map<String, dynamic>))
        .toList();
    final upNextList = (json['up_next'] as List<dynamic>)
        .map((e) => Job.fromJson(e as Map<String, dynamic>))
        .toList();

    return JobFeed(
      activeNow: activeNowList,
      upNext: upNextList,
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'active_now': activeNow.map((e) => e.toJson()).toList(),
    'up_next': upNext.map((e) => e.toJson()).toList(),
    'count': count,
  };
}

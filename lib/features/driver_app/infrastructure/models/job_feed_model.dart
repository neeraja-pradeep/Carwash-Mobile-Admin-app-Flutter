import '../../domain/entities/job.dart';
import '../../domain/entities/job_feed.dart';
import 'job_model.dart';

class JobFeedModel extends JobFeed {
  JobFeedModel({
    required super.activeNow,
    required super.upNext,
    required super.count,
  });

  factory JobFeedModel.fromJson(Map<String, dynamic> json) {
    final activeNowList = (json['active_now'] as List<dynamic>? ?? [])
        .map((e) => JobModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final upNextList = (json['up_next'] as List<dynamic>? ?? [])
        .map((e) => JobModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return JobFeedModel(
      activeNow: activeNowList,
      upNext: upNextList,
      count: json['count'] ?? 0,
    );
  }

  JobFeed toEntity() => JobFeed(
    activeNow: activeNow,
    upNext: upNext,
    count: count,
  );
}

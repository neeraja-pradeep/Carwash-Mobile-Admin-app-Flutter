import '../../domain/entities/schedule_day.dart';
import 'job_model.dart';

class ScheduleDayModel extends ScheduleDay {
  ScheduleDayModel({
    required super.date,
    required super.label,
    required super.jobs,
  });

  factory ScheduleDayModel.fromJson(Map<String, dynamic> json) {
    return ScheduleDayModel(
      date: json['date'],
      label: json['label'],
      jobs: (json['jobs'] as List<dynamic>)
          .map((j) => JobModel.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }

  ScheduleDay toEntity() => ScheduleDay(
    date: date,
    label: label,
    jobs: jobs,
  );
}

class ScheduleResponseModel extends ScheduleResponse {
  ScheduleResponseModel({
    required super.days,
    required super.completed,
    required super.completedPagination,
    required super.count,
  });

  factory ScheduleResponseModel.fromJson(Map<String, dynamic> json) {
    return ScheduleResponseModel(
      days: (json['days'] as List<dynamic>)
          .map((d) => ScheduleDayModel.fromJson(d as Map<String, dynamic>))
          .toList(),
      completed: (json['completed'] as List<dynamic>)
          .map((c) => JobModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      completedPagination: SchedulePaginationModel.fromJson(
        json['completed_pagination'] as Map<String, dynamic>,
      ),
      count: json['count'] as int,
    );
  }

  ScheduleResponse toEntity() => ScheduleResponse(
    days: days,
    completed: completed,
    completedPagination: completedPagination,
    count: count,
  );
}

class SchedulePaginationModel extends SchedulePagination {
  SchedulePaginationModel({
    required super.count,
    super.next,
    super.previous,
  });

  factory SchedulePaginationModel.fromJson(Map<String, dynamic> json) {
    return SchedulePaginationModel(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
    );
  }
}

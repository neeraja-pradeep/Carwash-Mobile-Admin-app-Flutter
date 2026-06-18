import 'job.dart';

class ScheduleDay {
  final String date;
  final String label;
  final List<Job> jobs;

  ScheduleDay({
    required this.date,
    required this.label,
    required this.jobs,
  });
}

class ScheduleResponse {
  final List<ScheduleDay> days;
  final List<Job> completed;
  final SchedulePagination completedPagination;
  final int count;

  ScheduleResponse({
    required this.days,
    required this.completed,
    required this.completedPagination,
    required this.count,
  });
}

class SchedulePagination {
  final int count;
  final String? next;
  final String? previous;

  SchedulePagination({
    required this.count,
    this.next,
    this.previous,
  });
}

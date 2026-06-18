import '../../domain/entities/schedule_day.dart';

sealed class ScheduleState {
  const ScheduleState();

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(ScheduleSuccess) success,
    required T Function(ScheduleError) error,
  }) {
    return switch (this) {
      ScheduleInitial() => initial(),
      ScheduleLoading() => loading(),
      ScheduleSuccess s => success(s),
      ScheduleError e => error(e),
    };
  }
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

class ScheduleSuccess extends ScheduleState {
  final ScheduleResponse schedule;
  final int currentPage;
  final bool isLoadingMore;

  const ScheduleSuccess({
    required this.schedule,
    this.currentPage = 1,
    this.isLoadingMore = false,
  });
}

class ScheduleError extends ScheduleState {
  final String message;

  const ScheduleError({required this.message});
}

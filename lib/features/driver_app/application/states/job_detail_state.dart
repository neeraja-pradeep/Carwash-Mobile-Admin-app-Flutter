import '../../domain/entities/job_detail.dart';
import '../../domain/entities/bill.dart';

sealed class JobDetailState {
  const JobDetailState();
}

class JobDetailInitial extends JobDetailState {
  const JobDetailInitial();
}

class JobDetailLoading extends JobDetailState {
  const JobDetailLoading();
}

class JobDetailSuccess extends JobDetailState {
  final JobDetail job;
  final Bill? bill;
  final bool isLoading;

  const JobDetailSuccess({
    required this.job,
    this.bill,
    this.isLoading = false,
  });
}

class JobDetailError extends JobDetailState {
  final String message;

  const JobDetailError({required this.message});
}

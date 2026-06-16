import '../../domain/entities/field_driver.dart';

/// Immutable filter state for the Drivers list.
/// All fields `final`; mutate only through [copyWith].
class DriversFilterState {
  const DriversFilterState({
    this.status,
  });

  /// `null` = all statuses; otherwise filters to the given [DriverStatus].
  final DriverStatus? status;

  /// Count of active filters (drives the Filter pill badge + chip row).
  int get activeCount => status != null ? 1 : 0;

  DriversFilterState copyWith({
    DriverStatus? status,
    bool clearStatus = false,
  }) {
    return DriversFilterState(
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

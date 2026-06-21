import 'badge_tone.dart';

/// Driver-hire / inspection service-request lifecycle states.
///
/// Shares the universal New / Assigned / Completed / Cancelled tones with
/// [BookingStatus]; `contacted` and `inProgress` are request-specific.
enum ServiceRequestStatus {
  created,
  contacted,
  assigned,
  arrived,
  inProgress,
  completed,
  cancelled,
}

/// Display label, badge tone and wire-key for a [ServiceRequestStatus].
extension ServiceRequestStatusX on ServiceRequestStatus {
  String get label => switch (this) {
        ServiceRequestStatus.created => 'New',
        ServiceRequestStatus.contacted => 'Contacted',
        ServiceRequestStatus.assigned => 'Assigned',
        ServiceRequestStatus.arrived => 'Arrived',
        ServiceRequestStatus.inProgress => 'In Progress',
        ServiceRequestStatus.completed => 'Completed',
        ServiceRequestStatus.cancelled => 'Cancelled',
      };

  BadgeTone get tone => switch (this) {
        ServiceRequestStatus.created => BadgeTone.amber,
        ServiceRequestStatus.completed => BadgeTone.green,
        ServiceRequestStatus.cancelled => BadgeTone.red,
        _ => BadgeTone.blue,
      };

  String get key => switch (this) {
        ServiceRequestStatus.created => 'new',
        ServiceRequestStatus.inProgress => 'in_progress',
        _ => name,
      };

  int get order => ServiceRequestStatus.values.indexOf(this);
}

/// Forward lifecycle order used by the request status-update block.
const List<ServiceRequestStatus> kServiceRequestStatusOrder = [
  ServiceRequestStatus.created,
  ServiceRequestStatus.contacted,
  ServiceRequestStatus.assigned,
  ServiceRequestStatus.inProgress,
  ServiceRequestStatus.completed,
];

/// Resolves a wire-key to a [ServiceRequestStatus].
ServiceRequestStatus serviceRequestStatusFromKey(String key) {
  return switch (key) {
    'new' => ServiceRequestStatus.created,
    'in_progress' => ServiceRequestStatus.inProgress,
    _ => ServiceRequestStatus.values.firstWhere(
        (s) => s.name == key,
        orElse: () => ServiceRequestStatus.created,
      ),
  };
}

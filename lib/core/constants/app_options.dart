/// Static option lists shared across feature forms (from `data.jsx`).
///
/// Top-level constants are `k`-prefixed per the project lint rules. These move
/// to remote config / the API in a later phase.
library;

/// Vehicle types master list.
const List<String> kVehicleTypes = [
  'Hatchback',
  'Sedan',
  'Compact SUV',
  'SUV',
  'Premium SUV',
];

/// Reasons a customer may be blocked.
const List<String> kBlockReasons = [
  'Frequent no-shows',
  'Abusive behavior',
  'Payment issues',
  'Fake bookings',
  'Other',
];

/// Refund reason categories.
const List<String> kRefundReasons = [
  'Cancellation by customer',
  'Founder cancellation',
  'Service quality issue',
  'Damage during wash',
  'Duplicate charge',
  'Other',
];

/// Driver-hire reasons (optional).
const List<String> kDriverReasons = [
  'One Way Trip',
  'Round Trip',
  'Hospital Assistance',
  'Outstation',
  'Event / Wedding',
];

/// Document types for driver/inspector profiles.
const List<String> kDocTypes = [
  'Driving License',
  'Aadhaar Card',
  'PAN Card',
  'Police Verification',
  'Vehicle RC',
  'Address Proof',
  'Other',
];

/// Hard-coded team roles.
const List<String> kDriverRoles = [
  'Wash driver',
  'Wash + hire driver',
  'Hire driver',
  'Inspector',
];

/// Damage types captured in the damage-check sheet.
const List<String> kDamageTypes = [
  'Minor scratch',
  'Major scratch',
  'Dent',
  'Glass crack',
  'Paint chip',
  'Interior stain',
  'Other',
];

/// Panels/locations captured in the damage-check sheet.
const List<String> kDamagePanels = [
  'Front bumper',
  'Rear bumper',
  'Front-left door',
  'Front-right door',
  'Rear-left door',
  'Rear-right door',
  'Bonnet',
  'Boot',
  'Roof',
  'Front windshield',
  'Rear windshield',
  'Interior',
  'Other',
];

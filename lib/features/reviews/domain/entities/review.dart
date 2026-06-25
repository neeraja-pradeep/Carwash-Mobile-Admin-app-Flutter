/// A customer review (view-only — no moderation in v0.1).
class Review {
  const Review({
    required this.id,
    required this.rating,
    required this.customer,
    required this.phone,
    required this.shop,
    required this.date,
    required this.time,
    required this.bookingId,
    required this.drivers,
    required this.text,
    this.tags = const [],
    this.bookingIntId,
    this.isFlagged = false,
    this.customerPhone,
    this.handledBy,
    this.shopId,
  });

  final String id;
  final int rating;
  final String customer;
  final String phone;
  final String shop;
  final String date;
  final String time;

  /// Human-readable booking reference (e.g. `DT-0529-0043`).
  final String bookingId;
  final List<String> drivers;

  /// Free-text body — empty for rating-only reviews.
  final String text;

  /// Detail-only fields (defaults keep the entity backward compatible with the
  /// list cards, which don't carry them).

  /// Free-form tag tokens, e.g. `["Quick", "Friendly"]`.
  final List<String> tags;

  /// The linked carwash booking id (numeric) — distinct from [bookingId]
  /// which is the string reference. `null` if the review has no booking.
  final int? bookingIntId;

  /// Informational flag — no moderation action is exposed in v0.1.
  final bool isFlagged;

  /// Reviewer's phone (detail). Mirrors [phone] when supplied.
  final String? customerPhone;

  /// The worker who handled the booking (detail). `null` if unassigned.
  final String? handledBy;

  /// The reviewed shop's id.
  final int? shopId;

  bool get hasText => text.isNotEmpty;
}

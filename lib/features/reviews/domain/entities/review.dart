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
  });

  final String id;
  final int rating;
  final String customer;
  final String phone;
  final String shop;
  final String date;
  final String time;
  final String bookingId;
  final List<String> drivers;

  /// Free-text body — empty for rating-only reviews.
  final String text;

  bool get hasText => text.isNotEmpty;
}

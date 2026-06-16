// Unit tests for the DriveDeck Admin domain/formatting layer.
//
// These are deterministic, dependency-light checks (no network fonts, no
// device surface) so `flutter test` passes reliably in CI. Widget/integration
// tests are added alongside the API-integration phase.

import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/core/status/badge_tone.dart';
import 'package:new_flutter_project/core/status/booking_status.dart';
import 'package:new_flutter_project/core/status/payment_status.dart';
import 'package:new_flutter_project/core/status/service_request_status.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    test('money formats rupees with Indian grouping', () {
      expect(Formatters.money(8450), '₹8,450');
      expect(Formatters.money(0), '₹0');
      expect(Formatters.money(100000), '₹1,00,000');
    });

    test('count pluralises against the value', () {
      expect(Formatters.count(1, 'shop'), '1 shop');
      expect(Formatters.count(5, 'booking'), '5 bookings');
      expect(Formatters.count(0, 'review'), '0 reviews');
    });

    test('initials takes up to two uppercase letters', () {
      expect(Formatters.initials('Ramesh Kurup'), 'RK');
      expect(Formatters.initials('Priya'), 'P');
      expect(Formatters.initials(''), '?');
    });
  });

  group('BookingStatus', () {
    test('label and tone map correctly', () {
      expect(BookingStatus.created.label, 'New');
      expect(BookingStatus.created.tone, BadgeTone.amber);
      expect(BookingStatus.completed.tone, BadgeTone.green);
      expect(BookingStatus.cancelled.tone, BadgeTone.red);
      expect(BookingStatus.washing.tone, BadgeTone.blue);
    });

    test('wire-key round-trips (incl. reserved-word "new")', () {
      expect(BookingStatus.created.key, 'new');
      expect(BookingStatus.atShop.key, 'atshop');
      expect(bookingStatusFromKey('new'), BookingStatus.created);
      expect(bookingStatusFromKey('atshop'), BookingStatus.atShop);
      expect(bookingStatusFromKey('washing'), BookingStatus.washing);
    });

    test('forward order excludes cancelled', () {
      expect(kBookingStatusOrder.contains(BookingStatus.cancelled), isFalse);
      expect(kBookingStatusOrder.first, BookingStatus.created);
      expect(kBookingStatusOrder.last, BookingStatus.completed);
    });
  });

  group('ServiceRequestStatus & PaymentStatus', () {
    test('service-request wire-keys', () {
      expect(ServiceRequestStatus.created.key, 'new');
      expect(ServiceRequestStatus.inProgress.key, 'in_progress');
      expect(
        serviceRequestStatusFromKey('in_progress'),
        ServiceRequestStatus.inProgress,
      );
    });

    test('payment tones', () {
      expect(PaymentStatus.paid.tone, BadgeTone.green);
      expect(PaymentStatus.pending.tone, BadgeTone.amber);
      expect(PaymentStatus.refunded.tone, BadgeTone.red);
    });
  });
}

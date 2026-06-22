import 'package:new_flutter_project/features/bookings/infrastructure/models/booking_detail_response_model.dart';

void main() {
  // Test with fields as different types (int, string, double, etc.)
  final testJson = {
    'id': 123,
    'reference': 'REF-456',
    'status': 'pending',
    'washing_status': 'washing',
    'amount': 500, // int instead of string
    'is_paid': false,
    'payment_status': 'unpaid',
    'customer_name': 'John Doe',
    'customer_phone': 123456789, // int instead of string
    'vehicle_label': 'ABC-1234',
    'car': 'Toyota', 
    'start_slot_time': 1234567890, // int instead of string
    'appointment_date': '2026-06-22',
    'address_detail': {
      'latitude': 12.5,
      'longitude': 75.5,
      'address': 'Test Address',
    },
    'shop': {
      'id': 1,
      'name': 'Shop 1',
      'address': 'Shop Address',
      'phone': '9876543210',
      'latitude': 12.0,
      'longitude': 75.0,
    },
    'drop_address': 'Drop Address',
    'services': [
      {
        'service_name': 'Wash',
        'estimated_minutes': 30,
        'amount': 300,
      }
    ],
    'driver': {
      'id': 10,
      'name': 'Driver Name',
      'title': 'Driver',
      'phone': '9876543210',
      'masked_phone': '****3210',
      'rating': 4.5,
    },
    'timeline': [
      {
        'washing_status': 'pending',
        'actor': 'Admin',
        'created_at': '2026-06-22T10:00:00Z',
      }
    ],
    'damage': null,
  };

  try {
    final response = BookingDetailResponse.fromJson(testJson);
    print('✅ SUCCESS: BookingDetailResponse parsed correctly!');
    print('   ID: ${response.id}');
    print('   Reference: ${response.reference}');
    print('   Customer: ${response.customerName}');
    print('   Phone: ${response.customerPhone}');
    print('   Start Time: ${response.startSlotTime}');
    print('   Amount: ${response.amount}');
  } catch (e) {
    print('❌ FAILED: $e');
  }
}

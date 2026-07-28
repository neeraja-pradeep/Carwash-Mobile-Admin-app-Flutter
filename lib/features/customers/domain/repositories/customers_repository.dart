import '../entities/customer.dart';

/// Contract for reading and managing customer data. Pure abstract — no implementation.
abstract class CustomersRepository {
  /// Customers list with optional server-side search/filter/sort.
  ///
  /// [status] → `active`|`blocked`; [joined] → `30d`|`90d`|`year`;
  /// [bookingCount] → `1-5`|`6-20`|`20plus`; [sort] → `name`|`spend`|`bookings`|`recent`.
  Future<List<Customer>> fetchCustomers({
    String? search,
    String? status,
    String? joined,
    String? bookingCount,
    String? sort,
  });

  /// A single customer by [id] (dedicated detail endpoint), or `null` when not found.
  Future<Customer?> fetchCustomerById(String id);

  /// Search customers by phone, name, or username.
  Future<List<Customer>> searchCustomers(String query);

  /// The customer's saved addresses, default first. Empty when they have none.
  Future<List<SavedAddress>> fetchSavedAddresses(String customerId);

  /// Update the editable founder notes; returns the refreshed customer.
  Future<Customer> updateFounderNotes(String id, String notes);

  /// Block a customer with an optional reason enum + free-text notes.
  Future<void> blockCustomer(String id, {String? reason, String? notes});

  /// Unblock a customer.
  Future<void> unblockCustomer(String id);

  /// One page of a customer's merged booking history.
  Future<CustomerHistoryPage> fetchCustomerHistory(
    String id, {
    int page,
    int pageSize,
  });

  /// Create a new customer account with phone and name.
  /// Optionally include [otpCode] for OTP verification, or omit for override.
  /// Returns the newly created customer.
  /// Throws if phone already exists or validation fails.
  Future<Customer> createCustomer({
    required String phone,
    required String fullName,
    String? otpCode,
    String? email,
  });
}

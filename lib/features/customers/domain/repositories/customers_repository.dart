import '../entities/customer.dart';

/// Contract for reading and managing customer data. Pure abstract — no implementation.
abstract class CustomersRepository {
  /// All customers, unfiltered.
  Future<List<Customer>> fetchCustomers();

  /// A single customer by [id], or `null` when not found.
  Future<Customer?> fetchCustomerById(String id);

  /// Search customers by phone, name, or username.
  Future<List<Customer>> searchCustomers(String query);

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

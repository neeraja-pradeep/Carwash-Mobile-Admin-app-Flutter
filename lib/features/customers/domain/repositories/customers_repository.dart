import '../entities/customer.dart';

/// Contract for reading customer data. Pure abstract — no implementation.
abstract class CustomersRepository {
  /// All customers, unfiltered.
  Future<List<Customer>> fetchCustomers();

  /// A single customer by [id], or `null` when not found.
  Future<Customer?> fetchCustomerById(String id);
}

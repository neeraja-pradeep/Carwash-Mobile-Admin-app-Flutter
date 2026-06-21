import 'package:flutter/foundation.dart';

import '../../domain/entities/customer.dart';
import '../../domain/repositories/customers_repository.dart';
import '../data_sources/local/customers_local_ds.dart';
import '../data_sources/customers_api.dart';

/// Fulfils [CustomersRepository] from API with fallback to local cache.
///
/// Tries API first, falls back to local static data if API fails.
class CustomersRepositoryImpl implements CustomersRepository {
  CustomersRepositoryImpl({
    CustomersLocalDs? local,
    CustomersApi? api,
  })  : _local = local ?? const CustomersLocalDs(),
        _api = api ?? CustomersApi();

  final CustomersLocalDs _local;
  final CustomersApi _api;

  @override
  Future<List<Customer>> fetchCustomers() async {
    try {
      final response = await _api.getCustomers();
      return response.results
          .map((m) => Customer(
                id: m.id.toString(),
                name: m.fullName,
                phone: m.phone ?? '',
                email: m.email ?? '',
                joined: '',
                blocked: false,
                blockedReason: '',
                notes: '',
                bookings: 0,
                spend: 0,
                lastBooking: '',
                accountAge: '',
                addresses: [],
                vehicles: [],
                history: [],
              ))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching customers from API: $e');
      debugPrint('StackTrace: $stackTrace');
      // Fallback to local data
      return _local.fetchCustomers();
    }
  }

  @override
  Future<Customer?> fetchCustomerById(String id) async {
    try {
      final response = await _api.getCustomers();
      final model = response.results.firstWhere(
        (m) => m.id.toString() == id,
        orElse: () => throw Exception('Customer not found'),
      );
      return Customer(
        id: model.id.toString(),
        name: model.fullName,
        phone: model.phone ?? '',
        email: model.email ?? '',
        joined: '',
        blocked: false,
        blockedReason: '',
        notes: '',
        bookings: 0,
        spend: 0,
        lastBooking: '',
        accountAge: '',
        addresses: [],
        vehicles: [],
        history: [],
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching customer $id from API: $e');
      debugPrint('StackTrace: $stackTrace');
      // Fallback to local data
      return _local.fetchCustomerById(id);
    }
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final response = await _api.searchCustomers(query);
      return response.results
          .map((m) => Customer(
                id: m.id.toString(),
                name: m.fullName,
                phone: m.phone ?? '',
                email: m.email ?? '',
                joined: '',
                blocked: false,
                blockedReason: '',
                notes: '',
                bookings: 0,
                spend: 0,
                lastBooking: '',
                accountAge: '',
                addresses: [],
                vehicles: [],
                history: [],
              ))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR searching customers: $e');
      debugPrint('StackTrace: $stackTrace');
      // Fallback to local data
      final localCustomers = await _local.fetchCustomers();
      final lowerQuery = query.toLowerCase();
      return localCustomers
          .where((c) =>
              c.name.toLowerCase().contains(lowerQuery) ||
              c.phone.contains(query))
          .toList();
    }
  }

  @override
  Future<Customer> createCustomer({
    required String phone,
    required String fullName,
    String? otpCode,
    String? email,
  }) async {
    try {
      final model = await _api.createCustomer(
        phone: phone,
        fullName: fullName,
        otpCode: otpCode,
        email: email,
      );
      return Customer(
        id: model.id.toString(),
        name: model.fullName,
        phone: model.phone ?? '',
        email: model.email ?? '',
        joined: '',
        blocked: false,
        blockedReason: '',
        notes: '',
        bookings: 0,
        spend: 0,
        lastBooking: '',
        accountAge: '',
        addresses: [],
        vehicles: [],
        history: [],
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR creating customer: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }
}

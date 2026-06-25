import 'package:flutter/foundation.dart';

import '../../domain/entities/customer.dart';
import '../../domain/repositories/customers_repository.dart';
import '../data_sources/local/customers_local_ds.dart';
import '../data_sources/customers_api.dart';

/// Fulfils [CustomersRepository] from the API with a local-cache fallback for
/// the list/search paths. Detail and history come from the API only (no
/// fallback) so they reflect live server state.
class CustomersRepositoryImpl implements CustomersRepository {
  CustomersRepositoryImpl({
    CustomersLocalDs? local,
    CustomersApi? api,
  })  : _local = local ?? const CustomersLocalDs(),
        _api = api ?? CustomersApi();

  final CustomersLocalDs _local;
  final CustomersApi _api;

  @override
  Future<List<Customer>> fetchCustomers({
    String? search,
    String? status,
    String? joined,
    String? bookingCount,
    String? sort,
  }) async {
    try {
      final response = await _api.getCustomers(
        search: search,
        status: status,
        joined: joined,
        bookingCount: bookingCount,
        sort: sort,
      );
      return response.results.map((m) => m.toEntity()).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching customers from API: $e');
      debugPrint('StackTrace: $stackTrace');
      // Fallback to local data so the list still renders offline.
      return _local.fetchCustomers();
    }
  }

  @override
  Future<Customer?> fetchCustomerById(String id) async {
    // Detail must come from the dedicated endpoint — no local fallback.
    final detail = await _api.getCustomerDetail(id);
    return detail.toEntity();
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final response = await _api.searchCustomers(query);
      return response.results.map((m) => m.toEntity()).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR searching customers: $e');
      debugPrint('StackTrace: $stackTrace');
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
  Future<Customer> updateFounderNotes(String id, String notes) async {
    try {
      final detail = await _api.patchFounderNotes(id, notes);
      return detail.toEntity();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR updating founder notes: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> blockCustomer(String id, {String? reason, String? notes}) async {
    try {
      await _api.blockCustomer(id, reason: reason, notes: notes);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR blocking customer: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> unblockCustomer(String id) async {
    try {
      await _api.unblockCustomer(id);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR unblocking customer: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<CustomerHistoryPage> fetchCustomerHistory(
    String id, {
    int page = 1,
    int pageSize = 20,
  }) async {
    // History must come from the API — no local fallback.
    final response =
        await _api.getCustomerHistory(id, page: page, pageSize: pageSize);
    return CustomerHistoryPage(
      rows: response.results.map((r) => r.toEntity()).toList(),
      count: response.count,
      page: response.page == 0 ? page : response.page,
      pageSize: response.pageSize == 0 ? pageSize : response.pageSize,
      hasNext: response.next != null && response.next!.isNotEmpty,
      hasPrevious: response.previous != null && response.previous!.isNotEmpty,
    );
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
      return model.toEntity();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR creating customer: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }
}

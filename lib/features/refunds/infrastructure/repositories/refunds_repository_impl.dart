import 'package:flutter/foundation.dart';
import '../../domain/entities/refund.dart';
import '../../domain/repositories/refunds_repository.dart';
import '../data_sources/refunds_api.dart';

/// Fulfils [RefundsRepository] from the API.
class RefundsRepositoryImpl implements RefundsRepository {
  RefundsRepositoryImpl({RefundsApi? api}) : _api = api ?? RefundsApi();

  final RefundsApi _api;

  @override
  Future<List<Refund>> fetchRefunds({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? status,
    String? reason,
    String? sort,
  }) async {
    try {
      final response = await _api.getRefunds(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        reason: reason,
        sort: sort,
      );

      return response.results.map((model) => model.toEntity()).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching refunds: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Refund?> getRefundById(String id) async {
    try {
      final response = await _api.getRefundDetail(id);
      return response.toEntity();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching refund detail: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }
}

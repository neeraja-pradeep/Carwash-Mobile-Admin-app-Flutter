/// Response from customer list API
class CustomerListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<CustomerApiModel> results;

  CustomerListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) {
    return CustomerListResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map((e) => CustomerApiModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Customer model from API response
class CustomerApiModel {
  final int id;
  final String fullName;
  final String? phone;
  final String? initials;
  final String? email;

  CustomerApiModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.initials,
    this.email,
  });

  factory CustomerApiModel.fromJson(Map<String, dynamic> json) {
    return CustomerApiModel(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      initials: json['initials'] as String?,
      email: json['email'] as String?,
    );
  }
}

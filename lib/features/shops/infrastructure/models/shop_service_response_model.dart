import '../../domain/entities/shop.dart';

/// Shop service list response from GET /api/shop/v1/shop-services/?shop={id}
class ShopServiceResponse {
  final int id;
  final int shop;
  final String name;
  final int? categoryId;
  final List<String> inclusions;
  final bool uniformPricing;
  final int price;
  final int durationInSlots;
  /// Nullable — the API omits it for variants saved without a duration.
  final int? estimatedMinutes;
  final List<ServiceVariantResponse> variants;
  final int fromPrice;
  final String summary;
  final bool active;

  ShopServiceResponse({
    required this.id,
    required this.shop,
    required this.name,
    this.categoryId,
    required this.inclusions,
    required this.uniformPricing,
    required this.price,
    required this.durationInSlots,
    required this.estimatedMinutes,
    required this.variants,
    required this.fromPrice,
    required this.summary,
    required this.active,
  });

  factory ShopServiceResponse.fromJson(Map<String, dynamic> json) {
    return ShopServiceResponse(
      id: json['id'] as int? ?? 0,
      shop: json['shop'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      categoryId: json['category_id'] as int?,
      inclusions: (json['inclusions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      uniformPricing: json['uniform_pricing'] as bool? ?? false,
      price: ((json['price'] as num?) ?? 0).toInt(),
      durationInSlots: json['duration_in_slots'] as int? ?? 1,
      estimatedMinutes: json['estimated_minutes'] as int?,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) =>
                  ServiceVariantResponse.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      fromPrice: ((json['from_price'] as num?) ?? 0).toInt(),
      summary: json['summary'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }

  /// Convert to domain ShopService entity.
  ShopService toDomain() {
    final pricing = uniformPricing
        ? [
            ServicePricing(
              type: 'all',
              price: price,
              minutes: estimatedMinutes ?? durationInSlots * 30,
              active: active,
            )
          ]
        : variants
            .map((v) => ServicePricing(
                  // Kept as the API slug (`hatchback`, `suv`, …); the form maps
                  // it back to a display label via `vehicleTypeSlug`.
                  type: v.vehicleType,
                  price: v.price,
                  minutes: v.estimatedMinutes ?? v.durationInSlots * 30,
                  active: v.active,
                ))
            .toList();

    return ShopService(
      id: id.toString(),
      name: name,
      description: inclusions.join(', '),
      samePrice: uniformPricing,
      // Null (not 0) when per-vehicle priced, so the flat-price fields render
      // empty rather than "0" if the user flips the uniform-pricing toggle.
      flatPrice: uniformPricing ? price : null,
      flatMinutes: uniformPricing ? (estimatedMinutes ?? durationInSlots * 30) : null,
      active: active,
      pricing: pricing,
    );
  }
}

class ServiceVariantResponse {
  final int id;
  final String vehicleType;
  final String label;
  final int price;
  final int durationInSlots;
  /// Nullable — the API returns null for variants saved without a duration.
  final int? estimatedMinutes;
  final bool active;

  ServiceVariantResponse({
    required this.id,
    required this.vehicleType,
    required this.label,
    required this.price,
    required this.durationInSlots,
    required this.estimatedMinutes,
    required this.active,
  });

  factory ServiceVariantResponse.fromJson(Map<String, dynamic> json) {
    return ServiceVariantResponse(
      id: json['id'] as int? ?? 0,
      vehicleType: json['vehicle_type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      price: ((json['price'] as num?) ?? 0).toInt(),
      durationInSlots: json['duration_in_slots'] as int? ?? 1,
      estimatedMinutes: json['estimated_minutes'] as int?,
      active: json['active'] as bool? ?? true,
    );
  }
}

/// Paginated services response
class ShopServicesListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<ShopServiceResponse> results;

  ShopServicesListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory ShopServicesListResponse.fromJson(Map<String, dynamic> json) {
    return ShopServicesListResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>?)
              ?.map((r) =>
                  ShopServiceResponse.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get hasNextPage => next != null && next!.isNotEmpty;
}

/// Create/Update service request payload
class ShopServiceCreateRequest {
  final int? shop;
  final String name;
  final List<String> inclusions;
  final int? categoryId;
  final bool uniformPricing;
  final bool active;
  final int? price;
  final int? durationInSlots;
  final List<ServiceVariantCreateRequest>? variants;

  ShopServiceCreateRequest({
    this.shop,
    required this.name,
    required this.inclusions,
    this.categoryId,
    required this.uniformPricing,
    required this.active,
    this.price,
    this.durationInSlots,
    this.variants,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'inclusions': inclusions,
      'uniform_pricing': uniformPricing,
      'active': active,
    };

    if (shop != null) {
      json['shop'] = shop;
    }

    if (categoryId != null) {
      json['category_id'] = categoryId;
    }

    if (uniformPricing) {
      json['price'] = price ?? 0;
      json['duration_in_slots'] = durationInSlots ?? 1;
    } else if (variants != null) {
      json['variants'] = variants!.map((v) => v.toJson()).toList();
    }

    return json;
  }
}

class ServiceVariantCreateRequest {
  final String vehicleType;
  final int price;
  final int durationInSlots;
  final bool active;

  ServiceVariantCreateRequest({
    required this.vehicleType,
    required this.price,
    required this.durationInSlots,
    required this.active,
  });

  Map<String, dynamic> toJson() => {
        'vehicle_type': vehicleType,
        'price': price,
        'duration_in_slots': durationInSlots,
        'active': active,
      };
}

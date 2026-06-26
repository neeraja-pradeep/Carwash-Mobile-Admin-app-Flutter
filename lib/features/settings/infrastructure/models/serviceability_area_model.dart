import 'package:flutter/foundation.dart';

import '../../domain/entities/app_settings.dart';
import 'json_helpers.dart';

/// A serviceability area from GET/POST/PATCH /api/shop/v1/serviceability-areas/.
class ServiceabilityAreaModel {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String pincode;
  final int radiusKm;
  final List<String> types;
  final bool active;

  ServiceabilityAreaModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.pincode,
    required this.radiusKm,
    required this.types,
    required this.active,
  });

  factory ServiceabilityAreaModel.fromJson(Map<String, dynamic> json) {
    try {
      return ServiceabilityAreaModel(
        id: asInt(json['id']),
        name: asString(json['name']),
        latitude: asDouble(json['latitude']),
        longitude: asDouble(json['longitude']),
        pincode: asString(json['pincode']),
        radiusKm: asInt(json['radius_km']),
        types: asStringList(json['types']),
        active: asBool(json['active'], true),
      );
    } catch (e) {
      debugPrint('Error parsing ServiceabilityAreaModel: $e');
      rethrow;
    }
  }

  ServiceArea toEntity() {
    return ServiceArea(
      id: id,
      name: name,
      pincode: pincode,
      radiusKm: radiusKm,
      latitude: latitude,
      longitude: longitude,
      types: types,
      active: active,
    );
  }
}

/// Parses a serviceability-areas list response — tolerates both a bare list and
/// a DRF paginated `{results: [...]}` envelope.
List<ServiceabilityAreaModel> parseServiceabilityAreas(dynamic data) {
  final list = data is Map<String, dynamic> ? data['results'] : data;
  if (list is List) {
    return list
        .map((e) =>
            ServiceabilityAreaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  return const [];
}

/// Builds the create/update payload. `radius_km` goes as a decimal string.
Map<String, dynamic> buildServiceAreaPayload({
  String? name,
  String? pincode,
  int? radiusKm,
  double? latitude,
  double? longitude,
  List<String>? types,
  bool? active,
}) {
  return {
    if (name != null) 'name': name,
    if (pincode != null) 'pincode': pincode,
    if (radiusKm != null) 'radius_km': radiusKm.toString(),
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (types != null) 'types': types,
    if (active != null) 'active': active,
  };
}

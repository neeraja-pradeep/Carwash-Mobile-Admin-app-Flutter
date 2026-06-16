import 'package:hive/hive.dart';

import 'cache_config.dart';

/// A cached HTTP response with LRU + freshness metadata (per
/// `docs/HIVE implementation.md`). The [CacheEntryAdapter] is hand-written so no
/// code-generation step is required. Wired into the cache in the API phase.
@HiveType(typeId: 1)
class CacheEntry {
  const CacheEntry({
    required this.key,
    required this.data,
    required this.cachedAt,
    required this.lastAccessed,
    required this.accessCount,
    required this.size,
    this.lastModified,
  });

  @HiveField(0)
  final String key;

  @HiveField(1)
  final dynamic data;

  @HiveField(2)
  final String? lastModified;

  @HiveField(3)
  final int cachedAt;

  @HiveField(4)
  final int lastAccessed;

  @HiveField(5)
  final int accessCount;

  @HiveField(6)
  final int size;

  bool get isStale =>
      DateTime.now().millisecondsSinceEpoch - cachedAt >
      CacheConfig.staleCacheThreshold.inMilliseconds;

  bool get isValid =>
      DateTime.now().millisecondsSinceEpoch - cachedAt <
      CacheConfig.validCacheThreshold.inMilliseconds;

  CacheEntry copyWith({
    String? key,
    dynamic data,
    String? lastModified,
    int? cachedAt,
    int? lastAccessed,
    int? accessCount,
    int? size,
  }) {
    return CacheEntry(
      key: key ?? this.key,
      data: data ?? this.data,
      lastModified: lastModified ?? this.lastModified,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      accessCount: accessCount ?? this.accessCount,
      size: size ?? this.size,
    );
  }
}

/// Hand-written Hive [TypeAdapter] for [CacheEntry] (typeId 1).
class CacheEntryAdapter extends TypeAdapter<CacheEntry> {
  @override
  final int typeId = 1;

  @override
  CacheEntry read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return CacheEntry(
      key: fields[0] as String,
      data: fields[1],
      lastModified: fields[2] as String?,
      cachedAt: fields[3] as int,
      lastAccessed: fields[4] as int,
      accessCount: fields[5] as int,
      size: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CacheEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.lastModified)
      ..writeByte(3)
      ..write(obj.cachedAt)
      ..writeByte(4)
      ..write(obj.lastAccessed)
      ..writeByte(5)
      ..write(obj.accessCount)
      ..writeByte(6)
      ..write(obj.size);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

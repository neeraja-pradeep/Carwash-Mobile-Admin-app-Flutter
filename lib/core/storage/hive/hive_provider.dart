import 'package:hive/hive.dart';
import 'package:synchronized/synchronized.dart';

import 'boxes.dart';

/// Single, lock-guarded access point to the Hive cache box (per
/// `docs/HIVE implementation.md`). All Hive operations go through [getBox] so a
/// box is never opened concurrently across isolates. Wired in the API phase.
class HiveProvider {
  const HiveProvider._();

  static Box<dynamic>? _box;
  static final Lock _lock = Lock();

  static Future<Box<dynamic>> getBox() {
    return _lock.synchronized(() async {
      return _box ??= await Hive.openBox<dynamic>(HiveBoxes.cache);
    });
  }
}

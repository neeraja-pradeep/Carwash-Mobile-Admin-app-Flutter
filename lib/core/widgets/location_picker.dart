import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../location/geo_place.dart';
import '../location/geocoding_service.dart';
import '../utils/logger.dart';
import 'app_button.dart';
import 'app_icons.dart';
import 'app_toast.dart';
import 'top_bar.dart';

/// Opens the full-screen map picker and resolves to the location the admin
/// confirmed, or `null` if they backed out.
///
/// [initial] pre-centres the map on an already-picked point (edit flows).
/// Otherwise the picker asks for the device location and falls back to
/// [_fallbackCentre].
Future<GeoPlace?> showLocationPicker(
  BuildContext context, {
  GeoPlace? initial,
}) {
  return Navigator.of(context).push<GeoPlace>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => LocationPickerScreen(initial: initial),
    ),
  );
}

/// Alappuzha, Kerala — the platform's launch city. Only used when there is no
/// initial point and the device location is unavailable.
const _fallbackCentre = LatLng(9.4981, 76.3388);

const _initialZoom = 16.0;
const _searchDebounce = Duration(milliseconds: 500);
const _settleDebounce = Duration(milliseconds: 600);

/// Full-screen "drop a pin" location picker built on OpenStreetMap tiles.
///
/// The pin is fixed at the centre of the viewport and the map moves under it —
/// the standard mobile pattern, and steadier than dragging a marker. Whenever
/// the map settles, the centre is reverse-geocoded so the admin sees the
/// address and pincode that will be saved before they confirm.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({this.initial, super.key});

  final GeoPlace? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  final _geocoder = GeocodingService();
  final _searchController = TextEditingController();

  late LatLng _centre;
  GeoPlace? _picked;
  bool _resolving = false;
  bool _locating = false;

  List<GeoPlace> _results = const [];
  bool _searching = false;

  Timer? _settleTimer;
  Timer? _searchTimer;

  /// Guards against out-of-order geocode responses — a slow lookup for an old
  /// centre must not overwrite the result for the centre the admin sees now.
  int _resolveSeq = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _centre = initial != null
        ? LatLng(initial.latitude, initial.longitude)
        : _fallbackCentre;
    _picked = initial;

    if (initial == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // A denial here is not an error — the admin never asked for it. Fall
        // back to resolving the default centre so the sheet isn't blank.
        final located = await _useMyLocation(silent: true);
        if (!located && mounted) _resolveCentre();
      });
    }
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    _searchTimer?.cancel();
    _searchController.dispose();
    _geocoder.dispose();
    _map.dispose();
    super.dispose();
  }

  // ─── Reverse geocoding ──────────────────────────────────────────────────────

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _centre = camera.center;
    if (!hasGesture) return;

    // The address on screen no longer matches the pin — clear it and re-resolve
    // once the admin stops panning.
    if (_picked != null || _results.isNotEmpty) {
      setState(() {
        _picked = null;
        _results = const [];
      });
    }
    _settleTimer?.cancel();
    _settleTimer = Timer(_settleDebounce, () => _resolveCentre());
  }

  Future<void> _resolveCentre() async {
    final target = _centre;
    final seq = ++_resolveSeq;
    setState(() => _resolving = true);

    final place = await _geocoder.reverse(target.latitude, target.longitude);
    if (!mounted || seq != _resolveSeq) return;

    setState(() {
      _picked = place;
      _resolving = false;
    });
  }

  // ─── Device location ────────────────────────────────────────────────────────

  /// Centres the map on the device's position, returning whether it managed to.
  ///
  /// [silent] suppresses the permission/error toasts for the automatic centring
  /// done on open, where a denial is not something the admin asked for.
  Future<bool> _useMyLocation({bool silent = false}) async {
    if (_locating) return false;
    setState(() => _locating = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!silent && mounted) {
          AppToast.show(context, 'Turn on location services to use this');
        }
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!silent && mounted) {
          AppToast.show(context, 'Location permission denied');
        }
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return false;

      _moveTo(LatLng(position.latitude, position.longitude));
      return true;
    } catch (e) {
      AppLogger.error('Device location lookup failed', error: e);
      if (!silent && mounted) {
        AppToast.show(context, 'Could not get your location');
      }
      return false;
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Recentres the map and resolves the new point. Used by both the search
  /// results and the my-location button, neither of which fires
  /// [_onPositionChanged]'s gesture path.
  void _moveTo(LatLng target, {GeoPlace? known}) {
    _settleTimer?.cancel();
    _centre = target;
    _map.move(target, _initialZoom);

    if (known != null) {
      // The search result already carries a full address — no lookup needed.
      _resolveSeq++;
      setState(() {
        _picked = known;
        _resolving = false;
      });
    } else {
      _resolveCentre();
    }
  }

  // ─── Search ─────────────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _results = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _searchTimer = Timer(_searchDebounce, () => _runSearch(value));
  }

  Future<void> _runSearch(String query) async {
    final results = await _geocoder.search(query);
    if (!mounted || _searchController.text != query) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  void _selectResult(GeoPlace place) {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() => _results = const []);
    _moveTo(LatLng(place.latitude, place.longitude), known: place);
  }

  // ─── Confirm ────────────────────────────────────────────────────────────────

  void _confirm() {
    // Coordinates are always valid even when no geocoder resolved an address —
    // the admin can still type the address by hand on the form.
    final place = _picked ??
        GeoPlace(latitude: _centre.latitude, longitude: _centre.longitude);
    Navigator.of(context).pop(place);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: 'Pick location',
              subtitle: 'Move the map to place the pin',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Stack(
                children: [
                  _buildMap(),
                  _buildCentrePin(),
                  _buildSearchOverlay(),
                  _buildMyLocationButton(),
                  _buildAttribution(),
                ],
              ),
            ),
            _buildConfirmBar(),
          ],
        ),
      ),
    );
  }

  // ─── Pieces ─────────────────────────────────────────────────────────────────

  Widget _buildMap() {
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: _centre,
        initialZoom: _initialZoom,
        minZoom: 3,
        maxZoom: 18,
        backgroundColor: AppColors.bgPage,
        onPositionChanged: _onPositionChanged,
        // Rotation would tilt the fixed centre pin and buys nothing here.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'cc.nexotech.new_flutter_project',
          maxNativeZoom: 19,
        ),
      ],
    );
  }

  /// The pin sits at the exact centre of the viewport. Its tip — not its middle
  /// — must land there, so the glyph is nudged up by half its height.
  Widget _buildCentrePin() {
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 34.h),
            Icon(
              Icons.location_on,
              size: 42.sp,
              color: AppColors.danger,
              shadows: const [
                Shadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              width: 8.r,
              height: 8.r,
              decoration: BoxDecoration(
                color: AppColors.fgPrimary.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 12.h,
      left: 14.w,
      right: 14.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 46.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.borderDefault),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                Icon(AppIcons.search, size: 18.sp, color: AppColors.fgTertiary),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (v) => _runSearch(v),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: 'Search area, landmark or pincode',
                      hintStyle: AppText.figtree(
                        size: 14,
                        weight: FontWeight.w500,
                        color: AppColors.fgMuted,
                      ),
                    ),
                    style: AppText.figtree(size: 14, weight: FontWeight.w500),
                  ),
                ),
                if (_searching)
                  SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _results = const []);
                    },
                    child: Icon(AppIcons.close,
                        size: 18.sp, color: AppColors.fgTertiary),
                  ),
              ],
            ),
          ),
          if (_results.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              constraints: BoxConstraints(maxHeight: 240.h),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.borderSoft),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 12,
                      offset: Offset(0, 4)),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 4.h),
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderSoft,
                  indent: 44.w,
                ),
                itemBuilder: (_, i) {
                  final r = _results[i];
                  return InkWell(
                    onTap: () => _selectResult(r),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(AppIcons.pin,
                              size: 18.sp, color: AppColors.fgTertiary),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.figtree(
                                      size: 13, weight: FontWeight.w600),
                                ),
                                if (r.hasPincode) ...[
                                  SizedBox(height: 2.h),
                                  Text(
                                    r.pincode,
                                    style: AppText.figtree(
                                      size: 12,
                                      weight: FontWeight.w500,
                                      color: AppColors.fgTertiary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return Positioned(
      right: 14.w,
      bottom: 16.h,
      child: GestureDetector(
        onTap: _locating ? null : _useMyLocation,
        child: Container(
          width: 44.r,
          height: 44.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: _locating
              ? SizedBox(
                  width: 18.r,
                  height: 18.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.my_location_rounded,
                  size: 20.sp, color: AppColors.fgSecondary),
        ),
      ),
    );
  }

  /// OpenStreetMap's licence requires visible attribution on the map.
  Widget _buildAttribution() {
    return Positioned(
      left: 8.w,
      bottom: 6.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          '© OpenStreetMap contributors',
          style: AppText.figtree(
            size: 9.5,
            weight: FontWeight.w500,
            color: AppColors.fgTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmBar() {
    final place = _picked;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.pin, size: 18.sp, color: AppColors.fgTertiary),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resolving
                            ? 'Finding address…'
                            : (place?.hasAddress ?? false)
                                ? place!.address
                                : 'Address not found — you can type it on the form',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.figtree(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: _resolving || !(place?.hasAddress ?? false)
                              ? AppColors.fgTertiary
                              : AppColors.fgPrimary,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Text(
                            place?.coordsLabel ??
                                GeoPlace(
                                  latitude: _centre.latitude,
                                  longitude: _centre.longitude,
                                ).coordsLabel,
                            style: AppText.figtree(
                              size: 11.5,
                              weight: FontWeight.w500,
                              color: AppColors.fgMuted,
                            ),
                          ),
                          if (place?.hasPincode ?? false) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 7.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.greenBg,
                                borderRadius: BorderRadius.circular(999.r),
                              ),
                              child: Text(
                                'PIN ${place!.pincode}',
                                style: AppText.figtree(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: AppColors.greenFg,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            AppButton(
              label: 'Use this location',
              full: true,
              disabled: _resolving,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:geolocator/geolocator.dart';
import 'package:medicalbooking_portal/features/catalog/domain/repositories/device_location_port.dart';

/// Reads the position from the browser (or the device) with `geolocator`.
///
/// Every failure becomes null: the page offers one message ("No pudimos obtener tu ubicación") and
/// never shows the plugin's internal reason.
class GeolocatorDeviceLocation implements DeviceLocationPort {
  const GeolocatorDeviceLocation({this.timeLimit = const Duration(seconds: 10)});

  final Duration timeLimit;

  @override
  Future<DevicePosition?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: timeLimit),
      );
      return DevicePosition(latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return null;
    }
  }
}

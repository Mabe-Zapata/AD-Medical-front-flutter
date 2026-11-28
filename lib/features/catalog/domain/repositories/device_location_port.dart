/// A position reported by the device.
class DevicePosition {
  const DevicePosition({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Reads the device position for the "nearest branch" feature.
///
/// Returns null when the user denied access, the service is off, or no position arrived in time.
/// The reason is never exposed: the page shows one friendly message for every case.
abstract interface class DeviceLocationPort {
  Future<DevicePosition?> currentPosition();
}

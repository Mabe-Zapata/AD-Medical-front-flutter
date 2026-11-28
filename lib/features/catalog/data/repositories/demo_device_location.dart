import 'package:medicalbooking_portal/features/catalog/domain/repositories/device_location_port.dart';

/// Demo mode has no real device: it reports a fixed position in Quito, between the two demo branches.
/// The page says so, so nobody mistakes the result for a real location.
class DemoDeviceLocation implements DeviceLocationPort {
  const DemoDeviceLocation();

  @override
  Future<DevicePosition?> currentPosition() async => const DevicePosition(latitude: -0.2050, longitude: -78.4900);
}

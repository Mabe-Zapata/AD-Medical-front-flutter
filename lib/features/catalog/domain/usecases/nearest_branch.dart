import 'dart:math' as math;

import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

const _earthRadiusKm = 6371.0;

/// Great-circle distance in kilometres between two coordinates (haversine formula).
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  final dLat = _radians(lat2 - lat1);
  final dLon = _radians(lon2 - lon1);
  final sinLat = math.sin(dLat / 2);
  final sinLon = math.sin(dLon / 2);
  final a = sinLat * sinLat + math.cos(_radians(lat1)) * math.cos(_radians(lat2)) * sinLon * sinLon;
  return 2 * _earthRadiusKm * math.asin(math.sqrt(a));
}

/// The branch closest to a position, or null when no branch has coordinates.
/// Branches without coordinates are skipped rather than guessed.
Branch? nearestBranch(List<Branch> branches, {required double latitude, required double longitude}) {
  Branch? nearest;
  var nearestKm = double.infinity;
  for (final branch in branches) {
    if (!branch.hasCoordinates) continue;
    final km = distanceKm(latitude, longitude, branch.latitude!, branch.longitude!);
    if (km < nearestKm) {
      nearest = branch;
      nearestKm = km;
    }
  }
  return nearest;
}

double _radians(double degrees) => degrees * math.pi / 180;

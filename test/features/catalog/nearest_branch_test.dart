import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/features/catalog/domain/usecases/nearest_branch.dart';

void main() {
  const central = Branch(id: 'central', name: 'Central', address: 'A', latitude: -0.2, longitude: -78.5);
  const north = Branch(id: 'north', name: 'Norte', address: 'B', latitude: -0.1, longitude: -78.5);
  const withoutCoordinates = Branch(id: 'none', name: 'Sin coordenadas', address: 'C');

  test('one degree of latitude is about 111.2 km', () {
    expect(distanceKm(0, 0, 1, 0), closeTo(111.2, 0.2));
  });

  test('the distance between a point and itself is zero', () {
    expect(distanceKm(-0.2, -78.5, -0.2, -78.5), closeTo(0, 1e-9));
  });

  test('returns the branch closest to the given position', () {
    expect(nearestBranch([central, north], latitude: -0.12, longitude: -78.5), north);
  });

  test('a branch without coordinates is never the nearest one', () {
    expect(nearestBranch([withoutCoordinates, central], latitude: -0.2, longitude: -78.5), central);
  });

  test('returns null when no branch has coordinates', () {
    expect(nearestBranch([withoutCoordinates], latitude: -0.2, longitude: -78.5), isNull);
  });

  test('returns null when there are no branches', () {
    expect(nearestBranch(const [], latitude: -0.2, longitude: -78.5), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

/// Tile server for the map. Defaults to the public OpenStreetMap tiles, which are for development only:
/// production must set `--dart-define=MAP_TILE_URL=...` to a provider with its own key (see README).
const _tileUrl = String.fromEnvironment('MAP_TILE_URL', defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');

const _quito = LatLng(-0.2100, -78.4950);

/// Presentational map of the branches that have coordinates. The container decides the nearest branch
/// and the controller moves the camera to it.
class BranchesMap extends StatelessWidget {
  const BranchesMap({super.key, required this.branches, required this.controller, this.nearest});

  final List<Branch> branches;
  final MapController controller;
  final Branch? nearest;

  @override
  Widget build(BuildContext context) {
    final placed = branches.where((branch) => branch.hasCoordinates).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 320,
        child: FlutterMap(
          mapController: controller,
          options: const MapOptions(initialCenter: _quito, initialZoom: 12),
          children: [
            TileLayer(urlTemplate: _tileUrl, userAgentPackageName: 'medilo_portal'),
            MarkerLayer(
              markers: [
                for (final branch in placed)
                  Marker(
                    point: LatLng(branch.latitude!, branch.longitude!),
                    width: 44,
                    height: 44,
                    child: Semantics(
                      label: 'Sucursal ${branch.name}',
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: identical(branch, nearest) ? Tokens.blueDeep : Tokens.orange,
                      ),
                    ),
                  ),
              ],
            ),
            const SimpleAttributionWidget(source: Text('© OpenStreetMap')),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/features/catalog/domain/usecases/nearest_branch.dart';
import 'package:medicalbooking_portal/features/catalog/presentation/widgets/branches_map.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';

/// Container: asks the device for its position and shows the branch closest to it.
/// The position never leaves the browser; it is used only to rank the branches shown here.
class BranchesMapSection extends StatefulWidget {
  const BranchesMapSection({super.key, required this.branches});

  final List<Branch> branches;

  @override
  State<BranchesMapSection> createState() => _BranchesMapSectionState();
}

class _BranchesMapSectionState extends State<BranchesMapSection> {
  final _map = MapController();
  Branch? _nearest;
  String? _message;
  bool _locating = false;

  bool get _hasPlacedBranches => widget.branches.any((branch) => branch.hasCoordinates);

  Future<void> _findNearest() async {
    setState(() {
      _locating = true;
      _message = null;
    });
    final position = await AppScope.of(context).deviceLocation.currentPosition();
    if (!mounted) return;

    if (position == null) {
      setState(() {
        _locating = false;
        _message = 'No pudimos obtener tu ubicación. Revisa que el navegador tenga permiso de ubicación.';
      });
      return;
    }
    final nearest = nearestBranch(widget.branches, latitude: position.latitude, longitude: position.longitude);
    if (nearest == null) {
      setState(() {
        _locating = false;
        _message = 'Ninguna sede tiene su ubicación registrada todavía.';
      });
      return;
    }
    final km = distanceKm(position.latitude, position.longitude, nearest.latitude!, nearest.longitude!);
    _map.move(LatLng(nearest.latitude!, nearest.longitude!), 14);
    setState(() {
      _locating = false;
      _nearest = nearest;
      _message = 'La sede más cercana es ${nearest.name}, a ${km.toStringAsFixed(1)} km de ti.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPlacedBranches) return const SizedBox.shrink();
    final wide = isWide(context);
    final map = BranchesMap(branches: widget.branches, controller: _map, nearest: _nearest);
    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Encuentra tu sede',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
        ),
        const SizedBox(height: 12),
        const Text(
          'Mira dónde quedan nuestras sedes o consulta cuál te queda más cerca.',
          style: TextStyle(fontSize: 15, height: 1.6, color: Tokens.slate600),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _locating ? null : _findNearest,
          icon: const Icon(Icons.near_me_outlined),
          label: Text(_locating ? 'Buscando tu ubicación…' : 'Ver la sede más cercana'),
          style: OutlinedButton.styleFrom(foregroundColor: Tokens.blueText, side: const BorderSide(color: Tokens.blueText)),
        ),
        if (_message != null) ...[
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Text(_message!, style: const TextStyle(fontSize: 15, height: 1.5, color: Tokens.slate900)),
          ),
        ],
      ],
    );
    return Constrained(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Expanded(child: side), const SizedBox(width: 56), Expanded(child: map)],
              )
            : Column(children: [side, const SizedBox(height: 24), map]),
      ),
    );
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }
}

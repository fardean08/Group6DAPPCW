import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/destination.dart';
import '../models/parking_space.dart';
import '../services/parking_service.dart';

class ParkingMap extends StatefulWidget {
  const ParkingMap({
    super.key,
    required this.destination,
    required this.allSpaces,
    required this.visibleResults,
    required this.onMarkerPressed,
  });

  final Destination destination;
  final List<ParkingSpace> allSpaces;
  final List<ParkingResult> visibleResults;
  final ValueChanged<ParkingResult> onMarkerPressed;

  @override
  State<ParkingMap> createState() => _ParkingMapState();
}

class _ParkingMapState extends State<ParkingMap> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
  }

  @override
  void didUpdateWidget(covariant ParkingMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final destinationChanged =
        oldWidget.destination.latitude != widget.destination.latitude ||
        oldWidget.destination.longitude != widget.destination.longitude;
    final resultsChanged =
        oldWidget.visibleResults.length != widget.visibleResults.length;

    if (destinationChanged || resultsChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
    }
  }

  void _fitCamera() {
    final points = [
      LatLng(widget.destination.latitude, widget.destination.longitude),
      ...widget.visibleResults
          .map((r) => LatLng(r.space.latitude, r.space.longitude)),
    ];

    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }

    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(60),
        maxZoom: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinationPoint = LatLng(
      widget.destination.latitude,
      widget.destination.longitude,
    );

    final visibleById = <String, ParkingResult>{
      for (final result in widget.visibleResults) result.space.id: result,
    };

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 360,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: destinationPoint,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.scrollWheelZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName:
                      'com.example.smart_parking_finder_flutter',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: destinationPoint,
                      width: 130,
                      height: 54,
                      child: const _DestinationMarker(),
                    ),
                    ...widget.allSpaces.map((space) {
                      final result = visibleById[space.id];
                      final isVisible = result != null;

                      return Marker(
                        point: LatLng(space.latitude, space.longitude),
                        width: 76,
                        height: 76,
                        child: Opacity(
                          opacity: isVisible ? 1 : 0.35,
                          child: _ParkingMarker(
                            space: space,
                            isVisible: isVisible,
                            onPressed: isVisible
                                ? () => widget.onMarkerPressed(result)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.black12,
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'Real map using OpenStreetMap/CARTO. Dimmed markers are filtered out or full.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black26,
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            'Destination',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ParkingMarker extends StatelessWidget {
  const _ParkingMarker({
    required this.space,
    required this.isVisible,
    required this.onPressed,
  });

  final ParkingSpace space;
  final bool isVisible;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color colour = switch (space.type) {
      'wide' => Colors.cyan.shade700,
      'disabled' => Colors.deepPurple,
      _ => Theme.of(context).colorScheme.primary,
    };

    final Color markerColour = space.availableSpaces == 0
        ? Colors.grey
        : isVisible
            ? colour
            : Colors.grey;

    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: markerColour,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black26,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Text(
                  '${space.availableSpaces}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            constraints: const BoxConstraints(maxWidth: 74),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              space.type,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

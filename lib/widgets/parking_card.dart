import 'package:flutter/material.dart';

import '../services/parking_service.dart';

class ParkingCard extends StatelessWidget {
  const ParkingCard({
    super.key,
    required this.result,
    required this.onDetails,
    required this.onNavigate,
  });

  final ParkingResult result;
  final VoidCallback onDetails;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final space = result.space;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    space.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _AvailabilityBadge(
                  availableSpaces: space.availableSpaces,
                  totalSpaces: space.totalSpaces,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${result.walkingDistanceKm.toStringAsFixed(2)} km walk • '
              '£${space.pricePerHour.toStringAsFixed(2)}/hour • '
              '${space.type}',
            ),
            const SizedBox(height: 4),
            Text(
              'Opening: ${space.openingHours} • '
              'Lighting: ${space.hasLighting ? 'Yes' : 'No'} • '
              'Safety: ${space.safetyScore}/5',
            ),
            const SizedBox(height: 10),
            _OccupancyBar(
              availableSpaces: space.availableSpaces,
              totalSpaces: space.totalSpaces,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
                FilledButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({
    required this.availableSpaces,
    required this.totalSpaces,
  });

  final int availableSpaces;
  final int totalSpaces;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;

    if (availableSpaces <= 5) {
      background = Colors.amber.shade100;
      foreground = Colors.amber.shade900;
    } else {
      background = Colors.green.shade100;
      foreground = Colors.green.shade900;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          availableSpaces == 0
              ? 'No availability'
              : '$availableSpaces/$totalSpaces available',
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _OccupancyBar extends StatelessWidget {
  const _OccupancyBar({
    required this.availableSpaces,
    required this.totalSpaces,
  });

  final int availableSpaces;
  final int totalSpaces;

  @override
  Widget build(BuildContext context) {
    final fraction =
        totalSpaces == 0 ? 0.0 : availableSpaces / totalSpaces;

    final Color barColor;
    if (fraction >= 0.5) {
      barColor = Colors.green.shade600;
    } else if (fraction >= 0.2) {
      barColor = Colors.amber.shade700;
    } else {
      barColor = Colors.red.shade600;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Occupancy', style: Theme.of(context).textTheme.labelSmall),
            Text(
              '${(fraction * 100).round()}% free',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

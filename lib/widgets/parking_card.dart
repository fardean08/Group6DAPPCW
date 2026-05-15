import 'package:flutter/material.dart';

import '../services/parking_service.dart';

/// A card that summarises a single [ParkingResult] in the results list.
///
/// Displays the space name, availability badge, distance, price, type,
/// opening hours, lighting, safety score, an occupancy progress bar, and
/// action buttons for Details and Navigate. An optional favourite heart
/// icon is shown when [onFavouriteToggle] is provided.
class ParkingCard extends StatelessWidget {
  /// Creates a [ParkingCard] for the given [result].
  ///
  /// [onDetails] and [onNavigate] are required callbacks for the two action
  /// buttons. [isFavourite] and [onFavouriteToggle] are optional; the heart
  /// icon is hidden when [onFavouriteToggle] is null.
  const ParkingCard({
    super.key,
    required this.result,
    required this.onDetails,
    required this.onNavigate,
    this.isFavourite = false,
    this.onFavouriteToggle,
  });

  /// The parking result (space + distance) to display.
  final ParkingResult result;

  /// Called when the user taps the Details button.
  final VoidCallback onDetails;

  /// Called when the user taps the Navigate button.
  final VoidCallback onNavigate;

  /// Whether this space is in the user's favourites list.
  final bool isFavourite;

  /// Called when the user taps the heart icon to toggle favourite status.
  ///
  /// The heart icon is only rendered when this is non-null.
  final VoidCallback? onFavouriteToggle;

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
                if (onFavouriteToggle != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      isFavourite ? Icons.favorite : Icons.favorite_border,
                      color: isFavourite ? Colors.red.shade400 : null,
                    ),
                    onPressed: onFavouriteToggle,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ],
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

/// Coloured pill badge showing available vs total spaces.
///
/// Renders amber when 5 or fewer spaces remain, green otherwise.
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

/// Horizontal bar showing what percentage of bays are currently free.
///
/// Colour coding: green ≥ 50 %, amber ≥ 20 %, red < 20 %.
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

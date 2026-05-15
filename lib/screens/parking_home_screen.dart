import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_user.dart';
import '../models/destination.dart';
import '../models/parking_space.dart';
import '../repositories/parking_repository.dart';
import '../services/auth_service.dart';
import '../services/geocoding_service.dart';
import '../services/parking_service.dart';
import '../widgets/parking_card.dart';
import '../widgets/parking_map.dart';

class ParkingHomeScreen extends StatefulWidget {
  const ParkingHomeScreen({
    super.key,
    required this.user,
    required this.authService,
    required this.repository,
    required this.firebaseReady,
  });

  final AppUser user;
  final AuthService authService;
  final ParkingRepository repository;
  final bool firebaseReady;

  @override
  State<ParkingHomeScreen> createState() => _ParkingHomeScreenState();
}

class _ParkingHomeScreenState extends State<ParkingHomeScreen> {
  final _parkingService = const ParkingService();
  final _geocodingService = const GeocodingService();

  final _destinationController =
      TextEditingController(text: 'Gillingham High Street');
  double _maxPrice = 3.00;
  double _maxDistance = 2.00;

  Destination _destination = const Destination(
    name: 'Gillingham High Street',
    latitude: 51.3890,
    longitude: 0.5486,
  );

  List<ParkingSpace> _spaces = [];
  List<ParkingResult> _results = [];
  List<ParkingSpace> _alerts = [];

  Timer? _timer;
  String _selectedType = 'any';
  bool _requiresLighting = false;
  ParkingSortOrder _sortOrder = ParkingSortOrder.distance;

  static const _recentKey = 'recent_destinations';
  List<Destination> _recentDestinations = [];

  static const _favKey = 'favourite_spaces';
  Set<String> _favouriteIds = {};
  bool _favouritesOnly = false;
  bool _isLoading = true;
  bool _isSearching = false;
  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadFavourites();
    _loadRecents();
    _loadDestination(_destination);

    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshAvailability(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favKey);
    if (raw == null || !mounted) return;
    setState(() {
      _favouriteIds = (jsonDecode(raw) as List).cast<String>().toSet();
    });
  }

  Future<void> _toggleFavourite(String id) async {
    final updated = Set<String>.from(_favouriteIds);
    if (updated.contains(id)) { updated.remove(id); } else { updated.add(id); }
    setState(() => _favouriteIds = updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favKey, jsonEncode(updated.toList()));
    _applyFilters();
  }

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentKey);
    if (raw == null || !mounted) return;
    final list = jsonDecode(raw) as List;
    setState(() {
      _recentDestinations = list.map((e) => Destination(
        name: e['name'] as String,
        latitude: (e['lat'] as num).toDouble(),
        longitude: (e['lon'] as num).toDouble(),
      )).toList();
    });
  }

  Future<void> _addToRecents(Destination destination) async {
    final updated = [
      destination,
      ..._recentDestinations.where((d) => d.name != destination.name),
    ].take(5).toList();
    setState(() => _recentDestinations = updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recentKey, jsonEncode([
      for (final d in updated)
        {'name': d.name, 'lat': d.latitude, 'lon': d.longitude},
    ]));
  }

  Future<void> _loadDestination(Destination destination) async {
    setState(() {
      _isLoading = true;
      _destination = destination;
    });

    List<ParkingSpace> spaces = [];

    try {
      spaces = await widget.repository.fetchParkingSpaces(destination.key);
    } catch (_) {
      spaces = [];
    }

    if (spaces.isEmpty) {
      spaces = _parkingService.generateParkingSpaces(destination);

      try {
        await widget.repository.replaceParkingSpaces(
          destinationKey: destination.key,
          spaces: spaces,
        );
      } catch (_) {
        // Keep the generated data even if persistence is unavailable.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _spaces = spaces;
      _alerts = _parkingService.spacesWithNewAvailability(spaces);
      _lastUpdated = DateTime.now();
      _isLoading = false;
    });

    _applyFilters();
  }

  Future<void> _searchDestination() async {
    final query = _destinationController.text.trim();

    if (query.isEmpty) {
      _showSnackBar('Enter a destination first.');
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final destination = await _geocodingService.searchDestination(query);
      await _loadDestination(destination);
      await _addToRecents(destination);
    } catch (error) {
      _showSnackBar(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      var results = _parkingService.filterParkingSpaces(
        destination: _destination,
        spaces: _spaces,
        maxPrice: _maxPrice,
        maxDistanceKm: _maxDistance,
        type: _selectedType,
        requiresLighting: _requiresLighting,
        sortOrder: _sortOrder,
      );
      if (_favouritesOnly) {
        results = results
            .where((r) => _favouriteIds.contains(r.space.id))
            .toList();
      }
      _results = results;
    });
  }

  Future<void> _refreshAvailability() async {
    if (_spaces.isEmpty) {
      return;
    }

    final updated = _parkingService.refreshAvailability(_spaces);

    await widget.repository.replaceParkingSpaces(
      destinationKey: _destination.key,
      spaces: updated,
    );

    setState(() {
      _spaces = updated;
      _alerts = _parkingService.spacesWithNewAvailability(updated);
      _lastUpdated = DateTime.now();
    });

    _applyFilters();
  }

  void _applyPreset(String preset) {
    setState(() {
      switch (preset) {
        case 'evening':
          _requiresLighting = true;
          _sortOrder = ParkingSortOrder.safetyScore;
        case 'cheap':
          _maxPrice = 1.50;
          _sortOrder = ParkingSortOrder.price;
        case 'accessible':
          _selectedType = 'disabled';
          _maxDistance = 5.0;
      }
    });
    _applyFilters();
  }

  void _resetFilters() {
    setState(() {
      _maxPrice = 3.00;
      _maxDistance = 2.00;
      _selectedType = 'any';
      _requiresLighting = false;
      _sortOrder = ParkingSortOrder.distance;
      _favouritesOnly = false;
    });

    _applyFilters();
  }

  Future<void> _openNavigation(ParkingSpace space) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${space.latitude},${space.longitude}',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar('Could not open Google Maps.');
    }
  }

  void _showDetails(ParkingResult result) {
    final space = result.space;
    final availability =
        space.availableSpaces == 0
            ? 'No availability'
            : '${space.availableSpaces}/${space.totalSpaces} available';
    final availabilityColor =
        space.availableSpaces == 0
            ? Colors.red.shade700
            : space.availableSpaces <= 5
                ? Colors.orange.shade700
                : Colors.green.shade700;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF9FAFB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_parking_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              space.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: availabilityColor.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Text(
                                  availability,
                                  style: TextStyle(
                                    color: availabilityColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    space.notes,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Parking details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _DetailsGrid(result: result),
                  const SizedBox(height: 14),
                  Text(
                    'Restrictions: ${space.restrictions}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _openNavigation(space),
                          icon: const Icon(Icons.navigation),
                          label: const Text('Navigate'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int get _totalAvailable {
    return _results.fold(
      0,
      (total, result) => total + result.space.availableSpaces,
    );
  }

  double get _averagePrice {
    if (_results.isEmpty) {
      return 0;
    }

    final total = _results.fold<double>(
      0,
      (sum, result) => sum + result.space.pricePerHour,
    );

    return total / _results.length;
  }

  double get _nearestDistance {
    if (_results.isEmpty) {
      return 0;
    }

    return _results.first.walkingDistanceKm;
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.firebaseReady
        ? 'Firebase connected'
        : 'Local fallback mode - configure Firebase for production demo';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Parking Finder'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(widget.user.name),
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: widget.authService.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshAvailability,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeroSection(
                    subtitle: subtitle,
                    onRefresh: _refreshAvailability,
                    onReset: _resetFilters,
                  ),
                  const SizedBox(height: 14),
                  _DestinationSearch(
                    controller: _destinationController,
                    destination: _destination,
                    isSearching: _isSearching,
                    onSearch: _searchDestination,
                    recentDestinations: _recentDestinations,
                    onRecentSelected: (d) {
                      _destinationController.text = d.name;
                      _loadDestination(d);
                    },
                  ),
                  const SizedBox(height: 14),
                  _StatsRow(
                    totalAvailable: _totalAvailable,
                    averagePrice: _averagePrice,
                    nearestDistance: _nearestDistance,
                    lastUpdated: _lastUpdated,
                  ),
                  const SizedBox(height: 14),
                  _FiltersSection(
                    maxPrice: _maxPrice,
                    maxDistance: _maxDistance,
                    selectedType: _selectedType,
                    requiresLighting: _requiresLighting,
                    sortOrder: _sortOrder,
                    onPriceChanged: (v) {
                      setState(() => _maxPrice = v);
                      _applyFilters();
                    },
                    onDistanceChanged: (v) {
                      setState(() => _maxDistance = v);
                      _applyFilters();
                    },
                    onTypeChanged: (value) {
                      setState(() => _selectedType = value ?? 'any');
                      _applyFilters();
                    },
                    onLightingChanged: (value) {
                      setState(() => _requiresLighting = value);
                      _applyFilters();
                    },
                    onSortChanged: (value) {
                      setState(() => _sortOrder = value ?? ParkingSortOrder.distance);
                      _applyFilters();
                    },
                    favouritesOnly: _favouritesOnly,
                    onFavouritesOnlyChanged: (value) {
                      setState(() => _favouritesOnly = value);
                      _applyFilters();
                    },
                    onPresetSelected: _applyPreset,
                  ),
                  const SizedBox(height: 14),
                  if (_alerts.isNotEmpty) _AlertSection(alerts: _alerts),
                  const SizedBox(height: 14),
                  Text(
                    'Parking map',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ParkingMap(
                    destination: _destination,
                    allSpaces: _spaces,
                    visibleResults: _results,
                    onMarkerPressed: _showDetails,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_results.length} available parking result${_results.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  if (_results.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'No parking spaces match the current filters. Try increasing distance or price.',
                        ),
                      ),
                    )
                  else
                    ..._results.map(
                      (result) => ParkingCard(
                        result: result,
                        isFavourite: _favouriteIds.contains(result.space.id),
                        onFavouriteToggle: () => _toggleFavourite(result.space.id),
                        onDetails: () => _showDetails(result),
                        onNavigate: () => _openNavigation(result.space),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.subtitle,
    required this.onRefresh,
    required this.onReset,
  });

  final String subtitle;
  final VoidCallback onRefresh;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SETaP Team 6D Prototype',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              'Find parking faster',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 8),
            const Text(
              'Search a destination, compare spaces on a real map, check details and navigate to a selected space.',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh availability'),
                ),
                OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationSearch extends StatelessWidget {
  const _DestinationSearch({
    required this.controller,
    required this.destination,
    required this.isSearching,
    required this.onSearch,
    required this.recentDestinations,
    required this.onRecentSelected,
  });

  final TextEditingController controller;
  final Destination destination;
  final bool isSearching;
  final VoidCallback onSearch;
  final List<Destination> recentDestinations;
  final ValueChanged<Destination> onRecentSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Search destination',
                hintText: 'Example: Portsmouth Guildhall',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => onSearch(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSearching ? null : onSearch,
                icon: isSearching
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: const Text('Search area'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current destination: ${destination.name}',
              textAlign: TextAlign.center,
            ),
            if (recentDestinations.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: recentDestinations.map((d) {
                  return ActionChip(
                    label: Text(d.name.split(',').first.trim()),
                    onPressed: () => onRecentSelected(d),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.totalAvailable,
    required this.averagePrice,
    required this.nearestDistance,
    required this.lastUpdated,
  });

  final int totalAvailable;
  final double averagePrice;
  final double nearestDistance;
  final DateTime lastUpdated;

  @override
  Widget build(BuildContext context) {
    final time =
        '${lastUpdated.hour.toString().padLeft(2, '0')}:${lastUpdated.minute.toString().padLeft(2, '0')}:${lastUpdated.second.toString().padLeft(2, '0')}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWide ? 4 : 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isWide ? 2.3 : 1.8,
          children: [
            _StatCard(label: 'Total spaces', value: '$totalAvailable'),
            _StatCard(
              label: 'Average price',
              value: '£${averagePrice.toStringAsFixed(2)}',
            ),
            _StatCard(
              label: 'Nearest space',
              value: '${nearestDistance.toStringAsFixed(2)} km',
            ),
            _StatCard(label: 'Last refresh', value: time),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _FiltersSection extends StatelessWidget {
  const _FiltersSection({
    required this.maxPrice,
    required this.maxDistance,
    required this.selectedType,
    required this.requiresLighting,
    required this.sortOrder,
    required this.onPriceChanged,
    required this.onDistanceChanged,
    required this.onTypeChanged,
    required this.onLightingChanged,
    required this.onSortChanged,
    required this.favouritesOnly,
    required this.onFavouritesOnlyChanged,
    required this.onPresetSelected,
  });

  final double maxPrice;
  final double maxDistance;
  final String selectedType;
  final bool requiresLighting;
  final ParkingSortOrder sortOrder;
  final bool favouritesOnly;
  final ValueChanged<double> onPriceChanged;
  final ValueChanged<double> onDistanceChanged;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<bool> onLightingChanged;
  final ValueChanged<ParkingSortOrder?> onSortChanged;
  final ValueChanged<bool> onFavouritesOnlyChanged;
  final ValueChanged<String> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick filters',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.nightlight_round, size: 16),
                  label: const Text('Evening'),
                  onPressed: () => onPresetSelected('evening'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.savings_outlined, size: 16),
                  label: const Text('Cheap'),
                  onPressed: () => onPresetSelected('cheap'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.accessible, size: 16),
                  label: const Text('Accessible'),
                  onPressed: () => onPresetSelected('accessible'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Max price / hour'),
                Text(
                  '£${maxPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Slider(
              value: maxPrice,
              min: 0.50,
              max: 5.00,
              divisions: 9,
              label: '£${maxPrice.toStringAsFixed(2)}',
              onChanged: onPriceChanged,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Max walking distance'),
                Text(
                  '${maxDistance.toStringAsFixed(1)} km',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Slider(
              value: maxDistance,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              label: '${maxDistance.toStringAsFixed(1)} km',
              onChanged: onDistanceChanged,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Space type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'any', child: Text('Any')),
                DropdownMenuItem(value: 'standard', child: Text('Standard')),
                DropdownMenuItem(value: 'wide', child: Text('Wide')),
                DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
              ],
              onChanged: onTypeChanged,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ParkingSortOrder>(
              value: sortOrder,
              decoration: const InputDecoration(
                labelText: 'Sort by',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: ParkingSortOrder.distance,
                  child: Text('Nearest first'),
                ),
                DropdownMenuItem(
                  value: ParkingSortOrder.price,
                  child: Text('Cheapest first'),
                ),
                DropdownMenuItem(
                  value: ParkingSortOrder.safetyScore,
                  child: Text('Safest first'),
                ),
              ],
              onChanged: onSortChanged,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: requiresLighting,
              title: const Text('Lighting required'),
              onChanged: onLightingChanged,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: favouritesOnly,
              title: const Text('Favourites only'),
              secondary: const Icon(Icons.favorite),
              onChanged: onFavouritesOnlyChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertSection extends StatelessWidget {
  const _AlertSection({
    required this.alerts,
  });

  final List<ParkingSpace> alerts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: alerts.map((space) {
        return Card(
          elevation: 0,
          color: Colors.amber.shade100,
          child: ListTile(
            leading: const Icon(Icons.notifications_active),
            title: Text('${space.name} now has spaces available.'),
            subtitle: Text('${space.availableSpaces} spaces currently free.'),
          ),
        );
      }).toList(),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({
    required this.result,
  });

  final ParkingResult result;

  @override
  Widget build(BuildContext context) {
    final space = result.space;

    final details = <({IconData icon, String label, String value})>[
      (
        icon: Icons.payments_outlined,
        label: 'Price',
        value: '£${space.pricePerHour.toStringAsFixed(2)} / hour',
      ),
      (
        icon: Icons.social_distance_outlined,
        label: 'Walking distance',
        value: '${result.walkingDistanceKm.toStringAsFixed(2)} km',
      ),
      (icon: Icons.category_outlined, label: 'Type', value: space.type),
      (
        icon: Icons.schedule_outlined,
        label: 'Opening hours',
        value: space.openingHours,
      ),
      (
        icon: Icons.light_outlined,
        label: 'Lighting',
        value: space.hasLighting ? 'Available' : 'Not available',
      ),
      (
        icon: Icons.shield_outlined,
        label: 'Safety score',
        value: '${space.safetyScore}/5',
      ),
      (icon: Icons.straighten_outlined, label: 'Bay width', value: space.bayWidth),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: details.map((entry) {
        return _DetailTile(
          icon: entry.icon,
          label: entry.label,
          value: entry.value,
        );
      }).toList(),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 60) / 2;

    return Container(
      width: width.clamp(150.0, 340.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

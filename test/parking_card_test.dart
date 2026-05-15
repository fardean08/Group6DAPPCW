import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking_finder_flutter/models/parking_space.dart';
import 'package:smart_parking_finder_flutter/services/parking_service.dart';
import 'package:smart_parking_finder_flutter/widgets/parking_card.dart';

void main() {
  const space = ParkingSpace(
    id: 'p1',
    name: 'Central Car Park',
    latitude: 50.7984,
    longitude: -1.0911,
    pricePerHour: 2.80,
    availableSpaces: 34,
    previousAvailableSpaces: 30,
    totalSpaces: 120,
    type: 'standard',
    hasLighting: true,
    safetyScore: 4,
    openingHours: '24 hours',
    restrictions: 'Maximum stay 6 hours',
    bayWidth: 'standard',
    notes: 'Close to the main destination area.',
  );

  const result = ParkingResult(space: space, walkingDistanceKm: 0.35);

  Widget buildCard({VoidCallback? onDetails, VoidCallback? onNavigate}) {
    return MaterialApp(
      home: Scaffold(
        body: ParkingCard(
          result: result,
          onDetails: onDetails ?? () {},
          onNavigate: onNavigate ?? () {},
        ),
      ),
    );
  }

  group('ParkingCard', () {
    testWidgets('shows the parking space name', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('Central Car Park'), findsOneWidget);
    });

    testWidgets('shows walking distance and price in summary line', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.textContaining('0.35 km'), findsOneWidget);
      expect(find.textContaining('£2.80/hour'), findsOneWidget);
    });

    testWidgets('shows opening hours and safety score', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.textContaining('24 hours'), findsOneWidget);
      expect(find.textContaining('Safety: 4/5'), findsOneWidget);
    });

    testWidgets('shows Lighting Yes when hasLighting is true', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.textContaining('Lighting: Yes'), findsOneWidget);
    });

    testWidgets('shows Lighting No when hasLighting is false', (tester) async {
      const dim = ParkingSpace(
        id: 'p2', name: 'Dark Park', latitude: 50.8, longitude: -1.1,
        pricePerHour: 1.0, availableSpaces: 10, previousAvailableSpaces: 10,
        totalSpaces: 50, type: 'standard', hasLighting: false, safetyScore: 2,
        openingHours: '24 hours', restrictions: 'None', bayWidth: 'standard', notes: '',
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ParkingCard(
            result: const ParkingResult(space: dim, walkingDistanceKm: 0.2),
            onDetails: () {},
            onNavigate: () {},
          ),
        ),
      ));
      expect(find.textContaining('Lighting: No'), findsOneWidget);
    });

    testWidgets('availability badge shows count when spaces are available', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('34/120 available'), findsOneWidget);
    });

    testWidgets('availability badge shows No availability when spaces is zero', (tester) async {
      const full = ParkingSpace(
        id: 'p3', name: 'Full Park', latitude: 50.8, longitude: -1.1,
        pricePerHour: 1.0, availableSpaces: 0, previousAvailableSpaces: 0,
        totalSpaces: 50, type: 'standard', hasLighting: true, safetyScore: 3,
        openingHours: '24 hours', restrictions: 'None', bayWidth: 'standard', notes: '',
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ParkingCard(
            result: const ParkingResult(space: full, walkingDistanceKm: 0.1),
            onDetails: () {},
            onNavigate: () {},
          ),
        ),
      ));
      expect(find.text('No availability'), findsOneWidget);
    });

    testWidgets('calls onDetails when Details button is tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(buildCard(onDetails: () => called = true));
      await tester.tap(find.text('Details'));
      expect(called, true);
    });

    testWidgets('calls onNavigate when Navigate button is tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(buildCard(onNavigate: () => called = true));
      await tester.tap(find.text('Navigate'));
      expect(called, true);
    });
  });
}

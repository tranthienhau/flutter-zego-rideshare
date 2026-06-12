import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_zego_rideshare/main.dart';
import 'package:flutter_zego_rideshare/mock_data.dart';
import 'package:flutter_zego_rideshare/models.dart';
import 'package:flutter_zego_rideshare/ride_provider.dart';

/// Test-only controller seeded with an already-matched ride so the screenshots
/// show a populated active ride (driver + ZEGO call mask + Stripe split)
/// without waiting on the production state-machine timers.
class SeededRideController extends RideController {
  SeededRideController() {
    final pickup = MockData.places[0];
    final dropoff = MockData.places[1];
    final distanceKm = MockData.haversineKm(pickup.coords, dropoff.coords);
    final etaMinutes = (distanceKm * 3).round().clamp(3, 60);
    state = Ride(
      id: 'ride_demo',
      pickup: pickup,
      dropoff: dropoff,
      status: RideStatus.enRoute,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      fare: MockData.computeFare(distanceKm, etaMinutes),
      driver: MockData.drivers.first,
      callMask: CallMask(
        proxyNumber: '+84-9000-4271',
        zegoToken: 'zego_ride_demo_8f2a91c4d7e6b035a1f2',
        expiresAt: DateTime(2026, 6, 12, 18, 30),
      ),
    );
  }

  @override
  void requestRide(Place pickup, Place dropoff) {}

  @override
  void cancel() {}
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shoot(WidgetTester tester, String name) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pump(const Duration(milliseconds: 400));
    await binding.takeScreenshot(name);
  }

  // 01 - Home: empty request state (map + pickup/dropoff + request button).
  testWidgets('capture home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RideshareApp()));
    await tester.pump(const Duration(milliseconds: 400));
    await shoot(tester, '01-home');
  });

  // 02 + 03 - Seeded active ride so the populated ride card + ZEGO call mask
  // render deterministically (a fresh ProviderContainer per testWidgets block).
  testWidgets('capture active ride and ZEGO call mask', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rideControllerProvider.overrideWith((ref) => SeededRideController()),
        ],
        child: const RideshareApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // 02 - Active ride: driver matched, fare split, Stripe breakdown.
    await shoot(tester, '02-ride-matched');

    // Open the ZEGO call masking bottom sheet via the call button.
    final callBtn = find.byIcon(Icons.call_outlined);
    await tester.ensureVisible(callBtn);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(callBtn, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 600));

    // 03 - ZEGO call masking sheet with proxy number + token.
    await shoot(tester, '03-zego-call-mask');
  });
}

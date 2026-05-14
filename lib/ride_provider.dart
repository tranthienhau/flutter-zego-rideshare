import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_data.dart';
import 'models.dart';

class RideController extends StateNotifier<Ride?> {
  RideController() : super(null);

  Timer? _statusTimer;

  void requestRide(Place pickup, Place dropoff) {
    final distanceKm = MockData.haversineKm(pickup.coords, dropoff.coords);
    final etaMinutes = (distanceKm * 3).round().clamp(3, 60);
    final fare = MockData.computeFare(distanceKm, etaMinutes);
    state = Ride(
      id: 'ride_${DateTime.now().millisecondsSinceEpoch}',
      pickup: pickup,
      dropoff: dropoff,
      status: RideStatus.requested,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      fare: fare,
    );
    _scheduleNext(const Duration(seconds: 2), () => _matchDriver());
  }

  void _matchDriver() {
    if (state == null) return;
    state!.driver = MockData.drivers.first;
    state!.status = RideStatus.matched;
    state!.callMask = CallMask(
      proxyNumber: '+84-9000-${(1000 + DateTime.now().millisecond % 8999)}',
      zegoToken: 'zego_${state!.id}_${DateTime.now().millisecondsSinceEpoch}',
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );
    state = state;
    _scheduleNext(const Duration(seconds: 3), () => _advance(RideStatus.enRoute));
  }

  void _advance(RideStatus next) {
    if (state == null) return;
    state!.status = next;
    state = state;
    if (next == RideStatus.enRoute) {
      _scheduleNext(const Duration(seconds: 4), () => _advance(RideStatus.arrived));
    } else if (next == RideStatus.arrived) {
      _scheduleNext(const Duration(seconds: 3), () => _advance(RideStatus.inProgress));
    } else if (next == RideStatus.inProgress) {
      _scheduleNext(const Duration(seconds: 5), () => _advance(RideStatus.completed));
    }
  }

  void cancel() {
    _statusTimer?.cancel();
    if (state != null) {
      state!.status = RideStatus.cancelled;
      state = state;
    }
  }

  void _scheduleNext(Duration delay, void Function() action) {
    _statusTimer?.cancel();
    _statusTimer = Timer(delay, action);
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }
}

final rideControllerProvider =
    StateNotifierProvider<RideController, Ride?>((ref) => RideController());

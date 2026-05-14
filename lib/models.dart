enum RideStatus {
  requested,
  matched,
  enRoute,
  arrived,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case RideStatus.requested:
        return 'Requesting';
      case RideStatus.matched:
        return 'Driver matched';
      case RideStatus.enRoute:
        return 'En route';
      case RideStatus.arrived:
        return 'Arrived';
      case RideStatus.inProgress:
        return 'In trip';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class LatLng {
  const LatLng(this.lat, this.lng);
  final double lat;
  final double lng;
}

class Place {
  const Place({required this.label, required this.address, required this.coords});
  final String label;
  final String address;
  final LatLng coords;
}

class Driver {
  const Driver({
    required this.id,
    required this.name,
    required this.vehicle,
    required this.plate,
    required this.rating,
    required this.coords,
    required this.stripeAccountId,
  });
  final String id;
  final String name;
  final String vehicle;
  final String plate;
  final double rating;
  final LatLng coords;
  final String stripeAccountId;
}

class CallMask {
  const CallMask({
    required this.proxyNumber,
    required this.zegoToken,
    required this.expiresAt,
  });
  final String proxyNumber;
  final String zegoToken;
  final DateTime expiresAt;
}

class FareBreakdown {
  const FareBreakdown({
    required this.baseCents,
    required this.distanceCents,
    required this.timeCents,
    required this.platformFeeCents,
    required this.driverNetCents,
  });
  final int baseCents;
  final int distanceCents;
  final int timeCents;
  final int platformFeeCents;
  final int driverNetCents;

  int get totalCents => baseCents + distanceCents + timeCents;
}

class Ride {
  Ride({
    required this.id,
    required this.pickup,
    required this.dropoff,
    required this.status,
    required this.distanceKm,
    required this.etaMinutes,
    required this.fare,
    this.driver,
    this.callMask,
  });

  final String id;
  final Place pickup;
  final Place dropoff;
  RideStatus status;
  final double distanceKm;
  final int etaMinutes;
  final FareBreakdown fare;
  Driver? driver;
  CallMask? callMask;
}

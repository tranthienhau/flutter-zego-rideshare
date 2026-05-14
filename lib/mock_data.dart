import 'models.dart';

class MockData {
  static const places = [
    Place(
      label: 'Home',
      address: '12 Nguyen Hue, District 1, HCMC',
      coords: LatLng(10.7769, 106.7009),
    ),
    Place(
      label: 'Tan Son Nhat Airport',
      address: 'Truong Son, Tan Binh, HCMC',
      coords: LatLng(10.8188, 106.6519),
    ),
    Place(
      label: 'Saigon Centre',
      address: '65 Le Loi, District 1, HCMC',
      coords: LatLng(10.7717, 106.7019),
    ),
    Place(
      label: 'Vincom Center',
      address: '72 Le Thanh Ton, District 1, HCMC',
      coords: LatLng(10.7795, 106.7011),
    ),
    Place(
      label: 'Bui Vien',
      address: 'Bui Vien, Pham Ngu Lao, District 1',
      coords: LatLng(10.7676, 106.6925),
    ),
  ];

  static const drivers = [
    Driver(
      id: 'drv_001',
      name: 'Minh Tran',
      vehicle: 'Honda City 2022',
      plate: '51F-123.45',
      rating: 4.92,
      coords: LatLng(10.7780, 106.6990),
      stripeAccountId: 'acct_1NaBcMinh',
    ),
    Driver(
      id: 'drv_002',
      name: 'Phuong Nguyen',
      vehicle: 'Toyota Vios 2023',
      plate: '59A-987.65',
      rating: 4.87,
      coords: LatLng(10.7755, 106.7030),
      stripeAccountId: 'acct_1NaBcPhuong',
    ),
    Driver(
      id: 'drv_003',
      name: 'Khoa Le',
      vehicle: 'Mitsubishi Xpander',
      plate: '50H-456.78',
      rating: 4.95,
      coords: LatLng(10.7810, 106.7000),
      stripeAccountId: 'acct_1NaBcKhoa',
    ),
  ];

  static FareBreakdown computeFare(double distanceKm, int etaMinutes) {
    const baseCents = 1500;
    final distanceCents = (distanceKm * 800).round();
    final timeCents = etaMinutes * 200;
    final total = baseCents + distanceCents + timeCents;
    final platformFee = (total * 0.15).round();
    final driverNet = total - platformFee;
    return FareBreakdown(
      baseCents: baseCents,
      distanceCents: distanceCents,
      timeCents: timeCents,
      platformFeeCents: platformFee,
      driverNetCents: driverNet,
    );
  }

  static double haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _radians(b.lat - a.lat);
    final dLng = _radians(b.lng - a.lng);
    final h = (1 - _cos(dLat)) / 2 +
        _cos(_radians(a.lat)) *
            _cos(_radians(b.lat)) *
            (1 - _cos(dLng)) /
            2;
    return 2 * r * _asin(_sqrt(h));
  }

  static double _radians(double deg) => deg * 3.141592653589793 / 180;
  static double _cos(double x) => _math(x, true);
  static double _math(double x, bool cos) {
    // Fallback - use dart:math in real code. POC uses naive Taylor expansion.
    double sum = 0;
    double term = cos ? 1 : x;
    for (var i = 0; i < 10; i++) {
      sum += term;
      final next = i + 1;
      final base = cos ? (2 * next - 1) * (2 * next) : (2 * next) * (2 * next + 1);
      term *= -x * x / base;
    }
    return sum;
  }

  static double _asin(double x) {
    double sum = x;
    double term = x;
    for (var n = 1; n < 8; n++) {
      term *= x * x * (2 * n - 1) / (2 * n);
      sum += term / (2 * n + 1);
    }
    return sum;
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double g = x;
    for (var i = 0; i < 20; i++) {
      g = (g + x / g) / 2;
    }
    return g;
  }
}

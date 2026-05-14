import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'mock_data.dart';
import 'models.dart';
import 'ride_provider.dart';

void main() {
  runApp(const ProviderScope(child: RideshareApp()));
}

class RideshareApp extends StatelessWidget {
  const RideshareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gride Rideshare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0F766E),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF14B8A6),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Place pickup = MockData.places[0];
  Place dropoff = MockData.places[1];

  @override
  Widget build(BuildContext context) {
    final ride = ref.watch(rideControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Gride')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _MapPreview(),
          const SizedBox(height: 12),
          _PlacePicker(
            label: 'Pickup',
            place: pickup,
            onChange: (p) => setState(() => pickup = p),
          ),
          const SizedBox(height: 8),
          _PlacePicker(
            label: 'Dropoff',
            place: dropoff,
            onChange: (p) => setState(() => dropoff = p),
          ),
          const SizedBox(height: 16),
          if (ride == null)
            FilledButton.icon(
              icon: const Icon(Icons.directions_car_filled),
              label: const Text('Request ride'),
              onPressed: pickup.label == dropoff.label
                  ? null
                  : () => ref
                      .read(rideControllerProvider.notifier)
                      .requestRide(pickup, dropoff),
            )
          else
            _RideCard(ride: ride),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDDF1EE), Color(0xFFB5DCD6)],
        ),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(Icons.map_outlined, size: 64, color: Color(0xFF0F766E)),
          ),
          Positioned(
            bottom: 8,
            left: 12,
            child: Text(
              'Google Maps preview (mock)',
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacePicker extends StatelessWidget {
  const _PlacePicker({
    required this.label,
    required this.place,
    required this.onChange,
  });
  final String label;
  final Place place;
  final ValueChanged<Place> onChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(
          '${place.label} - ${place.address}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.swap_horiz),
        onTap: () async {
          final selected = await showModalBottomSheet<Place>(
            context: context,
            builder: (_) => ListView(
              children: [
                for (final p in MockData.places)
                  ListTile(
                    title: Text(p.label),
                    subtitle: Text(p.address),
                    onTap: () => Navigator.of(context).pop(p),
                  ),
              ],
            ),
          );
          if (selected != null) onChange(selected);
        },
      ),
    );
  }
}

class _RideCard extends ConsumerWidget {
  const _RideCard({required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat.simpleCurrency();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusDot(status: ride.status),
                const SizedBox(width: 8),
                Text(ride.status.label,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text('${ride.distanceKm.toStringAsFixed(1)} km · ETA ${ride.etaMinutes} min'),
            const SizedBox(height: 12),
            if (ride.driver != null) _DriverRow(ride: ride),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Fare'),
                Text(fmt.format(ride.fare.totalCents / 100),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Platform fee (15%)',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(fmt.format(ride.fare.platformFeeCents / 100),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Driver payout',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(fmt.format(ride.fare.driverNetCents / 100),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            if (ride.status == RideStatus.completed)
              FilledButton.icon(
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Pay with Apple Pay / Google Pay'),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stripe PaymentIntent split confirmed (mocked)')),
                ),
              )
            else if (ride.status == RideStatus.cancelled)
              const Text('Ride cancelled.')
            else
              OutlinedButton(
                onPressed: () => ref.read(rideControllerProvider.notifier).cancel(),
                child: const Text('Cancel ride'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final d = ride.driver!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0F766E),
              child: Text(
                d.name[0],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${d.vehicle} · ${d.plate}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    Text(' ${d.rating}',
                        style: const TextStyle(fontSize: 12)),
                  ]),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.call_outlined),
              onPressed: () => _showCallMask(context, ride),
            ),
          ],
        ),
      ],
    );
  }

  void _showCallMask(BuildContext context, Ride ride) {
    final mask = ride.callMask;
    if (mask == null) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ZEGO call masking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'Neither party sees the other\'s real number. ZEGO bridges the call server-side.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.phone_in_talk_outlined, color: Color(0xFF0F766E)),
              const SizedBox(width: 12),
              Text(mask.proxyNumber,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            Text('Expires ${DateFormat.jm().format(mask.expiresAt)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('zegoToken: ${mask.zegoToken.substring(0, 24)}...',
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.call),
              label: const Text('Call via proxy'),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ZEGO call session started (mocked)')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final RideStatus status;

  Color _color() {
    switch (status) {
      case RideStatus.requested:
        return Colors.amber;
      case RideStatus.matched:
      case RideStatus.enRoute:
      case RideStatus.arrived:
      case RideStatus.inProgress:
        return const Color(0xFF0F766E);
      case RideStatus.completed:
        return const Color(0xFF16A34A);
      case RideStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: _color(), shape: BoxShape.circle),
    );
  }
}

/// WMATA fare presets on the DC Metro Station's 1-tap fare buttons.
enum MetroFare {
  shortHop('Short Hop', 'under 3 mi', 225),
  weekendMax('Weekend Max Cap', 'over 3 mi', 250),
  weekdayMax('Weekday Max Cap', '13+ mi', 675),
  custom('Custom Fare', 'any amount', 0);

  const MetroFare(this.label, this.detail, this.cents);

  final String label;
  final String detail;

  /// Preset fare in cents (0 for [custom]).
  final int cents;

  static MetroFare parse(String? raw) =>
      values.firstWhere((f) => f.name == raw, orElse: () => MetroFare.custom);
}

/// One paid Metro ride (transit spend tracking).
class MetroRide {
  const MetroRide({
    required this.id,
    required this.fare,
    required this.amountCents,
    required this.rideAt,
  });

  final String id;
  final MetroFare fare;
  final int amountCents;
  final DateTime rideAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'fare': fare.name,
        'amount_cents': amountCents,
        'ride_at': rideAt.toIso8601String(),
      };

  factory MetroRide.fromMap(Map<String, Object?> m) => MetroRide(
        id: m['id']! as String,
        fare: MetroFare.parse(m['fare'] as String?),
        amountCents: (m['amount_cents']! as num).toInt(),
        rideAt: DateTime.parse(m['ride_at']! as String),
      );
}

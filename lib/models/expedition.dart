import 'bird.dart';

/// Timed seed-foraging routes for the Scavenger Burrow squads. Squads come
/// home carrying a ready-to-pour seed bag — no second timer or payment.
enum ExpeditionRoute {
  meadowDash('Meadow Edge Dash', 2, 40, SeedKind.sunflowerMillet),
  ridgeTrek('Woodland Ridge Trek', 6, 120, SeedKind.berryHickory),
  deepForest('Deep Forest Expedition', 12, 300, SeedKind.goldenHusk);

  const ExpeditionRoute(this.label, this.hours, this.acorns, this.seed);

  final String label;
  final int hours;

  /// Acorn cost to send a squad.
  final int acorns;
  final SeedKind seed;

  Duration get duration => Duration(hours: hours);

  static ExpeditionRoute? tryParse(String? raw) {
    for (final r in values) {
      if (r.name == raw) return r;
    }
    return null;
  }
}

/// One dispatched squad (`expeditions` table).
class Expedition {
  const Expedition({
    required this.id,
    required this.route,
    required this.startedAt,
    required this.endsAt,
    required this.acorns,
    this.collectedAt,
  });

  final String id;
  final ExpeditionRoute route;
  final DateTime startedAt;
  final DateTime endsAt;
  final int acorns;

  /// When the squad came home and its seed bag joined the stash.
  final DateTime? collectedAt;

  bool get collected => collectedAt != null;
  bool get active => !collected;

  bool isDone(DateTime now) => !now.isBefore(endsAt);

  double progress(DateTime now) {
    final total = endsAt.difference(startedAt).inSeconds;
    if (total <= 0) return 1;
    return (now.difference(startedAt).inSeconds / total).clamp(0.0, 1.0);
  }

  Duration left(DateTime now) => isDone(now) ? Duration.zero : endsAt.difference(now);

  Expedition collect(DateTime at) => Expedition(
      id: id, route: route, startedAt: startedAt, endsAt: endsAt, acorns: acorns, collectedAt: at);

  Map<String, Object?> toMap() => {
        'id': id,
        'route': route.name,
        'started_at': startedAt.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
        'acorns': acorns,
        'collected_at': collectedAt?.toIso8601String(),
      };

  /// Returns null for a retired/unknown route.
  static Expedition? fromMap(Map<String, Object?> m) {
    final route = ExpeditionRoute.tryParse(m['route'] as String?);
    if (route == null) return null;
    final collected = m['collected_at'] as String?;
    return Expedition(
      id: m['id']! as String,
      route: route,
      startedAt: DateTime.parse(m['started_at']! as String),
      endsAt: DateTime.parse(m['ends_at']! as String),
      acorns: (m['acorns'] as num? ?? 0).toInt(),
      collectedAt: collected == null ? null : DateTime.parse(collected),
    );
  }
}

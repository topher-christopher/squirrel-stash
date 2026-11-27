import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wall clock for the time-driven colony (Hearth fuel, expeditions, feeder
/// visits). Tests override it to fast-forward hours in a single step.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// A Focus Shift length offered on the brass clock.
class FocusPreset {
  const FocusPreset(this.label, this.seconds);

  final String label;
  final int seconds;

  static const all = <FocusPreset>[
    FocusPreset('10s Demo', 10),
    FocusPreset('15m', 900),
    FocusPreset('25m', 1500),
    FocusPreset('45m', 2700),
    FocusPreset('60m', 3600),
  ];
}

/// Live Focus Shift timer state. The timer is wall-clock based ([endsAt])
/// so it survives the app being backgrounded or restarted.
class FocusState {
  const FocusState({
    this.totalSeconds = 1500,
    this.remainingSeconds = 1500,
    this.running = false,
    this.endsAt,
  });

  final int totalSeconds;
  final int remainingSeconds;
  final bool running;
  final DateTime? endsAt;

  bool get paused =>
      !running && remainingSeconds > 0 && remainingSeconds < totalSeconds;

  double get progress {
    if (totalSeconds <= 0) return 0;
    final p = 1 - remainingSeconds / totalSeconds;
    return p.clamp(0, 1).toDouble();
  }

  String get clock => formatClock(remainingSeconds);

  static String formatClock(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  FocusState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? running,
    DateTime? endsAt,
    bool clearEndsAt = false,
  }) =>
      FocusState(
        totalSeconds: totalSeconds ?? this.totalSeconds,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        running: running ?? this.running,
        endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
      );
}

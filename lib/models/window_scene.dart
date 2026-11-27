/// Swappable panoramic scenes outside the arched study window.
enum WindowScene {
  meadow('🌳', 'Meadow'),
  alpine('🎿', 'Alpine'),
  harbor('🦭', 'Harbor');

  const WindowScene(this.emoji, this.label);

  final String emoji;
  final String label;

  String get chip => '$emoji $label';

  WindowScene get next => values[(index + 1) % values.length];

  static WindowScene parse(String? raw) =>
      values.firstWhere((s) => s.name == raw, orElse: () => WindowScene.meadow);
}

/// Ambient audio loop played during Focus Shifts.
enum AmbientTrack {
  campfire('🔥', 'Campfire Crackle', 'audio/campfire.wav'),
  breeze('🍃', 'Forest Breeze', 'audio/forest_breeze.wav');

  const AmbientTrack(this.emoji, this.label, this.asset);

  final String emoji;
  final String label;

  /// Path relative to the `assets/` folder (audioplayers' AssetSource prefix).
  final String asset;

  static AmbientTrack parse(String? raw) => values
      .firstWhere((t) => t.name == raw, orElse: () => AmbientTrack.campfire);
}

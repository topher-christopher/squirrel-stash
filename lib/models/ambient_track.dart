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

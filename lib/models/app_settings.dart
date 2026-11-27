import 'window_scene.dart';

/// Scalar app state persisted in the `settings` key-value table.
/// Checking balance, Golden Leaves and Warm Hearth live here because they
/// are single values rather than collections.
class AppSettings {
  const AppSettings({
    this.checkingCents = 0,
    this.goldenLeaves = 0,
    this.hearthWarmth = 1,
    this.scene = WindowScene.meadow,
    this.zenMode = false,
    this.hootGreetedOn = '',
    this.brokerageApyBps = 460,
    this.paydayCents = 120000,
    this.focusIntention = 'Deep Work & Study Sprint',
    this.ambientOn = false,
    this.ambientTrack = AmbientTrack.campfire,
    this.sfxOn = true,
    this.hapticsOn = true,
  });

  final int checkingCents;
  final int goldenLeaves;

  /// 1 = Embers (1.0x), 2 = Hearth (1.25x), 3 = Blaze (1.5x).
  final int hearthWarmth;
  final WindowScene scene;
  final bool zenMode;

  /// `yyyy-mm-dd` of the last Professor Hoot gift (one gift per day).
  final String hootGreetedOn;

  /// Amber Reserve APY in basis points (460 = 4.60%).
  final int brokerageApyBps;
  final int paydayCents;
  final String focusIntention;
  final bool ambientOn;
  final AmbientTrack ambientTrack;
  final bool sfxOn;
  final bool hapticsOn;

  double get hearthMultiplier => switch (hearthWarmth) {
        >= 3 => 1.5,
        2 => 1.25,
        _ => 1.0,
      };

  String get hearthLabel => switch (hearthWarmth) {
        >= 3 => '1.5x Blaze',
        2 => '1.25x Hearth',
        _ => '1.0x Embers',
      };

  double get apyFraction => brokerageApyBps / 10000;

  AppSettings copyWith({
    int? checkingCents,
    int? goldenLeaves,
    int? hearthWarmth,
    WindowScene? scene,
    bool? zenMode,
    String? hootGreetedOn,
    int? brokerageApyBps,
    int? paydayCents,
    String? focusIntention,
    bool? ambientOn,
    AmbientTrack? ambientTrack,
    bool? sfxOn,
    bool? hapticsOn,
  }) =>
      AppSettings(
        checkingCents: checkingCents ?? this.checkingCents,
        goldenLeaves: goldenLeaves ?? this.goldenLeaves,
        hearthWarmth: hearthWarmth ?? this.hearthWarmth,
        scene: scene ?? this.scene,
        zenMode: zenMode ?? this.zenMode,
        hootGreetedOn: hootGreetedOn ?? this.hootGreetedOn,
        brokerageApyBps: brokerageApyBps ?? this.brokerageApyBps,
        paydayCents: paydayCents ?? this.paydayCents,
        focusIntention: focusIntention ?? this.focusIntention,
        ambientOn: ambientOn ?? this.ambientOn,
        ambientTrack: ambientTrack ?? this.ambientTrack,
        sfxOn: sfxOn ?? this.sfxOn,
        hapticsOn: hapticsOn ?? this.hapticsOn,
      );

  Map<String, String> toMap() => {
        'checking_cents': '$checkingCents',
        'golden_leaves': '$goldenLeaves',
        'hearth_warmth': '$hearthWarmth',
        'window_scene': scene.name,
        'zen_mode': zenMode ? '1' : '0',
        'hoot_greeted_on': hootGreetedOn,
        'brokerage_apy_bps': '$brokerageApyBps',
        'payday_cents': '$paydayCents',
        'focus_intention': focusIntention,
        'ambient_on': ambientOn ? '1' : '0',
        'ambient_track': ambientTrack.name,
        'sfx_on': sfxOn ? '1' : '0',
        'haptics_on': hapticsOn ? '1' : '0',
      };

  factory AppSettings.fromMap(Map<String, String> m) {
    const d = AppSettings();
    int i(String k, int fallback) => int.tryParse(m[k] ?? '') ?? fallback;
    bool b(String k, bool fallback) =>
        m.containsKey(k) ? m[k] == '1' : fallback;
    return AppSettings(
      checkingCents: i('checking_cents', d.checkingCents),
      goldenLeaves: i('golden_leaves', d.goldenLeaves),
      hearthWarmth: i('hearth_warmth', d.hearthWarmth).clamp(1, 3),
      scene: WindowScene.parse(m['window_scene']),
      zenMode: b('zen_mode', d.zenMode),
      hootGreetedOn: m['hoot_greeted_on'] ?? d.hootGreetedOn,
      brokerageApyBps: i('brokerage_apy_bps', d.brokerageApyBps),
      paydayCents: i('payday_cents', d.paydayCents),
      focusIntention: m['focus_intention'] ?? d.focusIntention,
      ambientOn: b('ambient_on', d.ambientOn),
      ambientTrack: AmbientTrack.parse(m['ambient_track']),
      sfxOn: b('sfx_on', d.sfxOn),
      hapticsOn: b('haptics_on', d.hapticsOn),
    );
  }
}

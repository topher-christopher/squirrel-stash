import 'ambient_track.dart';

/// Scalar app state persisted in the `settings` key-value table.
/// Checking balance, the Acorn economy and Warm Hearth live here because
/// they are single values rather than collections.
class AppSettings {
  const AppSettings({
    this.checkingCents = 0,
    this.acorns = 0,
    this.goldenAcorns = 0,
    this.goldenSavingsMilestones = 0,
    this.hearthWarmth = 1,
    this.zenMode = false,
    this.privacyMode = false,
    this.hootGreetedOn = '',
    this.paydayCents = 120000,
    this.lastPaydayOn = '',
    this.focusIntention = 'Deep Work & Study Sprint',
    this.focusShiftsCompleted = 0,
    this.focusMinutesTotal = 0,
    this.ambientOn = false,
    this.ambientTrack = AmbientTrack.campfire,
    this.sfxOn = true,
    this.hapticsOn = true,
  });

  final int checkingCents;

  /// Everyday cosmetic currency: 10 per $1 of willpower saved + Focus Shifts.
  final int acorns;

  /// Rare cosmetic currency: 1 per $100 cumulative willpower savings, 1 per
  /// reclaimed goal, plus seasonal and ladder milestones. Never real USD.
  final int goldenAcorns;

  /// How many $100 willpower milestones have already paid a Golden Acorn
  /// (so undoing and re-logging a win never pays twice).
  final int goldenSavingsMilestones;

  /// 1 = Embers (1.0x), 2 = Hearth (1.25x), 3 = Blaze (1.5x).
  final int hearthWarmth;

  /// Cozy Zen: hides HUD chrome and room icons so the tree is pure ambience.
  final bool zenMode;

  /// Privacy Eye: masks dollar amounts on the HUD and tree.
  final bool privacyMode;

  /// `yyyy-mm-dd` of the last Professor Hoot gift (one gift per day).
  final String hootGreetedOn;
  final int paydayCents;

  /// `yyyy-mm-dd` of the last +Payday tap (Double Harvest feat).
  final String lastPaydayOn;
  final String focusIntention;
  final int focusShiftsCompleted;
  final int focusMinutesTotal;
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

  AppSettings copyWith({
    int? checkingCents,
    int? acorns,
    int? goldenAcorns,
    int? goldenSavingsMilestones,
    int? hearthWarmth,
    bool? zenMode,
    bool? privacyMode,
    String? hootGreetedOn,
    int? paydayCents,
    String? lastPaydayOn,
    String? focusIntention,
    int? focusShiftsCompleted,
    int? focusMinutesTotal,
    bool? ambientOn,
    AmbientTrack? ambientTrack,
    bool? sfxOn,
    bool? hapticsOn,
  }) =>
      AppSettings(
        checkingCents: checkingCents ?? this.checkingCents,
        acorns: acorns ?? this.acorns,
        goldenAcorns: goldenAcorns ?? this.goldenAcorns,
        goldenSavingsMilestones:
            goldenSavingsMilestones ?? this.goldenSavingsMilestones,
        hearthWarmth: hearthWarmth ?? this.hearthWarmth,
        zenMode: zenMode ?? this.zenMode,
        privacyMode: privacyMode ?? this.privacyMode,
        hootGreetedOn: hootGreetedOn ?? this.hootGreetedOn,
        paydayCents: paydayCents ?? this.paydayCents,
        lastPaydayOn: lastPaydayOn ?? this.lastPaydayOn,
        focusIntention: focusIntention ?? this.focusIntention,
        focusShiftsCompleted: focusShiftsCompleted ?? this.focusShiftsCompleted,
        focusMinutesTotal: focusMinutesTotal ?? this.focusMinutesTotal,
        ambientOn: ambientOn ?? this.ambientOn,
        ambientTrack: ambientTrack ?? this.ambientTrack,
        sfxOn: sfxOn ?? this.sfxOn,
        hapticsOn: hapticsOn ?? this.hapticsOn,
      );

  Map<String, String> toMap() => {
        'checking_cents': '$checkingCents',
        'acorns': '$acorns',
        'golden_acorns': '$goldenAcorns',
        'golden_savings_milestones': '$goldenSavingsMilestones',
        'hearth_warmth': '$hearthWarmth',
        'zen_mode': zenMode ? '1' : '0',
        'privacy_mode': privacyMode ? '1' : '0',
        'hoot_greeted_on': hootGreetedOn,
        'payday_cents': '$paydayCents',
        'last_payday_on': lastPaydayOn,
        'focus_intention': focusIntention,
        'focus_shifts_completed': '$focusShiftsCompleted',
        'focus_minutes_total': '$focusMinutesTotal',
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
    // v1 → v1.1: retired Golden Leaves convert to Acorns at 10 : 1.
    final legacyLeaves = int.tryParse(m['golden_leaves'] ?? '');
    final acorns = m.containsKey('acorns')
        ? i('acorns', d.acorns)
        : (legacyLeaves ?? 0) * 10;
    return AppSettings(
      checkingCents: i('checking_cents', d.checkingCents),
      acorns: acorns,
      goldenAcorns: i('golden_acorns', d.goldenAcorns),
      goldenSavingsMilestones:
          i('golden_savings_milestones', d.goldenSavingsMilestones),
      hearthWarmth: i('hearth_warmth', d.hearthWarmth).clamp(1, 3),
      zenMode: b('zen_mode', d.zenMode),
      privacyMode: b('privacy_mode', d.privacyMode),
      hootGreetedOn: m['hoot_greeted_on'] ?? d.hootGreetedOn,
      paydayCents: i('payday_cents', d.paydayCents),
      lastPaydayOn: m['last_payday_on'] ?? d.lastPaydayOn,
      focusIntention: m['focus_intention'] ?? d.focusIntention,
      focusShiftsCompleted: i('focus_shifts_completed', d.focusShiftsCompleted),
      focusMinutesTotal: i('focus_minutes_total', d.focusMinutesTotal),
      ambientOn: b('ambient_on', d.ambientOn),
      ambientTrack: AmbientTrack.parse(m['ambient_track']),
      sfxOn: b('sfx_on', d.sfxOn),
      hapticsOn: b('haptics_on', d.hapticsOn),
    );
  }
}

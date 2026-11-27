import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/focus_state.dart';
import '../../providers/focus_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/ui_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import '../widgets/acorn_icons.dart';
import 'drawer_shell.dart';

/// Focus Shift Study Companion: timer, ambient audio, Warm Hearth, decor.
class FocusDrawer extends ConsumerStatefulWidget {
  const FocusDrawer({super.key});

  @override
  ConsumerState<FocusDrawer> createState() => _FocusDrawerState();
}

class _FocusDrawerState extends ConsumerState<FocusDrawer> {
  late final TextEditingController _intention =
      TextEditingController(text: ref.read(settingsProvider).focusIntention);

  @override
  void dispose() {
    _intention.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focus = ref.watch(focusProvider);
    final settings = ref.watch(settingsProvider);
    final timer = ref.read(focusProvider.notifier);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    return DrawerShell(
      emoji: '⏳',
      title: 'Focus Shift Study Companion',
      subtitle: 'Work alongside the colony to earn Acorns for Hearth fuel and expeditions',
      children: [
        StashCard(
          border: AppColors.amber.withValues(alpha: 0.35),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(children: [
            TextField(
              controller: _intention,
              textAlign: TextAlign.center,
              style: AppType.body(14, weight: FontWeight.w800, color: AppColors.honey),
              onChanged: (v) => settingsNotifier.update((s) => s.copyWith(focusIntention: v)),
              decoration: const InputDecoration(
                filled: false,
                border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0x55F59E0B))),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0x55F59E0B))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.amberBright)),
                hintText: 'What are you focusing on?',
              ),
            ),
            const SizedBox(height: 14),
            _TimerRing(focus: focus),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in FocusPreset.all)
                  PillButton(label: 'Start ${p.label}', dense: true, onPressed: () => timer.start(p.seconds)),
              ],
            ),
            if (focus.running || focus.paused) ...[
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (focus.running)
                  PillButton(label: 'Pause', dense: true, color: const Color(0xFFB91C1C), onPressed: timer.pause)
                else
                  PillButton(label: 'Resume', dense: true, color: AppColors.emeraldButton, onPressed: timer.resume),
                const SizedBox(width: 8),
                PillButton(label: 'Reset', dense: true, outlined: true, color: AppColors.stone, onPressed: timer.reset),
              ]),
            ],
            const SizedBox(height: 14),
            PressScale(
              onTap: () => settingsNotifier.update((s) => s.copyWith(ambientOn: !s.ambientOn)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: settings.ambientOn ? const Color(0xCC064E3B) : AppColors.stoneDeep,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: settings.ambientOn ? AppColors.emeraldBright : const Color(0xFF57534E)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(settings.ambientOn ? Icons.piano_rounded : Icons.piano_off_rounded, size: 16,
                      color: settings.ambientOn ? AppColors.emeraldSoft : AppColors.honey),
                  const SizedBox(width: 6),
                  Text(settings.ambientOn ? 'Calm piano: ON' : 'Calm piano: OFF',
                      style: AppType.body(13, weight: FontWeight.w800,
                          color: settings.ambientOn ? AppColors.emeraldSoft : AppColors.honey)),
                ]),
              ),
            ),
            if (ref.watch(ambientPianoAvailableProvider).value == false) ...[
              const SizedBox(height: 8),
              Text('Silent until you drop a loop at assets/audio/ambient_piano.wav and rebuild.',
                  textAlign: TextAlign.center, style: AppType.body(11, color: AppColors.stoneDim, height: 1.3)),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        _HearthRow(warmth: settings.hearthWarmth, label: settings.hearthLabel),
        const SizedBox(height: 10),
        StashCard(
          child: Row(children: [
            const AcornIcon(size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text('A 25-minute shift earns about ${(25 * 2 * settings.hearthMultiplier).round()} Acorns '
                  '(minutes × 2 × warmth). ${settings.focusShiftsCompleted} shifts completed so far.',
                  style: AppType.body(12, color: AppColors.stone, height: 1.35)),
            ),
          ]),
        ),
      ],
    );
  }
}

class _TimerRing extends StatelessWidget {
  const _TimerRing({required this.focus});

  final FocusState focus;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 168,
        height: 168,
        child: Stack(alignment: Alignment.center, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: focus.progress),
            duration: const Duration(milliseconds: 450),
            builder: (context, p, _) => CustomPaint(size: const Size.square(168), painter: _RingPainter(p)),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(focus.clock, style: AppType.number(42, weight: FontWeight.w600)),
            Text(focus.running ? 'focusing…' : (focus.paused ? 'paused' : 'ready'),
                style: AppType.body(12, color: AppColors.honey.withValues(alpha: 0.7))),
          ]),
        ]),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = const Color(0xFF3B2110));
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        progress * math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..shader = const SweepGradient(
            colors: [AppColors.amberDeep, AppColors.flame, AppColors.amberDeep],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
    for (var i = 0; i < 60; i++) {
      final a = i / 60 * math.pi * 2;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (r - 14), c + d * (r - (i % 5 == 0 ? 20 : 16)),
          Paint()..color = const Color(0x55FDE68A)..strokeWidth = i % 5 == 0 ? 1.6 : 0.8);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _HearthRow extends StatelessWidget {
  const _HearthRow({required this.warmth, required this.label});

  final int warmth;
  final String label;

  @override
  Widget build(BuildContext context) => StashCard(
        color: const Color(0x99431407),
        border: AppColors.ember.withValues(alpha: 0.35),
        child: Row(children: [
          for (var i = 1; i <= 3; i++)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: i <= warmth ? 1 : 0.25,
              child: Text('🔥', style: TextStyle(fontSize: 14 + i * 3.0, fontFamilyFallback: AppType.emojiFallback)),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Focus Warmth • $label', style: AppType.title(14.5, color: const Color(0xFFFDBA74))),
              Text('Grows with every Focus Shift & willpower win. It never cools down.',
                  style: AppType.body(11.5, color: AppColors.stone)),
            ]),
          ),
        ]),
      );
}

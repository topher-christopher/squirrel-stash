import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/haptics.dart';
import '../providers/settings_provider.dart';
import '../providers/stash_actions.dart';
import '../providers/ui_provider.dart';
import '../theme/app_colors.dart';
import 'diorama/tree_stage.dart';
import 'widgets/celebration_banner.dart';
import 'widgets/frost_vignette.dart';
import 'widgets/stash_controls.dart';
import 'widgets/study_hud_pill.dart';

/// The Great Oak home screen: the clean top HUD, the zoomable living tree,
/// celebration toasts, and the full-screen frost vignette. Cozy Zen fades
/// every control away, leaving only a faint leaf to come back.
class HomeStudyScreen extends ConsumerStatefulWidget {
  const HomeStudyScreen({super.key});

  @override
  ConsumerState<HomeStudyScreen> createState() => _HomeStudyScreenState();
}

class _HomeStudyScreenState extends ConsumerState<HomeStudyScreen> {
  Timer? _stargazer;

  @override
  void initState() {
    super.initState();
    // Ambient loop follows the persisted toggle + track.
    ref.listenManual(
      settingsProvider.select((s) => (s.ambientOn, s.ambientTrack)),
      (_, next) => ref.read(audioServiceProvider).setAmbient(next.$1 ? next.$2 : null),
      fireImmediately: true,
    );
    ref.listenManual(
      settingsProvider.select((s) => s.hapticsOn),
      (_, on) => Haptics.enabled = on,
      fireImmediately: true,
    );
    // Canopy Stargazer: a full minute of Cozy Zen.
    ref.listenManual(
      settingsProvider.select((s) => s.zenMode),
      (_, zen) {
        _stargazer?.cancel();
        if (zen) {
          _stargazer = Timer(const Duration(seconds: 60),
              () => ref.read(stashActionsProvider).finishedStargazing());
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _stargazer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zen = ref.watch(settingsProvider.select((s) => s.zenMode));
    return Scaffold(
      backgroundColor: AppColors.night,
      body: Stack(children: [
        SafeArea(
          bottom: false,
          child: Column(children: [
            IgnorePointer(
              ignoring: zen,
              child: AnimatedOpacity(
                opacity: zen ? 0 : 1,
                duration: const Duration(milliseconds: 450),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Center(child: StudyHud()),
                ),
              ),
            ),
            const Expanded(child: TreeStage()),
          ]),
        ),
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: SafeArea(child: Padding(padding: EdgeInsets.only(top: 104), child: CelebrationBanner())),
        ),
        const Positioned.fill(child: FrostVignette()),
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: IgnorePointer(
              ignoring: !zen,
              child: AnimatedOpacity(
                opacity: zen ? 0.55 : 0,
                duration: const Duration(milliseconds: 450),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: PressScale(
                    onTap: () => ref.read(stashActionsProvider).toggleZen(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(color: Color(0x66140C07), shape: BoxShape.circle),
                      child: const Icon(Icons.spa_rounded, size: 19, color: AppColors.honey),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

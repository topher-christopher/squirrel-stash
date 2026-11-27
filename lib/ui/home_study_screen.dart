import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/haptics.dart';
import '../providers/colony_actions.dart';
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
  Timer? _colonyClock;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    // The optional background piano follows the persisted toggle (the audio
    // service itself pauses it whenever the app leaves the foreground).
    ref.listenManual(
      settingsProvider.select((s) => s.ambientOn),
      (_, on) => ref.read(audioServiceProvider).setAmbient(on),
      fireImmediately: true,
    );
    // Colony clock: settle Hearth fuel, wild acorns, feeder visits and
    // returning squads now, every 20s, and whenever the app comes back.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(colonyActionsProvider).tick();
    });
    _colonyClock = Timer.periodic(const Duration(seconds: 20), (_) => ref.read(colonyActionsProvider).tick());
    _lifecycle = AppLifecycleListener(onResume: () => ref.read(colonyActionsProvider).tick());
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
    _colonyClock?.cancel();
    _lifecycle?.dispose();
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

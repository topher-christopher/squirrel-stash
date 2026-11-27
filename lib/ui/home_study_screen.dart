import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/haptics.dart';
import '../providers/settings_provider.dart';
import '../providers/ui_provider.dart';
import '../theme/app_colors.dart';
import 'diorama/diorama_stage.dart';
import 'widgets/celebration_banner.dart';
import 'widgets/frost_vignette.dart';
import 'widgets/study_hud_pill.dart';

/// The 1-Screen Hollow Oak Study: HUD pill, the living diorama (window,
/// desk, root cellar), celebration toasts and the full-screen frost vignette.
class HomeStudyScreen extends ConsumerStatefulWidget {
  const HomeStudyScreen({super.key});

  @override
  ConsumerState<HomeStudyScreen> createState() => _HomeStudyScreenState();
}

class _HomeStudyScreenState extends ConsumerState<HomeStudyScreen> {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.night,
      body: Stack(children: [
        const Positioned.fill(child: _Backdrop()),
        SafeArea(
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Center(child: StudyHudPill()),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 0, 10, MediaQuery.paddingOf(context).bottom > 0 ? 4 : 12),
                child: const DioramaStage(),
              ),
            ),
          ]),
        ),
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: SafeArea(
            child: Padding(padding: EdgeInsets.only(top: 64), child: CelebrationBanner()),
          ),
        ),
        const Positioned.fill(child: FrostVignette()),
      ]),
    );
  }
}

/// Warm candle-lit glow behind the diorama.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.1,
            colors: [Color(0xFF3A2010), Color(0xFF1E1109), AppColors.night],
            stops: [0, 0.55, 1],
          ),
        ),
      );
}

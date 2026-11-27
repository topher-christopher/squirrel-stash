import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../game/diorama_event.dart';
import '../../models/room.dart';
import '../../providers/ui_provider.dart';

/// Invisible tap region over a tree room or critter. Tapping squash-bounces
/// the room in the Flame world, plays a light haptic and runs [onTap]. The
/// optional [child] (a plaque) gets the same tactile press scale.
class TapZone extends ConsumerStatefulWidget {
  const TapZone({
    super.key,
    required this.onTap,
    required this.label,
    this.room,
    this.child,
    this.pressAlignment = Alignment.center,
  });

  final VoidCallback onTap;
  final String label;
  final RoomKey? room;
  final Widget? child;
  final Alignment pressAlignment;

  @override
  ConsumerState<TapZone> createState() => _TapZoneState();
}

class _TapZoneState extends ConsumerState<TapZone> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: () {
          Haptics.light();
          final room = widget.room;
          if (room != null) {
            ref.read(dioramaEventsProvider).emit(DioramaEvent.poke(room));
          }
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          alignment: widget.pressAlignment,
          duration: Duration(milliseconds: _down ? 90 : 240),
          curve: _down ? Curves.easeOut : Curves.easeOutBack,
          child: widget.child ?? const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Fades icons & plaques away in Cozy Zen (keeps their space).
class ZenFade extends StatelessWidget {
  const ZenFade({super.key, required this.zen, required this.child});

  final bool zen;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: zen,
        child: AnimatedOpacity(
          opacity: zen ? 0 : 1,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          child: child,
        ),
      );
}

/// A carved wooden plaque (desk cards, chamber labels).
class WoodPlaque extends StatelessWidget {
  const WoodPlaque({
    super.key,
    required this.child,
    this.border = const Color(0xFF92400E),
    this.color = const Color(0xFF241308),
    this.radius = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    this.glow,
  });

  final Widget child;
  final Color border;
  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? glow;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, Colors.white, 0.05)!, color],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: border, width: 1.4),
          boxShadow: [
            const BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2)),
            if (glow != null) BoxShadow(color: glow!.withValues(alpha: 0.35), blurRadius: 10),
          ],
        ),
        child: child,
      );
}

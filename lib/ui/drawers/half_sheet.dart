import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import 'drawer_shell.dart';

/// A bottom sheet that opens at half height so the zoomed room stays in
/// view above it. Drag the [header] up to fill the screen, down to return
/// to half (or further to close); tap the grab handle to toggle. The [body]
/// scrolls on its own at either height.
class HalfSheet extends StatefulWidget {
  const HalfSheet({super.key, required this.header, required this.body});

  final Widget header;
  final Widget body;

  /// Resting heights as a fraction of the space the sheet may use.
  static const half = 0.52;
  static const full = 1.0;

  /// Dragged below this, the sheet closes.
  static const closeBelow = 0.3;

  @override
  State<HalfSheet> createState() => _HalfSheetState();
}

class _HalfSheetState extends State<HalfSheet> {
  double _fraction = HalfSheet.half;
  bool _dragging = false;
  double _maxHeight = 1;

  bool get _expanded => _fraction > (HalfSheet.half + HalfSheet.full) / 2;

  void _settle(double target) {
    if (target != _fraction) Haptics.tap();
    setState(() {
      _dragging = false;
      _fraction = target;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) => setState(() {
        _dragging = true;
        _fraction = (_fraction - d.delta.dy / _maxHeight).clamp(0.15, HalfSheet.full);
      });

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (_fraction < HalfSheet.closeBelow || (v > 1600 && _fraction <= HalfSheet.half)) {
      Navigator.of(context).maybePop();
      return;
    }
    if (v < -500) return _settle(HalfSheet.full);
    if (v > 500) return _settle(HalfSheet.half);
    _settle(_expanded ? HalfSheet.full : HalfSheet.half);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        _maxHeight = box.maxHeight.isFinite ? box.maxHeight : MediaQuery.sizeOf(context).height;
        return AnimatedContainer(
          duration: _dragging ? Duration.zero : const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: _maxHeight * _fraction,
          decoration: drawerDecoration,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Semantics(
                  button: true,
                  label: _expanded ? 'Collapse drawer' : 'Expand drawer',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _settle(_expanded ? HalfSheet.half : HalfSheet.full),
                    child: const SizedBox(width: double.infinity, child: DrawerHandle()),
                  ),
                ),
                widget.header,
              ]),
            ),
            Expanded(child: widget.body),
          ]),
        );
      });
}

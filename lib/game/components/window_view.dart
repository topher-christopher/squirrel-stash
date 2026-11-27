import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import '../../models/window_scene.dart';
import '../art/paint_kit.dart';
import '../art/palette.dart';
import '../layout.dart';
import '../scenes/alpine_scene.dart';
import '../scenes/harbor_scene.dart';
import '../scenes/meadow_scene.dart';
import '../scenes/scene_art.dart';
import '../scenes/sky_painter.dart';
import '../scenes/window_props.dart';
import '../scenes/window_weather.dart';
import 'diorama_layer.dart';

/// Everything seen through the arched window, clipped to the arch:
/// sky, the active scene (cross-fading on swap), the acorn pile, the bills
/// campfire, payday runners, weather and creeping frost.
class WindowView extends DioramaLayer {
  WindowView() : super(priority: 10);

  final Path _arch = StudyLayout.archPath();
  final SkyPainter _sky = SkyPainter();
  final Map<WindowScene, SceneArt> _scenes = {
    WindowScene.meadow: MeadowScene(),
    WindowScene.alpine: AlpineScene(),
    WindowScene.harbor: HarborScene(),
  };
  final AcornPile _pile = AcornPile();
  final PaydayRush _rush = PaydayRush();
  final WindowWeather _weather = WindowWeather();
  final FrostPanes _frost = FrostPanes();

  WindowScene? _current;
  WindowScene? _previous;
  double _fade = 1;
  double _sparkleTimer = 0;

  SceneContext _context() =>
      SceneContext(snap: snap, time: t, art: game.art, poke: game.pokeAmount);

  @override
  void update(double dt) {
    final s = snap;
    if (_current != s.scene) {
      _previous = _current;
      _current = s.scene;
      _fade = _previous == null ? 1 : 0;
    }
    if (_fade < 1) {
      _fade = math.min(1, _fade + dt / 0.8);
      _scenes[_previous]?.update(dt);
    }
    _scenes[s.scene]!.update(dt);
    _sky.update(dt);
    _pile.update(dt, s.acornCount);
    _rush.update(dt, s.paydayBurst);
    _weather.update(dt, s);
    _frost.update(dt, s.frost);
    if (s.paydayBurst) {
      _sparkleTimer += dt;
      if (_sparkleTimer > 0.35) {
        _sparkleTimer = 0;
        game.fx.burst(StudyLayout.cashPile.translate(0, -10),
            count: 4, colors: const [Pal.gold, Color(0xFFFFFFFF)], speed: 40);
      }
    }
  }

  @override
  void renderTree(Canvas canvas) {
    canvas.save();
    canvas.clipPath(_arch);
    super.renderTree(canvas);
    canvas.restore();
  }

  @override
  void render(Canvas canvas) {
    final ctx = _context();
    final current = _current ?? snap.scene;
    final previous = _previous;
    if (previous != null && _fade < 1) {
      _drawScene(canvas, previous, ctx);
      canvas.saveLayer(StudyLayout.windowRect,
          Paint()..color = Color.fromRGBO(0, 0, 0, Ease.easeInOut(_fade)));
      _drawScene(canvas, current, ctx);
      canvas.restore();
    } else {
      _drawScene(canvas, current, ctx);
    }
    _pile.render(canvas, ctx);
    Campfire.render(canvas, ctx);
    _rush.render(canvas, ctx);
    final near = game.art.window(current, layer: '_near');
    if (near != null) _cover(canvas, near);
    _weather.render(canvas, ctx);
    _frost.render(canvas, ctx);
    _glassSheen(canvas);
  }

  void _drawScene(Canvas canvas, WindowScene scene, SceneContext ctx) {
    final custom = game.art.window(scene);
    if (custom != null) {
      final far = game.art.window(scene, layer: '_far');
      if (far != null) _cover(canvas, far);
      _cover(canvas, custom);
      return;
    }
    _sky.render(canvas, ctx);
    _scenes[scene]!.render(canvas, ctx);
  }

  /// BoxFit.cover of a custom backdrop into the window opening.
  static void _cover(Canvas canvas, ui.Image image) {
    const dst = StudyLayout.windowRect;
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    final scale = math.max(dst.width / iw, dst.height / ih);
    final w = dst.width / scale;
    final h = dst.height / scale;
    final src = Rect.fromLTWH((iw - w) / 2, (ih - h) / 2, w, h);
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.medium);
  }

  static void _glassSheen(Canvas canvas) {
    canvas.drawPath(
        Path()
          ..moveTo(60, 380)
          ..lineTo(104, 380)
          ..lineTo(262, 20)
          ..lineTo(218, 20)
          ..close(),
        Kit.fill(const Color(0x0DFFFFFF)));
    canvas.drawPath(
        Path()
          ..moveTo(118, 380)
          ..lineTo(130, 380)
          ..lineTo(288, 20)
          ..lineTo(276, 20)
          ..close(),
        Kit.fill(const Color(0x0AFFFFFF)));
  }

  @override
  void onRemove() {
    for (final s in _scenes.values) {
      s.dispose();
    }
    super.onRemove();
  }
}

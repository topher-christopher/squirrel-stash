import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/window_scene.dart';

/// A horizontal sprite strip for one squirrel pose.
class SpriteSheetSpec {
  const SpriteSheetSpec({
    required this.image,
    required this.frames,
    required this.fps,
    required this.frameSize,
    required this.anchor,
    required this.worldHeight,
  });

  final ui.Image image;
  final int frames;
  final double fps;
  final Size frameSize;
  final Offset anchor;
  final double worldHeight;

  Rect frameRect(double time) {
    final i = (time * fps).floor() % frames;
    return Rect.fromLTWH(
        i * frameSize.width, 0, frameSize.width, frameSize.height);
  }
}

/// The custom-artwork drop-in registry (CLAUDE.md "AssetManifest" config).
///
/// At startup it scans Flutter's asset manifest for PNGs in
///   assets/images/windows/   meadow.png, alpine.png, harbor.png
///   assets/images/props/     chest_lv1..3.png, acorn.png, frost_overlay.png
///   assets/sprites/squirrels/ `<pose>.png` described by squirrels.json
/// and decodes whatever exists. Painters ask for an image and fall back to
/// procedural art when none is present, so art can be swapped without
/// touching game logic.
class StashAssetManifest {
  StashAssetManifest._(this._images, this._sheets);

  static final StashAssetManifest empty = StashAssetManifest._(const {}, const {});

  static const windowDir = 'assets/images/windows/';
  static const propsDir = 'assets/images/props/';
  static const squirrelDir = 'assets/sprites/squirrels/';

  final Map<String, ui.Image> _images;
  final Map<String, SpriteSheetSpec> _sheets;

  bool get isEmpty => _images.isEmpty;

  /// [layer] is '' for the main backdrop, or '_far' / '_near'.
  ui.Image? window(WindowScene scene, {String layer = ''}) =>
      _images['$windowDir${scene.name}$layer.png'];

  ui.Image? prop(String name) => _images['$propsDir$name.png'];

  SpriteSheetSpec? squirrel(String pose) => _sheets[pose];

  static Future<StashAssetManifest> load([AssetBundle? bundle]) async {
    final assets = bundle ?? rootBundle;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(assets);
      final pngs = manifest.listAssets().where((a) =>
          a.endsWith('.png') &&
          (a.startsWith(windowDir) ||
              a.startsWith(propsDir) ||
              a.startsWith(squirrelDir)));
      final images = <String, ui.Image>{};
      for (final path in pngs) {
        images[path] = await _decode(assets, path);
      }
      final sheets = images.keys.any((k) => k.startsWith(squirrelDir))
          ? await _loadSheets(assets, images)
          : const <String, SpriteSheetSpec>{};
      return StashAssetManifest._(images, sheets);
    } catch (error) {
      debugPrint('SquirrelStash art: using procedural art ($error)');
      return empty;
    }
  }

  static Future<ui.Image> _decode(AssetBundle assets, String path) async {
    final data = await assets.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  static Future<Map<String, SpriteSheetSpec>> _loadSheets(
    AssetBundle assets,
    Map<String, ui.Image> images,
  ) async {
    final json = jsonDecode(await assets.loadString('${squirrelDir}squirrels.json'))
        as Map<String, dynamic>;
    final frame = Size((json['frameWidth'] as num).toDouble(),
        (json['frameHeight'] as num).toDouble());
    final anchorJson = json['anchor'] as Map<String, dynamic>;
    final anchor = Offset((anchorJson['x'] as num).toDouble(),
        (anchorJson['y'] as num).toDouble());
    final worldHeight = (json['worldHeight'] as num).toDouble();
    final sheets = <String, SpriteSheetSpec>{};
    (json['poses'] as Map<String, dynamic>).forEach((pose, raw) {
      final spec = raw as Map<String, dynamic>;
      final image = images['$squirrelDir${spec['file']}'];
      if (image == null) return;
      sheets[pose] = SpriteSheetSpec(
        image: image,
        frames: (spec['frames'] as num).toInt(),
        fps: (spec['fps'] as num).toDouble(),
        frameSize: frame,
        anchor: anchor,
        worldHeight: worldHeight,
      );
    });
    return sheets;
  }
}

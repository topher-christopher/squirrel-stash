import 'dart:ui';

import '../../models/room.dart';
import '../art/paint_kit.dart';
import '../layout.dart';
import '../rooms/bill_vault_art.dart';
import '../rooms/kitchen_art.dart';
import '../rooms/lab_goals_art.dart';
import '../rooms/metro_art.dart';
import '../rooms/outfitter_art.dart';
import '../rooms/pocket_art.dart';
import '../rooms/room_kit.dart';
import '../rooms/treasury_art.dart';
import '../rooms/trophy_hall_art.dart';
import 'diorama_layer.dart';

/// Draws every room: a cached static layer per room (re-recorded when its
/// level or contents change) and its animated residents each frame.
class RoomsLayer extends DioramaLayer {
  RoomsLayer() : super(priority: 30);

  final Map<RoomKey, PictureCache> _caches = {
    for (final r in RoomKey.values) r: PictureCache(),
  };

  final Map<RoomKey, RoomArt> _art = {
    RoomKey.treasury: const TreasuryArt(),
    RoomKey.outfitter: const OutfitterArt(),
    RoomKey.lab: LabArt(),
    RoomKey.trophyHall: const TrophyHallArt(),
    RoomKey.billVault: BillVaultArt(),
    RoomKey.kitchen: const KitchenArt(),
    RoomKey.goals: const GoalsArt(),
    RoomKey.metro: const MetroArt(),
    for (final r in RoomKey.values)
      if (r.size == RoomSize.pocket) r: const PocketArt(),
  };

  @override
  void render(Canvas canvas) {
    for (final room in RoomKey.values) {
      final ctx = RoomCtx(
        room: room,
        r: TreeLayout.room(room),
        t: t,
        level: snap.levelOf(room),
        detail: game.detail,
        snap: snap,
        art: game.art,
      );
      final art = _art[room]!;
      final squash = game.pokeAmount(room.name);
      canvas.save();
      if (squash != 0) {
        final pivot = ctx.r.bottomCenter;
        canvas.translate(pivot.dx, pivot.dy);
        canvas.scale(1 + squash * 0.025, 1 - squash * 0.035);
        canvas.translate(-pivot.dx, -pivot.dy);
      }
      final key = '${ctx.level}|${snap.frost}|${_contentKey(room)}|${game.art.isEmpty}';
      _caches[room]!.draw(canvas, key, (c) {
        if (!RoomKit.customArt(c, ctx)) {
          art.paintStatic(c, ctx);
          RoomKit.carvedName(c, ctx);
        }
      });
      art.paintLive(canvas, ctx);
      canvas.restore();
    }
  }

  /// Extra cache-key parts for rooms whose static art shows data.
  String _contentKey(RoomKey room) => switch (room) {
        RoomKey.trophyHall => '${snap.trophyCount}|${snap.statueCount}',
        _ => '',
      };

  @override
  void onRemove() {
    for (final c in _caches.values) {
      c.dispose();
    }
    super.onRemove();
  }
}

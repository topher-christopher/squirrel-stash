import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../models/room.dart';
import '../../providers/room_summary_provider.dart';
import '../../providers/stash_actions.dart';
import '../../providers/ui_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/acorn_icons.dart';
import '../widgets/animated_money.dart';
import '../widgets/room_icons.dart';
import '../widgets/stash_controls.dart';
import 'bills_drawer.dart';
import 'drawer_shell.dart';
import 'goals_drawer.dart';
import 'half_sheet.dart';
import 'kitchen_drawer.dart';
import 'lab_drawer.dart';
import 'metro_drawer.dart';
import 'outfitter_drawer.dart';
import 'reserve_drawer.dart';
import 'treasury_drawer.dart';
import 'trophies_drawer.dart';

/// One bottom sheet for every room. It opens at half height so the zoomed
/// room stays visible above it; drag the header up for the full drawer.
/// Swipe left/right (or tap the pills) to move between rooms without
/// zooming out — the tree camera follows along.
class RoomDrawer extends ConsumerStatefulWidget {
  const RoomDrawer({super.key, required this.initial});

  final RoomKey initial;

  @override
  ConsumerState<RoomDrawer> createState() => _RoomDrawerState();
}

class _RoomDrawerState extends ConsumerState<RoomDrawer> {
  late final PageController _pages = PageController(initialPage: widget.initial.index);
  final ScrollController _pills = ScrollController();
  late int _index = widget.initial.index;

  static const _pillWidth = 46.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stashActionsProvider).visitedRoom(widget.initial);
      _scrollPills(_index, animate: false);
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _pills.dispose();
    super.dispose();
  }

  void _scrollPills(int i, {bool animate = true}) {
    if (!_pills.hasClients) return;
    final target = (i * _pillWidth - _pills.position.viewportDimension / 2 + _pillWidth / 2)
        .clamp(0.0, _pills.position.maxScrollExtent);
    animate
        ? _pills.animateTo(target, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic)
        : _pills.jumpTo(target);
  }

  void _onPage(int i) {
    Haptics.tap();
    setState(() => _index = i);
    final room = RoomKey.values[i];
    ref.read(stashActionsProvider).visitedRoom(room);
    ref.read(uiProvider.notifier).focusCamera(room);
    _scrollPills(i);
  }

  @override
  Widget build(BuildContext context) {
    final room = RoomKey.values[_index];
    final accent = RoomIcons.accent(room);
    return HalfSheet(
      header: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 12, 6),
          child: Row(children: [
            RoomMedallion(room: room, size: 42, glow: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(room.title, key: ValueKey(room), style: AppType.title(20, color: accent, height: 1.15)),
                ),
                _HeadlineTotal(room: room, color: accent),
              ]),
            ),
            const ClosePeg(),
          ]),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            controller: _pills,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: RoomKey.values.length,
            itemExtent: _pillWidth,
            itemBuilder: (context, i) {
              final r = RoomKey.values[i];
              final on = i == _index;
              return Center(
                child: Tooltip(
                  message: r.title,
                  child: PressScale(
                    onTap: () => _pages.animateToPage(i,
                        duration: const Duration(milliseconds: 360), curve: Curves.easeOutCubic),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: on ? 40 : 34,
                      height: on ? 34 : 30,
                      decoration: BoxDecoration(
                        color: on ? RoomIcons.accent(r).withValues(alpha: 0.25) : AppColors.barkDeep,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: on ? RoomIcons.accent(r) : AppColors.amber.withValues(alpha: 0.18)),
                      ),
                      child: Icon(RoomIcons.icon(r), size: on ? 19 : 16,
                          color: on ? RoomIcons.accent(r) : AppColors.stoneDim),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _Dots(count: RoomKey.values.length, index: _index, color: accent),
      ]),
      body: PageView.builder(
        controller: _pages,
        itemCount: RoomKey.values.length,
        onPageChanged: _onPage,
        itemBuilder: (context, i) => roomBody(RoomKey.values[i]),
      ),
    );
  }
}

/// The scrollable content for one room page.
Widget roomBody(RoomKey room) => switch (room) {
      RoomKey.treasury => const TreasuryBody(),
      RoomKey.outfitter => const OutfitterBody(),
      RoomKey.lab => const LabBody(),
      RoomKey.trophyHall => const TrophyHallBody(),
      RoomKey.billVault => const BillsBody(),
      RoomKey.kitchen => const KitchenBody(),
      RoomKey.goals => const GoalsBody(),
      RoomKey.metro => const MetroBody(),
      _ => ReserveBody(kind: room.reserve!),
    };

/// The room's headline number (Free Cash, unpaid bills, vault value…) with
/// its tagline — the tree itself shows no numbers.
class _HeadlineTotal extends ConsumerWidget {
  const _HeadlineTotal({required this.room, required this.color});

  final RoomKey room;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(roomSummaryProvider(room));
    final value = AppType.number(15, weight: FontWeight.w700, color: color);
    final sub = AppType.body(12, color: AppColors.honey.withValues(alpha: 0.75));
    return Row(children: [
      if (s.cents != null) AnimatedMoney(s.cents!, style: value),
      if (s.acorns != null) AcornAmount(s.acorns!, size: 14, style: value),
      if (s.cents != null || s.acorns != null) const SizedBox(width: 6),
      Flexible(
        child: Text(s.text ?? room.tagline,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: sub),
      ),
    ]);
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.color});

  final int count;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: i == index ? 14 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: i == index ? color : AppColors.stoneDim.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ]),
      );
}

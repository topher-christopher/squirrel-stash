import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/bill.dart';
import '../../providers/bills_provider.dart';
import '../../theme/app_typography.dart';

/// Retro red Etch A Sketch with acorn-cap knobs: live "Days Until Due" for
/// every bill, highlighting anything due within 5 days or today.
class EtchBoard extends ConsumerWidget {
  const EtchBoard({super.key});

  static const urgentDays = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billsProvider);
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF7F1D1D), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(children: [
        Text('DAYS UNTIL DUE', style: AppType.label(10, color: const Color(0xFFFEF3C7), letterSpacing: 2)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF94A3B8)),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, spreadRadius: -2)],
          ),
          child: bills.isEmpty
              ? Text('Nothing due — doodle away!', textAlign: TextAlign.center, style: _ink(13, const Color(0xFF475569)))
              : Column(children: [for (final b in bills) _Line(bill: b, days: b.daysUntilDue(now))]),
        ),
        const SizedBox(height: 6),
        const Row(children: [_Knob(), Spacer(), _Knob()]),
      ]),
    );
  }

  static TextStyle _ink(double size, Color color) =>
      AppType.title(size, weight: FontWeight.w600, color: color, letterSpacing: 0.4);
}

class _Line extends StatelessWidget {
  const _Line({required this.bill, required this.days});

  final Bill bill;
  final int days;

  @override
  Widget build(BuildContext context) {
    final urgent = !bill.paid && days <= EtchBoard.urgentDays;
    final ink = bill.paid
        ? const Color(0xFF64748B)
        : (urgent ? const Color(0xFFB91C1C) : const Color(0xFF334155));
    final label = bill.paid
        ? 'PAID'
        : days < 0
            ? '${-days}d LATE'
            : days == 0
                ? 'DUE TODAY'
                : '$days ${days == 1 ? 'day' : 'days'}';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: urgent ? const Color(0x22DC2626) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(children: [
        Expanded(
          child: Text(bill.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EtchBoard._ink(13.5, ink).copyWith(
                  decoration: bill.paid ? TextDecoration.lineThrough : null)),
        ),
        Text(label, style: EtchBoard._ink(13.5, ink)),
      ]),
    );
  }
}

class _Knob extends StatelessWidget {
  const _Knob();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 26,
        height: 26,
        child: Stack(alignment: Alignment.center, children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle),
          ),
          // Acorn-cap knob top
          Positioned(
            top: 4,
            child: Container(
              width: 20,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF78350F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10), bottom: Radius.circular(3)),
              ),
            ),
          ),
        ]),
      );
}

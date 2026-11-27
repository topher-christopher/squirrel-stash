import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ids.dart';
import '../models/bill.dart';
import 'repository_providers.dart';

final billsProvider =
    NotifierProvider<BillsNotifier, List<Bill>>(BillsNotifier.new);

/// Bills in due-date order. Paid recurring bills whose date has passed roll
/// forward to their next monthly cycle automatically.
class BillsNotifier extends Notifier<List<Bill>> {
  @override
  List<Bill> build() {
    final now = DateTime.now();
    final loaded = ref.watch(stashSnapshotProvider).bills;
    final rolled = [for (final b in loaded) b.rolledForward(now)];
    final changed = [
      for (var i = 0; i < loaded.length; i++)
        if (!identical(loaded[i], rolled[i])) rolled[i],
    ];
    if (changed.isNotEmpty) {
      Future.microtask(() {
        for (final b in changed) {
          _save(b);
        }
      });
    }
    return _sorted(rolled);
  }

  static List<Bill> _sorted(Iterable<Bill> bills) => bills.toList()
    ..sort((a, b) {
      final byDate = a.dueDate.compareTo(b.dueDate);
      return byDate != 0 ? byDate : a.sortOrder.compareTo(b.sortOrder);
    });

  void _save(Bill bill) =>
      persist(ref.read(stashRepositoryProvider).upsertBill(bill));

  Bill? byId(String id) => state.where((b) => b.id == id).firstOrNull;

  Bill add({
    required String name,
    required int amountCents,
    required DateTime dueDate,
    BillKind kind = BillKind.other,
    int? dueDay,
  }) {
    final bill = Bill(
      id: newId('bill'),
      name: name,
      amountCents: amountCents,
      dueDate: dueDate,
      sortOrder: state.length,
      kind: kind,
      dueDay: dueDay,
    );
    state = _sorted([...state, bill]);
    _save(bill);
    return bill;
  }

  void upsert(Bill bill) {
    state = _sorted([
      for (final b in state)
        if (b.id != bill.id) b,
      bill,
    ]);
    _save(bill);
  }

  /// Flips a bill between Upcoming and Paid. Balances are not touched —
  /// checking mirrors what the bank reports.
  void togglePaid(String id) {
    final bill = byId(id);
    if (bill != null) upsert(bill.copyWith(paid: !bill.paid).rolledForward(DateTime.now()));
  }

  void remove(String id) {
    state = [for (final b in state) if (b.id != id) b];
    persist(ref.read(stashRepositoryProvider).deleteBill(id));
    ref.read(statementsProvider.notifier).dropForBill(id);
  }
}

final statementsProvider =
    NotifierProvider<StatementsNotifier, List<BillStatement>>(StatementsNotifier.new);

/// Monthly statement history (one row per bill per `yyyy-mm`).
class StatementsNotifier extends Notifier<List<BillStatement>> {
  @override
  List<BillStatement> build() => ref.watch(stashSnapshotProvider).statements.toList()
    ..sort((a, b) => a.yearMonth.compareTo(b.yearMonth));

  List<BillStatement> forBill(String billId) =>
      state.where((s) => s.billId == billId).toList();

  /// Records (or replaces) [bill]'s statement for its current cycle month.
  BillStatement record(Bill bill, int amountCents) {
    final key = bill.cycleKey;
    final statement = BillStatement(
      id: 'stmt_${bill.id}_$key',
      billId: bill.id,
      yearMonth: key,
      amountCents: amountCents,
      recordedAt: DateTime.now(),
    );
    state = [
      for (final s in state)
        if (!(s.billId == bill.id && s.yearMonth == key)) s,
      statement,
    ]..sort((a, b) => a.yearMonth.compareTo(b.yearMonth));
    persist(ref.read(stashRepositoryProvider).upsertStatement(statement));
    return statement;
  }

  void remove(String id) {
    state = [for (final s in state) if (s.id != id) s];
    persist(ref.read(stashRepositoryProvider).deleteStatement(id));
  }

  void dropForBill(String billId) =>
      state = [for (final s in state) if (s.billId != billId) s];
}

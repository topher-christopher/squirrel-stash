import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ids.dart';
import '../models/bill.dart';
import 'repository_providers.dart';

final billsProvider =
    NotifierProvider<BillsNotifier, List<Bill>>(BillsNotifier.new);

class BillsNotifier extends Notifier<List<Bill>> {
  @override
  List<Bill> build() => _sorted(ref.watch(stashSnapshotProvider).bills);

  static List<Bill> _sorted(Iterable<Bill> bills) => bills.toList()
    ..sort((a, b) {
      final byDate = a.dueDate.compareTo(b.dueDate);
      return byDate != 0 ? byDate : a.sortOrder.compareTo(b.sortOrder);
    });

  void _save(Bill bill) =>
      persist(ref.read(stashRepositoryProvider).upsertBill(bill));

  Bill add({
    required String name,
    required int amountCents,
    required DateTime dueDate,
  }) {
    final bill = Bill(
      id: newId('bill'),
      name: name,
      amountCents: amountCents,
      dueDate: dueDate,
      sortOrder: state.length,
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

  /// Prototype mechanic: tapping a bill flips it between Upcoming and Paid.
  /// Balances are not touched — checking mirrors what the bank reports.
  void togglePaid(String id) {
    final bill = state.where((b) => b.id == id).firstOrNull;
    if (bill != null) upsert(bill.copyWith(paid: !bill.paid));
  }

  void remove(String id) {
    state = [for (final b in state) if (b.id != id) b];
    persist(ref.read(stashRepositoryProvider).deleteBill(id));
  }
}

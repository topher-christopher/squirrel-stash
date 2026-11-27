import 'package:material_ui/material_ui.dart';

import '../../core/money.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';

/// Asks for a dollar amount; returns cents or null when cancelled.
Future<int?> promptAmount(
  BuildContext context, {
  required String title,
  String? message,
  int? initialCents,
  String confirmLabel = 'Save',
}) {
  final controller = TextEditingController(text: initialCents == null ? '' : Money.plain(initialCents));
  return showDialog<int>(
    context: context,
    builder: (context) {
      void submit() {
        final cents = Money.parse(controller.text);
        if (cents != null) Navigator.of(context).pop(cents);
      }

      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (message != null) ...[
              Text(message, style: AppType.body(13, color: AppColors.stone)),
              const SizedBox(height: 12),
            ],
            StashField(controller: controller, money: true, autofocus: true, hint: '0.00', onSubmitted: (_) => submit()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: AppType.body(14, color: AppColors.stone))),
          PillButton(label: confirmLabel, dense: true, onPressed: submit),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}

/// Asks for a label + amount pair (new holding, edited bill…).
Future<(String, int)?> promptLabelAmount(
  BuildContext context, {
  required String title,
  String labelHint = 'Name',
  String initialLabel = '',
  int? initialCents,
  String confirmLabel = 'Save',
}) {
  final label = TextEditingController(text: initialLabel);
  final amount = TextEditingController(text: initialCents == null ? '' : Money.plain(initialCents));
  return showDialog<(String, int)>(
    context: context,
    builder: (context) {
      void submit() {
        final cents = Money.parse(amount.text);
        if (label.text.trim().isEmpty || cents == null) return;
        Navigator.of(context).pop((label.text.trim(), cents));
      }

      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StashField(controller: label, hint: labelHint, autofocus: true),
            const SizedBox(height: 10),
            StashField(controller: amount, money: true, hint: '0.00', onSubmitted: (_) => submit()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: AppType.body(14, color: AppColors.stone))),
          PillButton(label: confirmLabel, dense: true, onPressed: submit),
        ],
      );
    },
  ).whenComplete(() {
    label.dispose();
    amount.dispose();
  });
}

/// Yes/no confirmation; destructive actions use a red confirm pill.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message, style: AppType.body(14, color: AppColors.stone, height: 1.35)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Keep', style: AppType.body(14, color: AppColors.stone))),
        PillButton(
          label: confirmLabel,
          dense: true,
          color: destructive ? const Color(0xFFB91C1C) : AppColors.amber,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Themed date picker.
Future<DateTime?> pickDate(BuildContext context, DateTime initial) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 15),
  );
}

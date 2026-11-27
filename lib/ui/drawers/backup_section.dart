import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backup_files.dart';
import '../../database/backup_codec.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import 'prompts.dart';

/// Settings → "Your data": export the whole stash as a JSON file (share
/// sheet or save dialog) and restore one after a reinstall.
class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({super.key});

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  final _shareKey = GlobalKey();
  bool _busy = false;

  /// Inline result line (a SnackBar would sit behind the modal sheet).
  ({String text, bool error})? _status;

  /// Runs [task] with the buttons disabled; failures land in [_status].
  Future<void> _run(Future<String?> Function() task) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    ({String text, bool error})? status;
    try {
      final done = await task();
      if (done != null) status = (text: done, error: false);
    } on BackupFormatException catch (e) {
      status = (text: e.message, error: true);
    } catch (e) {
      debugPrint('SquirrelStash: backup failed ($e)');
      status = (text: 'Something went wrong, and nothing was changed. ($e)', error: true);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = status;
    });
  }

  Rect? _shareOrigin() {
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<String?> _export({required bool saveAs}) async {
    final snapshot = await ref.read(stashRepositoryProvider).loadAll();
    final done = saveAs
        ? await BackupFiles.saveAs(snapshot)
        : await BackupFiles.share(snapshot, origin: _shareOrigin());
    if (!done) return null;
    return '${saveAs ? 'Backup saved' : 'Backup shared'}. Keep a copy somewhere off this phone.';
  }

  Future<String?> _import() async {
    final backup = await BackupFiles.pick();
    if (backup == null || !mounted) return null;
    final at = backup.exportedAt;
    final from = at == null ? 'this backup' : 'the backup from ${DateFormat.yMMMd().add_jm().format(at)}';
    final ok = await confirmAction(
      context,
      title: 'Restore this backup?',
      message: 'Replaces everything on this device with $from:\n\n'
          '${BackupCodec.describe(backup.snapshot)}\n\n'
          'Export a backup first if you want to keep what is here now.',
      confirmLabel: 'Restore',
      destructive: true,
    );
    if (!ok || !mounted) return null;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await ref.read(stashSnapshotProvider.notifier).replace(backup.snapshot);
    if (mounted) Navigator.of(context).pop();
    messenger?.showSnackBar(const SnackBar(content: Text('Backup restored 🌳')));
    return null;
  }

  /// iOS's share sheet already has "Save to Files"; elsewhere a direct save
  /// dialog is the surest way to land the file in Downloads or Drive.
  bool get _offerSaveAs => defaultTargetPlatform != TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    final busy = _busy, status = _status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your stash lives only on this device, and uninstalling the app erases it. '
          'Export a backup now and then and keep it in Google Drive or Files.',
          style: AppType.body(12, color: AppColors.stone, height: 1.4),
        ),
        const SizedBox(height: 10),
        PillButton(
          key: _shareKey,
          label: '📤 Export backup',
          color: AppColors.emeraldButton,
          expand: true,
          onPressed: busy ? null : () => _run(() => _export(saveAs: false)),
        ),
        if (_offerSaveAs) ...[
          const SizedBox(height: 8),
          PillButton(
            label: '💾 Save backup to Files',
            outlined: true,
            color: AppColors.emeraldBright,
            expand: true,
            onPressed: busy ? null : () => _run(() => _export(saveAs: true)),
          ),
        ],
        const SizedBox(height: 8),
        PillButton(
          label: '📥 Import backup',
          outlined: true,
          color: AppColors.honey,
          expand: true,
          onPressed: busy ? null : () => _run(_import),
        ),
        if (status != null) ...[
          const SizedBox(height: 8),
          Text(
            status.text,
            style: AppType.body(12.5,
                weight: FontWeight.w700, color: status.error ? AppColors.alertSoft : AppColors.emeraldSoft, height: 1.35),
          ),
        ],
      ],
    );
  }
}

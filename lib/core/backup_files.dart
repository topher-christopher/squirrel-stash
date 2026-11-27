import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/backup_codec.dart';
import '../models/stash_snapshot.dart';

/// Platform side of manual backups: share sheet, save dialog and file picker.
/// The JSON format itself lives in [BackupCodec].
abstract final class BackupFiles {
  /// Larger than any real stash by orders of magnitude; guards against
  /// someone picking a video by mistake.
  static const _maxBytes = 25 * 1024 * 1024;

  static ({String name, Uint8List bytes}) _encode(StashSnapshot snapshot) {
    final now = DateTime.now();
    return (
      name: BackupCodec.fileName(now),
      bytes: utf8.encode(BackupCodec.encode(snapshot, exportedAt: now)),
    );
  }

  /// Writes the backup to the temp folder and opens the platform share sheet
  /// (Google Drive, Files, email…). Returns false if the user dismissed it.
  static Future<bool> share(StashSnapshot snapshot, {Rect? origin}) async {
    final file = _encode(snapshot);
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, file.name);
    await File(path).writeAsBytes(file.bytes, flush: true);
    final result = await SharePlus.instance.share(ShareParams(
      files: [XFile(path, mimeType: 'application/json', name: file.name)],
      subject: 'SquirrelStash backup',
      title: file.name,
      sharePositionOrigin: origin,
    ));
    return result.status != ShareResultStatus.dismissed;
  }

  /// Opens the system "save as" dialog. Returns false if cancelled.
  static Future<bool> saveAs(StashSnapshot snapshot) async {
    final file = _encode(snapshot);
    final uri = await FilePicker.saveFile(
      fileName: file.name,
      bytes: file.bytes,
      mimeType: 'application/json',
      dialogTitle: 'Save SquirrelStash backup',
    );
    return uri != null;
  }

  /// Lets the user pick a backup file and decodes it. Returns null when the
  /// picker is cancelled; throws [BackupFormatException] for bad files.
  static Future<StashBackup?> pick() async {
    // FileType.any: Drive and some file managers report .json files under
    // other MIME types, so filtering would hide real backups. The codec
    // validates the contents instead.
    final picked = await FilePicker.pickFile(dialogTitle: 'Choose a SquirrelStash backup');
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    if (bytes.length > _maxBytes) {
      throw const BackupFormatException("That file is far too large to be a SquirrelStash backup.");
    }
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      throw const BackupFormatException("That file isn't a SquirrelStash backup (it isn't text).");
    }
    return BackupCodec.decode(text);
  }
}

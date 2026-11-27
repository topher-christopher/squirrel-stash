// Procedurally synthesizes SquirrelStash's bundled audio stems.
//
//   dart run tool/generate_audio.dart
//
// Writes 16-bit mono WAVs to assets/audio/. Deterministic, so re-running is
// reproducible. v1.2 retired the campfire/breeze loops and the owl chime; the
// optional background piano is a drop-in file (assets/audio/ambient_piano.wav),
// never generated here.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _rate = 22050;

void main() {
  Directory('assets/audio').createSync(recursive: true);
  _write('assets/audio/plink.wav', _plink());
  stdout.writeln('Wrote plink to assets/audio/');
}

Float64List _plink() {
  final n = (0.35 * _rate).round();
  final out = Float64List(n);
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final s = i / _rate;
    final f = 1480 * (1 - 0.08 * math.min(1.0, s / 0.05));
    phase += 2 * math.pi * f / _rate;
    final env = math.min(1.0, s / 0.002) * math.exp(-s / 0.07);
    out[i] = (math.sin(phase) + 0.3 * math.sin(phase * 2.01)) * env;
  }
  return _normalize(out, 0.6);
}

Float64List _normalize(Float64List s, double peak) {
  var max = 1e-9;
  for (final v in s) {
    max = math.max(max, v.abs());
  }
  final g = peak / max;
  for (var i = 0; i < s.length; i++) {
    s[i] *= g;
  }
  return s;
}

void _write(String path, Float64List samples) {
  final dataBytes = samples.length * 2;
  final b = ByteData(44 + dataBytes);
  void str(int o, String v) {
    for (var i = 0; i < v.length; i++) {
      b.setUint8(o + i, v.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  b.setUint32(4, 36 + dataBytes, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little); // PCM
  b.setUint16(22, 1, Endian.little); // mono
  b.setUint32(24, _rate, Endian.little);
  b.setUint32(28, _rate * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  str(36, 'data');
  b.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    b.setInt16(44 + i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  File(path).writeAsBytesSync(b.buffer.asUint8List());
}

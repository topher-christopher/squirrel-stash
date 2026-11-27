// Procedurally synthesizes SquirrelStash's bundled audio stems.
//
//   dart run tool/generate_audio.dart
//
// Writes 16-bit mono WAVs to assets/audio/. Loops are crossfaded so they
// repeat seamlessly. Deterministic (seeded) so re-running is reproducible.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _rate = 22050;

void main() {
  Directory('assets/audio').createSync(recursive: true);
  _write('assets/audio/campfire.wav', _loop(_campfire(10), 0.6));
  _write('assets/audio/forest_breeze.wav', _loop(_breeze(12), 0.8));
  _write('assets/audio/chime.wav', _chime());
  _write('assets/audio/plink.wav', _plink());
  stdout.writeln('Wrote campfire, forest_breeze, chime and plink to assets/audio/');
}

Float64List _campfire(double seconds) {
  final rng = math.Random(7);
  final n = (seconds * _rate).round();
  final out = Float64List(n);
  var brown = 0.0;
  var low = 0.0;
  for (var i = 0; i < n; i++) {
    brown = (brown + (rng.nextDouble() * 2 - 1) * 0.02) * 0.995;
    low += 0.06 * (brown - low);
    out[i] = low * 2.2;
  }
  // Wood crackles: short bursts of bright noise with fast decay.
  var t = 0;
  while (t < n) {
    t += (_rate * (0.05 + rng.nextDouble() * 0.35)).round();
    final amp = 0.15 + rng.nextDouble() * 0.5 * (rng.nextDouble() < 0.12 ? 1.6 : 1);
    final len = (_rate * (0.004 + rng.nextDouble() * 0.02)).round();
    var hp = 0.0;
    var prev = 0.0;
    for (var k = 0; k < len && t + k < n; k++) {
      final white = rng.nextDouble() * 2 - 1;
      hp = 0.7 * (hp + white - prev);
      prev = white;
      out[t + k] += hp * amp * math.exp(-k / (len * 0.25));
    }
  }
  return _normalize(out, 0.55);
}

Float64List _breeze(double seconds) {
  final rng = math.Random(11);
  final n = (seconds * _rate).round();
  final out = Float64List(n);
  var b0 = 0.0, b1 = 0.0, b2 = 0.0, low = 0.0;
  for (var i = 0; i < n; i++) {
    final white = rng.nextDouble() * 2 - 1;
    b0 = 0.99765 * b0 + white * 0.0990460;
    b1 = 0.96300 * b1 + white * 0.2965164;
    b2 = 0.57000 * b2 + white * 1.0526913;
    final pink = (b0 + b1 + b2 + white * 0.1848) * 0.2;
    final s = i / _rate;
    final gust = 0.45 + 0.35 * math.sin(2 * math.pi * s / seconds) + 0.2 * math.sin(2 * math.pi * s * 3 / seconds + 1.3);
    low += (0.03 + gust * 0.05) * (pink - low);
    out[i] = low * gust * 2.4;
  }
  // A few distant bird chirps (pitch sweeps with tremolo).
  for (final start in [1.4, 1.62, 4.9, 7.3, 7.48, 7.66, 10.2]) {
    final i0 = (start * _rate).round();
    final len = (_rate * 0.09).round();
    var phase = 0.0;
    for (var k = 0; k < len && i0 + k < n; k++) {
      final u = k / len;
      final f = 2600 + 1100 * math.sin(u * math.pi);
      phase += 2 * math.pi * f / _rate;
      out[i0 + k] += math.sin(phase) * math.sin(u * math.pi) * 0.09 * (0.6 + 0.4 * math.sin(k / 40));
    }
  }
  return _normalize(out, 0.45);
}

Float64List _chime() {
  final n = (1.9 * _rate).round();
  final out = Float64List(n);
  void bell(double startSec, double f0, double gain) {
    const partials = [(1.0, 1.0, 1.6), (2.0, 0.45, 0.9), (2.76, 0.3, 0.6), (5.4, 0.12, 0.25)];
    final i0 = (startSec * _rate).round();
    for (var i = i0; i < n; i++) {
      final s = (i - i0) / _rate;
      final attack = math.min(1.0, s / 0.004);
      for (final (ratio, amp, decay) in partials) {
        out[i] += math.sin(2 * math.pi * f0 * ratio * s) * amp * math.exp(-s / decay * 1.4) * gain * attack;
      }
    }
  }

  bell(0, 1046.5, 0.5); // C6
  bell(0.14, 1568.0, 0.35); // G6
  return _normalize(out, 0.7);
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

/// Crossfades the tail into the head so the buffer loops without a click.
Float64List _loop(Float64List s, double fadeSeconds) {
  final f = (fadeSeconds * _rate).round();
  final out = Float64List(s.length - f);
  for (var i = 0; i < out.length; i++) {
    out[i] = s[i];
  }
  for (var i = 0; i < f; i++) {
    final u = i / f;
    out[i] = s[i] * u + s[s.length - f + i] * (1 - u);
  }
  return out;
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

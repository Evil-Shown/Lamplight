// Regenerates the UI sounds in assets/sounds/.
//
//   dart run tool/generate_sounds.dart
//
// Each sound is a few soft sine/triangle partials with a short attack (no
// click) and an exponential fade-out, 16-bit mono PCM at 44.1 kHz.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int _rate = 44100;

class _Note {
  const _Note(this.freq, this.start, this.length, this.gain,
      {this.triangle = false});
  final double freq;
  final double start; // seconds
  final double length; // seconds
  final double gain;
  final bool triangle;
}

double _wave(double phase, bool triangle) {
  if (!triangle) return math.sin(phase);
  // Triangle from phase, band-limited enough at these low frequencies.
  final t = (phase / (2 * math.pi)) % 1.0;
  return 4 * (t < 0.5 ? t : 1 - t) - 1;
}

Uint8List _render(List<_Note> notes, double total) {
  final n = (total * _rate).round();
  final buf = List<double>.filled(n, 0);
  for (final note in notes) {
    final s0 = (note.start * _rate).round();
    final len = (note.length * _rate).round();
    const attack = 0.004; // seconds, avoids clicks
    for (var i = 0; i < len && s0 + i < n; i++) {
      final t = i / _rate;
      final env = math.min(1.0, t / attack) *
          math.exp(-5.5 * i / len) *
          (1 - math.pow(i / len, 8)); // hard-zero at the very end
      buf[s0 + i] += note.gain *
          env *
          _wave(2 * math.pi * note.freq * t, note.triangle);
    }
  }
  final bytes = ByteData(44 + n * 2);
  void ascii(int off, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(off + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + n * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, _rate, Endian.little);
  bytes.setUint32(28, _rate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    bytes.setInt16(44 + i * 2, (buf[i].clamp(-1.0, 1.0) * 32767).round(),
        Endian.little);
  }
  return bytes.buffer.asUint8List();
}

void main() {
  final sounds = <String, (List<_Note>, double)>{
    // Soft low "tick".
    'tap': ([const _Note(520, 0, 0.09, 0.55), const _Note(1040, 0, 0.05, 0.12)], 0.1),
    // Slightly brighter, short rising pair.
    'select': (
      [
        const _Note(660, 0, 0.09, 0.5, triangle: true),
        const _Note(880, 0.045, 0.1, 0.4),
      ],
      0.16
    ),
    // Switch click: quick two-tone.
    'toggle': (
      [
        const _Note(440, 0, 0.07, 0.5),
        const _Note(620, 0.035, 0.09, 0.4, triangle: true),
      ],
      0.14
    ),
    // Gentle major arpeggio C5-E5-G5.
    'success': (
      [
        const _Note(523.25, 0, 0.22, 0.45),
        const _Note(659.25, 0.07, 0.22, 0.4),
        const _Note(783.99, 0.14, 0.3, 0.38),
      ],
      0.38
    ),
    // Low soft descending minor third; deliberately not a buzzer.
    'error': (
      [
        const _Note(311.13, 0, 0.16, 0.5, triangle: true),
        const _Note(246.94, 0.09, 0.22, 0.5, triangle: true),
      ],
      0.34
    ),
  };
  final dir = Directory('assets/sounds')..createSync(recursive: true);
  sounds.forEach((name, spec) {
    final data = _render(spec.$1, spec.$2);
    File('${dir.path}/$name.wav').writeAsBytesSync(data);
    stdout.writeln('$name.wav  ${(spec.$2 * 1000).round()} ms  ${data.length} B');
  });
}

import 'dart:math';

final Random _rng = Random();
int _counter = 0;

/// Short, collision-resistant local id such as `goal_lx3k9a2f1`.
String newId(String prefix) {
  _counter = (_counter + 1) & 0xFFFF;
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final salt = (_rng.nextInt(1 << 20) ^ _counter).toRadixString(36);
  return '${prefix}_$time$salt';
}

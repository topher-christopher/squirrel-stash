import 'package:flame/components.dart';

import '../diorama_snapshot.dart';
import '../stash_diorama_game.dart';

/// Base for diorama layers. Layers draw in absolute world coordinates.
abstract class DioramaLayer extends Component
    with HasGameReference<StashDioramaGame> {
  DioramaLayer({super.priority});

  DioramaSnapshot get snap => game.snapshot;
  double get t => game.time;
}

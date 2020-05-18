import 'package:example/src/column.dart';
import 'package:example/src/sqlite_type.dart';
import 'package:example/src/wrapper.dart';

class Player {
  const Player();

  final columnName = 'Player';

  final id = const Column<Integer>();

  /// First name of player.
  final firstName = const Column<Text>(
    defaultValue: Text('Thomas'),
  );
}



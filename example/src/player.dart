import 'package:sqlite_entity/sqlite_entity.dart';

class Player {
  const Player();

  final columnName = 'Player';

  final id = const Column<Integer>(
    constraints: {
      Constraint.PRIMARY_KEY,
    },
  );

  /// First name of player.
  final firstName = const Column<Text>(
    defaultValue: Text('Thomas'),
    constraints: {
      Constraint.NOT_NULL,
      Constraint.UNIQUE,
    },
  );
}

import 'package:example/src/column.dart';
import 'package:example/src/sponsor.dart';
import 'package:example/src/sqlite_type.dart';

/// Class modelling a player.
class Player {
  const Player();

  /// Column name
  final columnName = 'Player';

  /// Column storing player id.
  final id = const Column<Integer>();

  /// Column storing first name of player.
  final firstName = const Column<Text>(
    defaultValue: Text('Thomas'),
  );

  /// List of sponsors
  final List<Sponsor> sponsors = const [
    Sponsor('Johnson\'s'),
    Sponsor('Smith Brothers'),
  ];
}

import 'package:example/example_generic_reader.dart';

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

  /// Test unregistered type.
  final unregistered = const UnRegisteredTestType();

  /// Test [Set<int>].
  final Set<int> primeNumbers = const {1, 3, 5, 7, 11, 13};
}

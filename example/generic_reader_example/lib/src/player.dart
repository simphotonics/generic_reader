import 'package:generic_reader_example/src/test_types/column.dart';
import 'package:generic_reader_example/src/test_types/greek.dart';
import 'package:generic_reader_example/src/test_types/sponsor.dart';
import 'package:generic_reader_example/src/test_types/sqlite_type.dart';
import 'package:generic_reader_example/src/test_types/unregistered_test_type.dart';

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

  /// Test enum
  final Greek greek = Greek.alpha;

  /// Test map
  final map = const <String, dynamic>{'one': 1, 'two': 2.0};

  /// Test map with enum entry
  final mapWithEnumEntry = const <String, dynamic>{
    'one': 1,
    'two': 2.0,
    'enum': Greek.alpha
  };
}

import 'package:generic_reader/src/test_types/sqlite_type.dart';

/// Const class for testing purposes.
class Researcher {
  const Researcher();

  final List<Integer> id = const [Integer(87)];

  final List<String> names = const ['Thomas', 'Mayor'];

  final Set<int> integers = const {47, 91};

  final num number = 19;

  final String title = 'Researcher';

  final Real real = const Real(39.5);
}

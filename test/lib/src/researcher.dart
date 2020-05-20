import 'package:generic_reader/src/test_types/sqlite_type.dart';

class Researcher {
  const Researcher();

  final int id = 87;

  final List<String> names = const ['Thomas', 'Mayor'];

  final Set<int> integers = const {47, 91};

  final num number = 19;

  final String title = 'Researcher';

  final Real real = const Real(39.5);
}

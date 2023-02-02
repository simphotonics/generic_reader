import 'package:generic_reader/src/types/unknown_type.dart';
import 'package:test_types/test_types.dart';

/// Const class for testing purposes.
class Researcher {
  const Researcher();

  final Column<int> id =
      const Column<int>(defaultValue: 3, name: 'id');

  final List<String> names = const ['Thomas', 'Mayor'];

  final Set<int> integers = const {47, 91};

  final num number = 19;

  final String role = 'Researcher';

  final Title title = Title.Dr;

  final Map<String, dynamic> map = const <String, dynamic>{
    'one': 1,
    'two': 2.0,
  };

  final Map<String, dynamic> mapWithEnumValue = const <String, dynamic>{
    'one': 1,
    'two': 2.0,
    'title': Title.Prof
  };

  final notRegistered = const UnknownType();
}

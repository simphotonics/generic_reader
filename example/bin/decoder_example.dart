import 'package:analyzer/dart/constant/value.dart';
import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:build_test/build_test.dart' show resolveSource;
import 'package:generic_reader/generic_reader.dart';

/// To run this program navigate to the root folder
/// in your local copy the package `generic_reader` and
/// use the command:
///
/// # dart example/bin/decoder_example.dart

/// Demonstrates how to use [Reader] to read constants.
class A {
  const A({required this.id, required this.names, required this.numbers});
  final int id;
  final Set<String> names;
  final List<num> numbers;

  @override
  String toString() =>
      'A(id: $id, names: $names, '
      'numbers: $numbers )';
}

final a = const A(id: 42, names: {'Andy', 'Eva'}, numbers: [42, 3.14]);

class DecoderForClassA extends Decoder<A> {
  const DecoderForClassA();
  @override
  A read(DartObject obj) {
    final id = obj.read<int>(fieldName: 'id');
    final names = obj.read<Set<String>>(fieldName: 'names');
    final numbers = obj.read<List<num>>(fieldName: 'numbers');
    return A(id: id, names: names, numbers: numbers);
  }
}

const decoderForA = DecoderForClassA();

Future<void> main() async {
  print('\nReading library <example>\n');
  final lib = await resolveSource(
    r'''
    library example;

    class A {
      const A({required this.id, required this.names, required this.numbers});
      final int id;
      final Set<String> names;
      final List<num> numbers;
    }

    class B{
      const B();
      final int id = 124;
      final Map<String, int> score = {'Adam': 4, 'Moira': 7};
      final isValid = true;
      final List<num> numbers = [7, 77.7];
      final a = const A(id: 42, names: {'Andy', 'Eva'}, numbers: [42, 3.14]);
      final num number = 3;
    }

    ''',
    (resolver) => resolver.findLibraryByName('example'),
    //readAllSourcesFromFilesystem: false,
  );

  /// Reading libraries.

  if (lib == null) {
    print('Could not read library!');
    return;
  }

  print(Reader.info);

  final idObj = lib.classes[1].fields[0].computeConstantValue();
  final id = idObj?.read<int>();
  print('Reading an ${'int:'.style(Ansi.green)} $id\n');

  final scoreObj = lib.classes[1].fields[1].computeConstantValue();
  final score = scoreObj?.readMap<String, int>();
  print(
    'Reading a ${'Map<String, int>'.style(Ansi.green)}: '
    '$score ${score.runtimeType}\n',
  );

  final isValidObj = lib.classes[1].fields[2].computeConstantValue();
  final isValid = isValidObj?.read<bool>();
  print(
    'Reading a ${'bool'.style(Ansi.green)}: $isValid ${isValid.runtimeType}\n',
  );

  final numbersObj = lib.classes[1].fields[3].computeConstantValue();
  final numbers = numbersObj?.read<List<num>>();
  print(
    'Reading a ${'List<num>'.style(Ansi.green)}: $numbers ${numbers.runtimeType}\n',
  );

  /// Adding a decoder:
  Reader.addDecoder(decoderForA);

  final aObj = lib.classes[1].fields[4].computeConstantValue();
  final a = aObj?.read<A>();

  print('Reading a constant with type ${'A'.style(Ansi.green)}: $a\n');

  final numberObj = lib.classes[1].fields[5].computeConstantValue();
  final number = numberObj?.read();

  print('Reading a constant with type ${'num'.style(Ansi.green)}: $number\n');

  print(Reader.info);
  return;
}

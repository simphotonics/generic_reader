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
    final names = obj.readSet<String>(fieldName: 'names');
    final numbers = obj.readList<num>(fieldName: 'numbers');
    return A(id: id, names: names, numbers: numbers);
  }
}

const decoderForA = DecoderForClassA();

Future<void> main() async {
  final library = await resolveSource(
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

      final a = const A(id: 42, names: {'Andy', 'Eva'}, numbers: [42, 3.14]);
    }

    ''',
    (resolver) => resolver.findLibraryByName('example'),
    //readAllSourcesFromFilesystem: false,
  );

  /// Reading libraries.
  print('\nReading library <example>\n');

  final lib = library!;

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

  /// Adding a decoder:
  Reader.addDecoder(decoderForA);

  final aObj = lib.classes[1].fields[3].computeConstantValue();
  final a = aObj?.read<A>();

  print('Reading a constant with type ${'A'.style(Ansi.green)}: $a');
}

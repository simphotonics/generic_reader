import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart' show resolveSource;
import 'package:exception_templates/exception_templates.dart';
import 'package:generic_reader/generic_reader.dart';

import 'package:test/test.dart';

final Future<LibraryElement?> library = resolveSource(
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

/// To run this program navigate to the top directory the package
/// [generic_reader] and use the command:
/// # pub run test -r expanded --test-randomize-ordering-seed=random
///
/// Note: The path to player.dart is specified relative to the main
/// directory of [generic_reader].
Future<void> main() async {
  /// Read library.
  final lib = await library;

  if (lib == null) throw TestFailure('Could not read test library');

  final idObj = lib.classes[1].fields[0].computeConstantValue();
  final scoreObj = lib.classes[1].fields[1].computeConstantValue();
  final isValidObj = lib.classes[1].fields[2].computeConstantValue();
  final aObj = lib.classes[1].fields[3].computeConstantValue();

  /// Adding a decoder:
  Reader.addDecoder(decoderForA);

  group('Decoders:', () {
    // Block the removal of decoders for built-in types.
    test('clearDecoder<String>()', () {
      Reader.removeDecoderFor<String>();
      expect(Reader.findDecoder<String>(), stringDecoder);
    });
    test('addDecoder<String>()', () {
      expect(Reader.addDecoder(stringDecoder), false);
    });
    test('addDecoder<List>()', () {});
  });

  group('Reading Constants:', () {
    test('read<int>', () {
      expect(idObj, isNotNull);
      expect(idObj?.read<int>(), 124);
    });
    test('readMap<String, int>', () {
      expect(scoreObj, isNotNull);
      expect(scoreObj!.readMap<String, int>(), const {'Adam': 4, 'Moira': 7});
    });
    test('read<A>()', () {
      expect(aObj, isNotNull);
      expect(
        aObj!.read<A>(),
        isA<A>()
            .having((a) => a.id, 'id', 42)
            .having((a) => a.names, 'names', {'Andy', 'Eva'})
            .having((a) => a.numbers, 'numbers', [42, 3.14]),
      );
    });
    test('read<bool>()', () {
      expect(isValidObj, isNotNull);
      expect(isValidObj!.read<bool>(), true);
    });
  });

  group('Errors:', () {
    test('ErrorOfType<DecoderNotFound>', () {
      expect(isValidObj, isNotNull);

      expect(
        isValidObj!.read<Runes>,
        throwsA(
          isA<ErrorOfType<DecoderNotFound>>().having(
            (e) => e.message,
            'message',
            'Decoder not found.',
          ),
        ),
      );
    });
    test('ErrorOf<ConstantReader>: Wrong type', () {
      try {
        aObj?.read<String>();
      } on ErrorOf catch (e) {
        expect(e, isA<ErrorOf<Decoder>>());
        expect(e.message, 'Error reading const <String> value.');
      }
    });
  });
  group('findDecoder:', () {
    test('bool', () {
      expect(Reader.findDecoder<bool>(), boolDecoder);
    });
    test('int', () {
      expect(Reader.findDecoder<int>(), intDecoder);
    });
    test('double', () {
      expect(Reader.findDecoder<double>(), doubleDecoder);
    });
    test('num', () {
      expect(Reader.findDecoder<num>(), numDecoder);
    });
  });
}

// ignore_for_file: unused_local_variable

import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart' show resolveSource;
import 'package:exception_templates/exception_templates.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:generic_reader/src/type/invalid_field_name.dart';

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

class const A({
  required final int id,
  required final Set<String> names,
  required final List<num> numbers,
}) {
  @override
  String toString() =>
      'A(id: $id, names: $names, '
      'numbers: $numbers )';
}

final a = const A(id: 42, names: {'Andy', 'Eva'}, numbers: [42, 3.14]);

class const DecoderForClassA() extends Decoder<A> {
  @override
  A read(DartObject dartObject) {
    final id = dartObject.read<int>(fieldName: 'id');
    final names = dartObject.readSet<String>(fieldName: 'names');
    final numbers = dartObject.readList<num>(fieldName: 'numbers');
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

  final idDartObject = lib.classes[1].fields[0].computeConstantValue();
  final scoreDartObject = lib.classes[1].fields[1].computeConstantValue();
  final isValidDartObject = lib.classes[1].fields[2].computeConstantValue();
  final aDartObject = lib.classes[1].fields[3].computeConstantValue();

  /// Adding a decoder:
  Reader.addDecoder(decoderForA);

  group('Decoders:', () {
    // Block the removal of decoders for built-in types.
    test('clearDecoder<String>()', () {
      expect(Reader.removeDecoderFor<String>(), null);
    });
    test('addDecoder<String>()', () {
      expect(Reader.addDecoder(StringDecoder()), false);
    });
    test('addDecoder<List>()', () {
      expect(Reader.addDecoder<List>(const ListDecoder<int>()), false);
    });
    test('addDecoder<List<dynamic>>', () {
      expect(Reader.addDecoder<List<dynamic>>(ListDecoder<dynamic>()), false);
      expect(Reader.hasDecoder<List<dynamic>>(), false);
    });
  });

  group('Reading Constants:', () {
    test('read<int>', () {
      expect(idDartObject, isNotNull);
      expect(idDartObject?.read<int>(), 124);
    });
    test('readMap<String, int>', () {
      expect(scoreDartObject, isNotNull);
      expect(scoreDartObject!.readMap<String, int>(), const {
        'Adam': 4,
        'Moira': 7,
      });
    });
    test('read<A>()', () {
      expect(aDartObject, isNotNull);
      expect(
        aDartObject!.read<A>(),
        isA<A>()
            .having((a) => a.id, 'id', 42)
            .having((a) => a.names, 'names', {'Andy', 'Eva'})
            .having((a) => a.numbers, 'numbers', [42, 3.14]),
      );
    });
    test('read<bool>()', () {
      expect(isValidDartObject, isNotNull);
      expect(isValidDartObject!.read<bool>(), true);
    });
  });

  group('Errors:', () {
    test('ErrorOfType<DecoderNotFound>', () {
      expect(isValidDartObject, isNotNull);

      expect(
        isValidDartObject!.read<A>,
        throwsA(
          isA<ErrorOfType<InvalidFieldName>>().having(
            (e) => e.message,
            'message',
            'Could not read a field with name: id.',
          ),
        ),
      );
    });
    test('ErrorOf<Reader>: Wrong type', () {
      expect(
        aDartObject!.read<String>,
        throwsA(
          isA<ErrorOf<Decoder>>().having(
            (e) => e.message,
            'message',
            'Error reading const <String> value.',
          ),
        ),
      );
    });
  });
  group('findDecoder:', () {
    test('bool', () {
      final isValid = isValidDartObject?.read<bool>();
      expect(Reader.findDecoder<bool>(), const BoolDecoder());
    });
    test('int', () {
      final id = idDartObject?.read<int>();
      expect(Reader.findDecoder<int>(), const IntDecoder());
    });
  });
}

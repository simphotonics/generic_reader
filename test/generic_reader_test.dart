import 'package:exception_templates/exception_templates.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/source_gen_test.dart';
import 'package:test/test.dart';

import 'package:generic_reader/generic_reader.dart';
import 'package:test_types/test_types.dart';

import 'package:generic_reader/src/types/unknown_type.dart';

/// To run this program navigate to the top directory the package
/// [generic_reader] and use the command:
/// # pub run test -r expanded --test-randomize-ordering-seed=random
///
/// Note: The path to player.dart is specified relative to the main
/// directory of [generic_reader].
Future<void> main() async {
  /// Read library.
  final lib =
      await initializeLibraryReaderForDirectory('test/src', 'researcher.dart');

  final idCR =
      ConstantReader(lib.classes.first.fields[0].computeConstantValue());

  final namesCR =
      ConstantReader(lib.classes.first.fields[1].computeConstantValue());

  final integersCR =
      ConstantReader(lib.classes.first.fields[2].computeConstantValue());

  final numberCR =
      ConstantReader(lib.classes.first.fields[3].computeConstantValue());

  final roleCR =
      ConstantReader(lib.classes.first.fields[4].computeConstantValue());

  final realCR =
      ConstantReader(lib.classes.first.fields[5].computeConstantValue());

  final titleCR =
      ConstantReader(lib.classes.first.fields[6].computeConstantValue());

  final mapCR =
      ConstantReader(lib.classes.first.fields[7].computeConstantValue());

  final mapWithEnumValueCR =
      ConstantReader(lib.classes.first.fields[8].computeConstantValue());

  final notRegisteredCR =
      ConstantReader(lib.classes.first.fields[9].computeConstantValue());

  Integer integerDecoder(ConstantReader cr) {
    return Integer(cr.read('value').intValue);
  }

  Real realDecoder(ConstantReader cr) {
    return Real(cr.read('value').doubleValue);
  }

  Boolean booleanDecoder(ConstantReader cr) {
    return Boolean(cr.read('value').boolValue);
  }

  Text textDecoder(ConstantReader cr) {
    return Text(cr.read('value').stringValue);
  }

  // Adding a decoder for constants of type [Column].
  Column columnDecoder(ConstantReader cr) {
    final defaultValue = cr.read('defaultValue').get<SqliteType>();
    final name = cr.read('name').get<String>();

    Column<T> columnFactory<T extends SqliteType>() {
      return Column<T>(
        defaultValue: defaultValue as T,
        name: name,
      );
    }

    if (cr.holdsA<Column<Text>>()) {
      return columnFactory<Text>();
    }
    if (cr.holdsA<Column<Real>>()) {
      return columnFactory<Real>();
    }
    if (cr.holdsA<Column<Integer>>()) {
      return columnFactory<Integer>();
    }
    return columnFactory<Boolean>();
  }

  SqliteType sqliteTypeDecoder(ConstantReader cr) {
    if (cr.holdsA<Integer>()) return cr.get<Integer>();
    if (cr.holdsA<Text>()) return cr.get<Text>();
    if (cr.holdsA<Real>()) return cr.get<Real>();
    if (cr.holdsA<Boolean>()) return cr.get<Boolean>();
    throw ErrorOf<Decoder<SqliteType>>(
        message: 'Could not reader const value of type `SqliteType`',
        invalidState: 'ConstantReader holds a const value of type '
            '`${cr.objectValue.type}`.');
  }

  GenericReader.addDecoder(columnDecoder);
  GenericReader.addDecoder(realDecoder);
  GenericReader.addDecoder(sqliteTypeDecoder);
  GenericReader.addDecoder(textDecoder);
  GenericReader.addDecoder(booleanDecoder);
  GenericReader.addDecoder(integerDecoder);

  group('Type functions:', () {
    test('holdsA<String>()', () {
      expect(roleCR.holdsA<String>(), true);
    });
    test('holdsA<UnKnownType>()', () {
      expect(notRegisteredCR.holdsA<UnknownType>(), true);
    });
    test('holdsA<Column>()', () {
      expect(idCR.holdsA<Column>(), true);
    });
    test('holdsA<Set>()', () {
      expect(integersCR.holdsA<Set>(), false);
    });
    test('holdsA<Set<int>>()', () {
      expect(integersCR.holdsA<Set<int>>(), true);
    });
    test('holdsA<Set<double>>()', () {
      expect(integersCR.holdsA<Set<double>>(), false);
    });
    test('holdsA<Map<String, dynamic>>()', () {
      expect(mapCR.holdsA<Map<String, dynamic>>(), true);
    });

    test('holdsA<Title>()', () {
      GenericReader.addDecoder<Title>((cr) => cr.enumValue<Title>());
      expect(titleCR.holdsA<Title>(), true);
    });
  });

  group('Decoders:', () {
    // Block the removal of decoders for built-in types.
    test('clearDecoder<String>()', () {
      GenericReader.clearDecoder<String>();
      expect(GenericReader.hasDecoder<String>(), true);
    });
    test('addDecoder<String>()', () {
      expect(GenericReader.addDecoder<String>((constantReader) => ''), false);
    });
    test('addDecoder<List>()', () {
      expect(GenericReader.addDecoder<List>((constantReader) => []), false);
    });
    test('addDecoder<List<dynamic>>()', () {
      expect(GenericReader.addDecoder<List<dynamic>>((constantReader) => []),
          false);
    });
    test('addDecoder<List<num>>()', () {
      addTearDown(() => GenericReader.clearDecoder<List<bool>>());
      expect(
        GenericReader.addDecoder<List<bool>>((constantReader) => []),
        true,
      );
    });
    test('addDecoder<Map<num, dynamic>>()', () {
      addTearDown(() => GenericReader.clearDecoder<Map<num, dynamic>>());
      expect(
        GenericReader.addDecoder<Map<num, dynamic>>((constantReader) => {}),
        true,
      );
    });
  });

  group('Reading Constants:', () {
    test('get<SqliteType>()', () {
      expect(realCR.get<SqliteType>(), Real(39.5));
    });
    test('getList<String>()', () {
      expect(
        namesCR.getList<String>(),
        const ['Thomas', 'Mayor'],
      );
    });
    test('get<Column>()', () {
      expect(
        idCR.get<Column>(),
        const Column<Integer>(defaultValue: Integer(3), name: 'id'),
      );
    });
    test('getSet<int>()', () {
      expect(
        integersCR.getSet<int>(),
        const {47, 91},
      );
    });
    test('getEnum<Title>()', () {
      expect(
        titleCR.enumValue<Title>(),
        Title.Dr,
      );
    });
    test('getMap<String, dynamic>()', () {
      expect(
        mapCR.getMap<String, dynamic>(),
        const <String, dynamic>{'one': 1, 'two': 2.0},
      );
    });
    test('getMap<String, dynamic>(), enum entry', () {
      GenericReader.addDecoder<Title>((cr) => cr.enumValue<Title>());
      expect(
        mapWithEnumValueCR.getMap<String, dynamic>(),
        const <String, dynamic>{
          'one': 1,
          'two': 2.0,
          'title': Title.Prof,
        },
      );
    });
  });

  group('Errors:', () {
    test('ErrorOf<ConstantReader>: Unreg. type', () {
      try {
        numberCR.get<Runes>();
      } catch (e) {
        expect(e, isA<ErrorOf<ConstantReader>>());
      }
    });
    test('ErrorOf<ConstantReader>: Wrong type', () {
      try {
        realCR.get<String>();
      } on ErrorOf catch (e) {
        expect(e, isA<ErrorOf<ConstantReader>>());
        expect(
            e.message, 'Input does not represent an object of type <String>');
      }
    });
  });
}

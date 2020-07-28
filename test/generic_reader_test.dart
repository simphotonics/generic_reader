import 'package:exception_templates/exception_templates.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';
import 'package:test/test.dart';

import 'package:generic_reader_example/generic_reader_example.dart';
import 'package:generic_reader/generic_reader.dart';

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

  Integer integerDecoder(ConstantReader cr) {
    if (cr == null) return null;
    return Integer(cr.peek('value')?.intValue);
  }

  Real realDecoder(ConstantReader cr) {
    if (cr == null) return null;
    return Real(cr.peek('value')?.doubleValue);
  }

  Boolean booleanDecoder(ConstantReader cr) {
    if (cr == null) return null;
    return Boolean(cr.peek('value')?.boolValue);
  }

  Text textDecoder(ConstantReader cr) {
    if (cr == null) return null;
    return Text(cr.peek('value')?.stringValue);
  }

  final reader = GenericReader();

  // Adding a decoder for constants of type [Column].
  Column columnDecoder(ConstantReader cr) {
    if (cr == null) return null;
    final defaultValueCR = cr.peek('defaultValue');
    final defaultValue = reader.get<SqliteType>(defaultValueCR);

    final nameCR = cr.peek('name');
    final name = reader.get<String>(nameCR);

    Column<T> columnFactory<T extends SqliteType>() {
      return Column<T>(
        defaultValue: defaultValue,
        name: name,
      );
    }

    if (reader.holdsA<Column>(cr, typeArgs: [Text])) {
      return columnFactory<Text>();
    }
    if (reader.holdsA<Column>(cr, typeArgs: [Real])) {
      return columnFactory<Real>();
    }
    if (reader.holdsA<Column>(cr, typeArgs: [Integer])) {
      return columnFactory<Integer>();
    }
    return columnFactory<Boolean>();
  }

  SqliteType sqliteTypeDecoder(ConstantReader cr) {
    if (cr == null) return null;
    if (reader.holdsA<Integer>(cr)) return reader.get<Integer>(cr);
    if (reader.holdsA<Text>(cr)) return reader.get<Text>(cr);
    if (reader.holdsA<Real>(cr)) return reader.get<Real>(cr);
    if (reader.holdsA<Boolean>(cr)) return reader.get<Boolean>(cr);
    throw ErrorOf<Decoder<SqliteType>>(
        message: 'Could not reader const value of type `SqliteType`',
        invalidState: 'ConstantReader holds a const value of type '
            '`${cr.objectValue.type}`.');
  }

  group('Type functions:', () {
    test('holdsA<Column>()', () {
      expect(reader.holdsA<Column>(idCR), true);
    });
    test('holdsA<Set>()', () {
      expect(reader.holdsA<Set>(integersCR), true);
    });
    test('holdsA<Set>(, [int])', () {
      expect(reader.holdsA<Set>(integersCR, typeArgs: [int]), true);
    });
    test('holdsA<Set>(, [int])', () {
      expect(reader.holdsA<Set>(integersCR, typeArgs: [double]), false);
    });
    test('holdsA<Map>(, [String, dynamic])', () {
      expect(reader.holdsA<Map>(mapCR, typeArgs: [String, dynamic]), true);
    });

    test('holdsA<Title>()', () {
      reader.addDecoder<Title>((cr) => cr.enumValue<Title>());
      expect(reader.holdsA<Title>(titleCR), true);
    });

    test('isBuiltIn<String>()', () {
      expect(reader.isBuiltIn(String), true);
    });
    test('isBuiltIn<Column>()', () {
      expect(reader.isBuiltIn(Column), false);
    });

    test('findType()', () {
      expect(reader.findTypeOf(roleCR), String);
      expect(reader.findTypeOf(realCR), TypeNotRegistered);
      reader.addDecoder<Real>(realDecoder);
      expect(reader.findTypeOf(realCR), Real);
      reader.clearDecoder<Real>();
    });
  });

  group('Decoders:', () {
    test('addDecoder<SqliteType>()', () {
      reader.addDecoder<SqliteType>(sqliteTypeDecoder);
      expect(
        reader.hasDecoder(SqliteType),
        true,
      );
      reader.clearDecoder<SqliteType>();
    });
    // Clearing a decoder for an unregistered type.
    test('clearDecoder<SqliteType>()', () {
      expect(
        reader.clearDecoder<SqliteType>(),
        null,
      );
    });
    // Block the removal of decoders for built-in types.
    test('clearDecoder<String>()', () {
      expect(reader.clearDecoder<String>(), null);
      expect(reader.hasDecoder(String), true);
    });
  });

  group('get:', () {
    test('get<SqliteType>()', () {
      reader.addDecoder<SqliteType>(sqliteTypeDecoder);
      reader.addDecoder<Real>(realDecoder);
      reader.addDecoder<Integer>(integerDecoder);
      reader.addDecoder<Text>(textDecoder);
      reader.addDecoder<Boolean>(booleanDecoder);
      expect(
        reader.get<SqliteType>(realCR),
        Real(39.5),
      );
      reader.clearDecoder<SqliteType>();
      reader.clearDecoder<Real>();
      reader.clearDecoder<Integer>();
      reader.clearDecoder<Text>();
      reader.clearDecoder<Boolean>();
    });
    test('getList<String>()', () {
      expect(
        reader.getList<String>(namesCR),
        const ['Thomas', 'Mayor'],
      );
    });
    test('get<Column>()', () {
      reader
        ..addDecoder<Column>(columnDecoder)
        ..addDecoder<SqliteType>(sqliteTypeDecoder)
        ..addDecoder<Real>(realDecoder)
        ..addDecoder<Integer>(integerDecoder)
        ..addDecoder<Text>(textDecoder)
        ..addDecoder<Boolean>(booleanDecoder);
      expect(
        reader.get<Column>(idCR),
        const Column<Integer>(
          defaultValue: Integer(3),
        ),
      );
      reader
        ..clearDecoder<Column>()
        ..clearDecoder<SqliteType>()
        ..clearDecoder<Real>()
        ..clearDecoder<Integer>()
        ..clearDecoder<Text>()
        ..clearDecoder<Boolean>();
    });
    test('getSet<int>()', () {
      expect(
        reader.getSet<int>(integersCR),
        const {47, 91},
      );
    });
    test('getEnum<Title>()', () {
      expect(
        reader.getEnum<Title>(titleCR),
        Title.DR,
      );
    });
    test('getMap<String, dynamic>()', () {
      expect(
        reader.getMap<String, dynamic>(mapCR),
        const <String, dynamic>{'one': 1, 'two': 2.0},
      );
    });
    test('getMap<String, dynamic>(), enum entry', () {
      reader.addDecoder<Title>((cr) => cr.enumValue<Title>());
      expect(
        reader.getMap<String, dynamic>(mapWithEnumValueCR),
        const <String, dynamic>{
          'one': 1,
          'two': 2.0,
          'title': Title.PROF,
        },
      );
      reader.clearDecoder<Title>();
    });
  });

  group('Errors:', () {
    test('ErrorOf<GenericReader>: Unreg. type', () {
      try {
        reader.get<Runes>(numberCR);
      } catch (e) {
        expect(e, isA<ErrorOf<GenericReader>>());
      }
    });
    test('ErrorOf<GenericReader>: Wrong type', () {
      try {
        reader.get<String>(realCR);
      } catch (e) {
        expect(e, isA<ErrorOf<GenericReader>>());
      }
    });
  });
}

import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';
import 'package:generic_reader/src/test_types/sqlite_type.dart';
import 'package:test/test.dart';

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

  print(lib.classes.first.fields);

  final idCR =
      ConstantReader(lib.classes.first.fields[0].computeConstantValue());

  final namesCR =
      ConstantReader(lib.classes.first.fields[1].computeConstantValue());

  final integersCR =
      ConstantReader(lib.classes.first.fields[2].computeConstantValue());

  final numberCR =
      ConstantReader(lib.classes.first.fields[3].computeConstantValue());

  final titleCR =
      ConstantReader(lib.classes.first.fields[4].computeConstantValue());

  final realCR =
      ConstantReader(lib.classes.first.fields[5].computeConstantValue());

  final Decoder<Integer> integerDecoder = ((cr) {
    if (cr == null) return null;
    return Integer(cr.peek('value')?.intValue);
  });
  final Decoder<Real> realDecoder = ((cr) {
    if (cr == null) return null;
    return Real(cr.peek('value')?.doubleValue);
  });
  final Decoder<Boolean> booleanDecoder = ((cr) {
    if (cr == null) return null;
    return Boolean(cr.peek('value')?.boolValue);
  });
  final Decoder<Text> textDecoder = ((cr) {
    if (cr == null) return null;
    return Text(cr.peek('value')?.stringValue);
  });

  final reader = GenericReader();

  final Decoder<SqliteType> sqliteTypeDecoder = ((cr) {
    if (cr == null) return null;
    if (reader.holdsA<Integer>(cr)) return reader.get<Integer>(cr);
    if (reader.holdsA<Text>(cr)) return reader.get<Text>(cr);
    if (reader.holdsA<Real>(cr)) return reader.get<Real>(cr);
    if (reader.holdsA<Boolean>(cr)) return reader.get<Boolean>(cr);
    return null;
  });

  group('Type functions:', () {
    test('holdsA<String>()', () {
      expect(reader.holdsA<String>(titleCR), true);
    });
    test('holdsA<Set>()', () {
      expect(reader.holdsA<Set>(integersCR), true);
    });
    test('holdsA<Set>(,[int])', () {
      expect(reader.holdsA<Set>(integersCR, typeArgs: [int]), true);
    });
    test('holdsA<Set>(,[int])', () {
      expect(reader.holdsA<Set>(integersCR, typeArgs: [double]), false);
    });

    test('isBuiltIn<String>()', () {
      expect(reader.isBuiltIn(String), true);
    });
    test('isBuiltIn<Column>()', () {
      expect(reader.isBuiltIn(Runes), false);
    });

    test('findType()', () {
      expect(reader.findTypeOf(titleCR), String);
      // [firstNameCR] represents a constant of type [Text].
      expect(reader.findTypeOf(realCR), TypeNotRegistered);
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
    test('getList<Integer>()', () {
      reader.addDecoder<Integer>(integerDecoder);
      expect(
        reader.getList<Integer>(idCR),
        const [Integer(87)],
      );
      reader.clearDecoder<Integer>();
    });
    test('getSet<int>()', () {
      expect(
        reader.getSet<int>(integersCR),
        const {47, 91},
      );
    });
  });

  group('Errors:', () {
    test('ReaderError: Unreg. type', () {
      try {
        reader.get<Runes>(numberCR);
      } catch (e) {
        expect(e, isA<ReaderError>());
      }
    });
    test('ReaderError: Wrong type', () {
      try {
        reader.get<String>(realCR);
      } catch (e) {
        expect(e, isA<ReaderError>());
      }
    });
  });
}

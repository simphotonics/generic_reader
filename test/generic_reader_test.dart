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

  final Decoder<SqliteType> sqliteTypeDecoder = ((cr) {
    final value = cr.peek('value');
    if (value.isInt) return Integer(value.intValue);
    if (value.isBool) return Boolean(value.boolValue);
    if (value.isString) return Text(value.stringValue);
    if (value.isDouble) return Real(value.doubleValue);
    return null;
  });

  final reader = GenericReader();

  group('Type functions:', () {
    test('isA<String>()', () {
      expect(reader.isA<String>(titleCR), true);
    });
    test('isA<Set>()', () {
      expect(reader.isA<Set>(integersCR), true);
    });
    test('isBuiltIn<String>()', () {
      expect(reader.isBuiltIn(String), true);
    });
    test('isBuiltIn<Column>()', () {
      expect(reader.isBuiltIn(Runes), false);
    });

    test('findType()', () {
      expect(reader.findType(titleCR), String);
      // [firstNameCR] represents a constant of type [Text].
      expect(reader.findType(realCR), TypeNotRegistered);
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
      expect(
        reader.get<SqliteType>(realCR),
        Real(39.5),
      );
      reader.clearDecoder<SqliteType>();
    });
    test('getList<String>()', () {
      expect(
        reader.getList<String>(namesCR),
        const ['Thomas', 'Mayor'],
      );
    });
    test('getList<Integer>()', () {
      reader.addDecoder<SqliteType>(sqliteTypeDecoder);
      expect(
        reader.getList<SqliteType>(idCR),
        const [Integer(87)],
      );
      reader.clearDecoder<SqliteType>();
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

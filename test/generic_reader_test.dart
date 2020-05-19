import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';
import 'package:test/test.dart';
import 'package:example/example_generic_reader.dart';

/// To run this program navigate to the top directory the package
/// [generic_reader] and use the command:
/// # pub run test -r expanded --test-randomize-ordering-seed=random
///
/// Note: The path to player.dart is specified relative to the main
/// directory of [generic_reader].
Future<void> main() async {
  /// Read library.
  final lib = await initializeLibraryReaderForDirectory(
      'example/lib/src', 'player.dart');

  print(lib.classes.first.fields);

  final columnNameCR =
      ConstantReader(lib.classes.first.fields[0].computeConstantValue());

  final idCR =
      ConstantReader(lib.classes.first.fields[1].computeConstantValue());

  final firstNameCR =
      ConstantReader(lib.classes.first.fields[2].computeConstantValue());

  final textCR = firstNameCR.peek('defaultValue');

  final sponsorsCR =
      ConstantReader(lib.classes.first.fields[3].computeConstantValue());

  final unregCR =
      ConstantReader(lib.classes.first.fields[4].computeConstantValue());

  final primeNumbersCR =
      ConstantReader(lib.classes.first.fields[5].computeConstantValue());

  final reader = GenericReader();

  Decoder<SqliteType> sqliteTypeDecoder = (cr) {
    final value = cr.peek('value');
    if (value.isInt) return Integer(value.intValue);
    if (value.isBool) return Boolean(value.boolValue);
    if (value.isString) return Text(value.stringValue);
    if (value.isDouble) return Real(value.doubleValue);
    return null;
  };

  Decoder<Column> columnDecoder = (cr) {
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

    if (reader.isA<Text>(defaultValueCR)) return columnFactory<Text>();
    if (reader.isA<Integer>(defaultValueCR)) return columnFactory<Integer>();
    if (reader.isA<Boolean>(defaultValueCR)) return columnFactory<Boolean>();
    if (reader.isA<Real>(defaultValueCR)) return columnFactory<Real>();
    return null;
  };

  Decoder<Sponsor> sponsorDecoder = (cr) {
    return Sponsor(cr.peek('name').stringValue);
  };

  group('Type functions:', () {
    test('isA<String>()', () {
      expect(reader.isA<String>(columnNameCR), true);
    });
    test('isA<Column>()', () {
      expect(reader.isA<Column>(idCR), true);
    });
    test('isBuiltIn<String>()', () {
      expect(reader.isBuiltIn(String), true);
    });
    test('isBuiltIn<Column>()', () {
      expect(reader.isBuiltIn(Column), false);
    });

    test('findType()', () {
      expect(reader.findType(columnNameCR), String);
      // [firstNameCR] represents a constant of type [Text].
      expect(reader.findType(firstNameCR), TypeNotRegistered);
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
        reader.get<SqliteType>(textCR),
        Text('Thomas'),
      );
      reader.clearDecoder<SqliteType>();
    });
    test('get<Column>()', () {
      reader.addDecoder<SqliteType>(sqliteTypeDecoder);
      reader.addDecoder<Column>(columnDecoder);
      expect(
        reader.get<Column>(firstNameCR).toString(),
        Column<Text>(
          defaultValue: Text('Thomas'),
        ).toString(),
      );
      reader.clearDecoder<SqliteType>();
      reader.clearDecoder<Column>();
    });

    test('getList<Sponsor>()', () {
      reader.addDecoder<Sponsor>(sponsorDecoder);
      expect(
        reader.getList<Sponsor>(sponsorsCR),
        const [
          Sponsor('Johnson\'s'),
          Sponsor('Smith Brothers'),
        ],
      );
      reader.clearDecoder<Sponsor>();
    });
    test('getSet<int>()', () {
      expect(
        reader.getSet<int>(primeNumbersCR),
        const {1, 3, 5, 7, 11, 13},
      );
    });
  });

  group('Errors:', () {
    test('ReaderError: Unreg. type', () {
      try {
        reader.get<UnRegisteredTestType>(unregCR);
      } catch (e) {
        expect(e, isA<ReaderError>());
      }
    });
    test('ReaderError: Wrong type', () {
      try {
        reader.get<String>(unregCR);
      } catch (e) {
        expect(e, isA<ReaderError>());
      }
    });

  });
}

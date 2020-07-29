import 'package:ansicolor/ansicolor.dart';
import 'package:exception_templates/exception_templates.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/source_gen_test.dart';
import 'package:source_gen_test/src/init_library_reader.dart';

import 'package:generic_reader_example/generic_reader_example.dart';

/// To run this program navigate to the folder: /example/generic_reader_example
/// in your local copy the package [generic_reader] and
/// use the command:
///
/// # dart bin/player_example.dart

/// Demonstrates how to use [GenericReader] to read constants
/// with parameterized type from a static representation
/// of a compile-time constant expression
/// represented by a [ConstantReader].
Future<void> main() async {
  /// Reading libraries.
  final playerLib = await initializeLibraryReaderForDirectory(
    'lib/src',
    'player.dart',
  );

  // ConstantReader representing field 'columnName'.
  final columnNameCR =
      ConstantReader(playerLib.classes.first.fields[0].computeConstantValue());

  final idCR =
      ConstantReader(playerLib.classes.first.fields[1].computeConstantValue());

  // ConstantReade representing field 'firstName'.
  final firstNameCR =
      ConstantReader(playerLib.classes.first.fields[2].computeConstantValue());

  final sponsorsCR =
      ConstantReader(playerLib.classes.first.fields[3].computeConstantValue());

  final greekCR =
      ConstantReader(playerLib.classes.first.fields[6].computeConstantValue());

  final mapCR =
      ConstantReader(playerLib.classes.first.fields[7].computeConstantValue());

  final mapWithEnumEntryCR =
      ConstantReader(playerLib.classes.first.fields[8].computeConstantValue());

  // Get singleton instance of the reader.
  final reader = GenericReader();

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

  // Registering decoders.
  reader
    ..addDecoder<Integer>(integerDecoder)
    ..addDecoder<Boolean>(booleanDecoder)
    ..addDecoder<Text>(textDecoder)
    ..addDecoder<Real>(realDecoder)
    ..addDecoder<SqliteType>(sqliteTypeDecoder);

  // Adding a decoder for constants of type [Column].
  reader.addDecoder<Column>((cr) {
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
  });

  final green = AnsiPen()..green(bold: true);

  // Retrieve an instance of [String].
  final columnName = reader.get<String>(columnNameCR);
  print(green('Retrieving a String:'));
  print('columnName = \'$columnName\'');
  print('');
  // Prints:
  // Retrieving a [String]
  // columnName = 'Player'

  // Retrieve an instance of [Column<Text>].
  final columnFirstName = reader.get<Column>(firstNameCR);
  print(green('Retrieving a Column<Text>:'));
  print(columnFirstName);
  // Prints:
  // Retrieving a [Column<Text>]:
  // Column<Text>(
  //   defaultValue: Text('Thomas')
  // )

  // Adding a decoder function for type [Sponsor].
  reader.addDecoder<Sponsor>((cr) => Sponsor(cr.peek('name').stringValue));

  final sponsors = reader.getList<Sponsor>(sponsorsCR);

  print('');
  print(green('Retrieving a List<Sponsor>:'));
  print(sponsors);
  // Prints:
  // Retrieving a [List<Sponsor>]:
  // [Sponsor: Johnson's, Sponsor: Smith Brothers]

  final id = reader.get<Column>(idCR);
  print('');
  print(green('Retrieving a Column<Integer>:'));
  print(id);
  // Prints:
  // Retrieving a [Column<Integer>]:
  // Column<Integer>(
  // )

  final greek = reader.getEnum<Greek>(greekCR);
  print('');
  print(green('Retrieving an instance of the '
      'enumeration: Greek{alpha, beta}.'));
  print(greek);
  // Prints:
  // 'Retrieving an instance of the enumeration: Greek{alpha, beta}.'
  // Greek.alpha

  final map = reader.getMap<String, dynamic>(mapCR);
  print('');
  print(green('Retrieving a Map<String, dynamic>:'));
  print(map);
  // Prints:
  // 'Retrieving a Map<String, dynamic>:'
  // {one: 1, two: 2.0}

  reader.addDecoder<Greek>((cr) => cr.enumValue<Greek>());
  final mapWithEnumEntry = reader.getMap<String, dynamic>(mapWithEnumEntryCR);
  print('');
  print(green('Retrieving a Map<String, dynamic>:'));
  print(mapWithEnumEntry);
  // Prints:
  // 'Retrieving a Map<String, dynamic>:'
  // {one: 1, two: 2.0, enum: Greek.alpha}
}
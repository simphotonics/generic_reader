import 'package:ansicolor/ansicolor.dart';
import 'package:exception_templates/exception_templates.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/source_gen_test.dart';
import 'package:test_types/test_types.dart';

/// To run this program navigate to the root folder
/// in your local copy the package `generic_reader` and
/// use the command:
///
/// # dart example/bin/player_example.dart

/// Demonstrates how to use [GenericReader] to read constants
/// with parameterized type from a static representation
/// of a compile-time constant expression
/// represented by a [ConstantReader].
Future<void> main() async {
  /// Reading libraries.
  print('Reading player.dart ...');
  final playerLib = await initializeLibraryReaderForDirectory(
    'example/src',
    'player.dart',
  );
  print('Done reading player.dart');

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

  final listCR =
      ConstantReader(playerLib.classes.first.fields[9].computeConstantValue());

  // Adding a decoder for constants of type [Column].
  GenericReader.addDecoder<Column>((cr) {
    final name = cr.read('name').get<String>();

    if (cr.holdsA<Column<int>>()) {
      final defaultValue = cr.read('defaultValue').get<int>();
      return Column<int>(defaultValue: defaultValue, name: name);
    }
    if (cr.holdsA<Column<bool>>()) {
      final defaultValue = cr.read('defaultValue').get<bool>();
      return Column<bool>(defaultValue: defaultValue, name: name);
    }
    if (cr.holdsA<Column<String>>()) {
      final defaultValue = cr.read('defaultValue').get<String>();
      return Column<String>(defaultValue: defaultValue, name: name);
    }
    if (cr.holdsA<Column<double>>()) {
      final defaultValue = cr.read('defaultValue').get<double>();
      return Column<double>(defaultValue: defaultValue, name: name);
    }
    throw ErrorOf<Decoder<Column>>(
        message: 'Error reading constant expression.',
        expectedState: 'An instance of ConstantReader holding a '
            'constant of type `Column`.');
  });

  final green = AnsiPen()..green(bold: true);

  // Retrieve an instance of [String].
  final columnName = columnNameCR.get<String>();
  print(green('Retrieving a String:'));
  print('columnName = \'$columnName\'');
  print('');
  // Prints:
  // Retrieving a [String]
  // columnName = 'Player'

  // Retrieve an instance of [Column<Text>].
  final columnFirstName = firstNameCR.get<Column>();
  print(green('Retrieving a Column<Text>:'));
  print(columnFirstName);
  // Prints:
  // Retrieving a [Column<Text>]:
  // Column<Text>(
  //   defaultValue: Text('Thomas')
  // )

  // Adding a decoder function for type [Sponsor].
  GenericReader.addDecoder<Sponsor>(
      (cr) => Sponsor(cr.read('name').stringValue));

  final sponsors = sponsorsCR.getList<Sponsor>();

  print('');
  print(green('Retrieving a List<Sponsor>:'));
  print(sponsors);
  // Prints:
  // Retrieving a [List<Sponsor>]:
  // [Sponsor: Johnson's, Sponsor: Smith Brothers]

  final id = idCR.get<Column>();
  print('');
  print(green('Retrieving a Column<Integer>:'));
  print(id);
  // Prints:
  // Retrieving a [Column<Integer>]:
  // Column<Integer>(
  // )

  final greek = greekCR.get<Greek>();
  print('');
  print(green('Retrieving an instance of the '
      'enumeration: Greek{alpha, beta}.'));
  print(greek);
  // Prints:
  // 'Retrieving an instance of the enumeration: Greek{alpha, beta}.'
  // Greek.alpha

  final map = mapCR.getMap<String, dynamic>();
  print('');
  print(green('Retrieving a Map<String, dynamic>:'));
  print(map);
  // Prints:
  // 'Retrieving a Map<String, dynamic>:'
  // {one: 1, two: 2.0}

  GenericReader.addDecoder<Greek>((cr) => cr.get<Greek>());
  final mapWithEnumEntry = mapWithEnumEntryCR.getMap<String, dynamic>();
  print('');
  print(green('Retrieving a Map<String, dynamic>:'));
  print(mapWithEnumEntry);
  // Prints:
  // 'Retrieving a Map<String, dynamic>:'
  // {one: 1, two: 2.0, enum: Greek.alpha}

  // Retrieving a nested list.
  // Add a specific decoder for the inner type.
  GenericReader.addDecoder<List<int>>((cr) => cr.getList<int>());

  final list = listCR.getList<List<int>>();
  print(green('\nRetrieving a List<List<int>>'));
  print(list);
}

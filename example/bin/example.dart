import 'package:ansicolor/ansicolor.dart';
import 'package:example/src/column.dart';
import 'package:example/src/sqlite_type.dart';
import 'package:example/src/wrapper.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';

Future<void> main() async {
  /// Reading libraries.
  final playerLib = await initializeLibraryReaderForDirectory(
    'lib/src',
    'player.dart',
  );

  final wrapperTestLib = await initializeLibraryReaderForDirectory(
    'lib/src',
    'wrapper_test.dart',
  );

  // ConstantReader representing field 'columnName'.
  final columnNameCR =
      ConstantReader(playerLib.classes.first.fields[0].computeConstantValue());

  // ConstantReade representing field 'firstName'.
  final firstNameCR =
      ConstantReader(playerLib.classes.first.fields[2].computeConstantValue());

  final wrapperCR = ConstantReader(
      wrapperTestLib.classes.first.fields[0].computeConstantValue());

  // Get singleton instance of the reader.
  final reader = GenericReader();

  // Add a decoder function for constants of type [SqliteType].
  reader.addDecoder<SqliteType>((cr) {
    final value = cr.peek('value');
    if (value.isInt) return Integer(value.intValue);
    if (value.isBool) return Boolean(value.boolValue);
    if (value.isString) return Text(value.stringValue);
    if (value.isDouble) return Real(value.doubleValue);
    return null;
  });

  // Add a decoder for constants of type [Column].
  reader.addDecoder<Column>((cr) {
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
  });

  AnsiPen green = AnsiPen()..green(bold: true);

  // Retrieve an instance of [String].
  final columnName = reader.get<String>(columnNameCR);
  print(green('Retrieving a [String]'));
  print('columnName = \'$columnName\'');
  print('');

  // Retrieve an instance of [Column<Text>].
  final columnFirstName = reader.get<Column>(firstNameCR);
  print(green('Retrieving a [Column<Text>].'));
  print(columnFirstName.sourceCode);

  reader.addDecoder<Text>((cr) {
    final valueCR = cr.peek('value');
    final value = valueCR.stringValue;
    return Text(value);
  });

  reader.addDecoder<Wrapper>((cr) {
    final valueCR = cr.peek('value');
    final value = reader.getOrError(valueCR);

    final type = reader.findType(valueCR);
    //final value = reader.getDecoder(type)(valueCR);
    return Wrapper(value);
  });

  print(reader.registeredTypes);

  print(wrapperCR.objectValue.type);

  final test = reader.get<Wrapper>(wrapperCR);

  print(test);

  final wrapper1 = Wrapper<dynamic>(Text('wrapper1'));

  print(wrapper1);

  print(Decoder7 is Decoder8);
}

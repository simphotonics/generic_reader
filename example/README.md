# Generic Reader


## Example
The file [example.dart] demonstrates how to use [generic_reader] to read the value of a constant from a static representation of a compile-time constant expression. The program also shows how to register [Decoder] functions for the types [Column] and [SqliteType].

To run the program in a terminal navigate to the
folder *generic_reader/example* in your local copy of this library and use the command:
```Shell
$ dart bin/example.dart
```

The constant values that are going to be read are the fields of the const class [Player] shown below:
```Dart
import 'package:sqlite_entity/sqlite_entity.dart';

class Player {
  const Player();

  final columnName = 'Player';

  final id = const Column<Integer>(
  );

  /// First name of player.
  final firstName = const Column<Text>(
    defaultValue: Text('Thomas'),
  );

  /// List of sponsors
  final List<Sponsor> sponsors = const [
    Sponsor('Johnson\'s'),
    Sponsor('Smith Brothers'),
  ];
}
```
The class field columnName holds a `String` value while the following two fields hold values of type `Column<Integer>` and `Column<Text>`, respectively.

In this simple example the function [initializeLibraryReaderForDirectory] provided by [source_gen_test] is used to load the source code and initialize objects of type [LibraryReader].

In a standard setting this task is delegated to a [builder] that reads a builder configuration and loads the relevant assets.

```Dart
import 'package:ansicolor/ansicolor.dart';
import 'package:example/src/column.dart';
import 'package:example/src/sqlite_type.dart';
import 'package:example/src/wrapper.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';

/// Demonstrates how use [GenericReader] to read constants
/// with parametrized type from a static representation
/// of a compile-time constant expression
/// represented by a [ConstantReader].
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

  // Adding a decoder for constants of type [Column].
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
  // Prints:
  // Retrieving a [String]
  // columnName = 'Player'

  // Retrieve an instance of [Column<Text>].
  final columnFirstName = reader.get<Column>(firstNameCR);
  print(green('Retrieving a [Column<Text>].'));
  print(columnFirstName);
  // Prints:
  // Retrieving a [Column<Text>].
  // Column<Text>(
  //   defaultValue: Text('Thomas')
  // )

  reader.addDecoder<Wrapper>((cr) {
    final valueCR = cr.peek('value');
    final value = reader.get<dynamic>(valueCR);
    return Wrapper(value);
  });

  final wrappedText = reader.get<Wrapper>(wrapperCR);
  print(green('Retrieving a [Wrapper<Text>]'));
  print(wrappedText);
  // Prints:
  // Retrieving a [Wrapper<Text>]
  // Wrapper<dynamic>(value: Text('I am of type [Text])'))

  // Adding a decoder function for type [Sponsor].
  reader.addDecoder<Sponsor>((cr) => Sponsor(cr.peek('name').stringValue));

  final sponsors = reader.getList<Sponsor>(sponsorsCR);

  print('');
  print(green('Retrieving a [List<Sponsor>]:'));
  print(sponsors);
  // Prints:
  // Retrieving a [List<Sponsor>]:
  // [Sponsor: Johnson's, Sponsor: Smith Brothers]
}
```

Taking advantage of the fact that [SqliteType] is the super-type of `Integer`, `Boolean`, `Text`, and `Real`, the decoder function of [Column] can be shortened to:
```Dart
// Adding a decoder for constants of type [Column].
  reader.addDecoder<Column>((cr) {
    final defaultValueCR = cr.peek('defaultValue');
    final defaultValue = reader.get<SqliteType>(defaultValueCR);
    final nameCR = cr.peek('name');
    final name = reader.get<String>(nameCR);

    return Column(defaultValue: defaultValue, name: name,);
  });

```
The only difference is that the resulting variable `columnFirstName` will be of type `Column<SqliteType>`.


## Features and bugs
Please file feature requests and bugs at the [issue tracker].

[builder]: https://github.com/dart-lang/build
[issue tracker]: https://github.com/simphotonics/directed_graph/issues

[initializeLibraryReaderForDirectory]: https://pub.dev/documentation/source_gen_test/latest/source_gen_test/initializeLibraryReaderForDirectory.html

[LibraryReader]: https://pub.dev/documentation/source_gen/latest/source_gen/LibraryReader-class.html

[generic_reader]: https://pub.dev/packages/generic_reader
[directed_graph]: https://github.com/simphotonics/directed_graph/
[Column]: https://github.com/simphotonics/generic_reader/blob/master/example/lib/src/column.dart
[SqliteType]: https://github.com/simphotonics/generic_reader/blob/master/example/lib/src/sqlite_type.dart
[Player]: https://github.com/simphotonics/generic_reader/blob/master/example/lib/src/player.dart
[example.dart]: https://github.com/simphotonics/generic_reader/blob/master/example/bin/example.dart
[Decoder]:https://github.com/simphotonics/generic_reader#decoder-functions

[source_gen]: https://pub.dev/packages/source_gen
[source_gen_test]: https://pub.dev/packages/source_gen_test

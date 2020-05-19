# Generic Reader - Example


## Retrieving Constants with Parametrized Type

The file [example.dart] demonstrates how to use [generic_reader] to read the value of a constant with parametrized type from a static representation of a compile-time constant expression. The program also shows how to register [Decoder] functions for the types [Column] and [SqliteType].

To run the program in a terminal navigate to the
folder *generic_reader/player_example* in your local copy of this library and use the command:
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
The class field *columnName* holds a `String` value while the following two fields hold values of type `Column<Integer>` and `Column<Text>`, respectively.

In this simple example the function [initializeLibraryReaderForDirectory] provided by [source_gen_test] is used to load the source code and initialize objects of type [LibraryReader].

In a standard setting this task is delegated to a [builder] that reads a builder configuration and loads the relevant assets.

```Dart
import 'package:ansicolor/ansicolor.dart';
import 'package:example/src/column.dart';
import 'package:example/src/sponsor.dart';
import 'package:example/src/sqlite_type.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';

/// To run this program navigate to the folder: /example
/// in your local copy the package [generic_reader] and
/// use the command:
///
/// # dart bin/player_example.dart

/// Demonstrates how to use [GenericReader] to read constants
/// with parametrized type from a static representation
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

  // ConstantReade representing field 'firstName'.
  final firstNameCR =
      ConstantReader(playerLib.classes.first.fields[2].computeConstantValue());

  final sponsorsCR =
      ConstantReader(playerLib.classes.first.fields[3].computeConstantValue());

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
  print(green('Retrieving a [Column<Text>]:'));
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
The only difference is that the resulting variable `columnFirstName` will then be of type `Column<SqliteType>`.

## Retrieving Constants with Arbitrary Type

The example in the section above demonstrates how to retrieve constants with known parametrized type. The program presented below shows how to proceed if the constant has an arbitrary type parameter.

For this purpose consider the following *wrapper* class. It is a generic class that wraps a value of type `T`:
```Dart
/// Wraps a variable of type [T].
class Wrapper<T> {
  const Wrapper(this.value);

  /// Value of type [T].
  final T value;

  @override
  String toString() => 'Wrapper<$T>(value: $value)';
}
```

The type argument `T` can assume any data-type and it is impractical to handle all available types manually in the decoder function of `Wrapper`.

Instead, one can use the method `get` with the type `dynamic` and the reader attempts to match the static type of the [ConstantReader] input to a registered data-type.
If a match is found `get<dynamic>(constantReader)` returns a constant with
the appropriate value, otherwise a [ReaderError] is thrown.


The program below retrieves the constant `wrappedVariable` defined in [wrapper_test.dart].
Note the use of the method `get<dynamic>()` when defining the [Decoder] function for
the data-type `Wrapper`.

```Dart
import 'package:ansicolor/ansicolor.dart';
import 'package:example/src/sqlite_type.dart';
import 'package:example/src/wrapper.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';

/// To run this program navigate to the folder: /example
/// in your local copy the package [generic_reader] and
/// use the command:
///
/// # dart bin/wrapper_example.dart

/// Demonstrates how use [GenericReader] to read constants
/// with parametrized type from a static representation
/// of a compile-time constant expression
/// represented by a [ConstantReader].
Future<void> main() async {
  /// Reading libraries.
  final wrapperTestLib = await initializeLibraryReaderForDirectory(
    'lib/src',
    'wrapper_test.dart',
  );

  final wrappedCR = ConstantReader(
      wrapperTestLib.classes.first.fields[0].computeConstantValue());

  // Get singleton instance of the reader.
  final reader = GenericReader();

  AnsiPen green = AnsiPen()..green(bold: true);

  // Adding a decoder function for type [Wrapper].
  reader.addDecoder<Wrapper>((cr) {
    final valueCR = cr.peek('value');
    final value = reader.get<dynamic>(valueCR);
    return Wrapper(value);
  });

  final wrapped = reader.get<Wrapper>(wrappedCR);
  print(green('Retrieving a [Wrapper<dynamic>]:'));
  print(wrapped);
  // Prints:
  // Retrieving a [Wrapper<dynamic>]:
  // Wrapper<dynamic>(value: 29)
}
```


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
[wrapper_test.dart]: https://github.com/simphotonics/generic_reader/blob/master/example/lib/src/wrapper_test.dart

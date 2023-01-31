# Generic Reader - Example
[![Dart](https://github.com/simphotonics/generic_reader/actions/workflows/dart.yml/badge.svg)](https://github.com/simphotonics/generic_reader/actions/workflows/dart.yml)

## Retrieving Constants with Parameterized Type

The file [player_example.dart] demonstrates how to use the library [`generic_reader`][generic_reader]
to read the value of a constant with parameterized type from a static representation of a
compile-time constant expression. The program also shows how to register `Decoder` functions for the types [`Column`][Column] and [`SqliteType`][SqliteType].

The constant values that are going to be read are the fields of the const class [`Player`][Player]:
<details>

<summary> Click to show player.dart. </summary>

```Dart
import 'package:test_types/test_types.dart';

/// Class modelling a player.
class Player {
  const Player();

  /// Column name
  final columnName = 'Player';

  /// Column storing player id.
  final id = const Column<Integer>(defaultValue: Integer(1), name: 'id');

  /// Column storing first name of player.
  final firstName = const Column<Text>(
    defaultValue: Text('Thomas'),
    name: 'FirstName',
  );

  /// List of sponsors
  final List<Sponsor> sponsors = const [
    Sponsor('Johnson\'s'),
    Sponsor('Smith Brothers'),
  ];

  /// Test unregistered type.
  final unregistered = const UnRegisteredTestType();

  /// Test [Set<int>].
  final Set<int> primeNumbers = const {1, 3, 5, 7, 11, 13};

  /// Test enum
  final Greek greek = Greek.alpha;

  /// Test map
  final map = const <String, dynamic>{'one': 1, 'two': 2.0};

  /// Test map with enum entry
  final mapWithEnumEntry = const <String, dynamic>{
    'one': 1,
    'two': 2.0,
    'enum': Greek.alpha
  };
}

```
</details>

In the simple example below, the function [`initializeLibraryReaderForDirectory`][initializeLibraryReaderForDirectory]
provided by [`source_gen_test`][source_gen_test] is used to load the source code and initialize objects of type [`LibraryReader`][LibraryReader].

In a standard setting this task is delegated to a [`builder`][builder]
that reads a builder configuration and loads the relevant assets.

<details>
<summary> Click to show player_example.dart. </summary>

```Dart
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
  print('Reading player.dart');
  final playerLib = await initializeLibraryReaderForDirectory(
    'example/src',
    'player.dart',
  );
  print('Done');

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

  // // Get singleton instance of the reader.
  // final reader = GenericReader();

  Integer integerDecoder(ConstantReader cr) {
    return Integer(cr.peek('value')?.intValue ?? double.nan.toInt());
  }

  Real realDecoder(ConstantReader cr) {
    return Real(cr.peek('value')?.doubleValue ?? double.nan);
  }

  Boolean booleanDecoder(ConstantReader cr) {
    return Boolean(cr.read('value').boolValue);
  }

  Text textDecoder(ConstantReader cr) {
    return Text(cr.read('value').stringValue);
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

  // Registering decoders.
  GenericReader.addDecoder<Integer>(integerDecoder);
  GenericReader.addDecoder<Boolean>(booleanDecoder);
  GenericReader.addDecoder<Text>(textDecoder);
  GenericReader.addDecoder<Real>(realDecoder);
  GenericReader.addDecoder<SqliteType>(sqliteTypeDecoder);

  // Adding a decoder for constants of type [Column].
  GenericReader.addDecoder<Column>((cr) {
    final defaultValue = cr.read('defaultValue').get<SqliteType>();
    final name = cr.read('name').get<String>();

    Column<T> columnFactory<T extends SqliteType>() {
      return Column<T>(
        defaultValue: defaultValue as T,
        name: name,
      );
    }

    if (cr.holdsA<Column>([Text])) {
      return columnFactory<Text>();
    }
    if (cr.holdsA<Column>([Real])) {
      return columnFactory<Real>();
    }
    if (cr.holdsA<Column>([Integer])) {
      return columnFactory<Integer>();
    }
    return columnFactory<Boolean>();
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
  GenericReader.addDecoder<Sponsor>((cr) => Sponsor(cr.read('name').stringValue));

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
}

```

</details>

## Retrieving Constants with Dynamic Type

The example in the section *above* demonstrates how to retrieve constants
with a *known* parameterized type.

The program presented below shows how to proceed if the constant has
a **dynamic** type parameter.
Note: The actual data-type must be either a `bool`, `double`, `int`, `num`, `String`, `Type`, `Symbol`
or a type with a **registered decoder**.

Consider the following generic class that wraps a value of type `T`:
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

The type argument `T` can assume any data-type and it is impractical
to handle all available types manually in the decoder function of `Wrapper`.

Instead, one can use the method [`get<dynamic>()`][get].
This signals to the reader to **match the static type**
of the [`ConstantReader`][ConstantReader] instance to a registered data-type.
If a match is found [`get<dynamic>()`][get] returns a constant
with the appropriate value, otherwise an error is thrown.

The program below retrieves the constant `wrapper` defined in [wrapper_instance.dart].
Note the use of the method [`get<dynamic>()`][get] when defining the [Decoder] function for
the data-type `Wrapper`.

<details> <summary> Click to show wrapper_example.dart. </summary>

```Dart
import 'package:analyzer/dart/element/element.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart'; // show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';

import 'package:test_types/test_types.dart';

/// To run this program navigate to the root folder
/// in your local copy the package `generic_reader` and
/// use the command:
///
/// # dart example/bin/wrapped_int_example.dart

/// Demonstrates how to use `GenericReader` to read constants
/// with parameterized type from a static representation
/// of a compile-time constant expression
/// represented by a `ConstantReader`.
Future<void> main() async {
  /// Reading libraries.
  final wrappedIntLib = await initializeLibraryReaderForDirectory(
    'example/src',
    'wrapper_instance.dart',
  );

  ConstantReader? wrapperCR;

  for (var element in wrappedIntLib.allElements) {
    if (element is TopLevelVariableElement) {
      if (element.name == 'wrapper') {
        wrapperCR = ConstantReader(element.computeConstantValue());
      }
    }
  }

  final green = AnsiPen()..green(bold: true);

  // Adding a decoder function for type [Wrapper].
  GenericReader.addDecoder<Wrapper>((ConstantReader cr) {
    return Wrapper(cr.read('value').get<dynamic>());
  });

  print('');
  print(green('Retrieving a Wrapper<dynamic>:'));
  if (wrapperCR == null) {
    print('Could not read constant of type Wrapper<dynamic>');
    return;
  }
  final wrapper = wrapperCR.get<Wrapper>();
  print(wrapper);
  print(wrapper.value.runtimeType);
  // Prints:
  //
  // Retrieving a [Wrapper<dynamic>]:
  // Wrapper<dynamic>(value: 297)
  // int
}

```
</details>


## Features and bugs
Please file feature requests and bugs at the [issue tracker].

[issue tracker]: https://github.com/simphotonics/generic_reader/issues

[builder]: https://github.com/dart-lang/build

[initializeLibraryReaderForDirectory]: https://pub.dev/documentation/source_gen_test/latest/source_gen_test/initializeLibraryReaderForDirectory.html

[LibraryReader]: https://pub.dev/documentation/source_gen/latest/source_gen/LibraryReader-class.html

[generic_reader]: https://pub.dev/packages/generic_reader

[Column]: https://github.com/simphotonics/generic_reader/blob/master/example/test_types/lib/src/column.dart

[ConstantReader]: https://pub.dev/documentation/source_gen/latest/source_gen/ConstantReader-class.html

[Decoder]: https://github.com/simphotonics/generic_reader#decoder-functions

[get]: https://pub.dev/documentation/generic_reader/latest/generic_reader/GenericReader/get.html

[getList]: https://pub.dev/documentation/generic_reader/latest/generic_reader/GenericReader/getList.html

[getMap]: https://pub.dev/documentation/generic_reader/latest/generic_reader/GenericReader/getMap.html

[getSet]: https://pub.dev/documentation/generic_reader/latest/generic_reader/GenericReader/getSet.html

[Player]: https://github.com/simphotonics/generic_reader/blob/master/example/src/player.dart

[player_example.dart]: https://github.com/simphotonics/generic_reader/blob/master/example/bin/player_example.dart

[source_gen]: https://pub.dev/packages/source_gen

[source_gen_test]: https://pub.dev/packages/source_gen_test

[SqliteType]: https://github.com/simphotonics/generic_reader/blob/master/example/test_types/lib/src/sqlite_type.dart

[wrapper_example.dart]: https://github.com/simphotonics/generic_reader/blob/master/example/bin/wrapper_example.dart

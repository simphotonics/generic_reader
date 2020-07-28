# Generic Reader - Example
[![Build Status](https://travis-ci.com/simphotonics/generic_reader.svg?branch=master)](https://travis-ci.com/simphotonics/generic_reader)

## Retrieving Constants with Parameterized Type

The file [player_example.dart] demonstrates how to use [`generic_reader`][generic_reader]
to read the value of a constant with parameterized type from a static representation of a
compile-time constant expression. The program also shows how to register [Decoder] functions for the types [`Column`][Column]
and [`SqliteType`][SqliteType].

The constant values that are going to be read are the fields of the const class [`Player`][Player]:
<details>

<summary> Click to show player.dart. </summary>

```Dart
 import 'package:generic_reader_example/src/test_types/column.dart';
 import 'package:generic_reader_example/src/test_types/greek.dart';
 import 'package:generic_reader_example/src/test_types/sponsor.dart';
 import 'package:generic_reader_example/src/test_types/sqlite_type.dart';
 import 'package:generic_reader_example/src/test_types/unregistered_test_type. dart';

 /// Class modelling a player.
 class Player {
   const Player();

   /// Column name
   final columnName = 'Player';

   /// Column storing player id.
   final id = const Column<Integer>();

   /// Column storing first name of player.
   final firstName = const Column<Text>(
     defaultValue: Text('Thomas'),
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
provided by [`source_gen_test`][source_gen_test] is used to load the source code and initialize objects of
type [`LibraryReader`][LibraryReader].

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
 import 'package:source_gen_test/src/init_library_reader.dart';

 import 'package:generic_reader_example/generic_reader_example.dart';

 /// To run this program navigate to the folder: /example
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
     'example/lib/src',
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
       .addDecoder<Integer>(integerDecoder)
       .addDecoder<Boolean>(booleanDecoder)
       .addDecoder<Text>(textDecoder)
       .addDecoder<Real>(realDecoder)
       .addDecoder<SqliteType>(sqliteTypeDecoder);

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
```

</details>

## Retrieving Constants with Unkown Type

The example in the section *above* demonstrates how to retrieve constants
with *known* parameterized type.

The program presented below shows how to proceed if the constant has an **unknown** type parameter. Note: The unknown data-type must be a supported built-in Dart type or a type with a registered decoder.

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

Instead, one can use the method `get` with the type `dynamic`.
This signals to the reader to **match the static type** of the [`ConstantReader`][ConstantReader]
input to a registered data-type. If a match is found `get<dynamic>(constantReader)` returns a constant with
the appropriate value, otherwise an error is thrown.

The program below retrieves the constant `wrappedVariable` defined in [wrapper_test.dart].
Note the use of the method `get<dynamic>()` when defining the [Decoder] function for
the data-type `Wrapper`.

<details> <summary> Click to show wrapper_example.dart. </summary>

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
/// with parameterized type from a static representation
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
    valueType = reader.findType(cr.objectValue.);

    final valueCR = cr.peek('value') as type;
    final value = reader.get<dynamic>(valueCR);
    return Wrapper(value);
  });

  final wrapped = reader.get<Wrapper>(wrappedCR);
  print(green('Retrieving a [Wrapper<dynamic>]:'));
  print(wrapped);
  // Prints:
  // Retrieving a [Wrapper<dynamic>]:
  // Wrapper<dynamic>(value: 27.9)
}
```
</details>


## Features and bugs
Please file feature requests and bugs at the [issue tracker].

[builder]: https://github.com/dart-lang/build
[issue tracker]: https://github.com/simphotonics/directed_graph/issues

[initializeLibraryReaderForDirectory]: https://pub.dev/documentation/source_gen_test/latest/source_gen_test/initializeLibraryReaderForDirectory.html

[LibraryReader]: https://pub.dev/documentation/source_gen/latest/source_gen/LibraryReader-class.html

[generic_reader]: https://pub.dev/packages/generic_reader
[directed_graph]: https://github.com/simphotonics/directed_graph/
[Column]: https://github.com/simphotonics/generic_reader/blob/master/example/lib/src/test_types/column.dart
[ConstantReader]: https://pub.dev/documentation/source_gen/latest/source_gen/ConstantReader-class.html
[Decoder]: https://github.com/simphotonics/generic_reader#decoder-functions
[Player]: https://github.com/simphotonics/generic_reader/blob/master/example/lib/src/player.dart

[player_example.dart]: https://github.com/simphotonics/generic_reader/blob/master/example/bin/player_example.dart

[ReaderError]: https://pub.dev/documentation/generic_reader/latest/generic_reader/ReaderError-class.html
[source_gen]: https://pub.dev/packages/source_gen
[source_gen_test]: https://pub.dev/packages/source_gen_test

[SqliteType]: https://github.com/simphotonics/generic_reader/blob/master/example/lib/src/test_types/sqlite_type.dart

[wrapper_test.dart]: https://github.com/simphotonics/generic_reader/blob/master/example/lib/src/wrapper_test.dart

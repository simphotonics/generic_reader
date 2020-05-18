# Generic Reader


## Example
The file `example.dart` (see folder *bin*) demonstrates how to use [generic_reader] to read a constant value from a static representation of a compile-time constant expression.

The program also shows how to register *Decoder* functions for the types `Column` and `SqliteType`.

To run the program in a terminal navigate to the
folder *generic_reader/example* in your local copy of this library and use the command:
```Shell
$ dart bin/example.dart
```

The constant values that are going to be read are the fields of the const class `Player`:
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
}
```
The classes `Column` and `SqliteType` are defined below.
```Dart
import 'package:example/src/sqlite_type.dart';

/// Class used to define Sqlite columns.
class Column<T extends SqliteType> {
  const Column({
    this.defaultValue,
    this.name,
  });

  /// Default value specified when defining the Sqlite column.
  final T defaultValue;

  /// Optional [name]. Has to be a valid Dart identifier.
  final String name;

  /// Returns the type argument.
  Type get type => T;

  /// Returns true if the generic type [T] is one of the
  /// following types: [Integer],[Boolean],[Real], or [Text].
  bool get isValid => (T == Integer || T == Boolean || T == Real || T == Text);

  /// Returns a [String] containing source code
  /// representing [this].
  @override
  String toString() {
    var b = StringBuffer();
    b.writeln('Column<$T>(');
    if (name != null) {
      b.writeln('  name: \'$name\',');
    }
    if (defaultValue != null) {
      b.writeln('  defalultValue: $defaultValue');
    }
    b.writeln(')');
    return b.toString();
  }
}
```


The first class field holds a `String` value while the following two fields hold values of type `Column<Integer>` and `Column<Text>`, respectively.

In this simple example the function [initializeLibraryReaderForDirectory] provided by [source_gen_test] is used to load the source code and initialize objects of type [LibraryReader].

In a standard setting this task is delegated to a builder that reads a builder configuration and loads the relevant assets.

```Dart
import 'package:ansicolor/ansicolor.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';
import 'package:example/lib/src/sqlite_entity.dart';

Future<void> main() async {

  /// Reading the library player.dart.
    final playerLib =
      await initializeLibraryReaderForDirectory('src', 'player.dart');

  // ConstantReader representing field 'columnName'.
  final columnNameCR =
      ConstantReader(playerLib.classes.first.fields[0].computeConstantValue());

  // ConstantReade representing field 'firstName'.
  final firstNameCR =
      ConstantReader(playerLib.classes.first.fields[2].computeConstantValue());

  // Getting the singleton instance of the reader.
  final reader = GenericReader();

  // Adding a decoder function for constants of type [SqliteType].
  reader.addDecoder<SqliteType>((cr) {
    final value = cr.peek('value');
    if (value.isInt) return Integer(value.intValue);
    if (value.isBool) return Boolean(value.boolValue);
    if (value.isString) return Text(value.stringValue);
    if (value.isDouble) return Real(value.doubleValue);
    return null;
  });

  // Adding a decoder for constants of type [Constraint].
  // Note: [Constraint] extends [GenericEnum]. The instance is retrieved from an internal
  // map. For more information see: https://pub.dev/packages/generic_enum .
  reader.addDecoder<Constraint>(
    (cr) => Constraint.valueMap[cr.peek('value').stringValue],
  );

  // Adding a decoder for constants of type [Column].
  reader.addDecoder<Column>((cr) {
    final defaultValueCR = cr.peek('defaultValue');
    final defaultValue = reader.get<SqliteType>(defaultValueCR);
    final constraintsCR = cr.peek('constraints');
    final constraints = reader.getSet<Constraint>(constraintsCR);
    final nameCR = cr.peek('name');
    final name = reader.get<String>(nameCR);

    Column<T> columnFactory<T extends SqliteType>() {
      return Column<T>(
        constraints: constraints,
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

  // How to retrieve an instance of type [String].
  final columnName = reader.get<String>(columnNameCR);
  print(green('Retrieving a [String]'));
  print('columnName = \'$columnName\'');
  print('');

  // How to retrieve an instance of type [Column<Text>].
  final columnFirstName = reader.get<Column>(firstNameCR);
  print(green('Retrieving a [Column<Text>].'));
  print(columnFirstName.sourceCode);
}

```


## Features and bugs
Please file feature requests and bugs at the [issue tracker].

[issue tracker]: https://github.com/simphotonics/directed_graph/issues
[graphs]: https://pub.dev/packages/graphs
[directed_graph]: https://github.com/simphotonics/directed_graph/
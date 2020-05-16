# Generic Reader


## Example
The file `example.dart` (see folder *bin*) demonstrates how to use [generic_reader] to convert a static Dart representation of a constant object to a runtime object.

The program also shows how to register *Decoder* functions for the types **Column** and **SqliteType**.

The program can be run in a terminal by navigating to the
folder *generic_reader/example* in your local copy of this library and using the command:
```Shell
$ dart bin/example.dart
```

The constant values that are going to be read are the fields of the constant class **Player**:
```Dart
import 'package:sqlite_entity/sqlite_entity.dart';

class Player {
  const Player();

  final columnName = 'Player';

  final id = const Column<Integer>(
    constraints: {
      Constraint.PRIMARY_KEY,
    },
  );

  /// First name of player.
  final firstName = const Column<Text>(
    defaultValue: Text('Thomas'),
    constraints: {
      Constraint.NOT_NULL,
      Constraint.UNIQUE,
    },
  );
}
```
The first class field holds a **String** value while the following two fields hold values of type **Column<Integer>** and **Column<Text>**, respectively.


```Dart
import 'package:ansicolor/ansicolor.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';
import 'package:sqlite_entity/sqlite_entity.dart';

Future<void> main() async {
  /// Reading the library player.dart.
  /// This is usually performed by the build-system, for example by using
  /// the package source_gen. https://pub.dev/packages/source_gen .
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
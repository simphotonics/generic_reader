
# Generic Reader



## Introduction

Source code generation has become an integral software development tool when building and maintaining a large number of data models, data access object, widgets, etc.
Setting up the build system initially takes time and effort but
subsequent maintenance is often easier, less error prone, and certainly less repetitive compared to applying manual modifications.

The premise of source code generation is that we can somehow specify (hopefully few) details and flesh out the rest of the classes, methods, and variables during the build process.

Dart's static analyzer provides access to libraries, classes, fields, class methods, etc (contained in *.dart files) in the form of elements. These elements are static representations of runtime objects.

Source code generation relies heavily on constant objects (instantiated by a constructor prefixed with the keyword const) since constants are known during static analysis. Constant values are represented by a DartObject and can be accessed by using the method computeConstantValue().

For built-in types, DartObject has methods that allow reading the underlying constant object.
For example, it is an easy task to retrieve a constant of type `String`.
```Dart
// Let name be a FieldElement containing a String.
final constantObject = nameFieldElement.computeConstantValue();
final String name = constantObject.toStringValue();
```

For complex user defined data-types that may be defined in terms of other user defined types it can be a daunting task to read the underlying value.
GenericReader provides a systematic way of retrieving constants objects with arbitrary types.

## Terminology

Complex data-types are often defined as a composition of other types, as illustrated in the example below. In order to retrieve a constant value of type `User` one has to retrieve its components first.
```Dart
class Age{
  const Age(this.age);
  final int age;
  bool get isAdult => age > 21;
}

class Name{
  const Name({this.firstName, this.lastName, this.middleName});
  final String firstName;
  final String lastName;
  final String middleName;
}

class User{
  const User({this.name, this.id, this.age});
  final Name name;
  final Age age;
  final int id;
}
```
### Decoder Functions

GenericReader simplifies the task of retrieving constants of complex data-types by allowing users to register `Decoder` functions (for lack of better word).
Decoder functions know how to handle a specific data-type. As such, a decoder is a parametrized function with the following signature:
```Dart
typedef T Decoder<T>(ConstantReader constantReader);
```
The input argument is of type `ConstantReader` (a wrapper around DartObject) and the function returns an object of type `T`. It is presumed that the input argument `constantReader` represents an object of type `T` and this is checked and enforced.

The following shows how to register decoder functions for the types `Age`, `Name`, and `User`.
```Dart
...

// ConstantReader representing an object of type [User].
final userCR = ConstantReader(userFieldElement.computeConstantValue());

// The reader instance. (It is a singleton).
final reader = GenericReader();

// Adding decoders.
reader.addDecoder<Age>((constantReader) => Age(constantReader.peak('age').intValue));
reader.addDecoder<Name>((constantReader) {
  final firstName = constantReader.peek('firstName').stringValue;
  final lastName = constantReader.peek('lastName').stringValue;
  final middleName = constantReader.peek('middleName').stringValue;
  return Name(firstName: firstName, lastName: lastName, middleName: middleName);
});
reader.addDecoder<User>((constantReader){
  final id = constantReader.peek('id').intValue;
  final age = reader.get<Age>(constantReader.peek('age'));
  final name = reader.get<Name>(constantReader.peek('name'));
  return User(name: name, age: age, id: id);
});

// Retrieving a constant of type User:
final User user = reader.get<User>(userCR);
```

## Limitations



## Usage

To use this library include [generic_reader] and [source_gen] as dependencies in your pubspec.yaml file. The example below shows how to read constant class fields of the class **Player** and create instances of type *Column** (a parametrized user defined type).

In the brief example below the LibraryReader is obtained by using the method *initializeLibraryReaderForDirectory* provided by the package [source_gen_test]. In a conventional setting loading of assets is delegated to a builder and source code generation is performed by generators, for example [Generator] or [GeneratorForAnnotation] provided by [source_gen].

```Dart
import 'package:sqlite_entity/sqlite_entity.dart';

class Player {
  const Player();

  final columnName = 'Player';

  /// Player id.
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

The program below illustrates how to register *Decoder* functions with `reader`, the `GenericReader` object.
Retrieval of runtime instances is done with generic function `reader.get<T>()`.

```Dart
import 'package:ansicolor/ansicolor.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';
import 'package:sqlite_entity/sqlite_entity.dart' show Column, SqliteType;

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

## Examples

For further information on how to generate a topological sorting of vertices see [example].

## Features and bugs

Please file feature requests and bugs at the [issue tracker].
[issue tracker]: https://github.com/simphotonics/generic_reader/issues
[example]: example

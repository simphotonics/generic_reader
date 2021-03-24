
# Generic Reader
[![Build Status](https://travis-ci.com/simphotonics/generic_reader.svg?branch=master)](https://travis-ci.com/simphotonics/generic_reader)


## Introduction

The premise of *source code generation* is that we can specify
(hopefully few) details and flesh out the rest of the classes, and methods during the build process.
Dart's static [`analyzer`][analyzer] provides access to libraries, classes,
class fields, class methods, functions, variables, etc in the form of [`Elements`][Elements].

Source code generation relies heavily on *constants* known at compile time.
Compile-time constant expressions are represented by a [`DartObject`][DartObject] and can be accessed by using the method
[`computeConstantValue()`][computeConstantValue()] (available for elements representing a variable).

For built-in types, [`DartObject`][DartObject] has methods that allow reading the underlying constant object.
It is a more laborious task to read constant values of user defined data-types.

The package [`generic_reader`][generic_reader] includes extentions on
[`ConstantReader`][ConstantReader] that simplify reading constants of type `List`, `Set`, `Map`
and provides a systematic way of reading arbitrary constants of known data-type.

## Usage

To use the package [`generic_reader`][generic_reader] the following steps are required:
1. Include [`generic_reader`][generic_reader] and [`source_gen`][source_gen] as dependencies in your pubspec.yaml file.

2. Register a [Decoder][Decoder] function for each *user defined* data-type that is going to be read.
If a decoder function is  missing, an error will be thrown detailing which data-type
needs to be registered with the extension [`GenericReader`][GenericReader].

   - The built-in types `bool`, `double`, `int`, `String`, `Type`, `Symbol` do **not** require a decoder function.

   - There is no need to define decoder functions for **Dart enums** as long as they are read using the method [`enumValue<T>()`][enumValue].

     The file [`player_example.dart`][player_example.dart]
     demonstrates how to read a constant of type `List<dynamic>` containing `int`, `double`,
     and enum values.

3. Retrieve the compile-time constant values using the methods [`get<T>()`][get], [`getList<T>()`][getList],
   [`getSet<T>()`][getSet], [`getMap<T>()`][getMap], [`enumValue<T>()`][enumValue].

4. Process the retrieved compile-time constants and generate the required source code.

## Decoder Functions

The extension [`GenericReader`][GenericReader] provides a systematic method of retrieving constants of
arbitrary data-types by allowing users to register `Decoder` functions (for lack of a better a name).
Decoder functions can make use of other registered decoder functions enabling the retrieval of
complex generic data-structures.

Decoders functions know how to **decode** a specific data-type and have the following signature:
```Dart
typedef T Decoder<T>(ConstantReader constantReader);
```
The input argument is of type [`ConstantReader`][ConstantReader], a wrapper around
[`DartObject`][DartObject],
and the function returns an object of type `T`.
It is presumed that the input argument `constantReader` represents an object of type `T`.

User defined types are often a composition of other types, as illustrated in the example below.
<details>  <summary> Click to show source-code. </summary>

 ```Dart
 enum Title{Mr, Mrs, Dr}

 class Age {
   const Age(this.age);
   final int age;
   bool get isAdult => age > 21;

   @override
   String toString() {
     return 'age: $age';
   }
 }

 class Name {
   const Name({
     required this.firstName,
     required this.lastName,
     this.middleName = '',
   });
   final String firstName;
   final String lastName;
   final String middleName;

   @override
   String toString() {
     return '$firstName ${middleName == '' ? '' : middleName + ' ' }$lastName';
   }
 }

 class User {
   const User({
     required this.name,
     required this.id,
     required this.age,
     required this.title,
   });
   final Name name;
   final Age age;
   final int id;
   final Title title;

   @override
   String toString() {
     return 'user: $name\n'
         '  title: ${title}\n'
         '  id: $id\n'
         '  $age\n';
   }
 }

 ```
</details>

In order to retrieve a constant value of type `User` one has
to retrieve the constructor parameters of type  `int`, `Name`, `Title`, and `Age` first.

The following shows how to define decoder functions for the types `Age`, `Name`, and `User`.
Note that each decoder knows the constructor *parameter-names* and *parameter-types*
of the class it handles. For example, the decoder for `User` knows that `age` has type `Age` and that the field-name is *age*.

```Dart
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;

import 'package:test_types/test_types.dart';

/// Defining decoder functions.
Age ageDecoder(ConstantReader constantReader) => Age(constantReader.read('age').intValue);

Name nameDecoder(ConstantReader constantReader) {
  final firstName = constantReader.read('firstName').stringValue;
  final lastName = constantReader.read('lastName').stringValue;
  final middleName = constantReader.read('middleName').stringValue;
  return Name(firstName: firstName, lastName: lastName, middleName: middleName);
};

User userDecoder(ConstantReader constantReader){
  final id = constantReader.read('id').intValue;
  final age = constantReader.read('age').get<Age>();
  final name = constantReader.read('name').get<Name>();
  final tile = constantReader.read('title').enumValue<Title>();
  return User(name: name, age: age, id: id, title: title);
};

// Registering decoders.
GenericReader.addDecoder<Age>(ageDecoder)
GenericReader.addDecoder<Name>(nameDecoder)
GenericReader.addDecoder<User>(userDecoder);

// Reading the library where an object of type User is defined.
// Retrieving the ConstantReader object representing an instance of User:
// constantReaderOfUser.

// Retrieving a constant value of type User:
final User user = reader.get<User>(constantReaderOfUser);
```
A short program demonstrating how to retrieve a constant of type `User`
is located at [`examples/bin/user_example.dart`](https://github.com/simphotonics/generic_reader/tree/master/example/bin/user_example.dart).

## Limitations

1) Constants retrievable with [`GenericReader`][GenericReader] must have
   a built-in Dart type or a type made available by depending on a package.
   The functions matching the static type of an analyzer element with the type
   of a runtime object do **not** work with relative imports.

   E.g. the demos in folder [`example/bin`](https://github.com/simphotonics/generic_reader/tree/master/example/bin) read types that are provided
   by the package `test_types` located in the subfolder with the same name.

2) Defining decoder functions for each data-type has its obvious limitiations when it comes to *generic types*. In practice, however, generic classes are often designed in such a manner that only few type parameters are valid or likely to be useful. Constants that need to be retrieved during the source-generation process are most likely *annotations* and *simple data-types* that convey information to source code generators. A demonstration on how to retrieve constant values with generic type is presented in [example].

## Examples

For further information on how to use [GenericReader] to retrieve constants of
arbitrary type see [example].

## Features and bugs

Please file feature requests and bugs at the [issue tracker].

[issue tracker]: https://github.com/simphotonics/generic_reader/issues

[analyzer]: https://pub.dev/packages/analyzer

[Elements]: https://pub.dev/documentation/analyzer/latest/dart_element_element/dart_element_element-library.html

[computeConstantValue()]: https://pub.dev/documentation/analyzer/latest/dart_element_element/VariableElement/computeConstantValue.html

[ConstantReader]: https://pub.dev/documentation/source_gen/latest/source_gen/ConstantReader-class.html

[Decoder]: https://github.com/simphotonics/generic_reader#decoder-functions

[DartObject]: https://pub.dev/documentation/analyzer/latest/dart_constant_value/DartObject-class.html

[enumValue]: https://pub.dev/documentation/generic_reader/latest/generic_reader/TypeMethods/enumValue.html

[example]: https://github.com/simphotonics/generic_reader/tree/master/example

[GenericReader]: https://pub.dev/packages/generic_reader

[generic_reader]: https://pub.dev/packages/generic_reader

[get]: https://pub.dev/documentation/generic_reader/latest/generic_reader/GenericReader/get.html

[getEnum]: https://pub.dev/documentation/generic_reader/latest/generic_reader/GenericReader/getEnum.html

[getList]: https://pub.dev/documentation/generic_reader/latest/generic_reader/GenericReader/getList.html

[getMap]: https://pub.dev/documentation/generic_reader/latest/generic_reader/GenericReader/getMap.html

[getSet]: https://pub.dev/documentation/generic_reader/latest/generic_reader/GenericReader/getSet.html

[peek]: https://pub.dev/documentation/source_gen/latest/source_gen/ConstantReader/peek.html

[player_example.dart]: https://github.com/simphotonics/generic_reader/blob/master/example/bin/player_example.dart

[source_gen]: https://pub.dev/packages/source_gen

[source_gen_test]: https://pub.dev/packages/source_gen_test

[TypeMethods]: https://pub.dev/documentation/generic_reader/latest/generic_reader/TypeMethods.html

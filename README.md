
# Generic Reader
[![Build Status](https://travis-ci.com/simphotonics/generic_reader.svg?branch=master)](https://travis-ci.com/simphotonics/generic_reader)


## Introduction

The premise of *source code generation* is that we can somehow specify
(hopefully few) details and flesh out the rest of the classes, methods, and variables during the build process.
Dart's static [`analyzer`][analyzer] provides access to libraries, classes,
class fields, class methods, functions, variables, etc in the form of [`Elements`][Elements].

Source code generation relies heavily on *constants* (instantiated by a constructor prefixed with the keyword const)
since constants are known at compile time.
Compile-time constant expressions are represented by a [`DartObject`][DartObject] and can be accessed by using the method
[`computeConstantValue()`][computeConstantValue()] (available for elements representing a variable).

For built-in types, [`DartType`][DartObject] has methods that allow reading the underlying constant object.
For example, it is an easy task to retrieve a value of type `String`:
```Dart
// Let 'nameFieldElement' be a FieldElement containing a String.
final constantObject = nameFieldElement.computeConstantValue();
final String name = constantObject.toStringValue();
```
It can be a sightly more difficult task to read the underlying constant value
of user defined data-types.
These are often a composition of other types, as illustrated in the example below.
<details>  <summary> Click to show source-code. </summary>

 ```Dart
 enum Title{Mr, Mrs, Dr}

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
   final Title title;
 }
 ```
</details>

In order to retrieve a constant value of type `User` one has to retrieve the constructor parameter of type  `int`, `Name`, `Title`, and `Age` first.


## Usage

To use [`generic_reader`][generic_reader] the following steps are required:
1. Include [`generic_reader`][generic_reader] and [`source_gen`][source_gen] as dependencies in your pubspec.yaml file.
2. Create an instance of [`GenericReader`][GenericReader] (e.g. within a source code generator function):
   ```Dart
   final reader = GenericReader(); // Note: [reader] is a singleton.
   ```
3. Register a [Decoder] function for each data-type that needs to be handled.
   The built-in types `bool`, `double`, `int`, `String`, `Type`, `Symbol` as well as Dart `enums`
   do *not* require decoder functions.
4. Retrieve the constant values that using the methods `get<T>()`, `getList<T>()`,
   `getSet<T>()`, `getEnum<T>()`, and `get<dynamic>()`:
5. Process the retrieved compile-time constants and generate the required source code.

## Decoder Functions

[`GenericReader`][GenericReader] provides a systematic method of retrieving constants of
arbitrary data-types by allowing users to register `Decoder` functions (for lack of a better a name).

Decoders functions know how to **decode** a specific data-type and have the following signature:
```Dart
typedef T Decoder<T>(ConstantReader constantReader);
```
The input argument is of type [`ConstantReader`][ConstantReader] (a wrapper around DartObject) and the function
returns an object of type `T`. It is presumed that the input argument `constantReader` represents
an object of type `T`.

The following shows how to define decoder functions for the types `Age`, `Name`,`Title`, and `User`.
Note that each decoder knows the *field-names* and *field-types* of the class it handles.
For example, the decoder for `User` knows that `age` is of type `Age` and that the field-name is *age*.

```Dart
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;

// The reader instance. (It is a singleton).
final reader = GenericReader();

/// Decoder function for type `Age`.
final Decoder<Age> ageDecoder = ((constantReader) => Age(constantReader.peek('age').intValue));

final Decoder<Name> nameDecoder = ((constantReader) {
  final firstName = constantReader.peek('firstName').stringValue;
  final lastName = constantReader.peek('lastName').stringValue;
  final middleName = constantReader.peek('middleName').stringValue;
  return Name(firstName: firstName, lastName: lastName, middleName: middleName);
});

final Decoder<User> userDecoder = ((constantReader){
  final id = constantReader.peek('id').intValue;
  final age = reader.get<Age>(constantReader.peek('age'));
  final name = reader.get<Name>(constantReader.peek('name'));
  final tile = reader.getEnum<Title>(constantReader.peek('title'));
  return User(name: name, age: age, id: id, title: title);
});

reader.addDecoder<Age>(ageDecoder).addDecoder<Name>(nameDecoder).addDecoder<User>(userDecoder);
...

// Retrieving a constant value of type User:
final User user = reader.get<User>(userCR);
```
Note: The method [peek] returns an instance of [ConstantReader] representing the class field specified by the input `String`.
It returns `null` if the field was not initialized or not present.
Moreover, [peek] will recursively scan the super classes if the field could not be found in the current context.

## Limitations

Defining decoder functions for each data-type has its obvious limitiations when it comes to generic types.
Programming the logic for reading generic constant values is made more difficult by the fact
that Dart does not allow variables of data-type `Type` but only **type-literals** to be used as type arguments.

In practice, however, generic classes are often designed in such a manner that only few type parameters
are valid or likely to be useful. A demonstration on how to retrieve
constant values with generic type is presented in [example].

Last but not least, constants that need to be retrieved
during the source-generation process are most likely *annotations*
and *simple data-types* that convey information to source code generators.


## Examples

For further information on how to use [GenericReader] to retrieve constants of arbitrary type see [example].

## Features and bugs

Please file feature requests and bugs at the [issue tracker].

[issue tracker]: https://github.com/simphotonics/generic_reader/issues
[analyzer]: https://pub.dev/packages/analyzer

[Elements]: https://pub.dev/documentation/analyzer/latest/dart_element_element/dart_element_element-library.html


[computeConstantValue()]: https://pub.dev/documentation/analyzer/latest/dart_element_element/VariableElement/computeConstantValue.html

[ConstantReader]: https://pub.dev/documentation/source_gen/latest/source_gen/ConstantReader-class.html

[Decoder]: https://github.com/simphotonics/generic_reader#decoder-functions

[DartObject]: https://pub.dev/documentation/analyzer/latest/dart_constant_value/DartObject-class.html

[example]: example

[Generator]: https://pub.dev/documentation/source_gen/latest/source_gen/Generator-class.html

[GeneratorForAnnotation]: https://pub.dev/documentation/source_gen/latest/source_gen/GeneratorForAnnotation-class.html

[GenericReader]: https://pub.dev/packages/generic_reader

[generic_reader]: https://pub.dev/packages/generic_reader

[peek]: https://pub.dev/documentation/source_gen/latest/source_gen/ConstantReader/peek.html

[Revivable]: https://pub.dev/documentation/source_gen/latest/source_gen/Revivable-class.html

[source_gen]: https://pub.dev/packages/source_gen

[source_gen_test]: https://pub.dev/packages/source_gen_test


# Generic Reader



## Introduction

Source code generation has become an integral software development tool when building and maintaining a large number of data models, data access object, widgets, etc.
Setting up the build system initially takes time and effort but
subsequent maintenance is often easier, less error prone, and certainly less repetitive compared to applying manual modifications.

The premise of source code generation is that we can somehow specify (hopefully few) details and flesh out the rest of the classes, methods, and variables during the build process.

Dart's static [analyzer] provides access to libraries, classes, class fields, class methods, functions, variables, etc in the form of [Elements].

Source code generation relies heavily on *constants* (instantiated by a constructor prefixed with the keyword const) since constants are at compile time and known during static analysis. Compile-time constant expressions are represented by a [DartObject] and can be accessed by using the method [computeConstantValue()] (available for elements representing a variable).

For built-in types, [DartObject] has methods that allow reading the underlying constant object.
For example, it is an easy task to retrieve a constant value of type `String`:
```Dart
// Let 'nameFieldElement' be a FieldElement containing a String.
final constantObject = nameFieldElement.computeConstantValue();
final String name = constantObject.toStringValue();
```

For user defined data-types that may be defined in terms of other user defined types it can be a sightly more difficult task to read the underlying constant value.
[GenericReader] is aimed at retrieving compile-time constant expressions with arbitrary types.

## Terminology

User defined data-types are often a composition of other types, as illustrated in the example below. In order to retrieve a constant value of type `User` one has to retrieve its components of type  `int`, `Name`, and `Age` first.
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

[GenericReader] provides a systematic method of retrieving constants of arbitrary data-types by allowing users to register `Decoder` functions (for lack of better word).

Decoders functions know how to `decode` a specific data-type and have the following signature:
```Dart
typedef T Decoder<T>(ConstantReader constantReader);
```
The input argument is of type [ConstantReader] (a wrapper around DartObject) and the function returns an object of type `T`. It is presumed that the input argument `constantReader` represents an object of type `T` and this is checked and enforced.

The following shows how to register decoder functions for the types `Age`, `Name`, and `User`. Note that each decoder knows the *field-names* and *field-types* of the class it handles. For example, the decoder for `User` knows that `age` is of type `Age` and that the field-name is 'age'.
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

// Retrieving a constant value of type User:
final User user = reader.get<User>(userCR);
```

## Limitations

Defining decoder functions for each data-type has its obvious limitiations when it comes to generic types.
Programming the logic for reading generic constant values is made more difficult by the fact that Dart does not allow variables of data-type `Type` but only **type-literals** to be used as type arguments.

<!-- This is demonstrated by the short program below:
```Dart
class Wrapper<T>{
  const Wrapper(T t);
  final T value;
}

main(){
  // Storing a class literal as a variable of type [Type].
  final Type intType = int;

  // Attempting to instantiate an object of type int.
  final wrappedInt = Wrapper<intType>(29);
}
```

The program above will fail with the error message:
```
$ dart bin/example.dart
bin/example.dart: Error: 'intType' isn't a type.
  final wrappedInt = Wrapper<intType>(29);
                             ^^^^^^^
```
This is slightly confusing since `intType` is of type `Type`. The point is that one cannot use a variable of data-type `Type` as a type parameter or to instantiate new objects. In these cases a **type literal** is required. -->

<!-- As a consequence, it is rather cumbersome to retrieve constants of arbitrary parametrized data-types.

 A decoder function for a generic data-type like `Wrapper` could be something like:
```Dart
reader.addDecoder<Wrapper>((constantReader){
  final valueCR = constantReader.peek('value');

  // Instead of:
  if (valueType == type) {
    final value = reader<valueType>get(valueCR);
    //                   ^^^^^^^^^ error: literal type required
    return Wrapper<valueType>(value);
    //             ^^^^^^^^^   error: literal type required
  }


  if (reader.isA<int>(valueCR)) {
    final value = reader<int>get(valueCR);
    return Wrapper<int>(value);
  }
  if (reader.isA<String>(valueCR)){
    final value = reader<String>get(valueCR);
    return Wrapper<String>(value);
  }
  return null;
});
``` -->

In practice, however, generic classes are often designed in such a manner that only few type parameters are valid or likely to be useful. A demonstration on how to retrieve constants with generic type is presented in [example].

Last but not least, constants that need to be retrieved during the source-generation process are most likely *annotations* and *simple data-types* that convey information to source code generators.


## Usage

To use this library include [generic_reader] and [source_gen] as dependencies in your pubspec.yaml file.

## Examples

For further information on how to a reader [DartObject]s and retrieve constants of arbitrary type see [example].

## Features and bugs

Please file feature requests and bugs at the [issue tracker].

[issue tracker]: https://github.com/simphotonics/generic_reader/issues
[analyzer]: https://pub.dev/packages/analyzer

[Elements]: https://pub.dev/documentation/analyzer/latest/dart_element_element/dart_element_element-library.html


[computeConstantValue()]: https://pub.dev/documentation/analyzer/latest/dart_element_element/VariableElement/computeConstantValue.html

[ConstantReader]: https://pub.dev/documentation/source_gen/latest/source_gen/ConstantReader-class.html

[DartObject]: https://pub.dev/documentation/analyzer/latest/dart_constant_value/DartObject-class.html

[example]: example

[Generator]: https://pub.dev/documentation/source_gen/latest/source_gen/Generator-class.html

[GeneratorForAnnotation]: https://pub.dev/documentation/source_gen/latest/source_gen/GeneratorForAnnotation-class.html

[GenericReader]: https://pub.dev/packages/generic_reader

[generic_reader]: https://pub.dev/packages/generic_reader

[source_gen]: https://pub.dev/packages/source_gen

[source_gen_test]: https://pub.dev/packages/source_gen_test


# Generic Reader



## Introduction

Source code generation has become an integral software development tool when building and maintaining a large number of data models, data access object, widgets, etc.
Setting up the build system initially takes time and effort but
subsequent maintenance is often easier, less error prone, and certainly less repetitive compared to applying manual modifications.

The premise of source code generation is that we can somehow specify (hopefully few) details and flesh out the rest of the classes, methods, and variables during the build process.

Dart's static [analyzer] provides access to libraries, classes, fields, class methods, etc (contained in *.dart files) in the form of elements. These elements are static representations of runtime objects.

Source code generation relies heavily on *constants* (instantiated by a constructor prefixed with the keyword const) since constants are known during static analysis. Constants are represented by a [DartObject] and can be accessed by using the method [computeConstantValue()] (available for elements representing a variable).

For built-in types, [DartObject] has methods that allow reading the underlying constant object.
For example, it is an easy task to retrieve a constant of type `String`.
```Dart
// Let name be a FieldElement containing a String.
final constantObject = nameFieldElement.computeConstantValue();
final String name = constantObject.toStringValue();
```

For complex user defined data-types that may be defined in terms of other user defined types it can be a daunting task to read the underlying value.
[GenericReader] provides a systematic way of retrieving constant objects with arbitrary types.

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

[GenericReader] simplifies the task of retrieving constants of complex data-types by allowing users to register `Decoder` functions (for lack of better word).
Decoder functions know how to handle a specific data-type. As such, a decoder is a parametrized function with the following signature:
```Dart
typedef T Decoder<T>(ConstantReader constantReader);
```
The input argument is of type [ConstantReader] (a wrapper around DartObject) and the function returns an object of type `T`. It is presumed that the input argument `constantReader` represents an object of type `T` and this is checked and enforced.

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

Dart does allow storing a class literals as a variable to type [Type], but it is not possible to use this variable as an alias to instantiate an object of type [Type]. This is demonstrated by the short program below:
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
```Shell
$ dart bin/example.dart
bin/example.dart: Error: 'intType' isn't a type.
  final wrappedInt = Wrapper<intType>(29);
                             ^^^^^^^
```
This is slightly confusing since `intType` is of type `Type`. The point is that one cannot use a variable of type `Type` as a type parameter or to instantiate new objects. In these cases a class literal is required.

As a consequence it makes is cumbersome to retrieve constants of parametrized data-types. A decoder function for a generic data-type like `Wrapper` could be something like:
```Dart
reader.addDecoder<Wrapper>((constantReader){
  final valueCR = constantReader.peek('value');
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

```









## Usage

To use this library include [generic_reader] and [source_gen] as dependencies in your pubspec.yaml file.

## Examples

For further information on how to generate a topological sorting of vertices see [example].

## Features and bugs

Please file feature requests and bugs at the [issue tracker].
[issue tracker]: https://github.com/simphotonics/generic_reader/issues
[example]: example

[analyzer]: https://pub.dev/packages/analyzer

[computeConstantValue()]: https://pub.dev/documentation/analyzer/latest/dart_element_element/VariableElement/computeConstantValue.html

[ConstantReader]: https://pub.dev/documentation/source_gen/latest/source_gen/ConstantReader-class.html

[DartObject]: https://pub.dev/documentation/analyzer/latest/dart_constant_value/DartObject-class.html

[Generator]: https://pub.dev/documentation/source_gen/latest/source_gen/Generator-class.html

[GeneratorForAnnotation]: https://pub.dev/documentation/source_gen/latest/source_gen/GeneratorForAnnotation-class.html

[GenericReader]: https://pub.dev/packages/generic_reader

[source_gen]: https://pub.dev/packages/source_gen

[source_gen_test]: https://pub.dev/packages/source_gen_test

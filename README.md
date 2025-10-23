
# Generic Reader
[![Dart](https://github.com/simphotonics/generic_reader/actions/workflows/dart.yml/badge.svg)](https://github.com/simphotonics/generic_reader/actions/workflows/dart.yml)

## Introduction

The premise of *source code generation* is that we can specify
(hopefully few) details and create libraries, classes, variables,
and methods during the build process.

Source code generation relies heavily on *constants* known at compile time,
represented by a [`DartObject`][DartObject].
For core types, [`DartObject`][DartObject] has methods that
allow reading the underlying constant object to create a runtime object.

The package [`generic_reader`][generic_reader] includes an extention on
[`DartObject`][DartObject] that *simplifies* reading constants of
type `bool`, `double`,`int`,`num`,`String`,`Symbol`,`Type` ,
`List`, `Set`, `Map`,`Iterabel`, `Enum`
and provides a systematic way of reading *arbitrary* constants of *known*
data-type.


## Usage

To use the package [`generic_reader`][generic_reader] the following steps are required:
1. Include [`generic_reader`][generic_reader] as a dependencies in
your pubspec.yaml file.

2. Register a [Decoder][Decoder] object for each *user defined*
data-type `U` that is going to be read
   (see section [Custom Decoders](#custom-decoders)). </br>
Note: The following types are supported out-of-the-box and do *not* require a decoder:
* `bool`, `double`, `int`, `num`,`String`, `Type`, `Symbol`,
* `List<bool>`, `List<double>`, `List<int>`, `List<num>`,
`List<String>`,`List<Symbol>`,`List<Type>`,
* `Set<bool>`, `Set<double>`, `Set<int>`, `Set<num>`, `Set<String>`, `Set<Symbol>`,
`Set<Type>`,
*   `Iterable<bool>`,`Iterable<double>`,`Iterable<int>`,`Iterable<num>`,`Iterable<String>`,
`Iterable<Symbol>`,`Iterable<Type>`.

3. Use Dart's static [`analyzer`][analyzer] to read a library, get
the relevant [`VariableElement`][VariableElement], and calculate the constant
expression represented by a [`DartObject`][DartObject]
using the method [`computeConstantValue()`][computeConstantValue()]. An exmple
is shown in section [Reading an Enumeration](#reading-an-enumeration).

4. Read the compile-time constant values using the extension method: [`read<T>`][read]. <br/>

   * To read a constant representing a *collection* of a *user-defined* type `U`
   use the convenience methods [`readList<U>`][readList],
   [`readSet<U>`][readSet], [`readMap<K,U>`][readMap], and [`readIterator<U>`][readIterator].
   These methods register a suitable decoder and call [`read`][read].
   For example calling [`readList<U>(obj)`][readList], registers the decoder
   `ListDecoder<U>()` and calls `read<List<U>>(obj)`.

   * If the compile-time constant represents a class which defines instance
   variables, one may read a specific instance variable  by specifying
   the parameter `fieldName`. For more info see section
   [Custom Decoders](#custom-decoders).

5. Use the constant values to generate the source-code and complete the building
process.

## Custom Decoders

The extension [`Reader`][Reader] provides a systematic method of
retrieving constants of
arbitrary data-types by allowing users to register [`Decoder`][Decoder] objects.


To create a custom decoder extend [`Decoder<T>`][Decoder] and override the
the method [`T read(DartObject obj)`][Decoder.read]. 
The example below demonstrates how to create a custom decoder for the
sample class `Annotation` and register an instance of the decoder with
the extension [`Reader`][Reader].

```Dart
import 'package:generic_reader/generic_reader.dart';
// An annotation with a const constructor
class Annotation {
  const A({required this.id, required this.names,);
  final int id;
  final Set<String> names;

  @override
  String toString() => 'A(id: $id, names: $names)';
}

class AnnotationDecoder extends Decoder<Annotation> {
  const AnnotationDecoder();

  @override
  Annotation read(DartObject obj) {
    // Read instance variable 'id'.
    final id = obj.read<int>(fieldName: 'id');

    // Read instance variable 'names'.
    final names = obj.read<Set<String>>(fieldName: 'names');
    return A(id: id, names: names);
  }
}
// Registering the decoder with the reader
Reader.addDecoder(const AnnotationDecoder());
```

## Reading an Enumeration

The example below show how to register and read an instance of an enumeration.
In this case, instead of creating a custom
decoder class we register an instance of the already defined generic class
[`EnumDecoder`][EnumDecoder]:

<details>  <summary> Click to show source-code. </summary>

```Dart
import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:build_test/build_test.dart' show resolveSource;
import 'package:generic_reader/generic_reader.dart';

/// Demonstrates how to use [Reader] to read an enum.
enum Order { asc, desc }

Future<void> main() async {
  print('\nReading library: example\n');

  // Read the dart library
  final lib = await resolveSource(
    r'''
    library example;

    enum Order { asc, desc }

    class A {
      const A();
      final Order order = Order.asc;
    }
    ''',
    (resolver) => resolver.findLibraryByName('example'),
    readAllSourcesFromFilesystem: false,
  );

  if (lib == null) return;

  /// Add a decoder for the enum:
  Reader.addDecoder(const EnumDecoder<Order>(Order.values));

  /// Compute the compile-time constant value
  final enumObj = lib.classes[0].fields[0].computeConstantValue();

  /// Read the compile-time constant value to obtain a runtime instance of the
  /// enumeration.
  final enum0 = enumObj?.read<Order>();

  print(
    '\nReading an enum of type ${'Order'.style(Ansi.green)}: '
    '$enum0\n',
  );
}

```
</details>


## Reading a Nested List

The program listed below is available in the folder [example][example] and
shows how to read a constant of type
`List<List<String>>`:

```Dart
import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:build_test/build_test.dart' show resolveSource;
import 'package:generic_reader/generic_reader.dart';

/// Demonstrates how to use [Reader] to read a nested list.
final libraryString = r'''
    library example;

    class A {
      const A();
      final nestedList = List<List<String>> [['a'], ['b']];
    }
    '''

Future<void> main() async {
  print('\nReading library: example\n');

  final lib = await resolveSource(libraryString,
    (resolver) => resolver.findLibraryByName('example'),
    readAllSourcesFromFilesystem: false,
  );

  if (lib == null) return;

  print('\nAdding decoder for List<List<String>>\n');
  Reader.addDecoder(const ListDecoder<List<String>>());

  final listObj = lib.classes[0].fields[0].computeConstantValue();
  final list1 = listObj?.read<List<List<String>>>();
  final list2 = listObj?.read();
  final list3 = listObj?.readList<List<String>>();

  print('\nlistObj.read<$listOfListOfString>: $list1');

  print('\nlistObj.read(): $list2');

  print('\nlistObj.readList<$listOfString>(): $list3\n');
}
```
The program above produces the following terminal output:


<details>  <summary> Click to show terminal output. </summary>


```Term
$ dart example/bin/list_example.dart

Reading library: example

  0s _ResolveSourceBuilder<LibraryElement?> on 5 inputs; $package$
  1s _ResolveSourceBuilder<LibraryElement?> on 5 inputs: 5 no-op
  Built with build_runner in 1s; wrote 0 outputs.

Adding decoder for List<List<String>>

listObj.read<List<List<String>>>: [[a], [b]]

listObj.read(): [[a], [b]]

listObj.readList<List<String>>(): [[a], [b]]

```
</details>


## Limitations

1) When using the type `dynamic` the static type of the [DartObject][DartObject]
is used to determine the correct type of the runtime object. If a suitable
decoder is registered with the [Reader][Reader] it is possible
(but not recommended) to omit the type parameter.
For example, the variable `list2` in section
[Reading a Nested List](#reading-a-nested-list) is calculated using the extension
method [read][read] without specifying the type parameter.

2) Defining decoder functions for each data-type has its obvious limitiations when it comes to *generic types*.
In practice, however, generic classes are often designed in such a manner
that only few type parameters are valid or likely to be useful.
Constants that need to be retrieved during the source-generation
process are most likely *annotations* and *simple data-types* that
convey information to source code generators.

## Examples

For further information on how to use [Reader] to retrieve constants of
arbitrary type see [example].

## Features and bugs

Please file feature requests and bugs at the [issue tracker].

[issue tracker]: https://github.com/simphotonics/generic_reader/issues

[analyzer]: https://pub.dev/packages/analyzer

[computeConstantValue()]: https://pub.dev/documentation/analyzer/latest/dart_element_element/VariableElement/computeConstantValue.html

[Decoder]: https://github.com/simphotonics/generic_reader#decoder-functions

[DartObject]: https://pub.dev/documentation/analyzer/latest/dart_constant_value/DartObject-class.html

[EnumDecoder]: https://pub.dev/packages/generic_reader/EnumDecoder.html

[example]: https://github.com/simphotonics/generic_reader/tree/main/example

[Reader]: https://pub.dev/packages/generic_reader/Reader.html

[generic_reader]: https://pub.dev/packages/generic_reader

[read]: https://pub.dev/documentation/generic_reader/latest/generic_reader/Reader/read.html

[Decoder.read]: https://pub.dev/documentation/generic_reader/latest/generic_reader/Decoder/read.html

[readIterator]: https://pub.dev/documentation/generic_reader/latest/generic_reader/Reader/readIterator.html

[readList]: https://pub.dev/documentation/generic_reader/latest/generic_reader/Reader/readList.html

[readMap]: https://pub.dev/documentation/generic_reader/latest/generic_reader/Reader/readMap.html

[readSet]: https://pub.dev/documentation/generic_reader/latest/generic_reader/Reader/readSet.html

[VariableElement]: https://pub.dev/documentation/analyzer/latest/dart_element_element/VariableElement-class.html

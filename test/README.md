# Generic Reader - Test

## Introduction

[GenericEnumBuilder] provides source code generating classes
based on [source_gen] and [analyzer].

This part of the library contains tests designed to verify
that generic_reader behaves as expected.

The folder [src](src) contains sample classes.
The content of these files is accessed via a [LibraryReader].


## Running the tests

The tests may be run in a terminal by navigating to the base folder of a local copy of the library and using the command:
```Shell
$ pub run test -r expanded --test-randomize-ordering-seed=random
```

## Features and bugs
Please file feature requests and bugs at the [issue tracker].

[issue tracker]: https://github.com/simphotonics/generic_reader/issues
[analyzer]: https://pub.dev/packages/analyzer
[source_gen]: https://pub.dev/packages/source_gen
[LibraryReader]: https://pub.dev/documentation/source_gen/latest/source_gen/LibraryReader-class.html

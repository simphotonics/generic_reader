# Generic Reader - Test

## Introduction

[GenericReader] provides a systematic method of retrieving constants of arbitrary data-type
from a static representation
of a Dart compile-time constant.

This part of the library contains tests designed to verify
that [generic_reader] behaves as expected.

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
[GenericReader]: https://pub.dev/packages/generic_reader
[generic_reader]: https://pub.dev/packages/generic_reader
[LibraryReader]: https://pub.dev/documentation/source_gen/latest/source_gen/LibraryReader-class.html

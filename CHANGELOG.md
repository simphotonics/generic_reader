## 0.3.2
- Removed extension method enumValue<T>. 
- Updated dependencies.
- This version requires Dart >=2.19.0.

## 0.2.2

- Amended Dart docs.
- Made the method
[`isEnum<T>()`](https://pub.dev/documentation/generic_reader/latest/generic_reader/GenericReader/isEnum.html) static.

## 0.2.1

- Amended docs.

## 0.2.0

- Converted `GenericReader` into an extension on `ConstantReader`.
- Added example `example/bin/user_example.dart`.

## 0.1.5

Fixed missing references in dartdocs.

## 0.1.4

Moved package `generic_reader_example` to its own folder to expose `README.md`.
Otherwise, the tab **example** just shows the content of the library `generic_reader_example`.

## 0.1.3

Amended `README.md`.

## 0.1.2

Rearranged folder structure of `lib`.

## 0.1.1

Added methods `getMap<T>()` and `getEnum<T>()`.

## 0.1.0
Added condition to handle `null` input in methods `getList<T>()` and `getSet<T>()`.Restructured folder `example`.

## 0.0.9

Removed debug print statement. Updated dependencies.

## 0.0.8

Removed pre-registered decoder for type `Type`.

## 0.0.7

Added method `holdsA<>()`. Deprecated method `isA<>()`.

## 0.0.6

The method `addDecoder<T>()` now returns an instance
of the reader to allow method chaining.

## 0.0.5

Amended README.md

## 0.0.4

Fixed test `get<T>()`.

## 0.0.3

Amended docs.

## 0.0.2

Changed Dart SDK version to >=2.8.1

## 0.0.1

Initial version of the library.

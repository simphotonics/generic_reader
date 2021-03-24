import 'package:ansicolor/ansicolor.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart'; // show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';

import 'package:test_types/test_types.dart';

/// To run this program navigate to the root folder
/// in your local copy the package `generic_reader` and
/// use the command:
///
/// # dart example/bin/wrapped_int_example.dart

/// Demonstrates how to use `GenericReader` to read constants
/// with parameterized type from a static representation
/// of a compile-time constant expression
/// represented by a `ConstantReader`.
Future<void> main() async {
  /// Reading libraries.
  final wrappedTestLib = await initializeLibraryReaderForDirectory(
    'example/src',
    'wrapped_int.dart',
  );

  final wrappedIntCR = ConstantReader(
      wrappedTestLib.classes.first.fields[0].computeConstantValue());

  final green = AnsiPen()..green(bold: true);

  // Adding a decoder function for type [Wrapper].
  GenericReader.addDecoder<Wrapper>((ConstantReader cr) {
    return Wrapper(cr.read('value').get<dynamic>());
  });

  print('');
  print(green('Retrieving a Wrapper<dynamic>:'));
  final wrapped = wrappedIntCR.get<Wrapper>();
  print(wrapped);
  print(wrapped.value.runtimeType);
  // Prints:
  //
  // Retrieving a [Wrapper<dynamic>]:
  // Wrapper<dynamic>(value: 279)
  // int
}

import 'package:analyzer/dart/element/element.dart';
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
  final wrappedIntLib = await initializeLibraryReaderForDirectory(
    'example/src',
    'wrapper_instance.dart',
  );

  ConstantReader? wrapperCR;

  for (var element in wrappedIntLib.allElements) {
    if (element is TopLevelVariableElement) {
      if (element.name == 'wrapper') {
        wrapperCR = ConstantReader(element.computeConstantValue());
      }
    }
  }

  final green = AnsiPen()..green(bold: true);

  // Adding a decoder function for type [Wrapper].
  GenericReader.addDecoder<Wrapper>((ConstantReader cr) {
    return Wrapper(cr.read('value').get<dynamic>());
  });

  print('');
  print(green('Retrieving a Wrapper<dynamic>:'));
  if (wrapperCR == null) {
    print('Could not read constant of type Wrapper<dynamic>');
    return;
  }
  final wrapper = wrapperCR.get<Wrapper>();
  print(wrapper);
  print(wrapper.value.runtimeType);
  // Prints:
  //
  // Retrieving a [Wrapper<dynamic>]:
  // Wrapper<dynamic>(value: 297)
  // int
}

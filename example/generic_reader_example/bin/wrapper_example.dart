import 'package:ansicolor/ansicolor.dart';
import 'package:generic_reader_example/generic_reader_example.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';

/// To run this program navigate to the folder: /example/generic_reader_example
/// in your local copy the package [generic_reader] and
/// use the command:
///
/// # dart bin/wrapper_example.dart

/// Demonstrates how use [GenericReader] to read constants
/// with parameterized type from a static representation
/// of a compile-time constant expression
/// represented by a [ConstantReader].
Future<void> main() async {
  /// Reading libraries.
  final wrapperTestLib = await initializeLibraryReaderForDirectory(
    'lib/src',
    'wrapper_test.dart',
  );

  final wrappedCR = ConstantReader(
      wrapperTestLib.classes.first.fields[0].computeConstantValue());

  // Get singleton instance of the reader.
  final reader = GenericReader();

  final green = AnsiPen()..green(bold: true);

  // Adding a decoder function for type [Wrapper].
  reader.addDecoder<Wrapper>((cr) {
    final value = reader.get<dynamic>(cr.peek('value'));
    return Wrapper(value);
  });

  print('');
  print(green('Retrieving a Wrapper<dynamic>:'));
  final wrapped = reader.get<Wrapper>(wrappedCR);
  print(wrapped);
  // Prints:
  //
  // Retrieving a [Wrapper<dynamic>]:
  // Wrapper<dynamic>(value: 27.9)
}

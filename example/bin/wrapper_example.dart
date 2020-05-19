import 'package:ansicolor/ansicolor.dart';
import 'package:example/src/sqlite_type.dart';
import 'package:example/src/wrapper.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';

/// To run this program navigate to the folder: /example
/// in your local copy the package [generic_reader] and
/// use the command:
///
/// # dart bin/wrapper_example.dart

/// Demonstrates how use [GenericReader] to read constants
/// with parametrized type from a static representation
/// of a compile-time constant expression
/// represented by a [ConstantReader].
Future<void> main() async {
  /// Reading libraries.
  final wrapperTestLib = await initializeLibraryReaderForDirectory(
    'lib/src',
    'wrapper_test.dart',
  );

  final wrapperCR = ConstantReader(
      wrapperTestLib.classes.first.fields[0].computeConstantValue());

  // Get singleton instance of the reader.
  final reader = GenericReader();

  // Add a decoder function for constants of type [SqliteType].
  reader.addDecoder<SqliteType>((cr) {
    final value = cr.peek('value');
    if (value.isInt) return Integer(value.intValue);
    if (value.isBool) return Boolean(value.boolValue);
    if (value.isString) return Text(value.stringValue);
    if (value.isDouble) return Real(value.doubleValue);
    return null;
  });

  AnsiPen green = AnsiPen()..green(bold: true);

  // Adding a decoder function for type [Wrapper].
  reader.addDecoder<Wrapper>((cr) {
    final valueCR = cr.peek('value');
    final value = reader.get<dynamic>(valueCR);
    return Wrapper(value);
  });

  final wrappedText = reader.get<Wrapper>(wrapperCR);
  print(green('Retrieving a [Wrapper<Text>]:'));
  print(wrappedText);
  // Prints:
  // Retrieving a [Wrapper<Text>]:
  // Wrapper<dynamic>(value: Text('I am of type [Text])'))
}
import 'package:ansicolor/ansicolor.dart';
import 'package:generic_reader/src/test_types/sqlite_type.dart';
import 'package:generic_reader/src/test_types/wrapper.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/src/init_library_reader.dart';

/// To run this program navigate to the folder: /example
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

  final Decoder<Integer> integerDecoder = ((cr) {
    if (cr == null) return null;
    return Integer(cr.peek('value')?.intValue);
  });
  final Decoder<Real> realDecoder = ((cr) {
    if (cr == null) return null;
    return Real(cr.peek('value')?.doubleValue);
  });
  final Decoder<Boolean> booleanDecoder = ((cr) {
    if (cr == null) return null;
    return Boolean(cr.peek('value')?.boolValue);
  });
  final Decoder<Text> textDecoder = ((cr) {
    if (cr == null) return null;
    return Text(cr.peek('value')?.stringValue);
  });

  final Decoder<SqliteType> sqliteTypeDecoder = ((cr) {
    if (cr == null) return null;
    if (reader.holdsA<Integer>(cr)) return reader.get<Integer>(cr);
    if (reader.holdsA<Text>(cr)) return reader.get<Text>(cr);
    if (reader.holdsA<Real>(cr)) return reader.get<Real>(cr);
    return reader.get<Boolean>(cr);
  });

  reader
      .addDecoder<Integer>(integerDecoder)
      .addDecoder<Boolean>(booleanDecoder)
      .addDecoder<Text>(textDecoder)
      .addDecoder<Real>(realDecoder)
      .addDecoder<SqliteType>(sqliteTypeDecoder);

  AnsiPen green = AnsiPen()..green(bold: true);

  // Adding a decoder function for type [Wrapper].
  reader.addDecoder<Wrapper>((cr) {
    final value = reader.get<dynamic>(cr.peek('value'));
    return Wrapper(value);
  });

  final wrapped = reader.get<Wrapper>(wrappedCR);
  print('');
  print(green('Retrieving a [Wrapper<dynamic>]:'));
  print(wrapped);
  // Prints:
  //
  // Retrieving a [Wrapper<dynamic>]:
  // Wrapper<dynamic>(value: 27.9)
}

import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:build_test/build_test.dart' show resolveSource;
import 'package:generic_reader/generic_reader.dart';

/// To run this program navigate to the root folder
/// in your local copy the package `generic_reader` and
/// use the command:
///
/// # dart example/bin/record_example.dart

/// Demonstrates how to use [Reader] to read an [Record].

/// A record with one positional and one named entry.
typedef Info = (int age, {String firstName});

class A {
  const A();
  final Info info = const (32, firstName: 'Alana');
}

Future<void> main() async {
  print('\nReading library: example\n');

  final lib = await resolveSource(
    r'''
    library example;

    typedef Info = (int age, {String name});

    class A {
      const A();
      final Info info = const (32, firstName: 'Alana');
    }
    ''',
    (resolver) => resolver.findLibraryByName('example'),
    readAllSourcesFromFilesystem: false,
  );

  if (lib == null) return;

  // Record factory:
  Info infoFactory({
    required Map<String, DartObject> named,
    required List<DartObject> positional,
  }) {
    if (!named.containsKey('firstName') || positional.isEmpty) {
      throw RecordDecoder.readRecordError();
    } else {
      final age = positional.first.read<int>();
      final firstName = named['firstName']!.read<String>();
      return (age, firstName: firstName);
    }
  }

  // Add Record Decoder
  Reader.addDecoder<Info>(RecordDecoder<Info>(infoFactory));

  final recordObj = lib.classes[0].fields[0].computeConstantValue();

  final info = recordObj?.read<Info>();

  print(
    '\n Reading a record of type ${'$Info'.style(Ansi.green)}: '
    '$info\n',
  );
}

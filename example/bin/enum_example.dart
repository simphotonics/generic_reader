import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:build_test/build_test.dart' show resolveSource;
import 'package:generic_reader/generic_reader.dart';

/// To run this program navigate to the root folder
/// in your local copy the package `generic_reader` and
/// use the command:
///
/// # dart example/bin/enum_example.dart

/// Demonstrates how to use [Reader] to read an enum.
enum Order { asc, desc }

Future<void> main() async {
  print('Done importing libaries\n');
  print('Reading library: example\n');

  final library = await resolveSource(
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

  final lib = library!;
  Reader.addDecoder(const EnumDecoder<Order>(Order.values));

  final enumObj = lib.classes[0].fields[0].computeConstantValue();
  final enum0 = enumObj?.read<Order>();

  print(
    '\n Reading an enum with type ${'Order'.style(Ansi.green)}: '
    '$enum0\n',
  );
}

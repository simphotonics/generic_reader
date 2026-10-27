import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:build_test/build_test.dart' show resolveSource;
import 'package:generic_reader/generic_reader.dart';

/// To run this program navigate to the root folder
/// in your local copy the package `generic_reader` and
/// use the command:
///
/// # dart example/bin/enum_example.dart

/// Demonstrates how to use [Reader] to read a nested list.
Future<void> main() async {
  print('\nReading library: example\n');

  final lib = await resolveSource(
    r'''
    library example;

    class A {
      const A();
      final nestedList = List<List<String>> [['a'], ['b']];
    }
    ''',
    (resolver) => resolver.findLibraryByName('example'),
    readAllSourcesFromFilesystem: false,
  );

  if (lib == null) return;

  final listOfString = 'List<String>'.style(Ansi.green);
  final listOfListOfString = 'List<List<String>>'.style(Ansi.green);

  print('\nAdding decoder for $listOfListOfString\n');
  Reader.addDecoder(const ListDecoder<List<String>>());

  print(Reader.info);

  final listDartObject = lib.classes[0].fields[0].computeConstantValue();
  final list1 = listDartObject?.read<List<List<String>>>();
  final list2 = listDartObject?.read();
  final list3 = listDartObject?.readList<List<String>>();

  print('\nlistDartObject.read<$listOfListOfString>: $list1');

  print('\nlistDartObject.read(): $list2');

  print('\nlistDartObject.readList<$listOfString>(): $list3\n');
}

import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import 'package:source_gen_test/src/init_library_reader.dart';

Future<void> main() async {
  /// Read library.
  final lib =
      await initializeLibraryReaderForDirectory('test/src', 'researcher.dart');

  print(lib.classes);
  print(lib.classes.first.fields);

  final idCR =
      ConstantReader(lib.classes.first.fields[0].computeConstantValue());

  final nameCR =
      ConstantReader(lib.classes.first.fields[1].computeConstantValue());

  final numbers =
      ConstantReader(lib.classes.first.fields[2].computeConstantValue());
}

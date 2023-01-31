import 'package:analyzer/dart/element/element.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:generic_reader/generic_reader.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;
import 'package:source_gen_test/source_gen_test.dart';

import 'package:test_types/test_types.dart';

Age ageDecoder(ConstantReader constantReader) =>
    Age(constantReader.read('age').intValue);

Name nameDecoder(ConstantReader constantReader) {
  final firstName = constantReader.read('firstName').stringValue;
  final lastName = constantReader.read('lastName').stringValue;
  final middleName = constantReader.read('middleName').stringValue;
  return Name(firstName: firstName, lastName: lastName, middleName: middleName);
}

User userDecoder(ConstantReader constantReader) {
  final id = constantReader.read('id').intValue;
  final age = constantReader.read('age').get<Age>();
  final name = constantReader.read('name').get<Name>();
  final title = constantReader.read('title').get<Title>();
  return User(name: name, age: age, id: id, title: title);
}

/// To run this program navigate to the root folder
/// in your local copy the package `generic_reader` and
/// use the command:
///
/// # dart example/bin/user_example.dart

/// Demonstrates how to use [GenericReader] to read constants
/// with parameterized type from a static representation
/// of a compile-time constant expression
/// represented by a [ConstantReader].
Future<void> main() async {
  final green = AnsiPen()..green(bold: true);

  /// Reading libraries.
  print('Reading example/src/user_instance.dart ...');
  final userLib = await initializeLibraryReaderForDirectory(
    'example/src',
    'user_instance.dart',
  );
  print('Done');

  ConstantReader? userCR;

  for (var element in userLib.allElements) {
    if (element is TopLevelVariableElement) {
      if (element.name == 'user') {
        userCR = ConstantReader(element.computeConstantValue());
      }
    }
  }

  // Registering decoders.
  GenericReader.addDecoder<Age>(ageDecoder);
  GenericReader.addDecoder<Name>(nameDecoder);
  GenericReader.addDecoder<User>(userDecoder);

  print(green('Retrieving a constant of type <User>:'));
  if (userCR != null) {
    print(userCR.get<User>());
  }
}

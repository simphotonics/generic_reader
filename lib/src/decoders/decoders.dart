import 'package:exception_templates/exception_templates.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;

import '../extensions/type_methods.dart';
import '../types/decoder.dart';

/// Decoder function for the type [num].
/// Attempts to read [constantReader] and returns an instance of `num`.
num numDecoder(ConstantReader constantReader) {
  if (constantReader.isInt) return constantReader.intValue;
  if (constantReader.isDouble) return constantReader.doubleValue;
  throw ErrorOf<Decoder<num>>(
      message: 'Error reading const `num` value.',
      invalidState: 'ConstantReader holds a variable of static type: '
          '${constantReader.dartType}',
      expectedState: 'The parameter \'constantReader\' must hold a'
          'constant of type <num>.');
}

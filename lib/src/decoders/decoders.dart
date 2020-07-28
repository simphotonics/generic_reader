/// Contains decoder functions used by [GenericReader].
library generic_reader_decoders;

import 'package:exception_templates/exception_templates.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;

import '../extensions/type_methods.dart';
import '../types/decoder.dart';

/// Decoder function for type [num].
/// Attempts to read [constantReader] and returns an instance of `num`.
///
/// Returns `null` if [constantReader] is `null`.
num numDecoder(ConstantReader constantReader) {
  if (constantReader == null) return null;
  if (constantReader.isInt) return constantReader.intValue;
  if (constantReader.isDouble) return constantReader.doubleValue;
  throw ErrorOf<Decoder<num>>(
    message: 'Error reading const `num` value.',
    invalidState: 'ConstantReader holds a variable of static type: '
        '${constantReader.type}',
  );
}

/// Library providing a customizable generic reader aimed at creating
/// runtime constant objects from a static representation
/// of a compile-time constant expression such as [source_gen.ConstantReader]
/// or [analyzer.DartObject].
library generic_reader;

export 'src/readers/generic_reader.dart';
export 'src/extensions/type_methods.dart';
export 'src/error_types/invalid_type_argument.dart';
export 'src/types/decoder.dart';

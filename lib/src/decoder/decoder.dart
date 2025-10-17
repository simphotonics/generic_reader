import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:exception_templates/exception_templates.dart' show ErrorOf;

import '../type/type_utils.dart';

abstract class Decoder<T> {
  const Decoder();

  /// Returns `true` if this decoder can read instances of
  /// [DartObject] representing type [S], and `false` otherwise.
  bool canDecode<S>() => isSubType<S, T>();

  /// Attempts to create an instance of [T] with information read from
  /// [obj].
  ///
  /// Should throw [ErrorOf] with type argument [Decoder] with type argument
  /// [T] if an instance of [T] cannot be read from [obj].
  T read(DartObject obj);

  /// Returns the generic type of the decoder.
  Type get type => T;

  /// Error thrown if [obj] does not hold a variable of type [T].
  ErrorOf<Decoder<T>> readError(DartObject obj) {
    return ErrorOf<Decoder<T>>(
      message: 'Error reading const <$T> value.',
      invalidState:
          'obj holds a variable with static type: '
          '${obj.type}',
      expectedState:
          'The parameter \'obj\' must hold a '
          'constant with type <$T>.',
    );
  }
}

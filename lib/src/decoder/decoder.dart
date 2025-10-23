import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:exception_templates/exception_templates.dart' show ErrorOf;

abstract class Decoder<T> {
  const Decoder();

  /// Attempts to create an instance of [T] with information read from
  /// the constant [obj].
  ///
  /// Should throw [ErrorOf] with type argument [Decoder] with type argument
  /// [T] if an instance of [T] cannot be read from [obj].
  T read(DartObject obj);

  /// Returns the generic type of the decoder.
  Type get type => T;

  /// Returns an instance of [ErrorOf] with type argument [Decoder]
  /// with type argument [T].
  /// Classes extending [Decoder] of [T] may throw the result of [readError]
  /// if [obj] does not hold a variable of type [T].
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

  @override
  String toString() => '$runtimeType()';
}

import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:exception_templates/exception_templates.dart' show ErrorOf;

abstract class const Decoder<T>() {
  /// Attempts to create an instance of [T] with information read from
  /// the constant represented by [dartObject].
  ///
  /// Should throw [ErrorOf] with type argument [Decoder] with type argument
  /// [T] if an instance of [T] cannot be read from [dartObject].
  T read(DartObject dartObject);

  /// Returns the generic type of the decoder.
  Type get type => T;

  /// Returns an instance of [ErrorOf] with type argument [Decoder]
  /// with type argument [T].
  /// Classes extending [Decoder] of [T] may throw the result of [readError]
  /// if [dartObject] does not hold a variable of type [T].
  ErrorOf<Decoder<T>> readError(DartObject dartObject) {
    return ErrorOf<Decoder<T>>(
      message: 'Error reading const <$T> value.',
      invalidState:
          'dartObject holds a variable with static type: '
          '${dartObject.type}',
      expectedState:
          'The parameter \'dartObject\' must hold a '
          'constant with type <$T>.',
    );
  }

  @override
  String toString() => '$runtimeType()';
}

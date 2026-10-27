import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:exception_templates/exception_templates.dart' show ErrorOf;

import 'decoder.dart';

class const BoolDecoder() extends Decoder<bool> {
  @override
  bool read(DartObject dartObject) => switch (dartObject.toBoolValue()) {
    bool value => value,
    _ => throw readError(dartObject),
  };
}

class const IntDecoder() extends Decoder<int> {
  @override
  int read(DartObject dartObject) => switch (dartObject.toIntValue()) {
    int value => value,
    _ => throw readError(dartObject),
  };
}

const intDecoder = IntDecoder();

class const DoubleDecoder() extends Decoder<double> {
  @override
  double read(DartObject dartObject) => switch (dartObject.toDoubleValue()) {
    double value => value,
    _ => throw readError(dartObject),
  };
}

const doubleDecoder = DoubleDecoder();

class const NumDecoder() extends Decoder<num> {
  @override
  num read(DartObject dartObject) {
    if (dartObject.type?.isDartCoreInt ?? false) {
      return intDecoder.read(dartObject);
    } else if (dartObject.type?.isDartCoreDouble ?? false) {
      return doubleDecoder.read(dartObject);
    } else {
      throw readError(dartObject);
    }
  }
}

class const StringDecoder() extends Decoder<String> {
  @override
  String read(DartObject dartObject) => switch (dartObject.toStringValue()) {
    String value => value,
    _ => throw readError(dartObject),
  };
}

class const SymbolDecoder() extends Decoder<Symbol> {
  @override
  Symbol read(DartObject dartObject) => switch (dartObject.toSymbolValue()) {
    String value => Symbol(value),
    _ => throw readError(dartObject),
  };
}

class const TypeDecoder() extends Decoder<Type> {
  @override
  Type read(DartObject dartObject) => switch (dartObject.toTypeValue()) {
    Type type => type,
    _ => throw readError(dartObject),
  };
}

/// A [Decoder] that can be registered to read a const object with no
/// substructure like a simple annotation. It returns the [value] provided as
/// constructor parameter.
class const ValueDecoder<T>(
  /// The object returned by the method [read].
  final T value,
) extends Decoder<T> {
  @override
  /// Returns the constant value of type [T]
  /// that is provided as constructor parameter.
  T read(DartObject dartObject) => value;
}

/// A generic enum decoder
class const EnumDecoder<E extends Enum>(
  /// Use the static getter `E.values` to obtain the enum values, where `E` is
  /// replaced which the actual enum class name.
  final List<E> values,
) extends Decoder<E> {
  @override
  E read(DartObject dartObject) =>
      switch (dartObject.getField('index')?.toIntValue()) {
        int index when index < values.length => values[index],
        _ => throw readError(dartObject),
      };

  @override
  String toString() {
    return '$runtimeType(), values: $values';
  }
}

/// A callback which returns a [Record] of shape/type [R]
/// given the [positional] and [named]
/// record fields as [DartObject]s.
typedef RecordFactory<R extends Record> = R Function({
  required List<DartObject> positional,
  required Map<String, DartObject> named,
});

/// Typedef representing the [Record] shape returned by
/// the method [DartObject.toRecordValue].
typedef RecordObj = ({
  Map<String, DartObject> named,
  List<DartObject> positional,
});

/// A decoder that can decode a record of shape/type [R].
class const RecordDecoder<R extends Record>(
  /// A callback which returns a [Record] given the positional and named
  /// record fields.
  final RecordFactory<R> recordFactory,
) extends Decoder<R> {
  @override
  /// Attempts to create an instance of [R] with information read from
  /// the constant [dartObject].
  ///
  /// Should throw [ErrorOf] with type argument [Decoder] with type argument
  /// [R] if an instance of [R] cannot be read from [dartObject].
  R read(DartObject dartObject) {
    return switch (dartObject.toRecordValue()) {
      RecordObj recordObj => recordFactory(
        positional: recordObj.positional,
        named: recordObj.named,
      ),
      _ => throw readError(dartObject),
    };
  }

  static ErrorOf<RecordDecoder<T>> readRecordError<T extends Record>() =>
      ErrorOf<RecordDecoder<T>>(
        message: 'Could not read a record of type $T.',
        invalidState:
            'The constant does seem to not represent a record with shape $T.',
        expectedState:
            'The positional and named fields of the record and '
            'their type must match $T. ',
      );
}

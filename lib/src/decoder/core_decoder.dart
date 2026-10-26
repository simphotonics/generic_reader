import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:exception_templates/exception_templates.dart' show ErrorOf;

import 'decoder.dart';

class const BoolDecoder() extends Decoder<bool> {
  @override
  bool read(DartObject obj) => switch (obj.toBoolValue()) {
    bool value => value,
    _ => throw readError(obj),
  };
}

class const IntDecoder() extends Decoder<int> {
  @override
  int read(DartObject obj) => switch (obj.toIntValue()) {
    int value => value,
    _ => throw readError(obj),
  };
}

const intDecoder = IntDecoder();

class const DoubleDecoder() extends Decoder<double> {
  @override
  double read(DartObject obj) => switch (obj.toDoubleValue()) {
    double value => value,
    _ => throw readError(obj),
  };
}

const doubleDecoder = DoubleDecoder();

class const NumDecoder() extends Decoder<num> {
  @override
  num read(DartObject obj) {
    if (obj.type?.isDartCoreInt ?? false) {
      return intDecoder.read(obj);
    } else if (obj.type?.isDartCoreDouble ?? false) {
      return doubleDecoder.read(obj);
    } else {
      throw readError(obj);
    }
  }
}

class const StringDecoder() extends Decoder<String> {
  @override
  String read(DartObject obj) => switch (obj.toStringValue()) {
    String value => value,
    _ => throw readError(obj),
  };
}

class const SymbolDecoder() extends Decoder<Symbol> {
  @override
  Symbol read(DartObject obj) => switch (obj.toSymbolValue()) {
    String value => Symbol(value),
    _ => throw readError(obj),
  };
}

class const TypeDecoder() extends Decoder<Type> {
  @override
  Type read(DartObject obj) => switch (obj.toTypeValue()) {
    Type type => type,
    _ => throw readError(obj),
  };
}

/// A [Decoder] that can be registered to read a const object with no
/// substructure like a simple annotation. It returns the [value] provided as
/// constructor parameter.
class const ValueDecoder<T>(
  /// The object returned by the method [read].
  final T value,
) extends Decoder<T> {
  /// The object returned by the method [read].

  @override
  /// Returns the constant value of type [T]
  /// that is provided as constructor parameter.
  T read(DartObject obj) => value;
}

/// A generic enum decoder
class const EnumDecoder<E extends Enum>(
  /// Use the static enum getter to obtain the values.
  final List<E> values,
) extends Decoder<E> {
  @override
  E read(DartObject obj) => switch (obj.getField('index')?.toIntValue()) {
    int index when index < values.length => values[index],
    _ => throw readError(obj),
  };
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
  /// Override this method and return a [Record] with shape [R]. <br/>
  /// Tip: Use the
  /// helper methods [positionalFields] and [namedFields].
  R read(DartObject obj) {
    return switch (obj.toRecordValue()) {
      RecordObj recordObj => recordFactory(
        positional: recordObj.positional,
        named: recordObj.named,
      ),
      _ => throw readError(obj),
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

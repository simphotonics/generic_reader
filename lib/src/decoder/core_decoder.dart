import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:exception_templates/exception_templates.dart' show ErrorOf;

import 'decoder.dart';

class BoolDecoder extends Decoder<bool> {
  const BoolDecoder();
  @override
  bool read(DartObject obj) => switch (obj.toBoolValue()) {
    bool value => value,
    _ => throw readError(obj),
  };
}

class IntDecoder extends Decoder<int> {
  const IntDecoder();
  @override
  int read(DartObject obj) => switch (obj.toIntValue()) {
    int value => value,
    _ => throw readError(obj),
  };
}

const intDecoder = IntDecoder();

class DoubleDecoder extends Decoder<double> {
  const DoubleDecoder();
  @override
  double read(DartObject obj) => switch (obj.toDoubleValue()) {
    double value => value,
    _ => throw readError(obj),
  };
}

const doubleDecoder = DoubleDecoder();

class NumDecoder extends Decoder<num> {
  const NumDecoder();
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

class StringDecoder extends Decoder<String> {
  const StringDecoder();
  @override
  String read(DartObject obj) => switch (obj.toStringValue()) {
    String value => value,
    _ => throw readError(obj),
  };
}

class SymbolDecoder extends Decoder<Symbol> {
  const SymbolDecoder();
  @override
  Symbol read(DartObject obj) => switch (obj.toSymbolValue()) {
    String value => Symbol(value),
    _ => throw readError(obj),
  };
}

class TypeDecoder extends Decoder<Type> {
  const TypeDecoder();
  @override
  Type read(DartObject obj) => switch (obj.toTypeValue()) {
    Type type => type,
    _ => throw readError(obj),
  };
}

/// A [Decoder] that can be registered to read a const object with no
/// substructure like a simple annotation. It returns the [value] provided as
/// constructor parameter.
class ValueDecoder<T> extends Decoder<T> {
  const ValueDecoder(this.value);

  /// The object returned by the method [read].
  final T value;

  @override
  /// Returns the constant value of type [T]
  /// that is provided as constructor parameter.
  T read(DartObject obj) => value;
}

/// A generic enum decoder
class EnumDecoder<E extends Enum> extends Decoder<E> {
  const EnumDecoder(this.values);

  /// Use the static enum getter to obtain the values.
  final List<E> values;

  @override
  E read(DartObject obj) => switch (obj.getField('index')?.toIntValue()) {
    int index when index < values.length => values[index],
    _ => throw readError(obj),
  };
}

/// A callback which returns a [Record] of shape/type [R]
/// given the [positional] and [named]
/// record fields as [DartObject]s.
typedef RecordFactory<R extends Record> =
    R Function({
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
class RecordDecoder<R extends Record> extends Decoder<R> {
  const RecordDecoder(this.recordFactory);

  /// A callback which returns a [Record] given the positional and named
  /// record fields.
  final RecordFactory<R> recordFactory;

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

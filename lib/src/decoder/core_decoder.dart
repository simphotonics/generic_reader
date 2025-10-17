import 'package:analyzer/dart/constant/value.dart' show DartObject;

import '../extension/type_methods.dart';
import 'decoder.dart';

class BoolDecoder extends Decoder<bool> {
  const BoolDecoder();
  @override
  bool read(DartObject obj) => switch (obj.toBoolValue()) {
    bool value => value,
    _ => throw readError(obj),
  };
}

const boolDecoder = BoolDecoder();

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
    if (obj.isInt) {
      return intDecoder.read(obj);
    } else if (obj.isDouble) {
      return doubleDecoder.read(obj);
    } else {
      throw readError(obj);
    }
  }
}

const numDecoder = NumDecoder();

class StringDecoder extends Decoder<String> {
  const StringDecoder();
  @override
  String read(DartObject obj) => switch (obj.toStringValue()) {
    String value => value,
    _ => throw readError(obj),
  };
}

const stringDecoder = StringDecoder();

class SymbolDecoder extends Decoder<Symbol> {
  const SymbolDecoder();
  @override
  Symbol read(DartObject obj) => switch (obj.toSymbolValue()) {
    String value => Symbol(value),
    _ => throw readError(obj),
  };
}

const symbolDecoder = SymbolDecoder();

class TypeDecoder extends Decoder<Type> {
  const TypeDecoder();
  @override
  Type read(DartObject obj) => switch (obj.toTypeValue()) {
    Type type => type,
    _ => throw readError(obj),
  };
}

const typeDecoder = TypeDecoder();

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

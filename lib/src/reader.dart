import 'dart:collection';

import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/type.dart' show DartType;
import 'package:exception_templates/exception_templates.dart';

import 'decoder/core_decoder.dart';
import 'decoder/decoder.dart';
import 'type/decoder_not_found.dart';
import 'type/invalid_field_name.dart';
import 'type/invalid_type_argument.dart' show InvalidTypeArgument;
import 'extension/type_methods.dart';

part 'decoder/collection_decoder.dart';

extension Reader on DartObject {
  static final Map<Type, Decoder> _decoders = <Type, Decoder>{
    bool: boolDecoder,
    double: doubleDecoder,
    int: intDecoder,
    num: numDecoder,
    String: stringDecoder,
    Symbol: symbolDecoder,
    Type: typeDecoder,
  };
  static final Map<DartType, Type> _resolvedTypes = {};

  /// Returns an [UnmodifiableMapView] of the currently registered decoders.
  static Map<Type, Decoder> get decoders => UnmodifiableMapView(_decoders);

  /// Returns an [UnmodifiableMapView] of the currently resolved types.
  static Map<DartType, Type> get resolvedTypes =>
      UnmodifiableMapView(_resolvedTypes);

  /// Returns `true` if there is a decoder for type [T].
  static bool hasDecoder<T>() => _decoders.containsKey(T);

  /// Returns a set including the core types:
  /// bool, double, dynamic, int,  num, String, Symbol, Type,
  /// Decoders for (exactly) these types cannot be registered or cleared.
  static Set<Type> coreTypes = Set.unmodifiable({
    bool,
    double,
    dynamic,
    int,
    num,
    String,
    Symbol,
    Type,
  });

  /// Returns `true` if [T] belongs to bool,
  /// double, dynamic, int,  num, String, Symbol, Type,
  /// and `false` otherwise.
  static bool isCoreType<T>() => coreTypes.contains(T);

  /// Attempts to remove [decoder] from the set of registered decoders and
  /// returns `true` on success, and `false` otherwise.
  /// Note: Decoders that cannot be cleared handle the following types:
  ///   - `bool`, `double`, `int`, `Null`,`num`,`Symbol`,`Type`,`dynamic`.
  static Decoder<T>? removeDecoderFor<T>() {
    if (isCoreType<T>()) {
      return null;
    } else {
      return _decoders.remove(T) as Decoder<T>;
    }
  }

  /// Adds or updates a decoder function for type [T].
  /// Returns `true` if the decoder was added.
  /// Note: Decoders for the following types can not be added
  /// or updated:
  /// - `bool`, `double`, `int`, `Null`,`num`,`Symbol`,`Type`,
  /// - `dynamic`.
  static bool addDecoder<T>(Decoder<T> decoder) {
    if (isCoreType<T>()) return false;
    if (hasDecoder<T>()) return false;
    // Adding Decoder function.
    _decoders[T] = decoder;
    return true;
  }

  /// Attemps to find a decoder that can decode type [T] and returns it.
  /// Return `null` if no suitable decoder was found.
  static Decoder<T>? findDecoder<T>() {
    if (_decoders.containsKey(T)) {
      return _decoders[T]! as Decoder<T>;
    }
    for (final decoder in _decoders.values) {
      if (decoder.canDecode<T>()) {
        // Just add decoders. Don't overwrite existing ones.
        _decoders[T] ??= decoder;
        return _decoders[T]! as Decoder<T>;
      }
    }
    return null;
  }

  /// Reads the [DartObject] and returns an instance of [T].
  /// * If the argument [fieldName] is not empty,
  /// it reads the field of the object instead and throws
  /// [ErrorOfType] with type argument [InvalidFieldName] if the field does
  /// not exist.
  /// * Throws [ErrorOfType] with type argument [DecoderNotFound] on failure.
  T read<T>({String fieldName = ''}) {
    if (fieldName.isNotEmpty) {
      final fieldObj = getField(fieldName);
      if (fieldObj != null) {
        return fieldObj.read<T>();
      } else {
        throw invalidFieldNameError<T>(fieldName: fieldName);
      }
    }
    if (T == dynamic) return _readDynamic();
    final decoder = findDecoder<T>();
    if (decoder != null) {
      return decoder.read(this);
    } else {
      throw decoderNotFoundError<T>();
    }
  }

  /// Reads a constant with type `dynamic`.
  /// Throws [ErrorOfType] with type argument [DecoderNotFound] on failure.
  dynamic _readDynamic() {
    if (type == null) {
      return null;
    } else {
      if (_resolvedTypes[type] != null) {
        final rType = _resolvedTypes[type]!;
        return _decoders[rType]?.read(this);
      }

      // Try your best
      for (final rType in _decoders.keys) {
        try {
          final result = _decoders[rType]?.read(this);
          // Store resolved type:
          _resolvedTypes[type!] = rType;
          return result;
        } on ErrorOf<Decoder> {
          //print('Read a constant <$type> using Decoder<$rType> failed.');
        }
      }
      throw decoderNotFoundError();
    }
  }

  /// Reads the `dartObject` instance and returns an instance of `List<T>`.
  /// * If the argument [fieldName] is not empty,
  /// it reads the field of the object instead and throws
  /// [ErrorOfType] with type argument [InvalidFieldName] if the field does
  /// not exist.
  /// * Throws [ErrorOf] with type argument [Decoder] with type argument
  /// [List] with type argument [T] if a list can not be constructed.
  List<T> readList<T>({String fieldName = ''}) {
    if (fieldName.isNotEmpty) {
      final fieldObj = getField(fieldName);
      if (fieldObj == null) {
        throw invalidFieldNameError<T>(fieldName: fieldName);
      } else {
        return fieldObj.readList<T>();
      }
    }
    if (isNotList) {
      throw invalidArgumentTypeError<List<T>>();
    }

    final result = toListValue()?.map((item) => item.read<T>()).toList();
    if (result == null) {
      throw isNullError<List<T>>();
    } else {
      return result;
    }
  }

  /// Reads the `dartObject` instance and returns an instance of `List<T>`.
  /// * If the argument [fieldName] is not empty,
  /// it reads the field of the object instead and throws
  /// [ErrorOfType] with type argument [InvalidFieldName] if the field does
  /// not exist.
  /// * Throws [ErrorOf] with type argument [Decoder] with type argument
  /// [Iterable] with type argument [T] if an iterable can not be constructed.
  Iterable<T> readIterable<T>({String fieldName = ''}) {
    if (fieldName.isNotEmpty) {
      final fieldObj = getField(fieldName);
      if (fieldObj == null) {
        throw invalidFieldNameError<T>(fieldName: fieldName);
      } else {
        return fieldObj.readIterable<T>();
      }
    }
    if (isNotList) {
      throw invalidArgumentTypeError<Iterable<T>>();
    }

    final result = toListValue()?.map((item) => item.read<T>());
    if (result == null) {
      throw isNullError<List<T>>();
    } else {
      return result;
    }
  }

  /// Reads the `dartObject` instance and returns an object of type `Set<T>`.
  /// * If the argument [fieldName] is not empty,
  /// it reads the field of the object instead and throws
  /// [ErrorOfType] with type argument [InvalidFieldName] if the field does
  /// not exist.
  /// * Throws [ErrorOf] with type argument [Decoder] with type argument
  /// [Iterable] with type argument [T] if an iterable can not be constructed.
  Set<T> readSet<T>({String fieldName = ''}) {
    if (fieldName.isNotEmpty) {
      final fieldObj = getField(fieldName);
      if (fieldObj == null) {
        throw invalidFieldNameError<Set<T>>(fieldName: fieldName);
      } else {
        return fieldObj.readSet<T>();
      }
    }
    if (isNotSet) {
      throw invalidArgumentTypeError<Set<T>>();
    }
    final result = toSetValue()?.map((item) => item.read<T>()).toSet();
    if (result == null) {
      throw isNullError<Set<T>>();
    } else {
      return result;
    }
  }

  /// Reads the [DartObject] and returns an object of type `Map<K, V>`.
  /// * If the argument [fieldName] is not empty,
  /// it reads the field of the object instead and throws
  /// [ErrorOfType] with type argument [InvalidFieldName] if the field does
  /// not exist.
  /// * Throws an instance of [ErrorOf] with type argument `Decoder<Map<K, V>>`
  /// if the map cannot be constructed.
  Map<K, V> readMap<K, V>({String fieldName = ''}) {
    if (fieldName.isNotEmpty) {
      final fieldObj = getField(fieldName);
      if (fieldObj == null) {
        throw invalidFieldNameError<Map<K, V>>(fieldName: fieldName);
      } else {
        return fieldObj.readMap<K, V>();
      }
    }
    if (isNotMap) {
      throw invalidArgumentTypeError<Map<K, V>>();
    }

    final result = <K, V>{};

    final mapObj = toMapValue();
    if (mapObj == null) {
      throw isNullError<Map<K, V>>();
    } else {
      mapObj.forEach((keyObj, valueObj) {
        final key = keyObj?.read<K>();
        final value = valueObj?.read<V>();

        if (key is K && value is V) {
          result[key] = value;
        }
      });
      return result;
    }
  }

  static String get info {
    return 'Reader:\n'
        '  Registered types: ${_decoders.keys}\n'
        '  Mapped types    : $_resolvedTypes';
  }

  ErrorOfType<InvalidTypeArgument> invalidArgumentTypeError<T>() =>
      throw ErrorOfType<InvalidTypeArgument>(
        message: 'Could not read constant $T.',
        invalidState: 'DartObject $this does not represent a $T.',
        expectedState: 'A DartObject that represents a $T.',
      );

  ErrorOfType<InvalidTypeArgument> isNullError<T>() =>
      throw ErrorOfType<InvalidTypeArgument>(
        message: 'Could not read constant $T.',
        invalidState: 'DartObject $this represents null.',
        expectedState: 'A DartObject that represents a $T.',
      );

  ErrorOfType<InvalidFieldName> invalidFieldNameError<T>({
    required String fieldName,
  }) => throw ErrorOfType<InvalidFieldName>(
    message: 'Could not read a field with name: $fieldName.',
    invalidState: 'DartObject $this does not seem to have a field $fieldName.',
    expectedState: 'Class $T should have a variable with name: $fieldName .',
  );

  ErrorOfType<DecoderNotFound> decoderNotFoundError<T>() {
    final rType = (T == dynamic) ? type : T;

    return ErrorOfType<DecoderNotFound>(
      message: 'Decoder not found.',
      invalidState: 'A decoder for type $rType is missing.',
      expectedState:
          'Use addDecoder<A>(decoder) to register '
          'a decoder for type $rType.',
    );
  }
}

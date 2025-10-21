import 'dart:collection';

import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/type.dart' show DartType;
import 'package:exception_templates/exception_templates.dart';

import 'decoder/core_decoder.dart';
import 'decoder/decoder.dart';
import 'type/decoder_not_found.dart';
import 'type/invalid_field_name.dart';
import 'type/invalid_type_argument.dart' show InvalidTypeArgument;

part 'decoder/collection_decoder.dart';

extension Reader on DartObject {
  static final Map<Type, Decoder> _decoders = <Type, Decoder>{
    bool: const BoolDecoder(),
    double: const DoubleDecoder(),
    int: const IntDecoder(),
    num: const NumDecoder(),
    String: const StringDecoder(),
    Symbol: const SymbolDecoder(),
    Type: const TypeDecoder(),
    // List
    List<bool>: const ListDecoder<bool>(),
    List<double>: const ListDecoder<double>(),
    List<int>: const ListDecoder<int>(),
    List<num>: const ListDecoder<num>(),
    List<String>: const ListDecoder<String>(),
    List<Symbol>: const ListDecoder<Symbol>(),
    List<Type>: const ListDecoder<Type>(),
    // Set
    Set<bool>: const SetDecoder<bool>(),
    Set<double>: const SetDecoder<double>(),
    Set<int>: const SetDecoder<int>(),
    Set<num>: const SetDecoder<num>(),
    Set<String>: const SetDecoder<String>(),
    Set<Symbol>: const SetDecoder<Symbol>(),
    Set<Type>: const SetDecoder<Type>(),
    // Iterable
    Iterable<bool>: const IterableDecoder<bool>(),
    Iterable<double>: const IterableDecoder<double>(),
    Iterable<int>: const IterableDecoder<int>(),
    Iterable<num>: const IterableDecoder<num>(),
    Iterable<String>: const IterableDecoder<String>(),
    Iterable<Symbol>: const IterableDecoder<Symbol>(),
    Iterable<Type>: const IterableDecoder<Type>(),
  };
  static final Map<DartType, Type> _resolvedTypes = {};

  /// Returns an [UnmodifiableMapView] containing the currently registered
  /// decoders.
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
    List<bool>,
    List<double>,
    List<dynamic>,
    List<int>,
    List<num>,
    List<String>,
    List<Symbol>,
    List<Type>,
    Set<bool>,
    Set<double>,
    Set<dynamic>,
    Set<int>,
    Set<num>,
    Set<String>,
    Set<Symbol>,
    Set<Type>,
    Iterable<bool>,
    Iterable<double>,
    Iterable<dynamic>,
    Iterable<int>,
    Iterable<num>,
    Iterable<String>,
    Iterable<Symbol>,
    Iterable<Type>,
  });

  /// Returns `true` if [T] belongs to the set with elements:
  /// * `bool`, `double`, `dynamic`, `int`, `num`, `String`, `Symbol`, `Type`,
  /// * `List<bool>`,  `List<double>`, `List<dynamic>`, `List<int>`,
  /// * `List<num>`, `List<String>`, `List<Symbol>`, `List<Type>`,
  /// * `Set<bool>`, `Set<double>`, `Set<dynamic>`, `Set<int>`, `Set<num>`,
  /// * `Set<String>`, `Set<Symbol>`, `Set<Type>`,
  /// * `Iterable<bool>`, `Iterable<double>`, `Iterable<dynamic>`, `Iterable<int>`,
  /// * `Iterable<num>`, `Iterable<String>`, `Iterable<Symbol>`, `Iterable<Type>`,
  ///
  ///  and `false` otherwise.
  static bool isCoreType<T>() => coreTypes.contains(T);

  /// Returns `true` if [T] does *not* belong to the set with elements:
  /// * `bool`, `double`, `dynamic`, `int`, `num`, `String`, `Symbol`, `Type`,
  /// * `List<bool>`,  `List<double>`, `List<dynamic>`, `List<int>`,
  /// * `List<num>`, `List<String>`, `List<Symbol>`, `List<Type>`,
  /// * `Set<bool>`, `Set<double>`, `Set<dynamic>`, `Set<int>`, `Set<num>`,
  /// * `Set<String>`, `Set<Symbol>`, `Set<Type>`,
  /// * `Iterable<bool>`, `Iterable<double>`, `Iterable<dynamic>`, `Iterable<int>`,
  /// * `Iterable<num>`, `Iterable<String>`, `Iterable<Symbol>`, `Iterable<Type>`,
  ///
  ///  and `false` otherwise.
  static bool isNotCoreType<T>() => !coreTypes.contains(T);

  /// Attempts to remove the decoder for type [T] from the set of
  /// registered decoders and
  /// returns the decoder on success, and `null` otherwise. <br/>
  /// Note: Decoders for built-in types:
  /// * `bool`, `double`, `dynamic`, `int`, `num`, `String`, `Symbol`, `Type`,
  /// * `List<bool>`,  `List<double>`, `List<dynamic>`, `List<int>`,
  /// * `List<num>`, `List<String>`, `List<Symbol>`, `List<Type>`,
  /// * `Set<bool>`, `Set<double>`, `Set<dynamic>`, `Set<int>`, `Set<num>`,
  /// * `Set<String>`, `Set<Symbol>`, `Set<Type>`,
  /// * `Iterable<bool>`, `Iterable<double>`, `Iterable<dynamic>`, `Iterable<int>`,
  /// * `Iterable<num>`, `Iterable<String>`, `Iterable<Symbol>`, `Iterable<Type>`,
  ///
  /// cannot be cleared.
  static Decoder<T>? removeDecoderFor<T>() {
    if (isCoreType<T>()) {
      return null;
    } else {
      return _decoders.remove(T) as Decoder<T>;
    }
  }

  // /// Attempts to find/add and return a [Decoder] for type [T].
  // /// * 1. Checks for existings decoders for precisely type [T].
  // /// * 2. Checks if there is a decoder for a supertype of [T] that can
  // /// decode a constant with static type [T].
  // Decoder<T>? _addDecoder<T>() {
  //   if (_decoders.containsKey(T)) {
  //     return _decoders[T]! as Decoder<T>;
  //   } else {
  //     for (final decoder in _decoders.values) {
  //       if (decoder.canDecode<T>()) {
  //         // Just add decoders. Don't overwrite existing ones.
  //         _decoders[T] ??= decoder;
  //         if (type != null && type.isType<) _resolvedTypes[type!] = T;
  //         return _decoders[T]! as Decoder<T>;
  //       }
  //     }
  //     return null;
  //   }
  // }

  /// Adds or updates a decoder function for type [T].
  /// Returns `true` if the decoder was added. <br/>
  /// Note: Decoders for the following types:
  /// * `bool`, `double`, `dynamic`, `int`, `num`, `String`, `Symbol`, `Type`,
  /// * `List<bool>`,  `List<double>`, `List<dynamic>`, `List<int>`,
  /// * `List<num>`, `List<String>`, `List<Symbol>`, `List<Type>`,
  /// * `Set<bool>`, `Set<double>`, `Set<dynamic>`, `Set<int>`, `Set<num>`,
  /// * `Set<String>`, `Set<Symbol>`, `Set<Type>`,
  /// * `Iterable<bool>`, `Iterable<double>`, `Iterable<dynamic>`, `Iterable<int>`,
  /// * `Iterable<num>`, `Iterable<String>`, `Iterable<Symbol>`, `Iterable<Type>`,
  ///
  /// cannot be added manually.
  static bool addDecoder<T>(
    Decoder<T> decoder, {
    bool replaceExisting = false,
  }) {
    if (isCoreType<T>()) return false;
    if (hasDecoder<T>() && !replaceExisting) return false;
    _decoders[T] = decoder;
    return true;
  }

  /// Attemps to find a decoder that can decode type [T] and returns it.
  /// Return `null` if no suitable decoder was found.
  static Decoder<T>? findDecoder<T>() {
    return _decoders[T] as Decoder<T>;
  }

  /// Reads the [DartObject] and returns an instance of [T].
  /// * If the argument [fieldName] is not empty,
  /// it reads the field of the object instead and throws
  /// [ErrorOfType] with type argument [InvalidFieldName] if the field does
  /// not exist.
  /// * Throws [ErrorOfType] with type argument [DecoderNotFound] on failure.
  T read<T>({String fieldName = ''}) {
    if (fieldName.isNotEmpty) {
      //return _readField(fieldName: fieldName, topType: T);
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
      final result = decoder.read(this);
      if (type != null) {
        // Store resolve type.
        _resolvedTypes[type!] = T;
      }
      return result;
    } else {
      throw decoderNotFoundError<T>();
    }
  }

  /// Reads a constant with type `dynamic`.
  /// Throws [ErrorOfType] with type argument [DecoderNotFound] on failure.
  dynamic _readDynamic() {
    final dtype = type;

    if (dtype == null) {
      return ErrorOfType<DecoderNotFound>(
        message: 'Cannot decode $this as dynamic.',
        invalidState: 'The type of $this is null.',
        expectedState:
            'A non-null type that can be matched to an existing decoder. ',
      );
    }

    if (_resolvedTypes.containsKey(dtype)) {
      return _decoders[_resolvedTypes[dtype]]!.read(this);
    }

    // Try your best
    for (final rType in _decoders.keys) {
      try {
        final result = _decoders[rType]!.read(this);
        // Must have worked. => Store resolved type.
        _resolvedTypes[type!] = rType;
        return result;
      } on ErrorOf<Decoder> {
        // Did not work. => Try the next decoder.
        print(
          'Reading a constant with type <$type> using decoder'
          ' ${_decoders[rType]} failed.',
        );
      }
    }
    throw decoderNotFoundError<dynamic>();
  }

  /// Reads the `dartObject` instance and returns an instance of `List<T>`.
  /// * If the argument [fieldName] is not empty,
  /// it reads the field of the object instead and throws
  /// [ErrorOfType] with type argument [InvalidFieldName] if the field does
  /// not exist.
  /// * Throws [ErrorOf] with type argument [Decoder] with type argument
  /// [List] with type argument [T] if a list can not be constructed.
  List<T> readList<T>({String fieldName = ''}) {
    if (isNotCoreType<List<T>>()) {
      addDecoder<List<T>>(ListDecoder<T>());
    }
    return read<List<T>>(fieldName: fieldName);
  }

  /// Reads the [DartObject] instance and returns an instance of `List<T>`.
  /// * If the argument [fieldName] is not empty,
  /// it reads the object field instead and throws
  /// [ErrorOfType] with type argument [InvalidFieldName] if the field does
  /// not exist.
  /// * Throws [ErrorOf] with type argument [Decoder] with type argument
  /// [Iterable] with type argument [T] if an iterable can not be constructed.
  Iterable<T> readIterable<T>({String fieldName = ''}) {
    if (isNotCoreType<Iterable<T>>()) {
      addDecoder<Iterable<T>>(IterableDecoder<T>());
    }
    return read<Iterable<T>>(fieldName: fieldName);
  }

  /// Reads the `dartObject` instance and returns an object of type `Set<T>`.
  /// * If the argument [fieldName] is not empty,
  /// it reads the field of the object instead and throws
  /// [ErrorOfType] with type argument [InvalidFieldName] if the field does
  /// not exist.
  /// * Throws [ErrorOf] with type argument [Decoder] with type argument
  /// [Iterable] with type argument [T] if an iterable can not be constructed.
  Set<T> readSet<T>({String fieldName = ''}) {
    if (isNotCoreType<Set<T>>()) {
      addDecoder<Set<T>>(SetDecoder<T>());
    }
    return read<Set<T>>(fieldName: fieldName);
  }

  /// Reads the [DartObject] and returns an object of type `Map<K, V>`.
  /// * If the argument [fieldName] is not empty,
  /// it reads the field of the object instead and throws
  /// [ErrorOfType] with type argument [InvalidFieldName] if the field does
  /// not exist.
  /// * Throws an instance of [ErrorOf] with type argument `Decoder<Map<K, V>>`
  /// if the map cannot be constructed.
  Map<K, V> readMap<K, V>({String fieldName = ''}) {
    if (!hasDecoder<Map<K, V>>()) {
      addDecoder<Map<K, V>>(MapDecoder<K, V>());
    }
    return read<Map<K, V>>(fieldName: fieldName);
  }

  static String get info {
    final decodableTypes = _decoders.keys;
    final count0 = decodableTypes.length;
    final count1 = resolvedTypes.length;
    final step = 4;

    final b0 = StringBuffer();
    final b1 = StringBuffer();
    b0.writeln('Reader:');
    b0.write('  Decodable types:');
    b1.write('  Resolved  types:');

    for (var i = 0; i < count0; i = i + step) {
      final indent = i == 0 ? ' ' : ' ' * 4;
      final step0 = i == 0 ? 7 : step;
      final group0 = decodableTypes
          .skip(i)
          .take(step0)
          .fold<String>('', (sum, e) => sum += '$e, ');
      b0.writeln(indent + group0);
    }

    for (var i = 0; i < count1; i = i + step) {
      final group1 = resolvedTypes.values
          .skip(i)
          .take(step)
          .fold<String>('', (sum, e) => sum += '$e, ');
      final indent = i == 0 ? ' ' : ' ' * 4;
      b1.writeln(indent + group1);
    }

    return b0.toString() + b1.toString();

    // return 'Reader:\n'
    //     '  Decodable types: ${_decoders.keys.toList()}\n'
    //     '  Resolved types: $_resolvedTypes';
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
    invalidState: 'DartObject $this does not have a field $fieldName.',
    expectedState:
        'Decoder expects a class declaring '
        'a variable: $T $fieldName.',
  );

  ErrorOfType<DecoderNotFound> decoderNotFoundError<T>() {
    final rType = (T == dynamic) ? type : T;

    return ErrorOfType<DecoderNotFound>(
      message: 'Decoder not found.',
      invalidState: 'A decoder for type $rType is missing.',
      expectedState:
          'Use addDecoder<$rType>(decoder) to register '
          'a decoder for type $rType.',
    );
  }
}

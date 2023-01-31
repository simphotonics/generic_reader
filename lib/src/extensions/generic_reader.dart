import 'dart:mirrors';

import 'package:source_gen/source_gen.dart' show ConstantReader, TypeChecker;

import 'package:analyzer/dart/element/type.dart'
    show DartType, ParameterizedType;
import 'package:exception_templates/exception_templates.dart';

import '../decoders/decoders.dart';
import '../extensions/type_methods.dart';
import '../types/decoder.dart';
import '../types/unknown_type.dart';

/// Adds the following methods to `ConstantReader`:
/// `get<T>()`, `getList<T>()`, `getSet<T>()`, `getMap<K, V>()`,
/// `holdsA<T>()`.
extension GenericReader on ConstantReader {
  /// Caches instances of `TypeChecker`.
  static final Map<Type, TypeChecker> _checkers = {};

  static final Map<DartType, Type> _resolvedTypes = <DartType, Type>{};

  /// Pre-registered instances of `Decoder` functions.
  static final Map<Type, Decoder> _decoders = {
    bool: (constantReader) => constantReader.boolValue,
    double: (constantReader) => constantReader.doubleValue,
    int: (constantReader) => constantReader.intValue,
    Null: (constantReader) => null,
    num: numDecoder,
    String: (constantReader) => constantReader.stringValue,
    Symbol: (constantReader) => constantReader.symbolValue,
  };

  // Returns true if `T` is a built-in type.
  /// Decoders for (exactly) these types cannot be registered or cleared.
  ///
  /// Note: It is possible to register decoders for generic types
  /// for example: `List<User>`, `Set<int>`, but it is **not** recommended.
  /// Instead, rather use the methods `getList`, `getSet`, and `getMap`.
  static bool isBuiltIn(Type T) {
    return (T == bool ||
        T == double ||
        T == int ||
        T == Map ||
        T == List ||
        T == Null ||
        T == num ||
        T == Set ||
        T == String ||
        T == Symbol ||
        T == Type);
  }

  /// Returns a type `Type` that matches `dartType` and instance of `DartType`.
  ///
  /// Returns `UnknownType` if no match is found.
  static Type resolveType(DartType? dartType) {
    if (dartType == null) return UnknownType;
    if (dartType.isDartCoreString) return String;
    if (dartType.isDartCoreBool) return bool;
    if (dartType.isDartCoreInt) return int;
    if (dartType.isDartCoreDouble) return double;
    if (dartType.isDartCoreNum) return num;
    if (dartType.isDynamic) return dynamic;
    if (dartType.isDartCoreNull) return Null;
    if (dartType.isDartCoreSymbol) return Symbol;
    return _resolvedTypes[dartType] ?? UnknownType;
  }

  /// Clears the decoder function for type `T`.
  /// * Note: Decoders that cannot be cleared handle the following types:
  ///   - `bool`, `double`, `int`, `Null`,`num`,`Symbol`,`Type`,`dynamic`,
  ///   - `List<dynamic>`, `Map<dynamic, dynamic>`, `Set<dynamic>`.
  static void clearDecoder<T>() {
    if (!isBuiltIn(T)) {
      _checkers.remove(T);
      _decoders.remove(T);
    }
  }

  /// Returns a `Set` containing all types with registered decoders.
  static Set<Type> get registeredTypes => _decoders.keys.toSet();

  /// Returns a `Set` containing all types previously resolved
  /// from a static type.
  static Set<Type> get resolvedTypes => _resolvedTypes.values.toSet();

  /// Returns `true` if a decoder function for type `T`
  /// is registered.
  static bool hasDecoder<T>() => _decoders.containsKey(T) ? true : false;

  /// Adds or updates a decoder function for type `T`.
  /// Returns `true` if the decoder was added.
  ///
  /// Note: Decoders for the following types can not be added
  /// or updated.
  /// - `bool`, `double`, `int`, `Null`,`num`,`Symbol`,`Type`,
  /// - `dynamic`, `List`, `Set`, `Map`,
  /// - `UnknownType`.
  static bool addDecoder<T>(Decoder<T> decoder) {
    if (isBuiltIn(T) || T == UnknownType) return false;
    // Adding Decoder function.
    _decoders[T] = decoder;
    return true;
  }

  /// Returns `true` if `T` is a Dart `enum`.
  ///
  /// Note: `T` must not be `dynamic`.
  static bool isEnum<T>() => <T>[] is List<Enum>;

  /// Returns `true` if the instance of `ConstantReader`
  /// represents an object of type `T`.
  bool holdsA<T>() => isMatch(dartType, T);

  /// Returns true if `dartType` represents the type `type`.
  static bool isMatch(DartType? dartType, Type type) {
    if (dartType == null) return false;
    if (resolveType(dartType) == type) return true;
    if (type == dynamic) {
      return dartType.isDynamic ? true : false;
    }
    // Dart:mirrors must not be used with type `dynamic`.
    final checker = _checkers[type] ?? TypeChecker.fromRuntime(type);
    if (checker.isExactlyType(dartType)) {
      final dartTypeArgs = (dartType is ParameterizedType)
          ? dartType.typeArguments
          : <DartType>[];
      final typeMirror = reflectType(type);
      final typeArgs = typeMirror.typeArguments;
      // Match type arguments
      if (dartTypeArgs.length != typeArgs.length) return false;
      for (var i = 0; i < typeArgs.length; i++) {
        if (!isMatch(
          dartTypeArgs[i],
          typeArgs[i].reflectedType,
        )) return false;
      }
      // Store fully resolved types.
      _resolvedTypes[dartType] = type;
      return true;
    } else if (checker.isAssignableFromType(dartType)) {
      return true;
    } else {
      return false;
    }
  }

  /// Reads the `ConstantReader` instance and returns an instance of `T`.
  ///
  /// Throws `ErrorOf<ConstantReader>` if an instance cannot be constructed.
  T get<T>() {
    if (T == dynamic) return getDynamic();

    if (isEnum<T>()) {
      final classMirror = reflectClass(T);
      final values = classMirror.getField(Symbol('values')).reflectee;
      final index = peek('index')?.intValue;

      if (index != null && dartType != null) {
        _resolvedTypes[dartType!] ??= T;
        return values[index];
      } else {
        throw ErrorOf<ConstantReader>(
            message: 'Could not read enum instance of type $T.');
      }
    }

    if (!holdsA<T>()) {
      throw ErrorOf<ConstantReader>(
          message: 'Input does not represent an object of type <$T>',
          invalidState: 'Input represents an object of '
              'type <$dartType>.');
    }
    if (!_decoders.containsKey(T)) {
      throw ErrorOf<ConstantReader>(
          message: 'Could not read value of type [$T].',
          invalidState: 'A decoder function for type [$T] is missing.',
          expectedState: 'Use addDecoder<$T>() to register a '
              'decoder function for type [$T].');
    }
    return _decoders[T]!(this);
  }

  /// Reads a constant with type `dynamic`.
  ///
  /// Throws an `ErrorOf<ConstantReader>` if a constant cannot be constructed.
  dynamic getDynamic() {
    final resolvedType = resolveType(dartType);
    if (resolvedType == UnknownType) {
      // Try registered types:
      final types = registeredTypes.difference(resolvedTypes);
      for (final type in types) {
        if (isMatch(dartType, type)) {
          return _decoders[type]!(this);
        }
      }
    } else if (_decoders.containsKey(resolvedType)) {
      return _decoders[resolvedType]!(this);
    }
    throw ErrorOf<ConstantReader>(
        message: 'Could not read constant via get<$dynamic>().',
        expectedState: 'A registered decoder for data-type '
            '<$dartType>.',
        invalidState: 'Only these types are registered: '
            '${_decoders.keys.toList()}');
  }

  /// Reads the `ConstantReader` instance and returns an instance of `List<T>`.
  ///
  /// Throws `ErrorOf` if an instance of `List<T>`
  /// can not be constructed.
  List<T> getList<T>() {
    if (!holdsA<List<T>>()) {
      throw ErrorOf<ConstantReader>(
          message: 'Input does not represent an object of type <List<$T>',
          invalidState: 'Input represents an object of type '
              '$dartType.');
    }
    if (!_decoders.containsKey(T) && T != dynamic) {
      throw ErrorOf<ConstantReader>(
          message: 'Could not read list-entry value of type [$T].',
          invalidState: 'A decoder function for type [$T] is missing.',
          expectedState: 'Use addDecoder<$T>() to register a decoder '
              'function for type [$T].');
    }
    return listValue.map((item) => ConstantReader(item).get<T>()).toList();
  }

  /// Reads the `ConstantReader` instance and returns an object of type `Set<T>`.
  ///
  /// Throws `ErrorOf` if an instance of `Set<T>`
  /// cannot be constructed.
  Set<T> getSet<T>() {
    if (!holdsA<Set<T>>()) {
      throw ErrorOf<ConstantReader>(
          message: 'Input does not represent an object of type <Set<$T>',
          invalidState: 'Input represents an object of type $dartType.');
    }
    if (!_decoders.containsKey(T) && T != dynamic) {
      throw ErrorOf<ConstantReader>(
          message: 'Could not read set-entry value of type [$T].',
          invalidState: 'A decoder function for type [$T] is missing.',
          expectedState:
              'Use addDecoder<$T>() to register a decoder function for type [$T].');
    }
    return setValue.map((item) => ConstantReader(item).get<T>()).toSet();
  }

  /// Reads `constantReader` and returns an object of type `Map<K, V>`.
  ///
  /// Throws if an instance of `Map<K, V>` cannot be constructed.
  Map<K, V> getMap<K, V>() {
    if (!holdsA<Map<K, V>>()) {
      throw ErrorOf<ConstantReader>(
          message: 'Input does not represent an object of type Map<$K, $V>.',
          invalidState: 'Input represents an object of type '
              '$dartType.');
    }
    if (!_decoders.containsKey(K)) {
      throw ErrorOf<ConstantReader>(
          message: 'Could not read map key of type [$K].',
          invalidState: 'A decoder function for type [$K] is missing.',
          expectedState: 'Use addDecoder<$K>() to register '
              'a decoder function for type [$K].');
    }
    if (!_decoders.containsKey(V) && V != dynamic) {
      throw ErrorOf<ConstantReader>(
          message: 'Could not read map value of type [$V].',
          invalidState: 'A decoder function for type [$V] is missing.',
          expectedState: 'Use addDecoder<$V>() to register a '
              'decoder function for type [$V].');
    }
    return mapValue.map((keyObj, valueObj) {
      final key = ConstantReader(keyObj).get<K>();
      final value = ConstantReader(valueObj).get<V>();
      return MapEntry<K, V>(key, value);
    });
  }

  static String get info {
    return 'GenericReader:\n'
        '  Registered types: ${_decoders.keys.toSet()}\n'
        '  Mapped types    : $_resolvedTypes';
  }
}

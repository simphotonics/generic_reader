import 'dart:mirrors';

import 'package:analyzer/dart/element/type.dart' show DartType;
import 'package:exception_templates/exception_templates.dart';
import 'package:source_gen/source_gen.dart';

import '../decoders/decoders.dart';
import '../extensions/type_methods.dart';
import '../types/decoder.dart';
import '../types/not_registered_type.dart';

/// Reader providing generic methods aimed at converting
/// instances of [DartObject] into runtime objects.
///
/// Intended use: Retrieval of compile-time constant expressions
/// during source code generation.
class GenericReader {
  /// Private constructor.
  GenericReader._();

  /// Singleton factory constructor.
  factory GenericReader() {
    _instance ??= GenericReader._();
    return _instance;
  }

  /// Private instance.
  static GenericReader _instance;

  /// Pre-registered instances of [TypeChecker].
  final Map<Type, TypeChecker> _checkers = {
    bool: TypeChecker.fromRuntime(bool),
    double: TypeChecker.fromRuntime(double),
    int: TypeChecker.fromRuntime(int),
    List: TypeChecker.fromRuntime(List),
    Set: TypeChecker.fromRuntime(Set),
    String: TypeChecker.fromRuntime(String),
    Symbol: TypeChecker.fromRuntime(Symbol),
    Type: TypeChecker.fromRuntime(Type),
  };

  /// Pre-registered instances of [Decoder] functions.
  final Map<Type, Decoder> _decoders = {
    //Null: (constantReader) => null,
    bool: (constantReader) => constantReader.boolValue,
    double: (constantReader) => constantReader.doubleValue,
    int: (constantReader) => constantReader.intValue,
    num: numDecoder,
    String: (constantReader) => constantReader.stringValue,
    Symbol: (constantReader) => constantReader.symbolValue,
  };

  /// Adds or updates a decoder function for type [T].
  /// Returns [this].
  ///
  /// Note: Decoders for the following types can not be added
  /// or updated.
  /// - `bool`, `double`, `int`, `Null`,`num`,`Symbol`,`Type`,
  /// - `dynamic`, `List`, `Set`, `Map`,
  /// - [NotRegisteredType].
  GenericReader addDecoder<T>(Decoder<T> decoder) {
    if (isBuiltIn(T) || T == NotRegisteredType || T == dynamic) return this;
    // Adding TypeChecker.
    _checkers[T] ??= TypeChecker.fromRuntime(T);

    // Adding Decoder function.
    _decoders[T] = decoder;
    return this;
  }

  /// Clears the decoder function for type [T] and returns it as instance
  /// of [Decoder].
  ///
  /// Note: Decoders that cannot be cleared handle the following types:
  /// - `bool`, `double`, `int`, `Null`,`num`,`Symbol`,`Type`,
  /// - `dynamic`, `List`, `Set`, `Map`,
  /// - [NotRegisteredType].
  Decoder<T> clearDecoder<T>() {
    if (isBuiltIn(T)) return null;
    _checkers.remove(T);
    return _decoders.remove(T);
  }

  /// Returns [true] if a decoder function for [type]
  /// is registered with [this].
  bool hasDecoder(Type type) {
    if (_decoders[type] == null) return false;
    return true;
  }

  /// Returns a `Set` containing all types with registered decoders.
  Set<Type> get registeredTypes => _decoders.keys.toSet();

  /// Returns `true` if [constantReader]
  /// represents an object of type `T`.
  ///
  /// * Type arguments of `T` may be specified
  /// via the optional argument [typeArgs].
  bool holdsA<T>(ConstantReader constantReader, {List<Type> typeArgs}) {
    if (T == Null && constantReader == null) return true;
    // An instance of null matches any type.
    if (constantReader == null) return true;
    // Handle case dynamic.
    if (T == dynamic && constantReader.isDynamic) {
      if (constantReader.isDynamic) {
        return true;
      }
      if (findTypeOf(constantReader) == NotRegisteredType) {
        return false;
      } else {
        return true;
      }
    }
    // Get checker.
    final checker = _checkers[T] ?? TypeChecker.fromRuntime(T);
    if (!constantReader.instanceOf(checker)) {
      return false;
    }
    // Passed comparison so far, return [true] if no typeArgs were passed.
    if (typeArgs == null) return true;
    if (typeArgs.isEmpty) return true;
    // Get parameterized DartType arguments:
    final dartTypeArgs = constantReader.typeArgs;
    if (dartTypeArgs.length != typeArgs.length) return false;
    for (var i = 0; i < typeArgs.length; i++) {
      if (!isMatch(
        dartType: dartTypeArgs[i],
        type: typeArgs[i],
      )) return false;
    }
    return true;
  }

  /// Returns `true` if `T` is a Dart `enum`.
  bool isEnum<T>() {
    return reflectClass(T).isEnum;
  }

  /// Returns true if [dartType] represents the type [type].
  ///
  /// Note: If [type] is `dynamic` the function [isMatch] returns
  /// true if there is a registered decoder function for a
  /// `Type` matching [dartType].
  bool isMatch({DartType dartType, Type type}) {
    if (type == dynamic) {
      if (dartType.isDynamic) {
        return true;
      } else {
        if (findType(dartType) == NotRegisteredType) {
          return false;
        } else {
          return true;
        }
      }
    }
    // Dart:mirrors must not be used with type `dynamic`.
    final checker = _checkers[type] ?? TypeChecker.fromRuntime(type);
    return checker.isExactlyType(dartType);
  }

  /// Returns a type [Type] that matches the static [source_gen.DartType] of
  /// [constantReader].
  ///
  /// Returns [NotRegisteredType] if no match is found
  /// among the types that are registered,
  /// i.e. have a decoder function.
  Type findTypeOf(ConstantReader constantReader) {
    if (constantReader.isDynamic) return dynamic;
    for (final type in _checkers.keys) {
      if (constantReader.instanceOf(_checkers[type])) {
        return type;
      }
    }
    return NotRegisteredType;
  }

  /// Returns a type [Type] that matches [dartType].
  ///
  /// Returns [NotRegisteredType] if no match is found
  /// among the types that are registered,
  /// i.e. have a decoder function.
  Type findType(DartType dartType) {
    if (dartType.isDynamic) return dynamic;
    for (final type in _checkers.keys) {
      if (_checkers[type].isExactlyType(dartType)) {
        return type;
      }
    }
    return NotRegisteredType;
  }

  /// Reads [constantReader] and returns an instance of [T].
  ///
  /// Note: Returns [null] if [constantReader] is null.
  ///
  /// Throws [exceptions_templates.ErrorOf] if an instance cannot be constructed.
  T get<T>(ConstantReader constantReader) {
    if (constantReader == null) return null;

    if (T == dynamic) return _getDynamic(constantReader);

    if (isEnum<T>()) return getEnum<T>(constantReader);

    if (!holdsA<T>(constantReader)) {
      throw ErrorOf<GenericReader>(
          message: 'Input does not represent an object of type <$T>',
          invalidState: 'Input represents an object of '
              'type <${constantReader}>.');
    }

    if (!_decoders.containsKey(T)) {
      throw ErrorOf<GenericReader>(
          message: 'Could not read value of type [$T].',
          invalidState: 'A decoder function for type [$T] is missing.',
          expectedState: 'Use addDecoder<$T>() to register a '
              'decoder function for type [$T].');
    }

    return _decoders[T](constantReader);
  }

  /// Reads a constant with type `dynamic`.
  ///
  /// Throws [ReaderError] if a constant cannot be constructed.
  dynamic _getDynamic(ConstantReader constantReader) {
    if (constantReader == null) return null;

    final type = findTypeOf(constantReader);

    if (type == NotRegisteredType) {
      throw ErrorOf<GenericReader>(
        message: 'Could not read constant via get<$dynamic>().',
        expectedState: 'A registered decoder for data-type '
            '<${constantReader.type}>.',
      );
    } else {
      return _decoders[type](constantReader);
    }
  }

  /// Reads [constantReader] and returns an instance of the
  /// Dart enum `T`.
  ///
  /// Throws `ErrorOfType<InvalidTypeArgument>` if `T` is `dynamic` or
  /// if `T` does not represent a Dart `enum`.
  T getEnum<T>(ConstantReader constantReader) => constantReader.enumValue<T>();

  /// Reads [constantReader] and returns an instance of `List<T>`.
  ///
  /// Throws [exception_templates.ErrorOf] if an instance of `List<T>`
  /// can not be constructed.
  List<T> getList<T>(ConstantReader constantReader) {
    if (constantReader == null) return null;

    if (!holdsA<List>(constantReader, typeArgs: [T])) {
      throw ErrorOf<GenericReader>(
          message: 'Input does not represent an object of type <List<$T>',
          invalidState: 'Input represents an object of type '
              '${constantReader.type}.');
    }
    if (!_decoders.containsKey(T) && T != dynamic) {
      throw ErrorOf<GenericReader>(
          message: 'Could not read list-entry value of type [$T].',
          invalidState: 'A decoder function for type [$T] is missing.',
          expectedState: 'Use addDecoder<$T>() to register a decoder '
              'function for type [$T].');
    }
    return constantReader.listValue
        .map((item) => get<T>(ConstantReader(item)))
        .toList();
  }

  /// Reads [constantReader] and returns an object of type `Set<T>`.
  ///
  /// Throws [exception_templates.ErrorOf] if an instance of `Set<T>`
  /// cannot be constructed.
  Set<T> getSet<T>(ConstantReader constantReader) {
    if (constantReader == null) return null;

    if (!holdsA<Set>(constantReader, typeArgs: [T])) {
      throw ErrorOf<GenericReader>(
          message: 'Input does not represent an object of type <Set<$T>',
          invalidState:
              'Input represents an object of type ${constantReader.type}.');
    }
    if (!_decoders.containsKey(T) && T != dynamic) {
      throw ErrorOf<GenericReader>(
          message: 'Could not read set-entry value of type [$T].',
          invalidState: 'A decoder function for type [$T] is missing.',
          expectedState:
              'Use addDecoder<$T>() to register a decoder function for type [$T].');
    }
    return constantReader.setValue
        .map((item) => get<T>(ConstantReader(item)))
        .toSet();
  }

  /// Reads [constantReader] and returns an object of type `Map<K, V>`.
  ///
  /// Throws if an instance of `Map<K, V>` cannot be constructed.
  Map<K, V> getMap<K, V>(ConstantReader constantReader) {
    if (constantReader == null) return null;

    if (!holdsA<Map>(constantReader, typeArgs: [K, V])) {
      throw ErrorOf<GenericReader>(
          message: 'Input does not represent an object of type Map<$K, $V>.',
          invalidState: 'Input represents an object of type '
              '${constantReader.type}.');
    }
    if (!_decoders.containsKey(K)) {
      throw ErrorOf<GenericReader>(
          message: 'Could not read map key of type [$K].',
          invalidState: 'A decoder function for type [$K] is missing.',
          expectedState: 'Use addDecoder<$K>() to register '
              'a decoder function for type [$K].');
    }
    if (!_decoders.containsKey(V) && V != dynamic) {
      throw ErrorOf<GenericReader>(
          message: 'Could not read map value of type [$V].',
          invalidState: 'A decoder function for type [$V] is missing.',
          expectedState: 'Use addDecoder<$V>() to register a '
              'decoder function for type [$V].');
    }

    return constantReader.mapValue.map((keyObj, valueObj) {
      final key = get<K>(ConstantReader(keyObj));
      final value = get<V>(ConstantReader(valueObj));
      return MapEntry<K, V>(key, value);
    });
  }

  /// Returns true if [T] is a built-in type.
  /// Decoders for (exactly) these types cannot be registered or cleared.
  ///
  /// Note: It is possible to register decoders for generic types
  /// for example: `List<User>`, `Set<int>`, but it is **not** recommended.
  /// Instead, rather use the methods `getList`, `getSet`, and `getMap`.
  bool isBuiltIn(Type T) {
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
}

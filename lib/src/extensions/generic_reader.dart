import 'dart:mirrors';

import 'package:source_gen/source_gen.dart' show ConstantReader, TypeChecker;

import 'package:analyzer/dart/element/type.dart'
    show DartType, ParameterizedType;
import 'package:exception_templates/exception_templates.dart';

import '../decoders/decoders.dart';
import '../error_types/invalid_type_argument.dart';
import '../extensions/type_methods.dart';
import '../types/decoder.dart';
import '../types/unknown_type.dart';

/// Adds the following methods to `ConstantReader`:
/// `get<T>()`, `getList<T>()`, `getSet<T>()`, `getMap<K, V>()`,
/// `enumValue<T>()`, `holdsA<T>()`.
extension GenericReader on ConstantReader {
  static final _gr = _GenericReader();

  /// Adds or updates a decoder function for type `T`.
  /// * Returns `true` if the decoder function was added.
  /// * Decoders for the following types can not be added
  ///   or updated:
  ///   - `bool`, `double`, `int`, `Null`,`num`,`Symbol`,`Type`,`dynamic`,
  ///   - `List<dynamic>`, `Map<dynamic, dynamic>`, `Set<dynamic>`.
  static bool addDecoder<T>(Decoder<T> decoder) => _gr.addDecoder(decoder);

  /// Clears the decoder function for type `T`.
  /// * Note: Decoders that cannot be cleared handle the following types:
  ///   - `bool`, `double`, `int`, `Null`,`num`,`Symbol`,`Type`,`dynamic`,
  ///   - `List<dynamic>`, `Map<dynamic, dynamic>`, `Set<dynamic>`.
  static void clearDecoder<T>() => _gr.clearDecoder<T>();

  /// Returns a `Set` containing all types with registered decoders.
  static Set<Type> get registeredTypes => _gr.registeredTypes;

  /// Returns `true` if a decoder function for `dartType`
  /// is registered.
  static bool hasDecoder<T>() => _gr.hasDecoder<T>();

  /// Returns `true` if `T` is a Dart `enum`.
  ///
  /// Note: `T` must not be `dynamic`.
  static bool isEnum<T>() => _gr.isEnum<T>();

  /// Returns `true` if the instance of `ConstantReader`
  /// represents an object of type `T`.
  bool holdsA<T>() => _gr.holdsA<T>(this);

  /// Reads the instance of `ConstantReader` and returns an instance of `T`.
  ///
  /// Throws `ErrorOf<ConstantReader>` if an instance cannot be constructed.
  T get<T>() => _gr.get<T>(this);

  /// Reads the instance of `ConstantReader` and returns an instance of `T`.
  ///
  /// Note: `T` must be a Dart enum.
  T enumValue<T>() => _gr.enumValue<T>(this);

  /// Reads the instance of `ConstantReader` and
  /// returns an instance of `List<T>`.
  ///
  /// Throws `ErrorOf<ConstantReader>` if an instance of `List<T>`
  /// can not be constructed.
  List<T> getList<T>() => _gr.getList<T>(this);

  /// Reads the instance of `ConstantReader` and returns
  /// an object of type `Set<T>`.
  ///
  /// Throws `ErrorOf` if an instance of `Set<T>`
  /// cannot be constructed.
  Set<T> getSet<T>() => _gr.getSet<T>(this);

  /// Reads the instance of `ConstantReader` and returns
  /// an object of type `Map<K, V>`.
  ///
  /// Throws `ErrorOf<GenericReader` if an instance of `Map<K, V>`
  /// cannot be constructed.
  Map<K, V> getMap<K, V>() => _gr.getMap<K, V>(this);
}

/// Reader providing generic methods aimed at converting
/// instances of `DartObject` into runtime objects.
///
/// Intended use: Retrieval of compile-time constant expressions
/// during source code generation.
class _GenericReader {
  /// Private constructor.
  _GenericReader._();

  /// Singleton factory constructor.
  factory _GenericReader() => _instance ??= _GenericReader._();

  /// Private instance.
  static _GenericReader? _instance;

  /// Caches instances of `TypeChecker`.
  final Map<Type, TypeChecker> _checkers = {};

  final Map<DartType, Type> _resolvedTypes = <DartType, Type>{};

  /// Pre-registered instances of `Decoder` functions.
  final Map<Type, Decoder> _decoders = {
    bool: (constantReader) => constantReader.boolValue,
    double: (constantReader) => constantReader.doubleValue,
    int: (constantReader) => constantReader.intValue,
    Null: (constantReader) => null,
    num: numDecoder,
    String: (constantReader) => constantReader.stringValue,
    Symbol: (constantReader) => constantReader.symbolValue,
  };

  /// Adds or updates a decoder function for type `T`.
  /// Returns `true` if the decoder was added.
  ///
  /// Note: Decoders for the following types can not be added
  /// or updated.
  /// - `bool`, `double`, `int`, `Null`,`num`,`Symbol`,`Type`,
  /// - `dynamic`, `List`, `Set`, `Map`,
  /// - `UnknownType`.
  bool addDecoder<T>(Decoder<T> decoder) {
    if (isBuiltIn(T) || T == UnknownType) return false;
    // Adding Decoder function.
    _decoders[T] = decoder;
    return true;
  }

  /// Clears the decoder function for type `T`.
  ///
  /// Decoder function for the following types cannot be cleared:
  ///   - `bool`, `double`, `int`, `Null`,`num`,`Symbol`,`Type`,`dynamic`,
  ///   - `List<dynamic>`, `Map<dynamic, dynamic>`, `Set<dynamic>`.
  void clearDecoder<T>() {
    if (!isBuiltIn(T)) {
      _checkers.remove(T);
      _decoders.remove(T);
    }
  }

  /// Returns `true` if a decoder function for `type`
  /// is registered with `this`.
  bool hasDecoder<T>() {
    return _decoders.containsKey(T) ? true : false;
  }

  /// Returns a `Set` containing all types with registered decoders.
  Set<Type> get registeredTypes => _decoders.keys.toSet();

  /// Returns a `Set` containing all types previously resolved
  /// from a static type.
  Set<Type> get resolvedTypes => _resolvedTypes.values.toSet();

  /// Returns `true` if `constantReader` is a static representation
  /// of an object of type `T`.
  bool holdsA<T>(ConstantReader constantReader) {
    if (constantReader.dartType == null) {
      return false;
    } else {
      return isMatch(constantReader.dartType!, T);
    }
  }

  /// Returns `true` if `T` is a Dart `enum`.
  bool isEnum<T>() => <T>[] is List<Enum>;

  /// Returns true if `dartType` represents the type `type`.
  bool isMatch(DartType? dartType, Type type) {
    if (dartType == null) return false;
    if (resolveDartType(dartType) == type) return true;
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

  /// Returns a type `Type` that matches the static `DartType` of
  /// `constantReader`.
  ///
  /// Returns `UnknownType` if no match is found.
  Type resolveDartTypeOf(ConstantReader constantReader) {
    if (constantReader.dartType == null) {
      return UnknownType;
    } else {
      return resolveDartType(constantReader.dartType!);
    }
  }

  /// Returns a type `Type` that matches `dartType`.
  ///
  /// Returns `UnknownType` if no match is found.
  Type resolveDartType(DartType dartType) {
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

  /// Reads `constantReader` and returns an instance of `T`.
  ///
  /// Throws `ErrorOf<ConstantReader>` if an instance cannot be constructed.
  T get<T>(ConstantReader constantReader) {
    if (T == dynamic) return _getDynamic(constantReader);

    if (isEnum<T>()) return enumValue<T>(constantReader);

    if (!holdsA<T>(constantReader)) {
      throw ErrorOf<ConstantReader>(
          message: 'Input does not represent an object of type <$T>',
          invalidState: 'Input represents an object of '
              'type <${constantReader.dartType}>.');
    }
    if (!_decoders.containsKey(T)) {
      throw ErrorOf<ConstantReader>(
          message: 'Could not read value of type [$T].',
          invalidState: 'A decoder function for type [$T] is missing.',
          expectedState: 'Use addDecoder<$T>() to register a '
              'decoder function for type [$T].');
    }
    return _decoders[T]!(constantReader);
  }

  /// Reads a constant with type `dynamic`.
  ///
  /// Throws an `ErrorOf<ConstantReader>` if a constant cannot be constructed.
  dynamic _getDynamic(ConstantReader constantReader) {
    final resolvedType = resolveDartTypeOf(constantReader);
    if (resolvedType == UnknownType) {
      // Try registered types:
      final types = registeredTypes.difference(resolvedTypes);
      for (final type in types) {
        if (isMatch(constantReader.dartType, type)) {
          return _decoders[type]!(constantReader);
        }
      }
    } else if (_decoders.containsKey(resolvedType)) {
      return _decoders[resolvedType]!(constantReader);
    }
    throw ErrorOf<ConstantReader>(
        message: 'Could not read constant via get<$dynamic>().',
        expectedState: 'A registered decoder for data-type '
            '<${constantReader.dartType}>.',
        invalidState: 'Only these types are registered: '
            '${_decoders.keys.toList()}');
  }

  /// Reads `constantReader` and returns an instance of the
  /// Dart enum `T`.
  ///
  /// Throws `ErrorOfType<InvalidTypeArgument>` if `T` is `dynamic` or
  /// if `T` does not represent a Dart `enum`.
  T enumValue<T>(ConstantReader constantReader) {
    if (T == dynamic) {
      throw ErrorOfType<InvalidTypeArgument>(
          message: 'Method enumValue() does not work with type: dynamic.',
          expectedState: 'A type argument "T" in enumValue<T>() '
              'that represents a Dart enum.');
    }
    if (!isEnum<T>()) {
      throw ErrorOfType<InvalidTypeArgument>(
          message: 'Could not read constant via enumValue<$T>().',
          invalidState: '$T is not a Dart enum.');
    }

    final classMirror = reflectClass(T);
    final typeMirror = reflectType(T);
    final varMirrors = <VariableMirror>[];
    for (final item in classMirror.declarations.values) {
      if (item is VariableMirror && item.type == typeMirror) {
        varMirrors.add(item);
      }
    }
    // Access enum field 'values'.
    final values = classMirror.getField(const Symbol('values')).reflectee;
    final index = constantReader.peek('index')?.intValue;
    if (index != null) {
      // Store resolved type
      final dartType = constantReader.dartType;
      if (dartType != null) {
        _resolvedTypes[dartType] ??= T;
      }
      return values[index];
    }

    throw ErrorOf<ConstantReader>(
        message: 'Could not read enum '
            'instance of type $T.');
  }

  /// Reads `constantReader` and returns an instance of `List<T>`.
  ///
  /// Throws `ErrorOf` if an instance of `List<T>`
  /// can not be constructed.
  List<T> getList<T>(ConstantReader constantReader) {
    if (!holdsA<List<T>>(constantReader)) {
      throw ErrorOf<ConstantReader>(
          message: 'Input does not represent an object of type <List<$T>',
          invalidState: 'Input represents an object of type '
              '${constantReader.dartType}.');
    }
    if (!_decoders.containsKey(T) && T != dynamic) {
      throw ErrorOf<ConstantReader>(
          message: 'Could not read list-entry value of type [$T].',
          invalidState: 'A decoder function for type [$T] is missing.',
          expectedState: 'Use addDecoder<$T>() to register a decoder '
              'function for type [$T].');
    }
    return constantReader.listValue
        .map((item) => get<T>(ConstantReader(item)))
        .toList();
  }

  /// Reads `constantReader` and returns an object of type `Set<T>`.
  ///
  /// Throws `ErrorOf` if an instance of `Set<T>`
  /// cannot be constructed.
  Set<T> getSet<T>(ConstantReader constantReader) {
    if (!holdsA<Set<T>>(constantReader)) {
      throw ErrorOf<ConstantReader>(
          message: 'Input does not represent an object of type <Set<$T>',
          invalidState:
              'Input represents an object of type ${constantReader.dartType}.');
    }
    if (!_decoders.containsKey(T) && T != dynamic) {
      throw ErrorOf<ConstantReader>(
          message: 'Could not read set-entry value of type [$T].',
          invalidState: 'A decoder function for type [$T] is missing.',
          expectedState:
              'Use addDecoder<$T>() to register a decoder function for type [$T].');
    }
    return constantReader.setValue
        .map((item) => get<T>(ConstantReader(item)))
        .toSet();
  }

  /// Reads `constantReader` and returns an object of type `Map<K, V>`.
  ///
  /// Throws if an instance of `Map<K, V>` cannot be constructed.
  Map<K, V> getMap<K, V>(ConstantReader constantReader) {
    if (!holdsA<Map<K, V>>(constantReader)) {
      throw ErrorOf<ConstantReader>(
          message: 'Input does not represent an object of type Map<$K, $V>.',
          invalidState: 'Input represents an object of type '
              '${constantReader.dartType}.');
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
    return constantReader.mapValue.map((keyObj, valueObj) {
      final key = get<K>(ConstantReader(keyObj));
      final value = get<V>(ConstantReader(valueObj));
      return MapEntry<K, V>(key, value);
    });
  }

  /// Returns true if `T` is a built-in type.
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

  @override
  String toString() {
    return 'GenericReader:\n'
        '  Registered types: ${_decoders.keys.toSet()}\n'
        '  Mapped types    : $_resolvedTypes';
  }
}

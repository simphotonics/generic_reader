import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:generic_reader/src/errors/reader_error.dart';

/// Typedef of a function return type [T]
/// and an input argument of type [ConstantReader].
///
/// The can be used to register a decoder with the [GenericReader].
///
/// Example:
/// ```
/// class CustomType{
///  const CustomType({this.id, this.name});
///  final int id;
///  final String name;
/// }
/// ...
///
/// final reader = Reader();
/// reader.addDecoder<CustomType>((constantReader) {
///   // Extract object information
///   final id = constantReader.peek('id').intValue;
///   final name = constantReader.peek('name').stringValue;
///   // Return an instance of CustomType
///   return CustomType(id:id, name: name);
/// });
/// ```
typedef Decoder<T> = T Function(ConstantReader constantReader);

/// A sealed type that is not and cannot be registered with GenericReader.
@sealed
class TypeNotRegistered<T> {
  /// Type that is not registered with GenericReader.
  final Type unkownType = T;

  @override
  String toString() {
    return 'TypeNotRegistered: $T.';
  }
}

/// Reader providing generic methods aimed at converting static Dart analyzer
/// object representations into runtime objects.
///
/// Intended use: Retrieval of compile-time constant expressions during source code generation.
class GenericReader {
  /// Private constructor.
  GenericReader._() {
    // Register decoder for built-in data-type [num]:
    addDecoder<num>((constantReader) {
      if (isA<int>(constantReader)) return constantReader.intValue;
      if (isA<double>(constantReader)) return constantReader.doubleValue;
      return null;
    });
  }

  /// Singleton factory constructor.
  factory GenericReader() {
    return _instance ??= GenericReader._();
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
  /// Note: [List]s and [Set]s are handled by
  /// [getList<T>()] and [getSet<T>()], respectively.
  final Map<Type, Decoder> _decoders = {
    //Null: (constantReader) => null,
    bool: (constantReader) => constantReader.boolValue,
    double: (constantReader) => constantReader.doubleValue,
    int: (constantReader) => constantReader.intValue,
    String: (constantReader) => constantReader.stringValue,
    Type: (constantReader) => constantReader.typeValue,
    Symbol: (constantReader) => constantReader.symbolValue,
  };

  /// Adds or updates a decoder function for type [T].
  ///
  /// Note: Decoders for built-in types or [TypeNotRegistered]
  /// must not be added or updated.
  void addDecoder<T>(Decoder decoder) {
    if (isBuiltIn(T) || T == TypeNotRegistered || T == dynamic) return;
    // Adding TypeChecker.
    _checkers[T] ??= TypeChecker.fromRuntime(T);

    // Adding Decoder function.
    _decoders[T] = decoder;
  }

  /// Clears the decoder function for type [T] and returns it as instance
  /// of [Decoder<T>].
  ///
  /// Note: Decoders that cannot be cleared handle the following types:
  /// [bool], [double], [int], [String], [Type], [Symbol], and [TypeNotRegistered].
  Decoder<T> clearDecoder<T>() {
    if (isBuiltIn(T)) return null;
    _checkers.remove(T);
    return _decoders.remove(T);
  }

  /// Returns [true] if a decoder function for [T] is registered with [this].
  bool hasDecoder(Type T) {
    if (_decoders[T] == null) return false;
    return true;
  }

  /// Returns the decoder for type [T].
  @deprecated
  Decoder<T> decoder<T>() => _decoders[T];

  /// Returns the decoder for [type].
  @deprecated
  Decoder getDecoder(Type type) => _decoders[type];

  /// Returns all types with registered decoders as [Set<Type>].
  Set<Type> get registeredTypes => _decoders.keys.toSet();

  /// Returns true if [constantReader] represents an object of type [T].
  ///
  /// Note: Type arguments of [T] are ignored.
  ///       For example: [Colum<int>] and [Column<String>]
  ///       both resolve to [Column].
  bool isA<T>(ConstantReader constantReader) {
    if (T == Null && constantReader == null) return true;
    if (constantReader == null) return true;
    final checker = _checkers[T] ?? TypeChecker.fromRuntime(T);
    return constantReader.instanceOf(checker);
  }

  /// Returns a type [Type] that matches the static [DartType] of
  /// [constantReader].
  ///
  /// Returns [TypeNotRegistered] if no match is found
  /// among the types that are registered, i.e. have a decoder function.
  Type findType(ConstantReader constantReader) {
    for (final type in _checkers.keys) {
      if (constantReader.instanceOf(_checkers[type])) {
        return type;
      }
    }
    return TypeNotRegistered;
  }

  /// Returns true if [type] and the static type of [constantReader] have
  /// matching display Strings.
  @deprecated
  bool hasSameType(ConstantReader constantReader, Type type) {
    if (type == Null && constantReader == null) return true;
    if (constantReader == null) return false;
    return (type.toString() ==
        constantReader.objectValue.type.getDisplayString());
  }

  /// Reads [constantReader] and returns an instance of [T].
  ///
  /// Note: Return [null] if [constantReader] is null.
  ///
  /// Throws [ReaderError] if an instance cannot be constructed.
  T get<T>(ConstantReader constantReader) {
    if (constantReader == null) return null;

    if (T == dynamic) return _getDynamic(constantReader);

    if (!isA<T>(constantReader)) {
      throw ReaderError(
          message: 'Input does not represent an object of type <$T>',
          invalidState:
              'Input represents an object of type <${constantReader.objectValue.type}>.');
    }
    if (!_decoders.containsKey(T)) {
      throw ReaderError(
          message: 'Could not read value of type [$T].',
          invalidState: 'A decoder function for type [$T] is missing.',
          expectedState:
              'Use addDecoder<$T>() to register a decoder function for type [$T].');
    }
    return _decoders[T](constantReader);
  }

  /// Reads a constant from a [ConstantReader] with generic type.
  ///
  /// Throws [ReaderError] if a constant cannot be constructed.
  dynamic _getDynamic(ConstantReader constantReader) {
    if (constantReader == null) return null;

    final type = findType(constantReader);

    if (type == TypeNotRegistered) {
      throw ReaderError(
        message: 'Could not read constant via get<$dynamic>.',
        expectedState:
            'A registered decoder for data-type <${constantReader.objectValue.type}>.',
      );
    } else {
      return _decoders[type](constantReader);
    }
  }

  /// Reads [constantReader] and returns an instance of [List<T>].
  ///
  /// Throws [ReaderError] if an instance of [List<T>] can not be constructed.
  List<T> getList<T>(ConstantReader constantReader) {
    if (!isA<List>(constantReader)) {
      throw ReaderError(
          message: 'Input does not represent an object of type <List<$T>',
          invalidState:
              'Input represents an object of type <${constantReader.objectValue.type}>.');
    }
    if (!_decoders.containsKey(T)) {
      throw ReaderError(
          message: 'Could not list entry value of type [$T].',
          invalidState: 'A decoder function for type [$T] is missing.',
          expectedState:
              'Use addDecoder<$T>() to register a decoder function for type [$T].');
    }
    // Get list of DartObjects.
    final List<T> result = [];
    final list = constantReader.listValue ?? [];
    for (final item in list) {
      final entry = get<T>(ConstantReader(item));
      if (entry != null) result.add(entry);
    }
    return result;
  }

  /// Reads [constantReader] and returns an object of type [Set<T>].
  ///
  /// Throws [ReaderError] if an instance of [Set<T>] cannot be constructed.
  Set<T> getSet<T>(ConstantReader constantReader) {
    if (!isA<Set>(constantReader)) {
      throw ReaderError(
          message: 'Input does not represent an object of type <Set<$T>',
          invalidState:
              'Input represents an object of type <${constantReader.objectValue.type}>.');
    }
    if (!_decoders.containsKey(T)) {
      throw ReaderError(
          message: 'Could not list entry value of type [$T].',
          invalidState: 'A decoder function for type [$T] is missing.',
          expectedState:
              'Use addDecoder<$T>() to register a decoder function for type [$T].');
    }
    // Get list of DartObjects.
    final Set<T> result = {};
    final _set = constantReader.objectValue.toSetValue();
    for (final item in _set ?? {}) {
      final entry = get<T>(ConstantReader(item));
      if (entry != null) result.add(entry);
    }
    return result;
  }

  /// Returns true if [T] is a built-in type.
  bool isBuiltIn(Type T) {
    return (T == int ||
        T == double ||
        T == bool ||
        T == String ||
        T == Map ||
        T == List ||
        T == num ||
        T == Set ||
        T == Symbol ||
        T == Null ||
        T == Type ||
        T == num);
  }
}

import 'package:analyzer/dart/element/type.dart' show DartType;
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:generic_reader/src/errors/reader_error.dart';

/// Typedef of a parameterized function with generic
/// type parameter [T] and an input argument of type [ConstantReader].
///
/// The function returns an instance of [T] and
/// can be used to register a decoder function with the [GenericReader].
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
/// Intended use: Retrieval of complile-time constant expressions during source code generation.
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
    int: TypeChecker.fromRuntime(int),
    double: TypeChecker.fromRuntime(double),
    bool: TypeChecker.fromRuntime(bool),
    String: TypeChecker.fromRuntime(String),
    Type: TypeChecker.fromRuntime(Type),
    Symbol: TypeChecker.fromRuntime(Symbol),
    List: TypeChecker.fromRuntime(List),
    Set: TypeChecker.fromRuntime(Set),
    Map: TypeChecker.fromRuntime(Map),
  };

  /// Pre-registered instances of [Decoder] functions.
  final Map<Type, Decoder> _decoders = {
    //Null: (constantReader) => null,
    int: (constantReader) => constantReader.intValue,
    double: (constantReader) => constantReader.doubleValue,
    bool: (constantReader) => constantReader.boolValue,
    String: (constantReader) => constantReader.stringValue,
    Type: (constantReader) => constantReader.typeValue,
    Symbol: (constantReader) => constantReader.symbolValue,
  };

  /// Adds or updates a decoder function for type [T].
  ///
  /// Note: Decoders for built-in type can not be added or updated.
  void addDecoder<T>(Decoder decoder) {
    if (isBuiltIn<T>() || T == TypeNotRegistered) return;
    // Adding TypeChecker.
    _checkers[T] ??= TypeChecker.fromRuntime(T);

    // Adding Decoder function.
    _decoders[T] = decoder;
  }

  /// Clears the decoder function for type [T] and returns it.
  ///
  /// Note: Pre-registered decoders for built-in types can not be cleared.
  Decoder<T> clearDecoder<T>() {
    if (T != isBuiltIn<T>()) {
      return _decoders.remove(T);
    } else {
      return null;
    }
  }

  /// Returns the decoder for type [T].
  Decoder<T> decoder<T>() => _decoders[T];

  Decoder getDecoder(Type type) => _decoders[type];

  /// Returns all types with registered decoders as [Set<Type>].
  Set<Type> get registeredTypes => _decoders.keys.toSet();

  /// Returns true if [constantReader] represents an object of type [T].
  ///
  /// Note: Type arguments of [T] are ignored.
  ///       For example: [Colum<int>] and [Column<String>]
  ///       both resolve to [Column].
  bool isA<T>(ConstantReader constantReader) {
    _checkers[T] ??= TypeChecker.fromRuntime(T);
    if (T == Null && constantReader == null) return true;
    if (constantReader == null) return false;
    return constantReader.instanceOf(_checkers[T]);
  }

  /// Returns a type [Type] that matches the static [DartType] of
  /// [constantReader] or [TypeNotRegistered] if no match is found
  /// among the types that are registered with [this].
  Type findType(ConstantReader constantReader) {
    for (final type in _checkers.keys) {
      if (constantReader.instanceOf(_checkers[type])) {
        return type;
      }
    }
    return TypeNotRegistered;
  }

  @deprecated
  /// Returns true if [type] and the static type of [constantReader] have
  /// matching display Strings.
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

  /// Returns the [DartType] of [constantReader.objectValue].
  DartType dartType(ConstantReader constantReader) {
    return constantReader.objectValue.type;
  }

  /// Returns [List<DartType], the type arguments for parametrized types.
  /// Return an empty list if no type arguments are present.
  List<DartType> dartTypeArguments(ConstantReader constantReader) {
    return constantReader.objectValue.type.typeArguments ?? [];
  }

  /// Returns true if [T] is a built-in type.
  bool isBuiltIn<T>() {
    return (T == int ||
        T == String ||
        T == bool ||
        T == double ||
        T == Map ||
        T == List ||
        T == num ||
        T == Set ||
        T == Symbol ||
        T == Null ||
        T == num);
  }
}

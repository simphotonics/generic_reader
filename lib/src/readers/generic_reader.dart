import 'package:analyzer/dart/element/type.dart' show DartType;
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
/// class MyNewType{
///  const MyNewType({this.id, this.name});
///  final int id;
///  final String name;
/// }
/// ...
///
/// final reader = Reader();
/// reader.addDecoder<MyNewType>((constantReader) {
///   // Extract object information
///   final id = constantReader.peek('id').intValue;
///   final name = constantReader.peek('name').stringValue;
///   // Return an instance of MyNewType
///   return MyNewType(id:id, name: name);
/// });
/// ```
typedef T Decoder<T>(ConstantReader constantReader);

/// Reader providing generic methods aimed at converting static Dart analyzer
/// object representations into runtime objects.
///
/// Intended use: Retrieval of annotations and constants during source code generation.
class GenericReader {
  /// Private constructor.
  GenericReader._();

  /// Singleton factory constructor.
  factory GenericReader() {
    return _instance ??= GenericReader._();
  }

  /// Private instance.
  static GenericReader _instance;

  /// Cached instances of [TypeChecker]
  final Map<Type, TypeChecker> _checkers = {};

  /// Pre-registered instances of [Decoder] functions.
  final Map<Type, Decoder> _decoders = {
    Null: (constantReader) => null,
    int: (constantReader) => constantReader.intValue,
    double: (constantReader) => constantReader.doubleValue,
    bool: (constantReader) => constantReader.boolValue,
    String: (constantReader) => constantReader.stringValue,
  };

  /// Adds or updates a decoder function for type [T].
  void addDecoder<T>(Decoder<T> decoder) => _decoders[T] = decoder;

  /// Clears the decoder function for type [T] and returns it.
  Decoder<T> clearDecoder<T>() {
    if (T != isBuiltIn<T>()) {
      return _decoders.remove(T);
    } else {
      return null;
    }
  }

  /// Returns the decoder for type [T].
  Decoder<T> decoder<T>() => _decoders[T];

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

  /// Reads [constantReader] and returns an instance of [T].
  ///
  /// Note: Return [null] if [constantReader] is null.
  ///
  /// Throws [ReaderError] if an instance cannot be constructed.
  T get<T>(ConstantReader constantReader) {
    if (constantReader == null) return null;
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
  /// Throws [ReaderError] if an instance cannot be constructed.
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

  /// Returns true if T is a built-in type.
  bool isBuiltIn<T>() {
    return (T == int ||
        T == String ||
        T == bool ||
        T == double ||
        T == Map ||
        T == List ||
        T == Set ||
        T == Symbol ||
        T == Runes ||
        T == Null);
  }
}

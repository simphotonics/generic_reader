import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;

/// Extension adding the type methods to `ConstantReader`.
extension TypeMethods on ConstantReader {
  /// Returns `true` if `this` represents a constant expression
  /// with type `dynamic`.
  bool get isDynamic => objectValue.type is DynamicType;

  /// Returns `true` is `this` represents a constant expression with
  /// type exactly `Iterable`.
  ///
  /// Note: Returns `false` if the static type represents `List` or `Set`.
  bool get isIterable => objectValue.type?.isDartCoreIterable ?? false;

  /// Returns `true` if the static type represents a
  /// `List`, `Set`, `Map`, or `Iterable`.
  bool get isCollection => isList || isSet || isMap || isIterable;

  /// Returns `true` if the static type *and* the static type argument
  /// represent a `List`, `Set`, `Map`, or `Iterable`
  bool get isRecursiveCollection {
    if (isNotCollection) return false;
    final typeArg = dartTypeArgs[0];
    if (typeArg.isDartCoreIterable ||
        typeArg.isDartCoreList ||
        typeArg.isDartCoreSet ||
        typeArg.isDartCoreMap) {
      return true;
    } else {
      return false;
    }
  }

  /// Returns `true` if the static type does not represent
  /// `List`, `Set`, `Map`, or `Iterable`.
  bool get isNotCollection => !isList && !isSet && !isMap && !isIterable;

  /// Returns the static type of `this`.
  DartType? get dartType => objectValue.type;

  /// Returns a `List` of type arguments or an empty list.
  List<DartType> get dartTypeArgs {
    var dartType = objectValue.type;

    return dartType is ParameterizedType
        ? dartType.typeArguments
        : <DartType>[];
  }
}

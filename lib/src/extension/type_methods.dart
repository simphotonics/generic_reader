import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/type.dart'
    show DynamicType, DartType, ParameterizedType;

/// Extension adding the type methods to `ConstantReader`.
extension TypeMethods on DartObject {
  // Returns `true` if `this` represents a constant expression
  /// with type [double].
  bool get isBool => type?.isDartCoreBool ?? false;

  // Returns `true` if `this` represents a constant expression
  /// with type
  bool get isDouble => type?.isDartCoreDouble ?? false;

  /// Returns `true` if `this` represents a constant expression
  /// with type [dynamic].
  bool get isDynamic => type is DynamicType;

  // Returns `true` if `this` represents a constant expression
  /// with type [Enum].
  bool get isEnum => type?.isDartCoreEnum ?? false;

  // Returns `true` if `this` represents a constant expression
  /// with type [int].
  bool get isInt => type?.isDartCoreInt ?? false;

  /// Returns `true` is `this` represents a constant expression with
  /// type exactly [Iterable]`.
  ///
  /// Note: Returns `false` if the static type represents `List` or `Set`.
  bool get isIterable => type?.isDartCoreIterable ?? false;

  // Returns `true` if `this` represents a constant expression
  /// with type [List].
  bool get isList => type?.isDartCoreList ?? false;

  // Returns `true` if `this` represents a constant expression
  /// with type that is not [List].
  bool get isNotList => !isList;

  // Returns `true` if `this` represents a constant expression
  /// with type [Map].
  bool get isMap => type?.isDartCoreMap ?? false;

  // Returns `true` if `this` represents a constant expression
  /// with type that is not [Map].
  bool get isNotMap => !isMap;

  // Returns `true` if `this` represents a constant expression
  /// with type [Set].
  bool get isSet => type?.isDartCoreSet ?? false;

  // Returns `true` if `this` represents a constant expression
  /// with a type that is not [Set].
  bool get isNotSet => !isSet;

  // Returns `true` if `this` represents a constant expression
  /// with type [Null].
  bool get isNull => type?.isDartCoreNull ?? false;

  // Returns `true` if `this` represents a constant expression
  /// with type [num].
  bool get isNum => type?.isDartCoreNum ?? false;

  // Returns `true` if `this` represents a constant expression
  /// with type [Object].
  bool get isObject => type?.isDartCoreObject ?? false;

  // Returns `true` if `this` represents a constant expression
  /// with type [Record].
  bool get isRecord => type?.isDartCoreRecord ?? false;

  // Returns `true` if `this` represents a constant expression
  /// with type [String].
  bool get isString => type?.isDartCoreString ?? false;

  // Returns `true` if `this` represents a constant expression
  /// with type [Symbol].
  bool get isSymbol => type?.isDartCoreSymbol ?? false;

  // Returns `true` if `this` represents a constant expression
  /// with type [Type].
  bool get isType => type?.isDartCoreType ?? false;

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

  /// Returns a `List` of type arguments or an empty list.
  List<DartType> get dartTypeArgs {
    final dartType = type;
    return dartType is ParameterizedType
        ? dartType.typeArguments
        : <DartType>[];
  }
}

// ignore_for_file: type_literal_in_constant_pattern

import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/element.dart' show EnumElement;
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
  // enum.computeConstantValue()?.type?.element is EnumElement.
  bool get isEnum => type?.element is EnumElement;

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

typedef ListOfBool = List<bool>;
typedef ListOfDouble = List<double>;
typedef ListOfDynamic = List<dynamic>;
typedef ListOfInt = List<int>;
typedef ListOfNum = List<num>;
typedef ListOfString = List<String>;
typedef ListOfSymbol = List<Symbol>;
typedef ListOfType = List<Type>;

extension GenericTypeMethods on DartType {
  /// Returns a list with elements of type [DartType]
  /// containing the type arguments if
  /// `this` is a [ParameterizedType] and and empty list else.
  List<DartType> get typeArgs {
    return (this is ParameterizedType)
        ? (this as ParameterizedType).typeArguments
        : <DartType>[];
  }

  bool isCoreType<T>() => switch (T) {
    (bool) when isDartCoreBool => true,
    (double) when isDartCoreDouble => true,
    (int) when isDartCoreInt => true,
    (num) when isDartCoreNum => true,
    (String) when isDartCoreString => true,
    (Symbol) when isDartCoreSymbol => true,
    (Type) when isDartCoreType => true,
    (dynamic) when this is DynamicType => true,

    (ListOfBool)
        when isDartCoreList &&
            typeArgs.isNotEmpty &&
            typeArgs.first.isDartCoreBool =>
      true,

    (ListOfDouble)
        when isDartCoreList &&
            typeArgs.isNotEmpty &&
            typeArgs.first.isDartCoreDouble =>
      true,

    (ListOfDynamic)
        when isDartCoreList &&
            typeArgs.isNotEmpty &&
            typeArgs.first is DynamicType =>
      true,

    (ListOfInt)
        when isDartCoreList &&
            typeArgs.isNotEmpty &&
            typeArgs.first.isDartCoreInt =>
      true,

    (ListOfNum)
        when isDartCoreList &&
            typeArgs.isNotEmpty &&
            typeArgs.first.isDartCoreNum =>
      true,

    (ListOfString)
        when isDartCoreList &&
            typeArgs.isNotEmpty &&
            typeArgs.first.isDartCoreString =>
      true,

    (ListOfSymbol)
        when isDartCoreList &&
            typeArgs.isNotEmpty &&
            typeArgs.first.isDartCoreSymbol =>
      true,

    (ListOfType)
        when isDartCoreList &&
            typeArgs.isNotEmpty &&
            typeArgs.first.isDartCoreType =>
      true,

    _ => false,
  };
}

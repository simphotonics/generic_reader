import 'dart:mirrors';

import 'package:analyzer/dart/element/type.dart';
import 'package:exception_templates/exception_templates.dart';
import 'package:generic_reader/src/error_types/invalid_type_argument.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader;

/// Extension adding the method `isDynamic`
extension TypeMethods on ConstantReader {
  /// Returns `true` if `this` represents a constant expression
  /// with type `dynamic`.
  bool get isDynamic => objectValue.type.isDynamic;

  /// Returns the static type of `this`.
  DartType get type => objectValue.type;

  /// Returns a `List` of type arguments or the empty list.
  List<DartType> get typeArgs => objectValue.type.typeArguments ?? <DartType>[];

  /// Reads a instance of a Dart enumeration.
  ///
  /// Throws [ErrorOf] if a constant cannot be read.
  T enumValue<T>() {
    if (T == dynamic) {
      throw ErrorOfType<InvalidTypeArgument>(
          message: 'Method getEnum does not work with type: dynamic.',
          expectedState: 'A type argument "T" in getEnum<T> '
              'that represents a Dart enum.');
    }

    final classMirror = reflectClass(T);
    final typeMirror = reflectType(T);
    if (!classMirror.isEnum) {
      throw ErrorOfType<InvalidTypeArgument>(
          message: 'Could not read constant via enumValue<$T>().',
          invalidState: '$T is not a Dart enum.');
    }
    final varMirrors = <VariableMirror>[];
    for (final item in classMirror.declarations.values) {
      if (item is VariableMirror && item.type == typeMirror) {
        varMirrors.add(item);
      }
    }
    // Access enum field 'values'.
    final values = classMirror.getField(const Symbol('values')).reflectee;
    for (final varMirror in varMirrors) {
      final name = MirrorSystem.getName(varMirror.simpleName);
      final index = peek(name)?.intValue;
      if (index != null) {
        return values[index];
      }
    }
    throw ErrorOf<ConstantReader>(
        message: 'Could not read enum '
            'instance of type $T.');
  }
}

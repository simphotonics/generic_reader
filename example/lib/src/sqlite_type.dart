import 'package:meta/meta.dart';

/// Base class of a Sqlite compatible type.
abstract class SqliteType {
  const SqliteType._();
}

/// Private class
class _SqliteType<T> extends SqliteType{
  const _SqliteType._(this.value) : super._();
  final T value;
  Type get type => T;

  String get sourceCode => '${this.runtimeType}($value)';

  @override
  String toString() => sourceCode;

  @override
  bool operator ==(Object other) =>
      other is _SqliteType<T> && other.hashCode == hashCode;

  @override
  int get hashCode => value.hashCode;

}

/// Sqlite type representing [int].
@sealed
class Integer extends _SqliteType<int> {
  const Integer(int value) : super._(value);
}

/// Sqlite type representing [bool].
@sealed
class Boolean extends _SqliteType<bool> {
  const Boolean(bool value) : super._(value);
}

/// Sqlite type representing [String].
@sealed
class Text extends _SqliteType {
  const Text(String value) : super._(value);
  @override
  String get sourceCode => '${this.runtimeType}(\'$value\')';
}

/// Sqlite type representing [double].
@sealed
class Real extends _SqliteType {
  const Real(double value) : super._(value);
}

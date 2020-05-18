import 'package:meta/meta.dart';

abstract class SqliteType {
  const SqliteType._();
}

class _SqliteType<T> extends SqliteType{
  const _SqliteType._(this.value) : super._();
  final T value;
  Type get type => T;

  String get sourceCode => '${this.runtimeType}($value)';

  @override
  String toString() => sourceCode;
}

@sealed
class Integer extends _SqliteType<int> {
  const Integer(int value) : super._(value);
}

@sealed
class Boolean extends _SqliteType<bool> {
  const Boolean(bool value) : super._(value);
}

@sealed
class Text extends _SqliteType {
  const Text(String value) : super._(value);
  @override
  String get sourceCode => '${this.runtimeType}(\'$value\')';
}

@sealed
class Real extends _SqliteType {
  const Real(double value) : super._(value);
}

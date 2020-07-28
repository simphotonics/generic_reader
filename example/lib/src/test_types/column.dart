import 'sqlite_type.dart';

/// TEST CLASS
class Column<T extends SqliteType> {
  const Column({
    this.defaultValue,
    this.name,
  });

  /// Default value specified when defining the Sqlite column.
  final T defaultValue;

  /// Optional [name]. Has to be a valid Dart identifier.
  final String name;

  /// Returns the type argument.
  Type get type => T;

  @override
  bool operator ==(Object other) =>
      other is Column<T> && other.hashCode == hashCode;

  @override
  int get hashCode => name.hashCode ^ defaultValue.hashCode;

  /// Returns a [String] containing source code
  /// representing [this].
  @override
  String toString() {
    var b = StringBuffer();
    b.writeln('Column<$T>(');
    if (name != null) {
      b.writeln('  name: \'$name\',');
    }
    if (defaultValue != null) {
      b.writeln('  defaultValue: $defaultValue');
    }
    b.writeln(')');
    return b.toString();
  }
}

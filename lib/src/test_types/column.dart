import 'package:generic_reader/src/test_types/sqlite_type.dart';

/// Class used to define Sqlite columns.
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

  /// Returns true if the generic type [T] is one of the
  /// following types: [Integer],[Boolean],[Real], or [Text].
  bool get isValid => (T == Integer || T == Boolean || T == Real || T == Text);

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

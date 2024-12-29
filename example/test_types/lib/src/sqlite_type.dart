// ignore_for_file: constant_identifier_names
enum SqliteType<T> {
  INTEGER<int>('INTEGER'),
  BOOL<bool>('INTEGER'),
  REAL<double>('REAL'),
  TEXT<String>('TEXT');

  const SqliteType(this.keyword);

  final String keyword;

  /// Dart type associated with the Sqlite type.
  Type get type => T;
}

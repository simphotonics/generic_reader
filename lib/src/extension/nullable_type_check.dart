extension NullableTypeCheck on Object? {
  /// Returns `true` if the object is null, and `false` otherwise.
  bool get isNull => this == null ? true : false;

  /// Returns `true` if the object is not null, and `false` otherwise.
  bool get isNotNull => this == null ? false : true;
}

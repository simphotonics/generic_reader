/// Returns `true` if the derived type [D] is a subtype of base type [B],
/// and `false` otherwise.
bool isSubType<D, B>() => Iterable<D>.empty() is Iterable<B>;

/// Returns `true` if [T] is exactly the same type as [S], and `false` otherwise.
bool isExactly<T, S>() => isSubType<T, S>() && isSubType<S, T>();

/// Returns `true` if [T] is nullable and `false` otherwise.
bool isNullable<T>() {
  return Iterable<T>.empty is Iterable<T?>;
}

/// Returns `true` if `T` is a Dart `enum`.
///
/// Note: `T` must not be `dynamic`.
bool isEnum<T>() => isSubType<Enum, T>();

/// Returns the [Type] representing [T]. Useful to get a instance [Type]
///  representing a parameterized type.
Type getType<T>() => T;

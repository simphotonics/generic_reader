/// Wraps a variable of type [T].
class Wrapper<T> {
  const Wrapper(this.value);

  /// Value of type [T].
  final T value;

  @override
  String toString() => 'Wrapper<$T>(value: $value)';
}

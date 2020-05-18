class Wrapper<T> {
  const Wrapper(this.value);
  final T value;

  @override
  String toString() => 'Wrapper<$T>(value: $value)';
}

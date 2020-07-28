import 'package:meta/meta.dart';

/// A sealed type that is not and cannot be registered with GenericReader.
@sealed
class NotRegisteredType<T> {
  /// Type that is not registered with GenericReader.
  final Type unkownType = T;

  @override
  String toString() {
    return 'TypeNotRegistered: $T.';
  }
}

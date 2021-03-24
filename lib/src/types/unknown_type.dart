import 'package:meta/meta.dart';

/// A sealed type that is not and cannot be registered with GenericReader.
@sealed
class UnknownType {
  const UnknownType();

  @override
  String toString() {
    return 'UnKnownType';
  }
}

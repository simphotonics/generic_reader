import 'package:example/src/sqlite_type.dart';
import 'package:example/src/wrapper.dart';

/// User to the [Wrapper].
class WrapperTest {
  const WrapperTest();
  final wrapper = const Wrapper<Text>(Text('I am of type [Text])'));
}
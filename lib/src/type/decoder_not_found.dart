import 'package:exception_templates/exception_templates.dart';

/// This type of error is thrown if an attempt at reading a `DartObject`
/// failed because a suitable `Decoder` is not registered with `GenericReader`.
abstract class DecoderNotFound extends ErrorType {}

/// Error thrown when a wrong generic type argument is found.
class GenericTypeError extends TypeError {
  GenericTypeError({
    this.message,
    this.invalidType,
    this.expectedType,
  });

  /// Message added when the error is thrown.
  final Object message;
  final Object invalidType;
  final Object expectedType;

  @override
  String toString() {
    final expected = (expectedType == null)
        ? ' Expected: ' + Error.safeToString(expectedType)
        : '';
    final found = (invalidType == null)
        ? 'Found: ' + Error.safeToString(invalidType)
        : '';
    return 'GenericTypeError: ' +
        Error.safeToString(message) +
        expected +
        found +
        super.stackTrace.toString();
  }
}

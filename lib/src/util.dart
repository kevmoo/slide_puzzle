

void requireArgument(bool truth, String argName, [String message]) {
  if (!truth) {
    if (message == null || message.isEmpty) {
      message = 'value was invalid';
    }
    throw ArgumentError('`$argName` - $message');
  }
}

void requireArgumentNotNull(argument, String argName) {
  if (argument == null) {
    throw ArgumentError.notNull(argName);
  }
}

/// Runs [write], one change to a list the caller owns (legacy `listItems:`).
///
/// A list that cannot change (`const`, `List.unmodifiable`, freezed) is left
/// as is, as in 7.x: the caller updates it from its own state. Only
/// [UnsupportedError] is swallowed; any other error still surfaces.
void writeShared(void Function() write) {
  try {
    write();
    // An unmodifiable list reports itself only by throwing this error.
    // ignore: avoid_catching_errors
  } on UnsupportedError {
    // Unmodifiable caller list: the caller owns it.
  }
}

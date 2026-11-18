import 'dart:convert';

/// Accumulates stream text chunks while enforcing maximum byte boundaries.
class StreamBoundedBuffer {
  StreamBoundedBuffer({required this.maxBytes});

  final int maxBytes;
  final StringBuffer _buffer = StringBuffer();
  int _currentByteLength = 0;
  bool _isExceeded = false;

  bool get isExceeded => _isExceeded;
  int get currentByteLength => _currentByteLength;

  /// Appends [chunk]. Returns whether new data was appended.
  bool append(String chunk) {
    if (_isExceeded) return false;

    final chunkBytes = utf8.encode(chunk).length;
    if (_currentByteLength + chunkBytes > maxBytes) {
      final allowedBytes = maxBytes - _currentByteLength;
      if (allowedBytes > 0) {
        // Truncate to remaining budget safely
        final encoded = utf8.encode(chunk);
        final sublist = encoded.sublist(0, allowedBytes);
        _buffer.write(utf8.decode(sublist, allowMalformed: true));
        _buffer.write('\n... [Output truncated: exceeded $maxBytes bytes limit]');
      } else {
        _buffer.write('\n... [Output truncated: exceeded $maxBytes bytes limit]');
      }
      _currentByteLength = maxBytes;
      _isExceeded = true;
      return false;
    }

    _buffer.write(chunk);
    _currentByteLength += chunkBytes;
    return true;
  }

  @override
  String toString() => _buffer.toString();
}

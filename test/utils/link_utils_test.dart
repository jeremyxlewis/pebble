import 'package:flutter_test/flutter_test.dart';
import 'package:pebble_board/utils/link_utils.dart';

void main() {
  group('LinkUtils', () {
    test('sanitizeUrl should remove tracking parameters', () {
      const url = 'https://example.com?utm_source=test&utm_medium=email&fbclid=123';
      const expected = 'https://example.com';
      expect(LinkUtils.sanitizeUrl(url), expected);
    });

    test('sanitizeUrl should handle URLs without tracking', () {
      const url = 'https://example.com/path?param=value';
      expect(LinkUtils.sanitizeUrl(url), url);
    });

    test('sanitizeUrl should handle URLs with only tracking params', () {
      const url = 'https://example.com?utm_source=test';
      const expected = 'https://example.com';
      expect(LinkUtils.sanitizeUrl(url), expected);
    });

    test('sanitizeUrl should preserve important params', () {
      const url = 'https://example.com?important=1&utm_source=test';
      const expected = 'https://example.com?important=1';
      expect(LinkUtils.sanitizeUrl(url), expected);
    });

    test('sanitizeUrl should handle malformed URLs gracefully', () {
      const url = 'not-a-url';
      expect(LinkUtils.sanitizeUrl(url), url);
    });
  });
}
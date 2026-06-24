import 'package:chezmoi/core/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidRedirect', () {
    test('accepts local paths', () {
      expect(isValidRedirect('/dashboard'), isTrue);
      expect(isValidRedirect('/loading-dashboard'), isTrue);
    });

    test('rejects invalid paths', () {
      expect(isValidRedirect(null), isFalse);
      expect(isValidRedirect(''), isFalse);
      expect(isValidRedirect('//evil.com'), isFalse);
      expect(isValidRedirect('https://evil.com'), isFalse);
      expect(isValidRedirect('/login'), isFalse);
      expect(isValidRedirect('/signup'), isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ironcoach/core/error/failures.dart';

void main() {
  group('Failure.displayMessage', () {
    test('falls back to a friendly default when no message is provided', () {
      const failure = Failure.network();
      expect(failure.displayMessage, contains('internet'));
    });

    test('surfaces a provided message verbatim for validation failures', () {
      const failure = Failure.validation('Email is invalid');
      expect(failure.displayMessage, 'Email is invalid');
    });

    test('unauthorized failures default to a session-expired message', () {
      const failure = Failure.unauthorized();
      expect(failure.displayMessage, contains('session'));
    });

    test('server failures preserve the given message', () {
      const failure = Failure.server(message: 'Row not found', statusCode: 404);
      expect(failure.displayMessage, 'Row not found');
    });
  });
}

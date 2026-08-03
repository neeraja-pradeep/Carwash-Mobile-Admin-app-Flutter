import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_flutter_project/core/monitoring/sentry_config.dart';

/// The DSN is the one setting that silently breaks reporting when it is wrong —
/// a typo just means events stop arriving, with nothing failing loudly. These
/// pin the resolution order down.
void main() {
  tearDown(dotenv.clean);

  group('SentryConfig.dsn', () {
    // Declared first on purpose: `dotenv.clean()` empties the map but leaves
    // the initialised flag set, so this is the only point in the file where the
    // never-loaded state — what bootstrap hits when `.env` is missing, and
    // where reading `dotenv.env` would throw — can still be observed.
    test('resolves when .env never loaded at all', () {
      expect(dotenv.isInitialized, isFalse);
      expect(SentryConfig.dsn, isNotEmpty);
    });

    test('falls back to the project DSN when .env has no override', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://example.test');

      expect(
        SentryConfig.dsn,
        'https://fe79ad5742956e58792b1782dba7a089@o4510509677608960.ingest.us.sentry.io/4511847144751104',
      );
      expect(SentryConfig.isEnabled, isTrue);
    });

    test('a SENTRY_DSN entry in .env wins over the compiled-in default', () {
      dotenv.testLoad(
          fileInput: 'SENTRY_DSN=https://abc@o1.ingest.us.sentry.io/2');

      expect(SentryConfig.dsn, 'https://abc@o1.ingest.us.sentry.io/2');
    });

    test('a blank SENTRY_DSN opts the machine out of reporting', () {
      dotenv.testLoad(fileInput: 'SENTRY_DSN=');

      expect(SentryConfig.dsn, isEmpty);
      expect(SentryConfig.isEnabled, isFalse);
    });
  });

  test('environment tags non-release builds as debug', () {
    expect(SentryConfig.environment, 'debug');
  });
}

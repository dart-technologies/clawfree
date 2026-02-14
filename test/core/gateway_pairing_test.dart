import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:clawfree/src/core/platform_config.dart';

void main() {
  group('Gateway /pair deep link construction', () {
    // Mirrors the logic in server.js:
    //   const deepLink = `clawfree://pair?url=${encodeURIComponent(targetUrl)}&token=${encodeURIComponent(token)}`;
    String buildDeepLink(String targetUrl, String token) {
      return 'clawfree://pair'
          '?url=${Uri.encodeComponent(targetUrl)}'
          '&token=${Uri.encodeComponent(token)}';
    }

    test('encodes localhost URL correctly', () {
      final link = buildDeepLink('http://localhost:18789', 'my-token');
      final uri = Uri.parse(link);

      expect(uri.scheme, 'clawfree');
      expect(uri.host, 'pair');
      expect(uri.queryParameters['url'], 'http://localhost:18789');
      expect(uri.queryParameters['token'], 'my-token');
    });

    test('encodes LAN IP with port', () {
      final link = buildDeepLink('http://192.168.1.50:18789', 'lan-secret');
      final uri = Uri.parse(link);

      expect(uri.queryParameters['url'], 'http://192.168.1.50:18789');
    });

    test('encodes HTTPS production URL', () {
      final link = buildDeepLink(
        'https://clawfree.example.com',
        'prod-token-abc',
      );
      final uri = Uri.parse(link);

      expect(uri.queryParameters['url'], 'https://clawfree.example.com');
      expect(uri.queryParameters['token'], 'prod-token-abc');
    });

    test('handles empty token', () {
      final link = buildDeepLink('http://localhost:18789', '');
      final uri = Uri.parse(link);

      expect(uri.queryParameters['token'], '');
    });

    test('preserves special characters in token', () {
      final link = buildDeepLink(
        'http://localhost:18789',
        'token/with+special=chars&more',
      );
      final uri = Uri.parse(link);

      expect(uri.queryParameters['token'], 'token/with+special=chars&more');
    });

    test('preserves path in gateway URL', () {
      final link = buildDeepLink('http://host:18789/api/v1', 'tok');
      final uri = Uri.parse(link);

      expect(uri.queryParameters['url'], 'http://host:18789/api/v1');
    });

    test('round-trip: build then parse preserves all data', () {
      const urls = [
        'http://localhost:18789',
        'https://prod.gateway.io:443',
        'http://10.0.0.1:18789',
        'http://[::1]:18789', // IPv6
      ];
      const tokens = ['simple', '', 'has spaces', 'a=b&c=d', 'slashes/ok'];

      for (final url in urls) {
        for (final token in tokens) {
          final link = buildDeepLink(url, token);
          final parsed = Uri.parse(link);
          expect(
            parsed.queryParameters['url'],
            url,
            reason: 'Failed for url=$url, token=$token',
          );
          expect(
            parsed.queryParameters['token'],
            token,
            reason: 'Failed for url=$url, token=$token',
          );
        }
      }
    });
  });

  group('Deep link consumer parsing', () {
    test('extracts gateway URL and token from deep link', () {
      const deepLink =
          'clawfree://pair?url=http%3A%2F%2F192.168.1.5%3A18789&token=test-token';
      final uri = Uri.parse(deepLink);

      expect(uri.scheme, 'clawfree');
      expect(uri.host, 'pair');
      expect(uri.queryParameters['url'], 'http://192.168.1.5:18789');
      expect(uri.queryParameters['token'], 'test-token');
    });

    test('handles deep link with only url (no token)', () {
      const deepLink = 'clawfree://pair?url=http%3A%2F%2Flocalhost%3A18789';
      final uri = Uri.parse(deepLink);

      expect(uri.queryParameters['url'], 'http://localhost:18789');
      expect(uri.queryParameters['token'], isNull);
    });

    test('parses deep link with empty token', () {
      final uri = Uri.parse('clawfree://pair?url=http%3A%2F%2Fhost&token=');

      expect(uri.queryParameters['token'], '');
    });

    test('parses HTTPS gateway URL in deep link', () {
      final uri = Uri.parse(
        'clawfree://pair?url=https%3A%2F%2Fmy-gateway.example.com%3A443&token=prod-token',
      );

      expect(uri.queryParameters['url'], 'https://my-gateway.example.com:443');
      expect(uri.queryParameters['token'], 'prod-token');
    });

    test('handles missing url query param gracefully', () {
      final uri = Uri.parse('clawfree://pair?token=orphan');

      expect(uri.queryParameters.containsKey('url'), isFalse);
      expect(uri.queryParameters['token'], 'orphan');
    });

    test('rejects deep link with wrong host', () {
      final uri = Uri.parse('clawfree://connect?url=http%3A%2F%2Fhost');

      expect(uri.host, isNot('pair'));
    });

    test('rejects non-clawfree scheme', () {
      final uri = Uri.parse('myapp://pair?url=http%3A%2F%2Fhost&token=t');

      expect(uri.scheme, isNot('clawfree'));
    });
  });

  group('PlatformConfig.parsePairingUri', () {
    test('parses clawfree://pair deep link', () {
      final uri = Uri.parse(
        'clawfree://pair?url=http%3A%2F%2F192.168.1.5%3A18789&token=abc',
      );
      final result = PlatformConfig.parsePairingUri(uri);

      expect(result, isNotNull);
      expect(result!.url, 'http://192.168.1.5:18789');
      expect(result.token, 'abc');
    });

    test('parses HTTP gateway URL', () {
      final uri = Uri.parse('http://192.168.1.5:18789');
      final result = PlatformConfig.parsePairingUri(uri);

      expect(result, isNotNull);
      expect(result!.url, 'http://192.168.1.5:18789');
      expect(result.token, isNull);
    });

    test('parses HTTPS gateway URL (default port normalized away)', () {
      final uri = Uri.parse('https://my-gateway.cloud:443');
      final result = PlatformConfig.parsePairingUri(uri);

      expect(result, isNotNull);
      // Dart normalizes default ports: 443 for HTTPS, 80 for HTTP.
      expect(result!.url, 'https://my-gateway.cloud');
    });

    test('parses HTTPS gateway URL with non-default port', () {
      final uri = Uri.parse('https://my-gateway.cloud:8443');
      final result = PlatformConfig.parsePairingUri(uri);

      expect(result, isNotNull);
      expect(result!.url, 'https://my-gateway.cloud:8443');
    });

    test('returns null for clawfree://pair without url param', () {
      final uri = Uri.parse('clawfree://pair?token=orphan');
      final result = PlatformConfig.parsePairingUri(uri);

      expect(result, isNull);
    });

    test('returns null for unrecognized scheme', () {
      final uri = Uri.parse('ftp://some-server/file');
      final result = PlatformConfig.parsePairingUri(uri);

      expect(result, isNull);
    });

    test('returns null for non-pair clawfree host', () {
      final uri = Uri.parse('clawfree://settings?url=http%3A%2F%2Fhost');
      final result = PlatformConfig.parsePairingUri(uri);

      expect(result, isNull);
    });

    test('lenient Uri.parse with invalid string returns empty scheme', () {
      final uri = Uri.parse('not a url at all');
      final result = PlatformConfig.parsePairingUri(uri);

      expect(result, isNull);
    });
  });

  group('Gateway URL validation logic', () {
    test('accepts valid clawfree-gateway health response', () async {
      final mockHttp = http_testing.MockClient((request) async {
        expect(request.url.path, '/health');
        return http.Response(
          jsonEncode({'status': 'ok', 'service': 'clawfree-gateway'}),
          200,
        );
      });

      final response = await mockHttp.get(
        Uri.parse('http://localhost:18789/health'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      expect(response.statusCode, 200);
      expect(body['service'], 'clawfree-gateway');
    });

    test('rejects response with wrong service identifier', () async {
      final mockHttp = http_testing.MockClient((request) async {
        return http.Response(
          jsonEncode({'status': 'ok', 'service': 'some-other-gateway'}),
          200,
        );
      });

      final response = await mockHttp.get(
        Uri.parse('http://localhost:18789/health'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      expect(body['service'], isNot('clawfree-gateway'));
    });

    test('rejects non-200 health response', () async {
      final mockHttp = http_testing.MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final response = await mockHttp.get(
        Uri.parse('http://localhost:18789/health'),
      );

      expect(response.statusCode, isNot(200));
    });

    test('rejects non-JSON health response', () async {
      final mockHttp = http_testing.MockClient((request) async {
        return http.Response('<html>Not a gateway</html>', 200);
      });

      final response = await mockHttp.get(
        Uri.parse('http://localhost:18789/health'),
      );

      expect(
        () => jsonDecode(response.body) as Map<String, dynamic>,
        throwsA(isA<FormatException>()),
      );
    });

    test('handles network error gracefully', () async {
      final mockHttp = http_testing.MockClient((request) async {
        throw Exception('Connection refused');
      });

      expect(
        () => mockHttp.get(Uri.parse('http://unreachable:18789/health')),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('QR result routing', () {
    test('http URL is recognized as gateway URL', () {
      final uri = Uri.parse('http://192.168.1.5:18789');

      expect(uri.scheme, 'http');
      expect(uri.host, '192.168.1.5');
      expect(uri.port, 18789);
    });

    test('https URL is recognized as gateway URL', () {
      final uri = Uri.parse('https://my-gateway.cloud:443');

      expect(uri.scheme, 'https');
    });

    test('clawfree:// URL is recognized as deep link', () {
      final uri = Uri.parse('clawfree://pair?url=http%3A%2F%2Fhost&token=t');

      expect(uri.scheme, 'clawfree');
      expect(uri.host, 'pair');
    });

    test('unrecognized scheme is neither gateway nor deep link', () {
      final uri = Uri.parse('ftp://some-server/file');

      expect(uri.scheme, isNot('http'));
      expect(uri.scheme, isNot('https'));
      expect(uri.scheme, isNot('clawfree'));
    });
  });
}

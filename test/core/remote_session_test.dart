import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:clawfree/src/core/platform_config.dart';
import 'package:clawfree/src/core/remote_session.dart';

void main() {
  group('RemoteSession.fromJson', () {
    test('parses all fields', () {
      final session = RemoteSession.fromJson({
        'session_id': 'abc-123',
        'device_type': 'tablet',
        'device_name': "Mike's iPad",
        'connected_at': '2026-02-12T14:30:00Z',
      });

      expect(session.sessionId, 'abc-123');
      expect(session.deviceType, DeviceFormFactor.tablet);
      expect(session.deviceName, "Mike's iPad");
      expect(session.connectedAt, DateTime.utc(2026, 2, 12, 14, 30));
    });

    test('handles missing fields gracefully', () {
      final session = RemoteSession.fromJson({});

      expect(session.sessionId, '');
      expect(session.deviceType, DeviceFormFactor.phone);
      expect(session.deviceName, 'Unknown');
      expect(session.connectedAt, isNull);
    });

    test('parses all device types', () {
      expect(
        RemoteSession.fromJson({'device_type': 'desktop'}).deviceType,
        DeviceFormFactor.desktop,
      );
      expect(
        RemoteSession.fromJson({'device_type': 'tablet'}).deviceType,
        DeviceFormFactor.tablet,
      );
      expect(
        RemoteSession.fromJson({'device_type': 'phone'}).deviceType,
        DeviceFormFactor.phone,
      );
      expect(
        RemoteSession.fromJson({'device_type': 'watch'}).deviceType,
        DeviceFormFactor.watch,
      );
    });

    test('unknown device_type defaults to phone', () {
      final session = RemoteSession.fromJson({'device_type': 'fridge'});
      expect(session.deviceType, DeviceFormFactor.phone);
    });

    test('invalid connected_at results in null', () {
      final session = RemoteSession.fromJson({'connected_at': 'not-a-date'});
      expect(session.connectedAt, isNull);
    });
  });

  group('defaultDemoSessions', () {
    test('returns all 5 demo devices regardless of self', () {
      final sessions = defaultDemoSessions(DeviceFormFactor.phone);
      expect(sessions.length, 5);
      expect(
        sessions.any((s) => s.deviceType == DeviceFormFactor.phone),
        isTrue,
      );
      expect(
        sessions.any((s) => s.deviceType == DeviceFormFactor.desktop),
        isTrue,
      );
      expect(
        sessions.any((s) => s.deviceType == DeviceFormFactor.tablet),
        isTrue,
      );
      expect(
        sessions.any((s) => s.deviceType == DeviceFormFactor.watch),
        isTrue,
      );
    });

    test('Mac is first, iPad is second', () {
      final sessions = defaultDemoSessions(DeviceFormFactor.tablet);
      expect(sessions.length, 5);
      expect(sessions[0].deviceName, 'Mac');
      expect(sessions[1].deviceName, 'iPad');
    });

    test('includes all device types for desktop self', () {
      final sessions = defaultDemoSessions(DeviceFormFactor.desktop);
      expect(sessions.length, 5);
      expect(
        sessions.any((s) => s.deviceType == DeviceFormFactor.desktop),
        isTrue,
      );
    });

    test('includes all device types for watch self', () {
      final sessions = defaultDemoSessions(DeviceFormFactor.watch);
      expect(sessions.length, 5);
      expect(
        sessions.any((s) => s.deviceType == DeviceFormFactor.watch),
        isTrue,
      );
    });
  });

  group('iconForDeviceType', () {
    test('returns correct icon for desktop', () {
      expect(iconForDeviceType(DeviceFormFactor.desktop), Symbols.desktop_mac);
    });

    test('returns correct icon for tablet', () {
      expect(iconForDeviceType(DeviceFormFactor.tablet), Symbols.tablet_mac);
    });

    test('returns correct icon for phone', () {
      expect(iconForDeviceType(DeviceFormFactor.phone), Symbols.phone_iphone);
    });

    test('returns correct icon for watch', () {
      expect(iconForDeviceType(DeviceFormFactor.watch), Symbols.watch);
    });
  });
}

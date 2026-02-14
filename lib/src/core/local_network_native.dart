import 'dart:io';

/// Returns the first non-loopback IPv4 address on the local network.
Future<String> getLocalIpAddress() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
  } catch (_) {
    // NetworkInterface unavailable (e.g. sandbox restrictions).
  }
  return 'localhost';
}

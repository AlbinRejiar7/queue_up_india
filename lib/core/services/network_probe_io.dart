import 'dart:io';

import 'network_probe_result.dart';

Future<NetworkProbeResult> probeInternetConnection() async {
  final stopwatch = Stopwatch()..start();
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);

  try {
    final request = await client
        .getUrl(Uri.parse('https://www.gstatic.com/generate_204'))
        .timeout(const Duration(seconds: 4));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');

    final response = await request.close().timeout(const Duration(seconds: 4));
    await response.drain<void>();
    stopwatch.stop();

    return NetworkProbeResult(
      hasInternet: response.statusCode >= 200 && response.statusCode < 500,
      latency: stopwatch.elapsed,
    );
  } catch (_) {
    stopwatch.stop();
    return NetworkProbeResult(hasInternet: false, latency: stopwatch.elapsed);
  } finally {
    client.close(force: true);
  }
}

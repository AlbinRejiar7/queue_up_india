import 'network_probe_result.dart';

Future<NetworkProbeResult> probeInternetConnection() async {
  return const NetworkProbeResult(hasInternet: true, latency: Duration.zero);
}

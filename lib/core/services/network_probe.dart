import 'network_probe_result.dart';
import 'network_probe_stub.dart'
    if (dart.library.io) 'network_probe_io.dart'
    as probe;

Future<NetworkProbeResult> probeInternetConnection() {
  return probe.probeInternetConnection();
}

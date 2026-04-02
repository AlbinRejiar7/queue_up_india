class NetworkProbeResult {
  const NetworkProbeResult({required this.hasInternet, required this.latency});

  final bool hasInternet;
  final Duration latency;
}

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/network_probe.dart';

enum NetworkStatusType { unknown, online, slow, offline }

class NetworkStatusState extends Equatable {
  const NetworkStatusState({
    this.status = NetworkStatusType.unknown,
    this.latency = Duration.zero,
  });

  final NetworkStatusType status;
  final Duration latency;

  bool get showBanner =>
      status == NetworkStatusType.slow || status == NetworkStatusType.offline;

  NetworkStatusState copyWith({NetworkStatusType? status, Duration? latency}) {
    return NetworkStatusState(
      status: status ?? this.status,
      latency: latency ?? this.latency,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, latency];
}

class NetworkStatusCubit extends Cubit<NetworkStatusState> {
  NetworkStatusCubit({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity(),
      super(const NetworkStatusState()) {
    _startMonitoring();
  }

  static const Duration _refreshInterval = Duration(seconds: 20);
  static const Duration _slowThreshold = Duration(milliseconds: 1600);

  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  void _startMonitoring() {
    unawaited(_refreshStatus());
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChanged,
    );
    _refreshTimer = Timer.periodic(
      _refreshInterval,
      (_) => unawaited(_refreshStatus()),
    );
  }

  Future<void> _refreshStatus({
    List<ConnectivityResult>? connectivityResults,
  }) async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    try {
      final results =
          connectivityResults ?? await _connectivity.checkConnectivity();
      if (!_hasUsableTransport(results)) {
        emit(const NetworkStatusState(status: NetworkStatusType.offline));
        return;
      }

      final probeResult = await probeInternetConnection();
      final nextStatus = !probeResult.hasInternet
          ? NetworkStatusType.offline
          : probeResult.latency >= _slowThreshold
          ? NetworkStatusType.slow
          : NetworkStatusType.online;

      emit(
        NetworkStatusState(status: nextStatus, latency: probeResult.latency),
      );
    } finally {
      _isRefreshing = false;
    }
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    if (!_hasUsableTransport(results)) {
      emit(const NetworkStatusState(status: NetworkStatusType.offline));
      return;
    }

    unawaited(_refreshStatus(connectivityResults: results));
  }

  bool _hasUsableTransport(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    _refreshTimer?.cancel();
    return super.close();
  }
}

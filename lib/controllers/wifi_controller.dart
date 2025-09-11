import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:async';

class WifiController extends ChangeNotifier {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  String _wifiName = 'Desconhecido';
  String _wifiIP = 'Não disponível';
  String _wifiBSSID = 'Não disponível';
  String _wifiGateway = 'Não disponível';
  String _wifiSubnet = 'Não disponível';
  int _signalStrength = 0;
  String _securityType = 'Desconhecido';
  bool _isChecking = false;

  final NetworkInfo _networkInfo = NetworkInfo();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Getters
  ConnectivityResult get connectionStatus => _connectionStatus;
  String get wifiName => _wifiName;
  String get wifiIP => _wifiIP;
  String get wifiBSSID => _wifiBSSID;
  String get wifiGateway => _wifiGateway;
  String get wifiSubnet => _wifiSubnet;
  int get signalStrength => _signalStrength;
  String get securityType => _securityType;
  bool get isChecking => _isChecking;

  void initialize() {
    checkConnectivity();
    _listenToConnectivityChanges();
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      _connectionStatus = result;
      notifyListeners();
      _updateWifiInfo();
    });
  }

  Future<void> checkConnectivity() async {
    _isChecking = true;
    notifyListeners();

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _connectionStatus = connectivityResult;
      await _updateWifiInfo();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao verificar conectividade: $e');
      }
    }

    _isChecking = false;
    notifyListeners();
  }

  Future<void> _updateWifiInfo() async {
    if (_connectionStatus == ConnectivityResult.wifi) {
      try {
        // Obter informações detalhadas do WiFi
        final wifiName = await _networkInfo.getWifiName();
        final wifiIP = await _networkInfo.getWifiIP();
        final wifiBSSID = await _networkInfo.getWifiBSSID();
        final wifiGateway = await _networkInfo.getWifiGatewayIP();
        final wifiSubnet = await _networkInfo.getWifiSubmask();

        _wifiName = wifiName?.replaceAll('"', '') ?? 'Nome não disponível';
        _wifiIP = wifiIP ?? 'IP não disponível';
        _wifiBSSID = wifiBSSID ?? 'BSSID não disponível';
        _wifiGateway = wifiGateway ?? 'Gateway não disponível';
        _wifiSubnet = wifiSubnet ?? 'Subnet não disponível';

        // Simular força do sinal (em um app real, seria obtido via plugin nativo)
        _signalStrength = -45 + (DateTime.now().millisecond % 30);
        _securityType = _determineSecurityType(_wifiName);
      } catch (e) {
        _wifiName = 'Erro ao obter informações';
        _wifiIP = 'Não disponível';
        _wifiBSSID = 'Não disponível';
        _wifiGateway = 'Não disponível';
        _wifiSubnet = 'Não disponível';
        _signalStrength = 0;
        _securityType = 'Desconhecido';
      }
    } else {
      _wifiName = 'Não conectado ao WiFi';
      _wifiIP = 'Não disponível';
      _wifiBSSID = 'Não disponível';
      _wifiGateway = 'Não disponível';
      _wifiSubnet = 'Não disponível';
      _signalStrength = 0;
      _securityType = 'Desconhecido';
    }
    notifyListeners();
  }

  String _determineSecurityType(String wifiName) {
    // Simulação básica de tipo de segurança baseada no nome
    if (wifiName.toLowerCase().contains('open') ||
        wifiName.toLowerCase().contains('free')) {
      return 'Aberta (Insegura)';
    } else if (wifiName.toLowerCase().contains('wpa3')) {
      return 'WPA3 (Muito Segura)';
    } else if (wifiName.toLowerCase().contains('wpa2')) {
      return 'WPA2 (Segura)';
    } else {
      return 'WPA/WPA2 (Segura)';
    }
  }

  String getConnectionStatusText() {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
        return 'Conectado via WiFi';
      case ConnectivityResult.mobile:
        return 'Conectado via Dados Móveis';
      case ConnectivityResult.ethernet:
        return 'Conectado via Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Conectado via Bluetooth';
      case ConnectivityResult.none:
        return 'Sem conexão';
      default:
        return 'Status desconhecido';
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

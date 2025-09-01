import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class WifiPage extends StatefulWidget {
  const WifiPage({super.key});

  @override
  State<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  String _wifiName = 'Desconhecido';
  String _wifiIP = 'Não disponível';
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _listenToConnectivityChanges();
  }

  void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _connectionStatus = result;
      });
      _updateWifiInfo();
    });
  }

  Future<void> _checkConnectivity() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      setState(() {
        _connectionStatus = connectivityResult;
      });
      await _updateWifiInfo();
    } catch (e) {
      print('Erro ao verificar conectividade: $e');
    }

    setState(() {
      _isChecking = false;
    });
  }

  Future<void> _updateWifiInfo() async {
    if (_connectionStatus == ConnectivityResult.wifi) {
      try {
        // Note: Para obter informações detalhadas do WiFi, seria necessário
        // usar plugins específicos da plataforma ou network_info_plus
        setState(() {
          _wifiName = 'Rede WiFi Conectada';
          _wifiIP = 'IP disponível via network_info_plus';
        });
      } catch (e) {
        setState(() {
          _wifiName = 'Erro ao obter informações';
          _wifiIP = 'Não disponível';
        });
      }
    } else {
      setState(() {
        _wifiName = 'Não conectado ao WiFi';
        _wifiIP = 'Não disponível';
      });
    }
  }

  String _getConnectionStatusText() {
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

  Color _getStatusColor() {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        return Colors.green;
      case ConnectivityResult.bluetooth:
        return Colors.blue;
      case ConnectivityResult.none:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon() {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_4_bar;
      case ConnectivityResult.ethernet:
        return Icons.settings_ethernet;
      case ConnectivityResult.bluetooth:
        return Icons.bluetooth;
      case ConnectivityResult.none:
        return Icons.signal_wifi_off;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi / Conectividade'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status da Conexão',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getConnectionStatusText(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(),
                                ),
                              ),
                              if (_connectionStatus ==
                                  ConnectivityResult.wifi) ...[
                                const SizedBox(height: 4),
                                Text(_wifiName),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isChecking ? null : _checkConnectivity,
                        icon: _isChecking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: const Text('Atualizar Status'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações da Rede',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Tipo de Conexão:',
                      _getConnectionStatusText(),
                    ),
                    if (_connectionStatus == ConnectivityResult.wifi) ...[
                      _buildInfoRow('Nome da Rede:', _wifiName),
                      _buildInfoRow('Endereço IP:', _wifiIP),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conceitos Importantes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• WiFi: Tecnologia de rede sem fio baseada no padrão IEEE 802.11\n'
                      '• Conectividade: Estado da conexão de rede do dispositivo\n'
                      '• IP: Endereço único do dispositivo na rede\n'
                      '• Dados Móveis: Conexão via operadora de telefonia',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

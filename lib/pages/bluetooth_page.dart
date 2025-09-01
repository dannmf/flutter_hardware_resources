import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    await _requestPermissions();
    
    // Obter estado inicial do adaptador
    _adapterState = await FlutterBluePlus.adapterState.first;
    setState(() {});
    
    // Escutar mudanças no estado do adaptador
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        _adapterState = state;
      });
    });

    // Escutar resultados do scan
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _scanResults = results;
      });
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
    ].request();
  }

  Future<void> _startScan() async {
    if (_adapterState != BluetoothAdapterState.on) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth deve estar ativado para buscar dispositivos')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: false,
      );
      
      // Aguardar o scan terminar
      await Future.delayed(const Duration(seconds: 15));
      
      setState(() {
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar dispositivos: $e')),
      );
    }
  }


  Future<void> _turnOnBluetooth() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth não é suportado neste dispositivo')),
        );
        return;
      }
      await FlutterBluePlus.turnOn();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ative o Bluetooth manualmente nas configurações do sistema')),
      );
    }
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth'),
        backgroundColor: Colors.blue,
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
                      'Status do Bluetooth',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _adapterState == BluetoothAdapterState.on
                              ? Icons.bluetooth
                              : Icons.bluetooth_disabled,
                          color: _adapterState == BluetoothAdapterState.on
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(_getAdapterStateText()),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _adapterState == BluetoothAdapterState.off
                              ? _turnOnBluetooth
                              : null,
                          child: const Text('Ativar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Dispositivos Próximos',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _adapterState == BluetoothAdapterState.on && !_isScanning
                      ? _startScan
                      : null,
                  child: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _adapterState != BluetoothAdapterState.on
                  ? const Center(
                      child: Text('Ative o Bluetooth para buscar dispositivos'),
                    )
                  : _isScanning
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Buscando dispositivos...'),
                            ],
                          ),
                        )
                      : _scanResults.isEmpty
                          ? const Center(
                              child: Text('Nenhum dispositivo encontrado.\nToque em "Buscar" para procurar dispositivos.'),
                            )
                          : ListView.builder(
                              itemCount: _scanResults.length,
                              itemBuilder: (context, index) {
                                final result = _scanResults[index];
                                final device = result.device;
                                return Card(
                                  child: ListTile(
                                    leading: Icon(_getDeviceIcon(device.platformName)),
                                    title: Text(device.platformName.isNotEmpty 
                                        ? device.platformName 
                                        : 'Dispositivo Desconhecido'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('MAC: ${device.remoteId}'),
                                        Text('RSSI: ${result.rssi} dBm'),
                                      ],
                                    ),
                                    trailing: result.device.isConnected
                                        ? const Icon(Icons.link, color: Colors.green)
                                        : const Icon(Icons.link_off, color: Colors.grey),
                                    onTap: () async {
                                      try {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Conectando a ${device.platformName}...')),
                                        );
                                        await device.connect();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Conectado com sucesso!')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Erro ao conectar: $e')),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
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
                      'Conceitos de Bluetooth',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Pairing: Processo de autenticação entre dispositivos\n'
                      '• MAC Address: Identificador único do dispositivo\n'
                      '• Alcance: Tipicamente 10 metros (Classe 2)\n'
                      '• Versões: 4.0 (LE), 5.0, 5.1, 5.2, etc.\n'
                      '• Perfis: A2DP (áudio), HID (teclado/mouse), etc.',
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

  String _getAdapterStateText() {
    switch (_adapterState) {
      case BluetoothAdapterState.on:
        return 'Ativado';
      case BluetoothAdapterState.off:
        return 'Desativado';
      case BluetoothAdapterState.turningOn:
        return 'Ativando...';
      case BluetoothAdapterState.turningOff:
        return 'Desativando...';
      default:
        return 'Desconhecido';
    }
  }

  IconData _getDeviceIcon(String deviceName) {
    final name = deviceName.toLowerCase();
    if (name.contains('phone') || name.contains('iphone') || name.contains('android')) {
      return Icons.smartphone;
    } else if (name.contains('headphone') || name.contains('earphone') || name.contains('audio')) {
      return Icons.headphones;
    } else if (name.contains('tv') || name.contains('television')) {
      return Icons.tv;
    } else if (name.contains('computer') || name.contains('laptop') || name.contains('pc')) {
      return Icons.computer;
    } else if (name.contains('watch')) {
      return Icons.watch;
    } else {
      return Icons.device_unknown;
    }
  }
}

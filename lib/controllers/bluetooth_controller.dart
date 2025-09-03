import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class BluetoothController extends ChangeNotifier {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;

  // Getters
  BluetoothAdapterState get adapterState => _adapterState;
  List<ScanResult> get scanResults => _scanResults;
  bool get isScanning => _isScanning;

  Future<void> initBluetooth() async {
    await _requestPermissions();

    // Obter estado inicial do adaptador
    _adapterState = await FlutterBluePlus.adapterState.first;
    notifyListeners();

    // Escutar mudanças no estado do adaptador
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      notifyListeners();
    });

    // Escutar resultados do scan
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      notifyListeners();
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

  Future<String?> startScan() async {
    if (_adapterState != BluetoothAdapterState.on) {
      return 'Bluetooth deve estar ativado para buscar dispositivos';
    }

    _isScanning = true;
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: false,
      );

      // Aguardar o scan terminar
      await Future.delayed(const Duration(seconds: 15));

      _isScanning = false;
      notifyListeners();
      return null; // Sucesso
    } catch (e) {
      _isScanning = false;
      notifyListeners();
      return 'Erro ao buscar dispositivos: $e';
    }
  }

  Future<String?> turnOnBluetooth() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        return 'Bluetooth não é suportado neste dispositivo';
      }
      await FlutterBluePlus.turnOn();
      return null; // Sucesso
    } catch (e) {
      return 'Ative o Bluetooth manualmente nas configurações do sistema';
    }
  }

  Future<String?> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      return null; // Sucesso
    } catch (e) {
      return 'Erro ao conectar: $e';
    }
  }

  String getAdapterStateText() {
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

  IconData getDeviceIcon(String deviceName) {
    final name = deviceName.toLowerCase();
    if (name.contains('phone') ||
        name.contains('iphone') ||
        name.contains('android')) {
      return Icons.smartphone;
    } else if (name.contains('headphone') ||
        name.contains('earphone') ||
        name.contains('audio')) {
      return Icons.headphones;
    } else if (name.contains('tv') || name.contains('television')) {
      return Icons.tv;
    } else if (name.contains('computer') ||
        name.contains('laptop') ||
        name.contains('pc')) {
      return Icons.computer;
    } else if (name.contains('watch')) {
      return Icons.watch;
    } else {
      return Icons.device_unknown;
    }
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();
    super.dispose();
  }
}

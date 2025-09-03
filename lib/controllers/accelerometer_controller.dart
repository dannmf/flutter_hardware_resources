import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class AccelerometerController extends ChangeNotifier {
  double _x = 0.0, _y = 0.0, _z = 0.0;
  double _gyroX = 0.0, _gyroY = 0.0, _gyroZ = 0.0;
  double _magnitude = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  bool _isMonitoring = false;

  // Getters
  double get x => _x;
  double get y => _y;
  double get z => _z;
  double get gyroX => _gyroX;
  double get gyroY => _gyroY;
  double get gyroZ => _gyroZ;
  double get magnitude => _magnitude;
  bool get isMonitoring => _isMonitoring;

  void startMonitoring() {
    _isMonitoring = true;
    notifyListeners();

    _accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      // Corrigir orientação dos eixos conforme padrão Android/iOS
      _x = event.x;  // Horizontal (esquerda/direita)
      _y = -event.y; // Vertical (cima/baixo) - invertido
      _z = event.z;  // Profundidade (frente/trás)
      _magnitude = sqrt(_x * _x + _y * _y + _z * _z);
      notifyListeners();
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      // Corrigir orientação dos eixos do giroscópio
      _gyroX = event.x;  // Pitch (rotação em torno do eixo X)
      _gyroY = -event.y; // Roll (rotação em torno do eixo Y) - invertido
      _gyroZ = event.z;  // Yaw (rotação em torno do eixo Z)
      notifyListeners();
    });
  }

  void stopMonitoring() {
    _isMonitoring = false;
    notifyListeners();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }
}

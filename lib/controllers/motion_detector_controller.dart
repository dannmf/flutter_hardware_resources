import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class MotionDetectorController extends ChangeNotifier {
  double _x = 0.0, _y = 0.0, _z = 0.0;
  double _magnitude = 0.0;
  double _previousMagnitude = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isMonitoring = false;

  // Detector de movimento
  bool _isMoving = false;
  double _movementThreshold = 2.0;
  int _movementCount = 0;

  // Detector de vibração
  bool _isVibrating = false;
  double _vibrationThreshold = 15.0;
  final List<double> _recentMagnitudes = [];

  // Nível digital (como bolha de nível)
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  bool _isLevel = false;
  final double _levelThreshold = 1.0;

  // Getters
  double get x => _x;
  double get y => _y;
  double get z => _z;
  double get magnitude => _magnitude;
  bool get isMonitoring => _isMonitoring;
  bool get isMoving => _isMoving;
  bool get isVibrating => _isVibrating;
  int get movementCount => _movementCount;
  double get tiltX => _tiltX;
  double get tiltY => _tiltY;
  bool get isLevel => _isLevel;
  double get movementThreshold => _movementThreshold;
  double get vibrationThreshold => _vibrationThreshold;

  void setMovementThreshold(double threshold) {
    _movementThreshold = threshold;
    notifyListeners();
  }

  void setVibrationThreshold(double threshold) {
    _vibrationThreshold = threshold;
    notifyListeners();
  }

  void resetMovementCount() {
    _movementCount = 0;
    notifyListeners();
  }

  void startMonitoring() {
    _isMonitoring = true;
    notifyListeners();

    _accelerometerSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      _x = event.x;
      _y = -event.y; // Invertido para corresponder à orientação da tela
      _z = event.z;
      _magnitude = sqrt(_x * _x + _y * _y + _z * _z);

      _detectMovement();
      _detectVibration();
      _calculateTilt();

      _previousMagnitude = _magnitude;
      notifyListeners();
    });
  }

  void _detectMovement() {
    // Detecta movimento baseado na mudança da magnitude
    double magnitudeChange = (_magnitude - _previousMagnitude).abs();

    if (magnitudeChange > _movementThreshold) {
      if (!_isMoving) {
        _isMoving = true;
        _movementCount++;
      }
    } else {
      _isMoving = false;
    }
  }

  void _detectVibration() {
    // Mantém histórico das últimas 10 leituras
    _recentMagnitudes.add(_magnitude);
    if (_recentMagnitudes.length > 10) {
      _recentMagnitudes.removeAt(0);
    }

    // Calcula variação nas leituras recentes
    if (_recentMagnitudes.length >= 5) {
      double variance = _calculateVariance(_recentMagnitudes);
      _isVibrating = variance > _vibrationThreshold;
    }
  }

  void _calculateTilt() {
    // Calcula inclinação baseada na gravidade
    // Normaliza os valores para ângulos de inclinação
    _tiltX = (atan2(_x, sqrt(_y * _y + _z * _z)) * 180 / pi);
    _tiltY = (atan2(_y, sqrt(_x * _x + _z * _z)) * 180 / pi);

    // Verifica se está nivelado (dentro do threshold)
    _isLevel = _tiltX.abs() < _levelThreshold && _tiltY.abs() < _levelThreshold;
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;

    double mean = values.reduce((a, b) => a + b) / values.length;
    double sumSquaredDiff = values
        .map((x) => pow(x - mean, 2).toDouble())
        .reduce((a, b) => a + b);
    return sumSquaredDiff / values.length;
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _isMoving = false;
    _isVibrating = false;
    notifyListeners();
    _accelerometerSubscription?.cancel();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
}

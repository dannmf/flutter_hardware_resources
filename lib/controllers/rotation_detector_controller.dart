import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class RotationDetectorController extends ChangeNotifier {
  double _gyroX = 0.0, _gyroY = 0.0, _gyroZ = 0.0;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  bool _isMonitoring = false;
  
  // Detector de rotação
  bool _isRotating = false;
  double _rotationThreshold = 0.5;
  String _rotationDirection = 'Parado';
  
  // Orientação do dispositivo
  double _pitch = 0.0; // Rotação em X (inclinar para frente/trás)
  double _roll = 0.0;  // Rotação em Y (inclinar para esquerda/direita)
  double _yaw = 0.0;   // Rotação em Z (girar no plano horizontal)
  
  // Contador de rotações
  int _rotationCount = 0;
  double _totalRotation = 0.0;
  
  // Estabilizador visual
  double _stabilizedX = 0.0;
  double _stabilizedY = 0.0;
  bool _stabilizerEnabled = false;

  // Getters
  double get gyroX => _gyroX;
  double get gyroY => _gyroY;
  double get gyroZ => _gyroZ;
  bool get isMonitoring => _isMonitoring;
  bool get isRotating => _isRotating;
  String get rotationDirection => _rotationDirection;
  double get pitch => _pitch;
  double get roll => _roll;
  double get yaw => _yaw;
  int get rotationCount => _rotationCount;
  double get totalRotation => _totalRotation;
  double get rotationThreshold => _rotationThreshold;
  double get stabilizedX => _stabilizedX;
  double get stabilizedY => _stabilizedY;
  bool get stabilizerEnabled => _stabilizerEnabled;

  void setRotationThreshold(double threshold) {
    _rotationThreshold = threshold;
    notifyListeners();
  }

  void resetRotationCount() {
    _rotationCount = 0;
    _totalRotation = 0.0;
    notifyListeners();
  }

  void toggleStabilizer() {
    _stabilizerEnabled = !_stabilizerEnabled;
    if (!_stabilizerEnabled) {
      _stabilizedX = 0.0;
      _stabilizedY = 0.0;
    }
    notifyListeners();
  }

  void startMonitoring() {
    _isMonitoring = true;
    notifyListeners();

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      _gyroX = event.x;  // Pitch (rotação em torno do eixo X)
      _gyroY = -event.y; // Roll (rotação em torno do eixo Y) - invertido
      _gyroZ = event.z;  // Yaw (rotação em torno do eixo Z)
      
      _detectRotation();
      _updateOrientation();
      _updateStabilizer();
      
      notifyListeners();
    });
  }

  void _detectRotation() {
    // Calcula magnitude total da rotação
    double rotationMagnitude = sqrt(_gyroX * _gyroX + _gyroY * _gyroY + _gyroZ * _gyroZ);
    
    _isRotating = rotationMagnitude > _rotationThreshold;
    
    if (_isRotating) {
      // Determina direção principal da rotação
      double maxRotation = [_gyroX.abs(), _gyroY.abs(), _gyroZ.abs()].reduce(max);
      
      if (maxRotation == _gyroX.abs()) {
        _rotationDirection = _gyroX > 0 ? 'Inclinando para baixo' : 'Inclinando para cima';
      } else if (maxRotation == _gyroY.abs()) {
        _rotationDirection = _gyroY > 0 ? 'Inclinando para direita' : 'Inclinando para esquerda';
      } else {
        _rotationDirection = _gyroZ > 0 ? 'Girando horário' : 'Girando anti-horário';
      }
      
      // Conta rotações significativas
      if (rotationMagnitude > _rotationThreshold * 2) {
        _rotationCount++;
        _totalRotation += rotationMagnitude;
      }
    } else {
      _rotationDirection = 'Parado';
    }
  }

  void _updateOrientation() {
    // Integra as velocidades angulares para obter orientação aproximada
    // Nota: Esta é uma aproximação simples, não um sistema completo de orientação
    double dt = 0.1; // Aproximação do intervalo de tempo
    
    _pitch += _gyroX * dt * 180 / pi; // Converte rad/s para graus
    _roll += _gyroY * dt * 180 / pi;
    _yaw += _gyroZ * dt * 180 / pi;
    
    // Mantém os ângulos no range -180 a 180
    _pitch = _normalizeAngle(_pitch);
    _roll = _normalizeAngle(_roll);
    _yaw = _normalizeAngle(_yaw);
  }

  void _updateStabilizer() {
    if (_stabilizerEnabled) {
      // Simula estabilização visual compensando a rotação
      // Em uma aplicação real, isso seria usado para estabilizar a câmera ou UI
      _stabilizedX = -_roll * 2; // Compensa inclinação lateral
      _stabilizedY = -_pitch * 2; // Compensa inclinação frontal
    }
  }

  double _normalizeAngle(double angle) {
    while (angle > 180) angle -= 360;
    while (angle < -180) angle += 360;
    return angle;
  }

  void resetOrientation() {
    _pitch = 0.0;
    _roll = 0.0;
    _yaw = 0.0;
    _stabilizedX = 0.0;
    _stabilizedY = 0.0;
    notifyListeners();
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _isRotating = false;
    _rotationDirection = 'Parado';
    notifyListeners();
    _gyroscopeSubscription?.cancel();
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }
}

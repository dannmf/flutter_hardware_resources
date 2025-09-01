import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class AccelerometerPage extends StatefulWidget {
  const AccelerometerPage({super.key});

  @override
  State<AccelerometerPage> createState() => _AccelerometerPageState();
}

class _AccelerometerPageState extends State<AccelerometerPage> {
  double _x = 0.0, _y = 0.0, _z = 0.0;
  double _gyroX = 0.0, _gyroY = 0.0, _gyroZ = 0.0;
  double _magnitude = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
  }

  void _startMonitoring() {
    setState(() {
      _isMonitoring = true;
    });

    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _x = event.x;
        _y = event.y;
        _z = event.z;
        _magnitude = sqrt(_x * _x + _y * _y + _z * _z);
      });
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroX = event.x;
        _gyroY = event.y;
        _gyroZ = event.z;
      });
    });
  }

  void _stopMonitoring() {
    setState(() {
      _isMonitoring = false;
    });
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acelerômetro & Giroscópio'),
        backgroundColor: Colors.purple,
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
                      'Controle dos Sensores',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
                        icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
                        label: Text(_isMonitoring ? 'Parar Monitoramento' : 'Iniciar Monitoramento'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isMonitoring ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                        ),
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
                      'Acelerômetro',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildSensorRow('Eixo X:', _x, Colors.red),
                    _buildSensorRow('Eixo Y:', _y, Colors.green),
                    _buildSensorRow('Eixo Z:', _z, Colors.blue),
                    const SizedBox(height: 8),
                    _buildInfoRow('Magnitude:', '${_magnitude.toStringAsFixed(2)} m/s²'),
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
                      'Giroscópio',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildSensorRow('Rotação X:', _gyroX, Colors.red),
                    _buildSensorRow('Rotação Y:', _gyroY, Colors.green),
                    _buildSensorRow('Rotação Z:', _gyroZ, Colors.blue),
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
                      'Visualização',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: CustomPaint(
                          painter: AccelerometerPainter(_x, _y, _z),
                          size: const Size(200, 200),
                        ),
                      ),
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

  Widget _buildSensorRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: (value + 10) / 20, // Normalizar para 0-1
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              value.toStringAsFixed(2),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
}

class AccelerometerPainter extends CustomPainter {
  final double x, y, z;

  AccelerometerPainter(this.x, this.y, this.z);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Desenhar círculo base
    canvas.drawCircle(center, size.width / 2 - 10, paint);
    
    // Desenhar ponto baseado na aceleração
    final pointX = center.dx + (x * 5);
    final pointY = center.dy + (y * 5);
    
    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(pointX, pointY), 8, pointPaint);
    
    // Desenhar linha do centro ao ponto
    final linePaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2;
    
    canvas.drawLine(center, Offset(pointX, pointY), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

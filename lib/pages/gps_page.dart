import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GpsPage extends StatefulWidget {
  const GpsPage({super.key});

  @override
  State<GpsPage> createState() => _GpsPageState();
}

class _GpsPageState extends State<GpsPage> {
  Position? _currentPosition;
  bool _isLoading = false;
  String _statusMessage = 'Toque no botão para obter localização';

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Obtendo localização...';
    });

    try {
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusMessage = 'Permissão de localização negada';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _statusMessage = 'Permissão de localização negada permanentemente';
          _isLoading = false;
        });
        return;
      }

      // Verificar se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusMessage = 'Serviço de localização desabilitado';
          _isLoading = false;
        });
        return;
      }

      // Obter localização atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _statusMessage = 'Localização obtida com sucesso!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao obter localização: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS / Localização'),
        backgroundColor: Colors.green,
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
                      'Localização Atual',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _getCurrentLocation,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.location_on),
                        label: const Text('Obter Localização'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _currentPosition != null ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_currentPosition != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalhes da Localização',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Latitude:', '${_currentPosition!.latitude.toStringAsFixed(6)}°'),
                      _buildInfoRow('Longitude:', '${_currentPosition!.longitude.toStringAsFixed(6)}°'),
                      _buildInfoRow('Altitude:', '${_currentPosition!.altitude.toStringAsFixed(2)} m'),
                      _buildInfoRow('Precisão:', '${_currentPosition!.accuracy.toStringAsFixed(2)} m'),
                      _buildInfoRow('Velocidade:', '${_currentPosition!.speed.toStringAsFixed(2)} m/s'),
                      _buildInfoRow('Direção:', '${_currentPosition!.heading.toStringAsFixed(2)}°'),
                      _buildInfoRow('Timestamp:', DateTime.fromMillisecondsSinceEpoch(_currentPosition!.timestamp.millisecondsSinceEpoch).toString()),
                    ],
                  ),
                ),
              ),
            ],
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
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

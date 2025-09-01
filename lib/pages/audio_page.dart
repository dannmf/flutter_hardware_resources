import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AudioPage extends StatefulWidget {
  const AudioPage({super.key});

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startRecording() async {
    // Simulação de gravação para compatibilidade multiplataforma
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    
    setState(() {
      _isRecording = false;
      _hasRecording = true;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gravação simulada concluída!')),
      );
    }
  }

  Future<void> _playRecording() async {
    if (_hasRecording) {
      try {
        // Simular reprodução de áudio
        setState(() {
          _isPlaying = true;
        });

        // Simular duração de reprodução
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        });
      } catch (e) {
        print('Erro ao reproduzir áudio: $e');
      }
    }
  }

  Future<void> _stopPlaying() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Áudio'),
        backgroundColor: Colors.teal,
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
                      'Gravação de Áudio',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecording
                                  ? Colors.red
                                  : Colors.grey[300],
                              boxShadow: _isRecording
                                  ? [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: IconButton(
                              onPressed: _isRecording
                                  ? _stopRecording
                                  : _startRecording,
                              icon: Icon(
                                _isRecording ? Icons.stop : Icons.mic,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_isRecording) ...[
                            Text(
                              'Gravando...',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              _formatDuration(_recordingDuration),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'Toque para gravar',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_hasRecording) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reprodução',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isPlaying
                                ? _stopPlaying
                                : _playRecording,
                            icon: Icon(
                              _isPlaying ? Icons.stop : Icons.play_arrow,
                            ),
                            label: Text(_isPlaying ? 'Parar' : 'Reproduzir'),
                          ),
                        ],
                      ),
                      if (_isPlaying) ...[
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'Reproduzindo áudio...',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conceitos de Áudio',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Microfone: Sensor que captura ondas sonoras e converte em sinais elétricos\n'
                      '• Alto-falante: Dispositivo que converte sinais elétricos em ondas sonoras\n'
                      '• Sampling Rate: Taxa de amostragem do áudio (ex: 44.1kHz)\n'
                      '• Formatos: M4A, MP3, WAV, etc.\n'
                      '• Permissões: Necessário solicitar acesso ao microfone',
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
}

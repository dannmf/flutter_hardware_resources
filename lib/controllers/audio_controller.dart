import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class AudioController extends ChangeNotifier {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecording = false;
  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String? _recordingPath;

  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get hasRecording => _hasRecording;
  bool get isRecorderInitialized => _isRecorderInitialized;
  bool get isPlayerInitialized => _isPlayerInitialized;
  Duration get recordingDuration => _recordingDuration;

  Future<String?> initializeAudio() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    
    try {
      // Solicitar permissão de microfone
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return 'Permissão de microfone necessária!';
      }

      // Inicializar recorder e player
      await _recorder!.openRecorder();
      await _player!.openPlayer();
      
      _isRecorderInitialized = true;
      _isPlayerInitialized = true;
      notifyListeners();
      return null; // Sucesso
    } catch (e) {
      return 'Erro ao inicializar áudio: $e';
    }
  }

  Future<String> _getRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
  }

  Future<String?> startRecording() async {
    if (!_isRecorderInitialized) return 'Recorder não inicializado';
    
    try {
      _recordingPath = await _getRecordingPath();
      
      await _recorder!.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacADTS,
      );
      
      _isRecording = true;
      _recordingDuration = Duration.zero;
      notifyListeners();

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration = Duration(seconds: timer.tick);
        notifyListeners();
      });
      return null; // Sucesso
    } catch (e) {
      return 'Erro ao iniciar gravação: $e';
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return 'Não está gravando';
    
    try {
      await _recorder!.stopRecorder();
      _recordingTimer?.cancel();
      
      _isRecording = false;
      _hasRecording = true;
      notifyListeners();
      
      return null; // Sucesso
    } catch (e) {
      return 'Erro ao parar gravação: $e';
    }
  }

  Future<String?> playRecording() async {
    if (!_hasRecording || !_isPlayerInitialized || _recordingPath == null) {
      return 'Nenhuma gravação disponível';
    }
    
    try {
      _isPlaying = true;
      notifyListeners();

      await _player!.startPlayer(
        fromURI: _recordingPath,
        whenFinished: () {
          _isPlaying = false;
          notifyListeners();
        },
      );
      return null; // Sucesso
    } catch (e) {
      _isPlaying = false;
      notifyListeners();
      return 'Erro ao reproduzir áudio: $e';
    }
  }

  Future<String?> stopPlaying() async {
    if (!_isPlaying) return 'Não está reproduzindo';
    
    try {
      await _player!.stopPlayer();
      _isPlaying = false;
      notifyListeners();
      return null; // Sucesso
    } catch (e) {
      return 'Erro ao parar reprodução: $e';
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    super.dispose();
  }
}

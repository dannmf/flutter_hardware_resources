import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class CameraControllerService extends ChangeNotifier {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  File? _capturedImage;
  final ImagePicker _imagePicker = ImagePicker();
  String? _initializationError;
  bool _isInitializing = false;

  // Getters
  CameraController? get cameraController => _cameraController;
  List<CameraDescription>? get cameras => _cameras;
  bool get isCameraInitialized => _isCameraInitialized;
  File? get capturedImage => _capturedImage;
  String? get initializationError => _initializationError;
  bool get isInitializing => _isInitializing;

  Future<void> initialize() async {
    if (_isInitializing) return;
    
    _isInitializing = true;
    _initializationError = null;
    notifyListeners();

    try {
      // Verificar permissões primeiro
      final cameraPermission = await Permission.camera.status;
      if (cameraPermission.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied) {
          _initializationError = 'Permissão da câmera negada';
          _isInitializing = false;
          notifyListeners();
          return;
        }
      }

      // Obter câmeras disponíveis
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        _initializationError = 'Nenhuma câmera encontrada';
        _isInitializing = false;
        notifyListeners();
        return;
      }

      // Inicializar controller da câmera
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false, // Evita problemas de áudio
      );

      await _cameraController!.initialize();
      
      if (_cameraController!.value.isInitialized) {
        _isCameraInitialized = true;
        _initializationError = null;
      } else {
        _initializationError = 'Falha ao inicializar câmera';
      }
    } catch (e) {
      _initializationError = 'Erro ao inicializar câmera: ${e.toString()}';
      if (kDebugMode) {
        print('Erro detalhado: $e');
      }
      // Limpar recursos em caso de erro
      await _cameraController?.dispose();
      _cameraController = null;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }


  Future<void> takePicture() async {
    if (!_isCameraInitialized || _cameraController == null) {
      if (kDebugMode) {
        print('Câmera não inicializada');
      }
      return;
    }

    try {
      if (_cameraController!.value.isTakingPicture) {
        return; // Já está tirando foto
      }

      final XFile image = await _cameraController!.takePicture();
      _capturedImage = File(image.path);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao capturar imagem: $e');
      }
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        _capturedImage = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao selecionar imagem: $e');
      }
    }
  }

  Future<void> switchCamera() async {
    if (!_isCameraInitialized || _cameras == null || _cameras!.length <= 1) {
      return;
    }

    try {
      final currentCameraIndex = _cameras!.indexOf(
        _cameraController!.description,
      );
      final newCameraIndex = (currentCameraIndex + 1) % _cameras!.length;

      await _cameraController!.dispose();
      
      _cameraController = CameraController(
        _cameras![newCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao trocar câmera: $e');
      }
    }
  }

  void clearCapturedImage() {
    _capturedImage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    _isCameraInitialized = false;
    super.dispose();
  }
}

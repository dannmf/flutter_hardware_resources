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

  // Getters
  CameraController? get cameraController => _cameraController;
  List<CameraDescription>? get cameras => _cameras;
  bool get isCameraInitialized => _isCameraInitialized;
  File? get capturedImage => _capturedImage;

  Future<void> initialize() async {
    await _requestPermissions();

    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
        );

        await _cameraController!.initialize();
        _isCameraInitialized = true;
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao inicializar câmera: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
  }

  Future<void> takePicture() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile image = await _cameraController!.takePicture();
        _capturedImage = File(image.path);
        notifyListeners();
      } catch (e) {
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
      print('Erro ao selecionar imagem: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_cameras != null && _cameras!.length > 1) {
      final currentCameraIndex = _cameras!.indexOf(
        _cameraController!.description,
      );
      final newCameraIndex = (currentCameraIndex + 1) % _cameras!.length;

      await _cameraController!.dispose();
      _cameraController = CameraController(
        _cameras![newCameraIndex],
        ResolutionPreset.medium,
      );

      await _cameraController!.initialize();
      notifyListeners();
    }
  }

  void clearCapturedImage() {
    _capturedImage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}

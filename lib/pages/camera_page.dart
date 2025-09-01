import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  File? _capturedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _requestPermissions();
    
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
        );
        
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Erro ao inicializar câmera: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
  }

  Future<void> _takePicture() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile image = await _cameraController!.takePicture();
        setState(() {
          _capturedImage = File(image.path);
        });
      } catch (e) {
        print('Erro ao capturar imagem: $e');
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _capturedImage = File(image.path);
        });
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras != null && _cameras!.length > 1) {
      final currentCameraIndex = _cameras!.indexOf(_cameraController!.description);
      final newCameraIndex = (currentCameraIndex + 1) % _cameras!.length;
      
      await _cameraController!.dispose();
      _cameraController = CameraController(
        _cameras![newCameraIndex],
        ResolutionPreset.medium,
      );
      
      await _cameraController!.initialize();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Câmera'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _isCameraInitialized
                ? Stack(
                    children: [
                      CameraPreview(_cameraController!),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: FloatingActionButton(
                          mini: true,
                          onPressed: _switchCamera,
                          child: const Icon(Icons.flip_camera_ios),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _pickImageFromGallery,
                  child: const Icon(Icons.photo_library),
                ),
                FloatingActionButton.large(
                  onPressed: _takePicture,
                  child: const Icon(Icons.camera_alt, size: 32),
                ),
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _capturedImage = null;
                    });
                  },
                  child: const Icon(Icons.delete),
                ),
              ],
            ),
          ),
          if (_capturedImage != null) ...[
            Expanded(
              flex: 2,
              child: Card(
                margin: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Imagem Capturada',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: Image.file(
                        _capturedImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Expanded(
              flex: 2,
              child: Card(
                margin: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_camera,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma imagem capturada',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use os botões abaixo para capturar\nou selecionar uma imagem',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conceitos de Câmera',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Resolução: Qualidade da imagem (ex: 1080p, 4K)\n'
                  '• Autofoco: Ajuste automático do foco\n'
                  '• Flash: Iluminação artificial para fotos\n'
                  '• Zoom: Aproximação digital ou óptica',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

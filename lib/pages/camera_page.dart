import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../controllers/camera_controller.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraControllerService _controller;

  @override
  void initState() {
    super.initState();
    _controller = CameraControllerService();
    _controller.addListener(_onControllerUpdate);
    _controller.initialize();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _showImagePreview() {
    if (_controller.capturedImage != null) {
      showModalBottomSheet(
        useSafeArea: true,
        context: context,
        isScrollControlled: true,
        builder: (_) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pré-visualização',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Image.file(_controller.capturedImage!, fit: BoxFit.contain),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _takePictureAndShow() async {
    await _controller.takePicture();
    if (mounted && _controller.capturedImage != null) {
      _showImagePreview();
    }
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
        spacing: 10,
        children: [
          Expanded(
            flex: 3,
            child: _controller.isCameraInitialized
                ? Stack(
                    fit: StackFit.expand,

                    children: [
                      FittedBox(
                        fit: BoxFit.fitWidth, // ocupa largura inteira
                        child: SizedBox(
                          width: _controller.cameraController!.value.previewSize!.height,
                          height: _controller.cameraController!.value.previewSize!.width,
                          child: CameraPreview(_controller.cameraController!),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: FloatingActionButton(
                          mini: true,
                          onPressed: _controller.switchCamera,
                          child: const Icon(Icons.flip_camera_ios),
                        ),
                      ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          ),

          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _controller.pickImageFromGallery,
                  child: const Icon(Icons.photo_library),
                ),
                FloatingActionButton.large(
                  onPressed: _takePictureAndShow,
                  child: const Icon(Icons.camera_alt, size: 32),
                ),
                FloatingActionButton(
                  onPressed: () {
                    _controller.clearCapturedImage();
                  },
                  child: const Icon(Icons.delete),
                ),
              ],
            ),
          ),
          if (_controller.capturedImage != null) ...[
            Expanded(
              flex: 2,
              child: Card(
                margin: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        textAlign: TextAlign.center,
                        'Imagem Capturada (Clique para Expandir)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Ao clicar no preview pequeno → mostra modal
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: InteractiveViewer(
                                // permite zoom com gesto
                                child: Image.file(
                                  _controller.capturedImage!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Image.file(
                          _controller.capturedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(child: Padding(padding: const EdgeInsets.all(12.0))),
      ),
    );
  }
}

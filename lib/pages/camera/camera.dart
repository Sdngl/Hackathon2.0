import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../service/analysis_api_service.dart';
import '../../service/health_scan_repository.dart';
import '../../service/image_base64_service.dart';
import 'analysis_result_screen.dart';



enum ScanType {
  meal,
  medicine,
  report,
}

class Camera extends StatefulWidget {
  const Camera({super.key});

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera>
    with WidgetsBindingObserver {
  CameraController? _cameraController;

  final ImagePicker _imagePicker = ImagePicker();
  final AnalysisApiService _analysisApiService =
  AnalysisApiService();
  final ImageBase64Service _imageBase64Service =
  ImageBase64Service();
  final HealthScanRepository _healthScanRepository =
  HealthScanRepository();

  bool _isCameraReady = false;
  bool _isInitializing = false;
  bool _isFlashOn = false;
  bool _isTakingPicture = false;
  bool _isAnalyzing = false;

  ScanType _selectedScanType = ScanType.medicine;

  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (_isInitializing) return;

    _isInitializing = true;

    try {
      PermissionStatus status =
      await Permission.camera.status;

      if (!status.isGranted) {
        status = await Permission.camera.request();
      }

      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }

        if (mounted) {
          setState(() {
            _isCameraReady = false;
          });
        }

        return;
      }

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No camera was found on this device.',
            ),
          ),
        );

        return;
      }

      final backCamera = cameras.firstWhere(
            (camera) =>
        camera.lensDirection ==
            CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await _cameraController?.dispose();

      _cameraController = controller;

      setState(() {
        _isCameraReady = true;
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to start the camera.',
          ),
        ),
      );
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    try {
      await controller.setFlashMode(
        _isFlashOn
            ? FlashMode.off
            : FlashMode.torch,
      );

      if (!mounted) return;

      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Flash is not available.',
          ),
        ),
      );
    }
  }

  Future<void> _captureImage() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPicture ||
        _isAnalyzing) {
      return;
    }

    try {
      setState(() {
        _isTakingPicture = true;
      });

      final image =
      await controller.takePicture();

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
      });

      _showSelectedImagePreview();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not capture the image.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isAnalyzing) return;

    try {
      final image =
      await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        _selectedImage = image;
      });

      _showSelectedImagePreview();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the gallery.',
          ),
        ),
      );
    }
  }

  Future<void> _analyzeSelectedImage() async {
    final image = _selectedImage;

    if (image == null || _isAnalyzing) {
      return;
    }

    try {
      setState(() {
        _isAnalyzing = true;
      });

      final type = _selectedScanType.name;

      final imageBase64 =
      await _imageBase64Service.convertToCompressedBase64(
        image,
      );

      final recordId =
      await _healthScanRepository.createPendingScan(
        type: type,
        imageBase64: imageBase64,
      );

      final result = await _analysisApiService.analyzeSavedImage(
        recordId: recordId,
        type: type,
      );

      if (!mounted) return;

      _handleAnalysisResult(result);
    } on DioException catch (e) {
      if (!mounted) return;

      final status = e.response?.statusCode;
      final data = e.response?.data;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'API Error $status: $data',
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _handleAnalysisResult(
      Map<String, dynamic> result,
      ) {
    final type = _selectedScanType.name;

    setState(() {
      _selectedImage = null;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalysisResultScreen(
          type: type,
          result: result,
        ),
      ),
    );
  }

  void _showSelectedImagePreview() {
    final image = _selectedImage;

    if (image == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor:
      const Color(0xFF101715),
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24,
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                  child: Image.file(
                    File(image.path),
                    width: double.infinity,
                    height: 320,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child:
                      OutlinedButton(
                        onPressed:
                        _isAnalyzing
                            ? null
                            : () {
                          Navigator.pop(
                            bottomSheetContext,
                          );

                          setState(() {
                            _selectedImage =
                            null;
                          });
                        },
                        style:
                        OutlinedButton.styleFrom(
                          minimumSize:
                          const Size
                              .fromHeight(
                            52,
                          ),
                          side:
                          const BorderSide(
                            color:
                            Colors.white24,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              16,
                            ),
                          ),
                        ),
                        child:
                        const Text(
                          'Retake',
                          style:
                          TextStyle(
                            color:
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child:
                      ElevatedButton(
                        onPressed:
                        _isAnalyzing
                            ? null
                            : () async {
                          Navigator.pop(
                            bottomSheetContext,
                          );

                          await _analyzeSelectedImage();
                        },
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(
                            0xFF5EE6B8,
                          ),
                          foregroundColor:
                          const Color(
                            0xFF06251D,
                          ),
                          minimumSize:
                          const Size
                              .fromHeight(
                            52,
                          ),
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              16,
                            ),
                          ),
                        ),
                        child:
                        const Text(
                          'Use Image',
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight
                                .w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    final controller =
        _cameraController;

    if (controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    if (state ==
        AppLifecycleState.inactive) {
      controller.dispose();

      _cameraController = null;

      if (mounted) {
        setState(() {
          _isCameraReady = false;
        });
      }
    } else if (state ==
        AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    _cameraController?.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraPreview(),
          _buildCameraOverlay(),
          _buildTopControls(),
          _buildScannerFrame(),
          _buildBottomSection(),
          if (_isTakingPicture ||
              _isAnalyzing)
            _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller =
        _cameraController;

    if (!_isCameraReady ||
        controller == null ||
        !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child:
          CircularProgressIndicator(
            color:
            Color(0xFF5EE6B8),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller
              .value
              .previewSize
              ?.height ??
              1,
          height: controller
              .value
              .previewSize
              ?.width ??
              1,
          child:
          CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return IgnorePointer(
      child: Container(
        color:
        Colors.black.withOpacity(
          0.12,
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding:
        const EdgeInsets.fromLTRB(
          18,
          16,
          18,
          0,
        ),
        child: Align(
          alignment:
          Alignment.topCenter,
          child: Row(
            children: [
              _circleButton(
                icon:
                Icons.close_rounded,
                onTap: () {
                  Navigator.pop(
                    context,
                  );
                },
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Container(
                  height: 46,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 14,
                  ),
                  decoration:
                  BoxDecoration(
                    color: Colors.black
                        .withOpacity(
                      0.38,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      24,
                    ),
                    border:
                    Border.all(
                      color: Colors.white
                          .withOpacity(
                        0.08,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      const Icon(
                        Icons
                            .auto_awesome_rounded,
                        color:
                        Color(
                          0xFF5EE6B8,
                        ),
                        size: 16,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Flexible(
                        child: Text(
                          _statusText,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            color:
                            Colors.white,
                            fontSize: 13,
                            fontWeight:
                            FontWeight
                                .w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              _circleButton(
                icon: _isFlashOn
                    ? Icons
                    .flash_on_rounded
                    : Icons
                    .flash_off_rounded,
                onTap: _toggleFlash,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _statusText {
    switch (_selectedScanType) {
      case ScanType.meal:
        return 'Ready to scan meal';

      case ScanType.medicine:
        return 'Ready to scan medicine';

      case ScanType.report:
        return 'Ready to scan report';
    }
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(
          50,
        ),
        child: Container(
          width: 48,
          height: 48,
          decoration:
          BoxDecoration(
            color: Colors.black
                .withOpacity(
              0.38,
            ),
            shape:
            BoxShape.circle,
            border: Border.all(
              color: Colors.white
                  .withOpacity(
                0.08,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildScannerFrame() {
    return Center(
      child: Transform.translate(
        offset:
        const Offset(
          0,
          -45,
        ),
        child: SizedBox(
          width: 300,
          height: 320,
          child: Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                child:
                ScannerCorner(
                  top: true,
                  left: true,
                ),
              ),
              const Positioned(
                top: 0,
                right: 0,
                child:
                ScannerCorner(
                  top: true,
                  right: true,
                ),
              ),
              const Positioned(
                bottom: 0,
                left: 0,
                child:
                ScannerCorner(
                  bottom: true,
                  left: true,
                ),
              ),
              const Positioned(
                bottom: 0,
                right: 0,
                child:
                ScannerCorner(
                  bottom: true,
                  right: true,
                ),
              ),
              Align(
                alignment:
                Alignment.center,
                child: Container(
                  margin:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 28,
                  ),
                  height: 2,
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFF5EE6B8,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      20,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                        const Color(
                          0xFF5EE6B8,
                        ).withOpacity(
                          0.8,
                        ),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return SafeArea(
      child: Align(
        alignment:
        Alignment.bottomCenter,
        child: Padding(
          padding:
          const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            22,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              _buildScanTypeSelector(),
              const SizedBox(
                height: 22,
              ),
              _buildCameraActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanTypeSelector() {
    return Container(
      padding:
      const EdgeInsets.all(
        5,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFF101715,
        ).withOpacity(
          0.92,
        ),
        borderRadius:
        BorderRadius.circular(
          30,
        ),
        border: Border.all(
          color:
          Colors.white.withOpacity(
            0.08,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _scanTypeItem(
              type: ScanType.meal,
              icon:
              Icons.restaurant_rounded,
              label: 'Meal',
            ),
          ),
          Expanded(
            child: _scanTypeItem(
              type:
              ScanType.medicine,
              icon:
              Icons.medication_rounded,
              label: 'Medicine',
            ),
          ),
          Expanded(
            child: _scanTypeItem(
              type:
              ScanType.report,
              icon:
              Icons.description_rounded,
              label: 'Report',
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanTypeItem({
    required ScanType type,
    required IconData icon,
    required String label,
  }) {
    final selected =
        _selectedScanType == type;

    return GestureDetector(
      onTap: _isAnalyzing
          ? null
          : () {
        setState(() {
          _selectedScanType =
              type;
        });
      },
      child: AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 180,
        ),
        height: 48,
        decoration:
        BoxDecoration(
          color: selected
              ? const Color(
            0xFF5EE6B8,
          )
              : Colors.transparent,
          borderRadius:
          BorderRadius.circular(
            25,
          ),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: selected
                  ? const Color(
                0xFF06251D,
              )
                  : Colors.white70,
            ),
            const SizedBox(
              width: 7,
            ),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(
                  0xFF06251D,
                )
                    : Colors.white70,
                fontSize: 13,
                fontWeight:
                selected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraActions() {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment:
            Alignment.center,
            child:
            _galleryButton(),
          ),
        ),
        _captureButton(),
        const Expanded(
          child: SizedBox(),
        ),
      ],
    );
  }

  Widget _galleryButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isAnalyzing
            ? null
            : _pickFromGallery,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        child: Container(
          width: 56,
          height: 56,
          decoration:
          BoxDecoration(
            color: Colors.black
                .withOpacity(
              0.42,
            ),
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: Colors.white
                  .withOpacity(
                0.15,
              ),
            ),
          ),
          child: const Icon(
            Icons
                .photo_library_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
    );
  }

  Widget _captureButton() {
    return GestureDetector(
      onTap:
      _isAnalyzing
          ? null
          : _captureImage,
      child: Container(
        width: 84,
        height: 84,
        decoration:
        BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
        ),
        padding:
        const EdgeInsets.all(
          6,
        ),
        child: Container(
          decoration:
          const BoxDecoration(
            shape:
            BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color:
      Colors.black.withOpacity(
        0.55,
      ),
      child: Center(
        child: Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 22,
          ),
          decoration:
          BoxDecoration(
            color:
            const Color(
              0xFF101715,
            ),
            borderRadius:
            BorderRadius.circular(
              20,
            ),
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color:
                Color(
                  0xFF5EE6B8,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                _isAnalyzing
                    ? 'Analyzing ${_selectedScanType.name}...'
                    : 'Capturing image...',
                style:
                const TextStyle(
                  color:
                  Colors.white,
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScannerCorner
    extends StatelessWidget {
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const ScannerCorner({
    super.key,
    this.top = false,
    this.bottom = false,
    this.left = false,
    this.right = false,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return SizedBox(
      width: 58,
      height: 58,
      child: CustomPaint(
        painter:
        ScannerCornerPainter(
          top: top,
          bottom: bottom,
          left: left,
          right: right,
        ),
      ),
    );
  }
}

class ScannerCornerPainter
    extends CustomPainter {
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  ScannerCornerPainter({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap =
          StrokeCap.round
      ..style =
          PaintingStyle.stroke;

    const radius = 18.0;

    final path = Path();

    if (top && left) {
      path.moveTo(
        0,
        size.height,
      );

      path.lineTo(
        0,
        radius,
      );

      path.quadraticBezierTo(
        0,
        0,
        radius,
        0,
      );

      path.lineTo(
        size.width,
        0,
      );
    }

    if (top && right) {
      path.moveTo(
        0,
        0,
      );

      path.lineTo(
        size.width - radius,
        0,
      );

      path.quadraticBezierTo(
        size.width,
        0,
        size.width,
        radius,
      );

      path.lineTo(
        size.width,
        size.height,
      );
    }

    if (bottom && left) {
      path.moveTo(
        0,
        0,
      );

      path.lineTo(
        0,
        size.height - radius,
      );

      path.quadraticBezierTo(
        0,
        size.height,
        radius,
        size.height,
      );

      path.lineTo(
        size.width,
        size.height,
      );
    }

    if (bottom && right) {
      path.moveTo(
        size.width,
        0,
      );

      path.lineTo(
        size.width,
        size.height - radius,
      );

      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      );

      path.lineTo(
        0,
        size.height,
      );
    }

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
      covariant ScannerCornerPainter
      oldDelegate,
      ) {
    return false;
  }
}

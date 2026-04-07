import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';

class FeedPhotoCapturePage extends StatefulWidget {
  const FeedPhotoCapturePage({super.key});

  @override
  State<FeedPhotoCapturePage> createState() => _FeedPhotoCapturePageState();
}

class _FeedPhotoCapturePageState extends State<FeedPhotoCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];

  bool _isInitializing = true;
  bool _isCapturingPhoto = false;
  int _selectedCameraIndex = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadAvailableCameras());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    _controller = null;
    unawaited(controller?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller = null;
      unawaited(controller.dispose());
      return;
    }

    if (state == AppLifecycleState.resumed && _cameras.isNotEmpty) {
      unawaited(_initializeCamera(_selectedCameraIndex));
    }
  }

  Future<void> _loadAvailableCameras() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) {
        return;
      }

      if (cameras.isEmpty) {
        setState(() {
          _cameras = const [];
          _isInitializing = false;
          _errorMessage = 'ไม่พบกล้องบนอุปกรณ์นี้';
        });
        return;
      }

      final backCameraIndex = cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      setState(() {
        _cameras = cameras;
        _selectedCameraIndex = backCameraIndex >= 0 ? backCameraIndex : 0;
      });

      await _initializeCamera(_selectedCameraIndex);
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _errorMessage = _cameraErrorMessage(error);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _errorMessage = 'เปิดกล้องไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  Future<void> _initializeCamera(int cameraIndex) async {
    if (_cameras.isEmpty) {
      return;
    }

    final previousController = _controller;
    final nextController = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    setState(() {
      _isInitializing = true;
      _isCapturingPhoto = false;
      _errorMessage = null;
      _selectedCameraIndex = cameraIndex;
      _controller = nextController;
    });

    await previousController?.dispose();

    try {
      await nextController.initialize();
      await nextController.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!mounted) {
        await nextController.dispose();
        return;
      }

      setState(() => _isInitializing = false);
    } on CameraException catch (error) {
      await nextController.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _controller = null;
        _isInitializing = false;
        _errorMessage = _cameraErrorMessage(error);
      });
    } catch (_) {
      await nextController.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _controller = null;
        _isInitializing = false;
        _errorMessage = 'เปิดกล้องไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isBusy) {
      return;
    }

    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initializeCamera(nextIndex);
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isInitializing ||
        _isCapturingPhoto) {
      return;
    }

    setState(() => _isCapturingPhoto = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) {
        return;
      }
      // PRE-POST MODERATION HOOK runs in feed_view.dart before createPost().
      Navigator.of(context).pop(file);
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isCapturingPhoto = false);
      _showSnackBar(_cameraErrorMessage(error));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isCapturingPhoto = false);
      _showSnackBar('ถ่ายรูปไม่สำเร็จ');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _cameraErrorMessage(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
        return 'ยังไม่ได้รับสิทธิ์ใช้งานกล้อง';
      case 'CameraAccessDeniedWithoutPrompt':
        return 'กรุณาเปิดสิทธิ์กล้องจากการตั้งค่าเครื่อง';
      default:
        return error.description?.trim().isNotEmpty == true
            ? error.description!.trim()
            : 'เปิดกล้องไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
    }
  }

  bool get _isBusy => _isInitializing || _isCapturingPhoto;

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final scale = context.responsive;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildPreview(controller),
            ),
            Positioned(
              top: scale.rs(12, min: 8, max: 12),
              left: scale.rs(16, min: 12, max: 16),
              right: scale.rs(16, min: 12, max: 16),
              child: Row(
                children: [
                  _CameraOverlayButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: scale.rs(28, min: 18, max: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isCapturingPhoto
                        ? 'กำลังบันทึกรูป...'
                        : 'แตะปุ่มด้านล่างเพื่อถ่ายรูป',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: scale.rf(14, min: 12, max: 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: scale.rs(18, min: 12, max: 18)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: scale.rs(64, min: 40, max: 64)),
                      GestureDetector(
                        onTap: _isBusy ? null : _capturePhoto,
                        child: Container(
                          width: scale.rs(88, min: 72, max: 88),
                          height: scale.rs(88, min: 72, max: 88),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: scale.rs(5, min: 4, max: 5),
                            ),
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          child: Center(
                            child: Container(
                              width: scale.rs(64, min: 50, max: 64),
                              height: scale.rs(64, min: 50, max: 64),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFDFDFDF),
                                  width: scale.rs(2, min: 1.5, max: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: scale.rs(28, min: 18, max: 28)),
                      Opacity(
                        opacity: (_cameras.length > 1 && !_isBusy) ? 1 : 0.45,
                        child: _CameraOverlayButton(
                          icon: Icons.cameraswitch_rounded,
                          onTap: (_cameras.length > 1 && !_isBusy)
                              ? _switchCamera
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(CameraController? controller) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive.rs(28, min: 20, max: 28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: context.responsive.rs(52, min: 42, max: 52),
              ),
              SizedBox(height: context.responsive.rs(16, min: 12, max: 16)),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive.rf(16, min: 14, max: 16),
                  height: 1.4,
                ),
              ),
              SizedBox(height: context.responsive.rs(20, min: 14, max: 20)),
              FilledButton(
                onPressed: _loadAvailableCameras,
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isInitializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _CameraOverlayButton extends StatelessWidget {
  const _CameraOverlayButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: scale.rs(48, min: 40, max: 48),
          height: scale.rs(48, min: 40, max: 48),
          child: Icon(
            icon,
            color: Colors.white,
            size: scale.rs(24, min: 20, max: 24),
          ),
        ),
      ),
    );
  }
}

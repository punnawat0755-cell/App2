import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VideoCapturePage extends StatefulWidget {
  const VideoCapturePage({super.key});

  @override
  State<VideoCapturePage> createState() => _VideoCapturePageState();
}

class _VideoCapturePageState extends State<VideoCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  Timer? _recordingTimer;

  bool _isInitializing = true;
  bool _isStoppingRecording = false;
  int _selectedCameraIndex = 0;
  Duration _recordingDuration = Duration.zero;
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
    _recordingTimer?.cancel();
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
      _recordingTimer?.cancel();
      _recordingDuration = Duration.zero;
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
      enableAudio: true,
    );

    setState(() {
      _isInitializing = true;
      _isStoppingRecording = false;
      _errorMessage = null;
      _selectedCameraIndex = cameraIndex;
      _recordingDuration = Duration.zero;
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
    if (_cameras.length < 2 || _isBusy || _isRecording) {
      return;
    }

    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initializeCamera(nextIndex);
  }

  Future<void> _toggleRecording() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isInitializing ||
        _isStoppingRecording) {
      return;
    }

    if (controller.value.isRecordingVideo) {
      _recordingTimer?.cancel();
      setState(() => _isStoppingRecording = true);

      try {
        final file = await controller.stopVideoRecording();
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(file);
      } on CameraException catch (error) {
        if (!mounted) {
          return;
        }
        setState(() => _isStoppingRecording = false);
        _showSnackBar(_cameraErrorMessage(error));
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() => _isStoppingRecording = false);
        _showSnackBar('หยุดบันทึกวิดีโอไม่สำเร็จ');
      }
      return;
    }

    try {
      await controller.prepareForVideoRecording();
      await controller.startVideoRecording();
      _startRecordingTimer();
      if (!mounted) {
        return;
      }
      setState(() {});
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_cameraErrorMessage(error));
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar('เริ่มบันทึกวิดีโอไม่สำเร็จ');
    }
  }

  Future<void> _closeCameraPage() async {
    if (!_isRecording) {
      Navigator.of(context).pop();
      return;
    }

    final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('ยกเลิกการถ่ายวิดีโอ?'),
              content: const Text('วิดีโอที่กำลังบันทึกอยู่จะไม่ถูกบันทึก'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('ถ่ายต่อ'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('ยกเลิก'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!mounted || !shouldDiscard) {
      return;
    }

    Navigator.of(context).pop();
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    setState(() => _recordingDuration = Duration.zero);
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRecording) {
        _recordingTimer?.cancel();
        return;
      }

      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
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
      case 'AudioAccessDenied':
        return 'ยังไม่ได้รับสิทธิ์ใช้งานไมโครโฟน';
      case 'AudioAccessDeniedWithoutPrompt':
        return 'กรุณาเปิดสิทธิ์ไมโครโฟนจากการตั้งค่าเครื่อง';
      default:
        return error.description?.trim().isNotEmpty == true
            ? error.description!.trim()
            : 'เปิดกล้องไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
    }
  }

  bool get _isRecording => _controller?.value.isRecordingVideo ?? false;

  bool get _isBusy => _isInitializing || _isStoppingRecording;

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return PopScope<void>(
      canPop: !_isRecording,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _closeCameraPage();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: _buildPreview(controller),
              ),
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    _CameraOverlayButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: _closeCameraPage,
                    ),
                    const Spacer(),
                    if (_isRecording)
                      _RecordingBadge(duration: _recordingDuration),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 28,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isRecording
                          ? 'แตะปุ่มสีแดงเพื่อหยุดบันทึก'
                          : 'แตะปุ่มด้านล่างเพื่อเริ่มอัดวิดีโอ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 64),
                        GestureDetector(
                          onTap: _isBusy ? null : _toggleRecording,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 5),
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: _isRecording ? 34 : 64,
                                height: _isRecording ? 34 : 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4B4B),
                                  shape: _isRecording
                                      ? BoxShape.rectangle
                                      : BoxShape.circle,
                                  borderRadius: _isRecording
                                      ? BorderRadius.circular(12)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 28),
                        Opacity(
                          opacity:
                              (_cameras.length > 1 && !_isBusy && !_isRecording)
                                  ? 1
                                  : 0.45,
                          child: _CameraOverlayButton(
                            icon: Icons.cameraswitch_rounded,
                            onTap: (_cameras.length > 1 &&
                                    !_isBusy &&
                                    !_isRecording)
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
      ),
    );
  }

  Widget _buildPreview(CameraController? controller) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_rounded,
                color: Colors.white,
                size: 52,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
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
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _RecordingBadge extends StatelessWidget {
  const _RecordingBadge({
    required this.duration,
  });

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: Color(0xFFFF4B4B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

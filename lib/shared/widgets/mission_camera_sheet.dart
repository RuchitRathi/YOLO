import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'mission_proof_filter.dart';

class MissionCameraCapture {
  const MissionCameraCapture({
    required this.bytes,
    required this.filter,
    required this.sticker,
    required this.stickerAlignment,
  });
  final Uint8List bytes;
  final MissionProofFilter filter;
  final MissionProofSticker sticker;
  final Alignment stickerAlignment;
}

Future<MissionCameraCapture?> showMissionCamera(BuildContext context) =>
    showModalBottomSheet<MissionCameraCapture>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: YoloColors.ink,
      builder: (_) => const MissionCameraSheet(),
    );

class MissionCameraSheet extends StatefulWidget {
  const MissionCameraSheet({super.key});

  @override
  State<MissionCameraSheet> createState() => _MissionCameraSheetState();
}

class _MissionCameraSheetState extends State<MissionCameraSheet> {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _cameraIndex = 0;
  bool _initializing = true;
  bool _capturing = false;
  MissionProofFilter _filter = MissionProofFilter.comic;
  MissionProofSticker _sticker = MissionProofSticker.shinchan;
  Alignment _stickerAlignment = const Alignment(.72, .48);
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera({int? preferredIndex}) async {
    if (mounted) {
      setState(() {
        _initializing = true;
        _error = null;
      });
    }
    final previous = _controller;
    _controller = null;
    await previous?.dispose();
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('NoCamera', 'No camera is available.');
      }
      if (preferredIndex != null) _cameraIndex = preferredIndex;
      if (_cameraIndex >= _cameras.length) _cameraIndex = 0;
      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();
      if (mounted) setState(() => _initializing = false);
    } on CameraException catch (error) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = switch (error.code) {
            'CameraAccessDenied' ||
            'permissionDenied' =>
              'Camera permission is off. Allow camera access in your browser or device settings, then try again.',
            'CameraAccessDeniedWithoutPrompt' =>
              'Camera permission is blocked. Enable it in your browser or device settings.',
            _ =>
              'Could not start the camera. Check that it is connected and not being used by another app.',
          };
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error =
              'Could not access the camera. Allow camera permission and try again.';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _capturing) return;
    final next = (_cameraIndex + 1) % _cameras.length;
    await _startCamera(preferredIndex: next);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();
      if (mounted) {
        Navigator.of(context).pop(MissionCameraCapture(
          bytes: bytes,
          filter: _filter,
          sticker: _sticker,
          stickerAlignment: _stickerAlignment,
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _capturing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not capture the photo. Please try again.')));
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * .94;
    final controller = _controller;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
        child: Column(children: [
          Row(children: [
            const Expanded(
              child: Text('CAPTURE YOUR MISSION',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: 'Close camera',
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ]),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: _initializing
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: YoloColors.yellow))
                    : _error != null
                        ? _cameraError()
                        : controller != null && controller.value.isInitialized
                            ? _livePreview(controller)
                            : _cameraError(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _lensTray(),
          const SizedBox(height: 7),
          _stickerTray(),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 54,
              child: _cameras.length > 1
                  ? IconButton(
                      onPressed: _switchCamera,
                      tooltip: 'Switch camera',
                      icon: const Icon(Icons.flip_camera_android_rounded,
                          color: Colors.white, size: 29),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 20),
            Semantics(
              button: true,
              label: 'Take photo',
              child: GestureDetector(
                onTap: _initializing || _error != null ? null : _capture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _initializing || _error != null
                        ? Colors.white24
                        : YoloColors.yellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 10),
                    ],
                  ),
                  child: _capturing
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: YoloColors.ink),
                        )
                      : const Icon(Icons.camera_alt_rounded,
                          color: YoloColors.ink, size: 31),
                ),
              ),
            ),
            const SizedBox(width: 74),
          ]),
          const SizedBox(height: 9),
          const Text('Your photo stays on this device until you share it.',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _lensTray() => Row(children: [
        const SizedBox(
          width: 55,
          child: Text('LENS',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7)),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final filter in MissionProofFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                    selectedColor: YoloColors.yellow,
                    backgroundColor: Colors.white12,
                    labelStyle: TextStyle(
                      color: _filter == filter ? YoloColors.ink : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                    side: BorderSide(
                        color: _filter == filter
                            ? YoloColors.yellow
                            : Colors.white54),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ]),
          ),
        ),
      ]);

  Widget _stickerTray() => Row(children: [
        const SizedBox(
          width: 55,
          child: Text('STICKER',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7)),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final sticker in MissionProofSticker.values)
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    avatar: switch (sticker) {
                      MissionProofSticker.none => const Icon(
                          Icons.block_rounded,
                          size: 16,
                          color: Colors.white70),
                      MissionProofSticker.shinchan => const Icon(
                          Icons.face_rounded,
                          size: 16,
                          color: Colors.black),
                      MissionProofSticker.heart =>
                        const Text('💖', style: TextStyle(fontSize: 15)),
                      MissionProofSticker.sparkle =>
                        const Text('✨', style: TextStyle(fontSize: 15)),
                      MissionProofSticker.pow => const Icon(Icons.bolt_rounded,
                          size: 16, color: Colors.black),
                    },
                    label: Text(switch (sticker) {
                      MissionProofSticker.none => 'OFF',
                      MissionProofSticker.shinchan => 'SHINCHAN',
                      MissionProofSticker.heart => 'HEART',
                      MissionProofSticker.sparkle => 'SPARKLE',
                      MissionProofSticker.pow => 'POW',
                    }),
                    selected: _sticker == sticker,
                    onSelected: (_) => setState(() => _sticker = sticker),
                    selectedColor: YoloColors.yellow,
                    backgroundColor: Colors.white12,
                    labelStyle: TextStyle(
                      color:
                          _sticker == sticker ? YoloColors.ink : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                    ),
                    side: BorderSide(
                        color: _sticker == sticker
                            ? YoloColors.yellow
                            : Colors.white54),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ]),
          ),
        ),
      ]);

  Widget _livePreview(CameraController controller) => LayoutBuilder(
        builder: (context, constraints) => ClipRect(
          child: Stack(fit: StackFit.expand, children: [
            ColorFiltered(
                colorFilter: ColorFilter.matrix(_filter.matrix),
                child: CameraPreview(controller)),
            if (_filter == MissionProofFilter.comic)
              const IgnorePointer(
                  child: CustomPaint(painter: MissionHalftonePainter())),
            IgnorePointer(child: _lensTint()),
            if (_sticker != MissionProofSticker.none)
              Align(
                alignment: _stickerAlignment,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    if (width <= 0 || height <= 0) return;
                    setState(() {
                      _stickerAlignment = Alignment(
                        (_stickerAlignment.x + details.delta.dx * 2 / width)
                            .clamp(-.82, .82)
                            .toDouble(),
                        (_stickerAlignment.y + details.delta.dy * 2 / height)
                            .clamp(-.82, .82)
                            .toDouble(),
                      );
                    });
                  },
                  child: MissionProofStickerView(
                      sticker: _sticker, size: constraints.maxWidth * .28),
                ),
              ),
          ]),
        ),
      );

  Widget _lensTint() => MissionProofTint(filter: _filter);

  Widget _cameraError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.no_photography_rounded,
                size: 48, color: YoloColors.yellow),
            const SizedBox(height: 12),
            Text(_error ?? 'Camera unavailable',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, height: 1.4)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _startCamera,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('TRY AGAIN'),
            ),
          ]),
        ),
      );
}

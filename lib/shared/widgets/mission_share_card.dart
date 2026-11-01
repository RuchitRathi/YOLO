import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/repository.dart';
import 'mission_camera_sheet.dart';
import 'mission_proof_filter.dart';

Future<void> showMissionShareCard(
        BuildContext context, WidgetRef ref, Mission mission,
        {String? subtitle, int? xpEarned}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: YoloColors.background,
      builder: (context) => _ShareCardSheet(
          mission: mission,
          username: ref.read(repositoryProvider).username,
          totalXp: ref.read(repositoryProvider).xp,
          streak: ref.read(repositoryProvider).streak,
          subtitle: subtitle,
          xpEarned: xpEarned ?? mission.xp),
    );

class _ShareCardSheet extends StatefulWidget {
  const _ShareCardSheet(
      {required this.mission,
      required this.username,
      required this.totalXp,
      required this.streak,
      this.subtitle,
      required this.xpEarned});
  final Mission mission;
  final String username;
  final int totalXp, streak, xpEarned;
  final String? subtitle;
  @override
  State<_ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<_ShareCardSheet> {
  final _controller = ScreenshotController();
  final _picker = ImagePicker();
  Uint8List? _photo;
  bool _sharing = false;
  MissionProofFilter _filter = MissionProofFilter.comic;
  MissionProofSticker _sticker = MissionProofSticker.none;
  Alignment _stickerAlignment = const Alignment(.72, .48);

  Future<void> _openCamera() async {
    final capture = await showMissionCamera(context);
    if (capture != null && mounted) {
      setState(() {
        _photo = capture.bytes;
        _filter = capture.filter;
        _sticker = capture.sticker;
        _stickerAlignment = capture.stickerAlignment;
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
          source: source, imageQuality: 90, maxWidth: 1600);
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _photo = bytes;
            _filter = MissionProofFilter.comic;
            _sticker = MissionProofSticker.none;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Photo picker is unavailable on this device.')));
      }
    }
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final bytes = await _controller.capture(pixelRatio: 3);
      if (bytes == null) throw StateError('Could not render the card.');
      await SharePlus.instance.share(ShareParams(
        title: 'My YOLO mission',
        text: 'I just did “${widget.mission.title}” with YOLO! 🎉',
        files: [XFile.fromData(bytes, mimeType: 'image/png')],
        fileNameOverrides: ['yolo-mission.png'],
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sharing is unavailable here: $e')));
      }
    }
    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
          child: Padding(
        padding: EdgeInsets.fromLTRB(
            18, 18, 18, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Expanded(
                child: Text('YOUR MISSION CARD',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 1.1))),
            IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close mission card',
                icon: const Icon(Icons.close_rounded))
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openCamera,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('TAKE PHOTO'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('CHOOSE PHOTO'),
              ),
            ),
          ]),
          if (_photo != null) ...[
            const SizedBox(height: 9),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(spacing: 7, children: [
                for (final filter in MissionProofFilter.values)
                  ChoiceChip(
                    label: Text(filter.label),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                    visualDensity: VisualDensity.compact,
                  ),
              ]),
            ),
          ],
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
                'Your photo stays on this device until you choose to share.',
                style: TextStyle(fontSize: 10, color: Color(0xFF6B665E))),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) => Screenshot(
              controller: _controller,
              child: SizedBox(width: constraints.maxWidth, child: _card()),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: _sharing ? null : _share,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(
                      _sharing ? 'Preparing card…' : 'Share mission card'))),
          const SizedBox(height: 5),
          const Text(
              'Choose Instagram Stories, WhatsApp, TikTok or another app from the share menu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11)),
        ])),
      ));

  Widget _card() => Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 510),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: YoloColors.yellow,
            border: Border.all(color: YoloColors.ink, width: 3),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(color: YoloColors.ink, offset: Offset(6, 7))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('YOLO!',
                style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1)),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: YoloColors.ink, width: 2),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(widget.mission.category.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w900)))
          ]),
          const SizedBox(height: 20),
          if (_photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: Stack(fit: StackFit.expand, children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix(_filter.matrix),
                    child: Image.memory(_photo!, fit: BoxFit.cover),
                  ),
                  if (_filter == MissionProofFilter.comic)
                    const CustomPaint(painter: MissionHalftonePainter()),
                  IgnorePointer(child: MissionProofTint(filter: _filter)),
                  if (_sticker != MissionProofSticker.none)
                    Align(
                      alignment: _stickerAlignment,
                      child:
                          MissionProofStickerView(sticker: _sticker, size: 94),
                    ),
                  Positioned(
                    top: 11,
                    right: 11,
                    child: Transform.rotate(
                      angle: .08,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: YoloColors.yellow,
                          border: Border.all(color: YoloColors.ink, width: 2),
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: const [
                            BoxShadow(
                                color: YoloColors.ink, offset: Offset(2, 3)),
                          ],
                        ),
                        child: const Text('I DID IT!',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 10,
                    bottom: 9,
                    child: _ComicBurst(label: 'YOLO!'),
                  ),
                ]),
              ),
            )
          else
            Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: YoloColors.background,
                    border: Border.all(color: YoloColors.ink, width: 2),
                    borderRadius: BorderRadius.circular(18)),
                child: const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_a_photo_rounded,
                      size: 47, color: YoloColors.red),
                  SizedBox(height: 6),
                  Text('ADD YOUR MISSION MOMENT',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                ]))),
          const SizedBox(height: 19),
          Text(widget.subtitle ?? 'MISSION COMPLETE!',
              style: const TextStyle(
                  color: YoloColors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text(widget.mission.title,
              style: const TextStyle(
                  fontSize: 27,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7)),
          const SizedBox(height: 7),
          Text(widget.mission.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 18),
          const Divider(color: YoloColors.ink, thickness: 1.5),
          Row(children: [
            Expanded(child: _stat('+${widget.xpEarned}', 'XP GAINED')),
            Expanded(child: _stat('${widget.totalXp}', 'TOTAL XP')),
            Expanded(child: _stat('${widget.streak} DAYS', 'STREAK'))
          ]),
          const SizedBox(height: 12),
          Text(
              '${widget.username}  •  ${DateTime.now().toLocal().toString().split(' ').first}',
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _stat(String value, String label) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        Text(label,
            style: const TextStyle(
                fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .5))
      ]);
}

class _ComicBurst extends StatelessWidget {
  const _ComicBurst({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: -.08,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: YoloColors.red,
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(color: YoloColors.ink, offset: Offset(2, 3)),
            ],
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7)),
        ),
      );
}

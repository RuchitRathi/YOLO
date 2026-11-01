import 'package:flutter/material.dart';

enum MissionProofFilter {
  comic('COMIC POP', [
    1.38,
    0,
    0,
    0,
    -28,
    0,
    1.38,
    0,
    0,
    -28,
    0,
    0,
    1.38,
    0,
    -28,
    0,
    0,
    0,
    1,
    0,
  ]),
  sunny('SUN KISS', [
    1.18,
    0,
    0,
    0,
    8,
    0,
    1.02,
    0,
    0,
    2,
    0,
    0,
    .76,
    0,
    -5,
    0,
    0,
    0,
    1,
    0,
  ]),
  mono('B&W', [
    .213,
    .715,
    .072,
    0,
    0,
    .213,
    .715,
    .072,
    0,
    0,
    .213,
    .715,
    .072,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  const MissionProofFilter(this.label, this.matrix);
  final String label;
  final List<double> matrix;
}

class MissionHalftonePainter extends CustomPainter {
  const MissionHalftonePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dots = Paint()..color = Colors.black.withValues(alpha: .23);
    for (var y = 5.0; y < size.height; y += 9) {
      for (var x = 5.0; x < size.width; x += 9) {
        canvas.drawCircle(Offset(x, y), 1.35, dots);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MissionProofTint extends StatelessWidget {
  const MissionProofTint({super.key, required this.filter});
  final MissionProofFilter filter;

  @override
  Widget build(BuildContext context) => switch (filter) {
        MissionProofFilter.comic => DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFD640).withValues(alpha: .30),
                  Colors.transparent,
                  const Color(0xFFE53935).withValues(alpha: .22),
                ],
              ),
            ),
          ),
        MissionProofFilter.sunny => DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFC857).withValues(alpha: .35),
                  const Color(0xFFFF6B8A).withValues(alpha: .20),
                ],
              ),
            ),
          ),
        MissionProofFilter.mono =>
          ColoredBox(color: Colors.black.withValues(alpha: .07)),
      };
}

enum MissionProofSticker { none, shinchan, heart, sparkle, pow }

class MissionProofStickerView extends StatelessWidget {
  const MissionProofStickerView({
    super.key,
    required this.sticker,
    this.size = 90,
  });

  final MissionProofSticker sticker;
  final double size;

  @override
  Widget build(BuildContext context) => switch (sticker) {
        MissionProofSticker.none => const SizedBox.shrink(),
        MissionProofSticker.shinchan => Container(
            width: size * .78,
            height: size,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black54, blurRadius: 8, offset: Offset(2, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:
                  Image.asset('assets/images/shinchan.png', fit: BoxFit.cover),
            ),
          ),
        MissionProofSticker.heart => Text('💖',
            style: TextStyle(fontSize: size * .62, shadows: const [
              Shadow(
                  color: Colors.black45, blurRadius: 8, offset: Offset(2, 3)),
            ])),
        MissionProofSticker.sparkle => Text('✨⭐✨',
            style: TextStyle(fontSize: size * .36, shadows: const [
              Shadow(
                  color: Colors.black54, blurRadius: 6, offset: Offset(2, 3)),
            ])),
        MissionProofSticker.pow => Transform.rotate(
            angle: -.12,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: size * .14, vertical: size * .08),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD640),
                border: Border.all(color: Colors.black, width: 3),
                borderRadius: BorderRadius.circular(size * .14),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black54,
                      blurRadius: 7,
                      offset: Offset(2, 4)),
                ],
              ),
              child: Text('POW!',
                  style: TextStyle(
                      color: const Color(0xFFE53935),
                      fontSize: size * .28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5)),
            ),
          ),
      };
}

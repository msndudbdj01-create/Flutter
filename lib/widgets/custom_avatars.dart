import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HappyFaceAvatar extends StatelessWidget {
  final Color color;
  final double size;

  const HappyFaceAvatar({
    Key? key,
    required this.color,
    this.size = 70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size.w, size.h),
      painter: HappyFacePainter(color: color),
    );
  }
}

class HappyFacePainter extends CustomPainter {
  final Color color;

  HappyFacePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final facePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.38),
      radius * 0.12,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.38),
      radius * 0.12,
      eyePaint,
    );

    final pupilPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.38),
      radius * 0.06,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.38),
      radius * 0.06,
      pupilPaint,
    );

    final smilePath = Path();
    smilePath.moveTo(size.width * 0.35, size.height * 0.6);
    smilePath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.75,
      size.width * 0.65,
      size.height * 0.6,
    );
    final smilePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(smilePath, smilePaint);

    final blushPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.55),
      radius * 0.08,
      blushPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.55),
      radius * 0.08,
      blushPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SadFaceAvatar extends StatelessWidget {
  final Color color;
  final double size;

  const SadFaceAvatar({
    Key? key,
    required this.color,
    this.size = 70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size.w, size.h),
      painter: SadFacePainter(color: color),
    );
  }
}

class SadFacePainter extends CustomPainter {
  final Color color;

  SadFacePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final facePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.35, size.height * 0.38),
        width: radius * 0.2,
        height: radius * 0.1,
      ),
      eyePaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.65, size.height * 0.38),
        width: radius * 0.2,
        height: radius * 0.1,
      ),
      eyePaint,
    );

    final mouthPath = Path();
    mouthPath.moveTo(size.width * 0.35, size.height * 0.65);
    mouthPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.5,
      size.width * 0.65,
      size.height * 0.65,
    );
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SurprisedFaceAvatar extends StatelessWidget {
  final Color color;
  final double size;

  const SurprisedFaceAvatar({
    Key? key,
    required this.color,
    this.size = 70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size.w, size.h),
      painter: SurprisedFacePainter(color: color),
    );
  }
}

class SurprisedFacePainter extends CustomPainter {
  final Color color;

  SurprisedFacePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final facePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.33, size.height * 0.38),
      radius * 0.13,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.67, size.height * 0.38),
      radius * 0.13,
      eyePaint,
    );

    final pupilPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.33, size.height * 0.38),
      radius * 0.05,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.67, size.height * 0.38),
      radius * 0.05,
      pupilPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.62),
      radius * 0.12,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.62),
      radius * 0.08,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AngryFaceAvatar extends StatelessWidget {
  final Color color;
  final double size;

  const AngryFaceAvatar({
    Key? key,
    required this.color,
    this.size = 70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size.w, size.h),
      painter: AngryFacePainter(color: color),
    );
  }
}

class AngryFacePainter extends CustomPainter {
  final Color color;

  AngryFacePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final facePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    final browPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1
      ..strokeCap = StrokeCap.round;

    final leftBrowPath = Path();
    leftBrowPath.moveTo(size.width * 0.27, size.height * 0.32);
    leftBrowPath.lineTo(size.width * 0.4, size.height * 0.35);
    canvas.drawPath(leftBrowPath, browPaint);

    final rightBrowPath = Path();
    rightBrowPath.moveTo(size.width * 0.73, size.height * 0.32);
    rightBrowPath.lineTo(size.width * 0.6, size.height * 0.35);
    canvas.drawPath(rightBrowPath, browPaint);

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.45),
      radius * 0.09,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.45),
      radius * 0.09,
      eyePaint,
    );

    final mouthPath = Path();
    mouthPath.moveTo(size.width * 0.35, size.height * 0.68);
    mouthPath.lineTo(size.width * 0.5, size.height * 0.63);
    mouthPath.lineTo(size.width * 0.65, size.height * 0.68);
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoveFaceAvatar extends StatelessWidget {
  final Color color;
  final double size;

  const LoveFaceAvatar({
    Key? key,
    required this.color,
    this.size = 70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size.w, size.h),
      painter: LoveFacePainter(color: color),
    );
  }
}

class LoveFacePainter extends CustomPainter {
  final Color color;

  LoveFacePainter({required this.color});

  void _drawHeart(Canvas canvas, Offset center, double size) {
    final heartPath = Path();
    heartPath.moveTo(center.dx, center.dy - size);
    heartPath.cubicTo(
      center.dx - size * 0.8,
      center.dy - size * 0.6,
      center.dx - size,
      center.dy + size * 0.2,
      center.dx,
      center.dy + size * 0.6,
    );
    heartPath.cubicTo(
      center.dx + size,
      center.dy + size * 0.2,
      center.dx + size * 0.8,
      center.dy - size * 0.6,
      center.dx,
      center.dy - size,
    );
    canvas.drawPath(heartPath, Paint()..color = Colors.white);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final facePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    _drawHeart(
        canvas, Offset(size.width * 0.32, size.height * 0.4), radius * 0.12);
    _drawHeart(
        canvas, Offset(size.width * 0.68, size.height * 0.4), radius * 0.12);
    _drawHeart(
        canvas, Offset(size.width * 0.5, size.height * 0.62), radius * 0.13);

    final blushPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.55),
      radius * 0.07,
      blushPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.55),
      radius * 0.07,
      blushPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SleepyFaceAvatar extends StatelessWidget {
  final Color color;
  final double size;

  const SleepyFaceAvatar({
    Key? key,
    required this.color,
    this.size = 70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size.w, size.h),
      painter: SleepyFacePainter(color: color),
    );
  }
}

class SleepyFacePainter extends CustomPainter {
  final Color color;

  SleepyFacePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final facePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.4),
      Offset(size.width * 0.4, size.height * 0.4),
      eyePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.4),
      Offset(size.width * 0.7, size.height * 0.4),
      eyePaint,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.6),
        width: radius * 0.2,
        height: radius * 0.15,
      ),
      0,
      3.14,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.08,
    );

    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.25),
      radius * 0.06,
      bubblePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.2),
      radius * 0.04,
      bubblePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.16),
      radius * 0.03,
      bubblePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GrumpyFaceAvatar extends StatelessWidget {
  final Color color;
  final double size;

  const GrumpyFaceAvatar({
    Key? key,
    required this.color,
    this.size = 70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size.w, size.h),
      painter: GrumpyFacePainter(color: color),
    );
  }
}

class GrumpyFacePainter extends CustomPainter {
  final Color color;

  GrumpyFacePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final facePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    final browPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1;

    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.35),
      Offset(size.width * 0.4, size.height * 0.38),
      browPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.35),
      Offset(size.width * 0.6, size.height * 0.38),
      browPaint,
    );

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.45),
      radius * 0.09,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.45),
      radius * 0.09,
      eyePaint,
    );

    final mouthPath = Path();
    mouthPath.moveTo(size.width * 0.35, size.height * 0.65);
    mouthPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.7,
      size.width * 0.65,
      size.height * 0.65,
    );
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SmileyFaceAvatar extends StatelessWidget {
  final Color color;
  final double size;

  const SmileyFaceAvatar({
    Key? key,
    required this.color,
    this.size = 70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size.w, size.h),
      painter: SmileyFacePainter(color: color),
    );
  }
}

class SmileyFacePainter extends CustomPainter {
  final Color color;

  SmileyFacePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final facePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.33, size.height * 0.38),
      radius * 0.1,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.67, size.height * 0.38),
      radius * 0.1,
      eyePaint,
    );

    final pupilPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.33, size.height * 0.38),
      radius * 0.05,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.67, size.height * 0.38),
      radius * 0.05,
      pupilPaint,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.6),
        width: radius * 0.6,
        height: radius * 0.4,
      ),
      0,
      3.14,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.08
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.63),
        width: radius * 0.15,
        height: radius * 0.12,
      ),
      0,
      3.14,
      true,
      Paint()..color = Colors.redAccent.withOpacity(0.8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TiredFaceAvatar extends StatelessWidget {
  final Color color;
  final double size;

  const TiredFaceAvatar({
    Key? key,
    required this.color,
    this.size = 70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size.w, size.h),
      painter: TiredFacePainter(color: color),
    );
  }
}

class TiredFacePainter extends CustomPainter {
  final Color color;

  TiredFacePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final facePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.42),
      radius * 0.1,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.42),
      radius * 0.1,
      eyePaint,
    );

    final eyelidPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.38,
        radius * 0.18,
        radius * 0.1,
      ),
      eyelidPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.58,
        size.height * 0.38,
        radius * 0.18,
        radius * 0.1,
      ),
      eyelidPaint,
    );

    final mouthPath = Path();
    mouthPath.moveTo(size.width * 0.4, size.height * 0.65);
    mouthPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.68,
      size.width * 0.6,
      size.height * 0.65,
    );
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.08,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

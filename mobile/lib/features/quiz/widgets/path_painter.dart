import 'package:flutter/material.dart';

class PathPainter extends CustomPainter {
  final int levelCount;
  final int completedLevels;

  PathPainter({
    required this.levelCount,
    required this.completedLevels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final paint = Paint()
      ..color = Colors.amber.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25.0
      ..strokeCap = StrokeCap.round;

    final completedPaint = Paint()
      ..color = Colors.green.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25.0
      ..strokeCap = StrokeCap.round;

    final levelPositions = List.generate(levelCount, (index) {
      final progress = index / (levelCount - 1);
      final y = size.height * (0.9 - progress * 0.8);
      final x = size.width * (index % 2 == 0 ? 0.7 : 0.3);
      return Offset(x, y);
    });

    if (completedLevels > 0) {
      final completedPath = Path();
      completedPath.moveTo(levelPositions[0].dx, levelPositions[0].dy);

      for (int i = 1; i < levelCount && i <= completedLevels; i++) {
        _addPathSegment(completedPath, levelPositions[i-1], levelPositions[i]);
      }

      canvas.drawPath(completedPath, completedPaint);
    }

    path.moveTo(levelPositions[0].dx, levelPositions[0].dy);
    for (int i = 1; i < levelCount; i++) {
      _addPathSegment(path, levelPositions[i-1], levelPositions[i]);
    }
    canvas.drawPath(path, paint);

    for (int i = 0; i < levelCount; i++) {
      final position = levelPositions[i];
      final isCompleted = i < completedLevels;

      canvas.drawCircle(
        position,
        10,
        Paint()
          ..color = isCompleted ? Colors.green : Colors.amber.shade300
          ..style = PaintingStyle.fill,
      );

      canvas.drawCircle(
        position,
        12,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _addPathSegment(Path path, Offset start, Offset end) {
    final controlX1 = start.dx;
    final controlY1 = (start.dy + end.dy) / 2;
    final controlX2 = end.dx;
    final controlY2 = (start.dy + end.dy) / 2;

    path.cubicTo(
      controlX1, controlY1,
      controlX2, controlY2,
      end.dx, end.dy,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
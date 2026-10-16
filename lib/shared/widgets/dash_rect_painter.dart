import 'package:flutter/material.dart';
import 'dart:ui';

class DashRectPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double gap;

  DashRectPainter(
      {this.strokeWidth = 2.0, required this.color, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path.addRRect(RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(16)));

    Path dashPath = Path();
    double dashWidth = 10.0;
    double dashSpace = gap;
    double distance = 0.0;

    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

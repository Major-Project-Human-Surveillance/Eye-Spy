import 'package:flutter/material.dart';

import '../models/body_part.dart';
import '../models/person.dart';

const minConfidence = 0.25;

/// A custom painter that overlays keypoint circles and body joints on a canvas.
class OverlayView extends CustomPainter {
  final bool showSkeleton;
  final bool showPoints;
  final bool showBox;
  OverlayView(
      {required this.showSkeleton,
      required this.showPoints,
      required this.showBox,
      required double scale})
      : _scale = scale;

  static const _bodyJoints = [
    [BodyPart.nose, BodyPart.leftEye],
    [BodyPart.nose, BodyPart.rightEye],
    [BodyPart.leftEye, BodyPart.leftEar],
    [BodyPart.rightEye, BodyPart.rightEar],
    [BodyPart.nose, BodyPart.leftShoulder],
    [BodyPart.nose, BodyPart.rightShoulder],
    [BodyPart.leftShoulder, BodyPart.leftElbow],
    [BodyPart.leftElbow, BodyPart.leftWrist],
    [BodyPart.rightShoulder, BodyPart.rightElbow],
    [BodyPart.rightElbow, BodyPart.rightWrist],
    [BodyPart.leftShoulder, BodyPart.rightShoulder],
    [BodyPart.leftShoulder, BodyPart.leftHip],
    [BodyPart.rightShoulder, BodyPart.rightHip],
    [BodyPart.leftHip, BodyPart.rightHip],
    [BodyPart.leftHip, BodyPart.leftKnee],
    [BodyPart.leftKnee, BodyPart.leftAnkle],
    [BodyPart.rightHip, BodyPart.rightKnee],
    [BodyPart.rightKnee, BodyPart.rightAnkle]
  ];

  final double _scale;
  Person? _persons;

  final Paint _strokePaint = Paint()
    ..color = Colors.red
    ..strokeWidth = 5
    ..style = PaintingStyle.stroke;

  final Paint _circlePaint = Paint()
    ..color = Colors.green
    ..strokeWidth = 3
    ..style = PaintingStyle.fill;

  /// Updates the person data to be displayed on the overlay.
  void updatePerson(Person persons) {
    _persons = persons;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_persons == null) return;

    // Draw circles for each keyPoint
    if (_persons!.score > minConfidence) {
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      _persons?.keyPoints.forEach((element) {
        double scaledY = element.coordinate.dy * _scale;
        double scaledX = element.coordinate.dx * _scale;

        // Update bounding box coordinates
        if (scaledX < minX) minX = scaledX;
        if (scaledY < minY) minY = scaledY;
        if (scaledX > maxX) maxX = scaledX;
        if (scaledY > maxY) maxY = scaledY;

        // Draw points on canvas
        if (showPoints) {
          canvas.drawCircle(Offset(scaledX, scaledY), 5, _circlePaint);
        }
      });

      // Draw bounding box
      if (showBox) {
        canvas.drawRect(
          Rect.fromPoints(Offset(minX, minY), Offset(maxX, maxY)),
          _strokePaint,
        );
      }

      // Draw lines for body joints
      if (showSkeleton) {
        for (List<BodyPart> index in _bodyJoints) {
          final pointAIndex = index[0].index;
          final pointBIndex = index[1].index;

          final pointA = _persons?.keyPoints[pointAIndex].coordinate;
          final pointB = _persons?.keyPoints[pointBIndex].coordinate;

          if (pointA != null && pointB != null) {
            canvas.drawLine(Offset(pointA.dx * _scale, pointA.dy * _scale),
                Offset(pointB.dx * _scale, pointB.dy * _scale), _strokePaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant OverlayView oldDelegate) =>
      oldDelegate._persons != _persons;
}

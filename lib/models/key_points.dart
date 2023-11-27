
import 'dart:ui';

import 'body_part.dart';


class KeyPoint {
  final BodyPart bodyPart;
  final Offset coordinate;
  final double score;

  KeyPoint({
    required this.bodyPart,
    required this.coordinate,
    required this.score,
  });
}
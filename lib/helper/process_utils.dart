import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:image/image.dart';

import '../models/body_part.dart';
import '../models/key_points.dart';
import '../models/person.dart';

abstract class ProcessUtils {

  /// Converts the given input image to a matrix representation.
  ///
  /// The image is converted to a 4-dimensional list, where each element
  /// represents a pixel in the image. The pixel values are normalized
  /// to the range of -1 to 1.
  ///
  /// The inputImage parameter is an instance of the Image class from the
  /// `image` package.
  ///
  /// Returns a 4-D list representing the image matrix.
  static List<List<List<List<double>>>> getImageMatrix(Image inputImage) {
    final imageMatrix = List.generate(
      inputImage.height,
      (y) => List.generate(
        inputImage.width,
        (x) {
          final pixel = inputImage.getPixel(x, y);
          // normalize -1 to 1
          return [
            (pixel.r - 127.5) / 127.5,    //red
            (pixel.g - 127.5) / 127.5,    //green
            (pixel.b - 127.5) / 127.5    //blue
          ];
        },
      ),
    );

    return [imageMatrix];
  }

  /// The function prepares an output map for a model by initializing nested lists with specific
  /// dimensions and filling them with zeros.
  /// 
  /// Returns:
  ///   The function `prepareOutput()` returns a `Map<int, Object>` containing four key-value pairs. The
  /// keys are integers and the values are lists. Each list is a 4-D array filled with zeros.
  /// The dimensions of the arrays are as follows:
  // Preparing the output map for the model.
  static Map<int, Object> prepareOutput() {
    // outputMap
    final outputMap = <int, Object>{};

    // 1 * 9 * 9 * 17 contains heatMaps
    outputMap[0] = [List.filled(9, List.filled(9, List.filled(17, 0.0)))];

    // 1 * 9 * 9 * 34 contains offsets
    outputMap[1] = [List.filled(9, List.filled(9, List.filled(34, 0.0)))];

    // 1 * 9 * 9 * 32 contains forward displacements
    outputMap[2] = [List.filled(9, List.filled(9, List.filled(32, 0.0)))];

    // 1 * 9 * 9 * 32 contains backward displacements
    outputMap[3] = [List.filled(9, List.filled(9, List.filled(32, 0.0)))];

    return outputMap;
  }
}
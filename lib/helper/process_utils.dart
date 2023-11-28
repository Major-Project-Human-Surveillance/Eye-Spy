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
            (pixel.r - 127.5) / 127.5,
            (pixel.g - 127.5) / 127.5,
            (pixel.b - 127.5) / 127.5
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
   static Person postProcessModelOutputs(
      List<List<List<List<double>>>> heatMap,
      List<List<List<List<double>>>> offsets,
      int inputImageWidth,
      int inputImageHeight,
      int originalWidth,
      int originalHeight,
      double ratio) {
    final height = heatMap[0].length;
    final width = heatMap[0][0].length;
    final numKeyPoints = heatMap[0][0][0].length;

    final keyPointPositions = <List<int>>[];
    for (var keyPoint = 0; keyPoint < numKeyPoints; keyPoint++) {
      double maxVal = heatMap[0][0][0][keyPoint];
      int maxRow = 0;
      int maxCol = 0;

      // Finding the max keyPoint value in the heatmap across all locations.
      for (var row = 0; row < height; row++) {
        for (var col = 0; col < width; col++) {
          if (heatMap[0][row][col][keyPoint] > maxVal) {
            maxVal = heatMap[0][row][col][keyPoint];
            maxRow = row;
            maxCol = col;
          }
        }
      }
      keyPointPositions.add([maxRow, maxCol]);
    }

    // Calculating the x and y coordinates of the keyPoints with offset adjustment.
    final xCoords = List.filled(numKeyPoints, 0.0);
    final yCoords = List.filled(numKeyPoints, 0.0);
    final confidenceScores = List.filled(numKeyPoints, 0.0);
    for (var idx = 0; idx < keyPointPositions.length; idx++) {
      final positionY = keyPointPositions[idx][0];
      final positionX = keyPointPositions[idx][1];

      final inputImageCoordinateY =
          positionY / (height - 1.0) * inputImageHeight +
              offsets[0][positionY][positionX][idx];
      final double ratioHeight = originalHeight / inputImageHeight;
      yCoords[idx] = inputImageCoordinateY * ratioHeight;

      final inputImageCoordinateX =
          positionX / (width - 1.0) * inputImageWidth +
              offsets[0][positionY][positionX][idx + numKeyPoints];
      final double ratioWidth = originalWidth / inputImageWidth;
      xCoords[idx] = inputImageCoordinateX * ratioWidth;

      confidenceScores[idx] = sigmoid(heatMap[0][positionY][positionX][idx]);
    }
    final keyPointList = <KeyPoint>[];
    double totalScore = 0.0;

    // Calculating the total score of all keyPoints.
    for (var value in BodyPart.values) {
      totalScore += confidenceScores[value.index];
      keyPointList.add(KeyPoint(
          bodyPart: value,
          coordinate: Offset(xCoords[value.index], yCoords[value.index]),
          score: confidenceScores[value.index]));
    }
    return Person(keyPoints: keyPointList, score: totalScore / numKeyPoints);
  }
}

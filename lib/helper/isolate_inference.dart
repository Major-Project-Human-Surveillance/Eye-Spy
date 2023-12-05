import 'dart:io';
import 'dart:isolate';     //support for concurrent programming

import 'package:camera/camera.dart';
import 'package:image/image.dart';     //decoding, encoding, manipulating, and processing images 
import 'package:tflite_flutter/tflite_flutter.dart';  //tensorflow lite interpreter

import '../image_utils.dart';
import 'process_utils.dart';

/// A class that handles inference using isolates.
class IsolateInference {
  /// The receive port for the isolate.
  final ReceivePort _receivePort = ReceivePort();

  /// The isolate.
  late Isolate _isolate;

  /// The send port for the isolate.
  SendPort? _sendPort;

  /// The send port for the isolate.
  SendPort? get sendPort => _sendPort;

  /// Starts the isolate and initializes the send port.
  Future<void> start() async {
    _isolate = await Isolate.spawn(entryPoint, _receivePort.sendPort);
    _sendPort = await _receivePort.first;
  }

  /// Closes the receive port and kills the isolate.
  Future<void> close() async {
    _receivePort.close();
    _isolate.kill();
  }

  /// The entry point for the isolate.
  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);
    await for (final InferenceModel message in port) {
      // Perform inference on the received message
      var originalImage = ImageUtils.convertCameraImage(message.cameraImage);

      // Rotate image 90 degrees in Android because the Android camera is landscape
      if (Platform.isAndroid) {
        originalImage = copyRotate(originalImage!, angle: 90);
      }

      // Resize image to match the input shape
      final inputImage = copyResize(originalImage!,
          width: message.inputShape[2], height: message.inputShape[1]);

      // Convert image to input matrix
      final inputData = ProcessUtils.getImageMatrix(inputImage);

      // Prepare output map for model output
      final outputData = ProcessUtils.prepareOutput();

      // Run the model
      final Interpreter interpreter =
          Interpreter.fromAddress(message.interpreterAddress);
      interpreter.runForMultipleInputs([inputData], outputData);

      // Prepare the output
      final heatMap = outputData[0] as List<List<List<List<double>>>>;
      final offsets = outputData[1] as List<List<List<List<double>>>>;

      // Post process the output
      // final person = ProcessUtils.postProcessModelOutputs(
      //     heatMap, offsets, inputImage.width, inputImage.height,
      //     originalImage.width, originalImage.height, 0);

      // Send the result back
      // message.responsePort.send(person);
    }
  }
}

/// Represents an inference model.
class InferenceModel {
  final CameraImage cameraImage;
  final int interpreterAddress;
  final List<int> inputShape;
  late SendPort responsePort;

  InferenceModel(this.cameraImage, this.interpreterAddress, this.inputShape);
}
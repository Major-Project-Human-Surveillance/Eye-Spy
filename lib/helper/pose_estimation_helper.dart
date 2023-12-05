import 'dart:isolate';

import 'package:camera/camera.dart';
//import 'package:pose_animation/helper/isolate_inference.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/person.dart';
import 'isolate_inference.dart';

/// A helper class for pose estimation.
class PoseEstimationHelper {
  late final Interpreter _interpreter;
  late final Tensor _inputTensor;
  late final IsolateInference _isolateInference;

  /// Loads the pose estimation model from an asset file.
  Future<void> _loadModel() async {
    _interpreter =
        await Interpreter.fromAsset('assets/posenet_mobilenet.tflite');
    _interpreter.allocateTensors();
    _inputTensor = _interpreter.getInputTensors().first;
  }

  /// Initializes the helper by loading the model and starting the isolate inference.
  Future<void> initHelper() async {
    await _loadModel();
    _isolateInference = IsolateInference();
    await _isolateInference.start();
  }

  /// Estimates poses from the given [cameraImage].
  ///
  /// Returns a [Future] that completes with a [Person] object representing the estimated poses.
  Future<Person> estimatePoses(CameraImage cameraImage) async {
    final isolateModel =
        InferenceModel(cameraImage, _interpreter.address, _inputTensor.shape);
    ReceivePort responsePort = ReceivePort();
    _isolateInference.sendPort
        ?.send(isolateModel..responsePort = responsePort.sendPort);
    // get inference result.
    return await responsePort.first;
  }

  /// Closes the interpreter.
  void close() {
    _interpreter.close();
  }
}
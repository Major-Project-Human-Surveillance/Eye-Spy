import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../helper/pose_estimation_helper.dart';
import '../models/person.dart';
import 'overlay_view.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isProcessing = false;
  // bool _isRecording = false;
  final person = Rx<Person?>(null);
  final fps = RxDouble(0);
  final fpsList = <double>[];
  final averageFps = RxDouble(0);
  final showSkeleton = RxBool(false);
  final showPoints = RxBool(false);
  final showBox = RxBool(true);
  // final showDetails = RxBool(false);
  final autoRecording = RxBool(false);
  late final PoseEstimationHelper poseEstimationHelper;
  late CameraDescription _cameraDescription;

  /// Initializes the camera and sets up the camera controller.
  ///
  /// This method initializes the camera by selecting the camera with the back lens direction.
  /// It creates a [CameraController] with the selected camera description and sets the resolution preset to low.
  /// The audio is disabled and the image format group is set to [ImageFormatGroup.yuv420].
  /// After initializing the camera controller, it starts the image stream with the [_imageAnalysis] callback.
  /// If the widget is still mounted, it triggers a state update.
  void _initCamera() {
    _cameraDescription = widget.cameras.firstWhere(
        (element) => element.lensDirection == CameraLensDirection.back);
    _cameraController = CameraController(
        _cameraDescription, ResolutionPreset.medium,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
    _cameraController!.initialize().then((value) {
      _cameraController!.startImageStream(_imageAnalysis);
      if (mounted) setState(() {});
    });
  }

  int _frameCount = 0;
  DateTime _frameStartTime = DateTime.now();

  /// Performs image analysis on the given [cameraImage].
  ///
  /// This method estimates poses using the [poseEstimationHelper] and updates the [person] value with the detected persons.
  /// It also calculates the frames per second (fps) and updates the [fps] value accordingly.
  ///
  /// If the processing is already in progress, this method returns without performing any analysis.
  ///
  /// Note: This method should be called within a mounted widget.
  Future<void> _imageAnalysis(CameraImage cameraImage) async {
    if (_isProcessing) {
      return;
    }
    _isProcessing = true;

    final persons = await poseEstimationHelper.estimatePoses(cameraImage);
    _isProcessing = false;

    if (mounted) {
      person.value = persons;
    }

    // Calculate fps
    _frameCount++;
    final currentTime = DateTime.now();
    final elapsedTime = currentTime.difference(_frameStartTime).inMilliseconds;
    if (elapsedTime >= 1000) {
      final fpsValue = _frameCount / (elapsedTime / 1000);
      fps.value = fpsValue;
      _frameCount = 0;
      _frameStartTime = currentTime;
    }
    fpsList.add(fps.value);
    _calculateAverageFps();
  }

  // this function using config camera and init model
  _initHelper() async {
    _initCamera();
    poseEstimationHelper = PoseEstimationHelper();
    await poseEstimationHelper.initHelper();
  }



  // Calculate average fps
  void _calculateAverageFps() {
    if (fpsList.isEmpty) return;
    final sum = fpsList.reduce((a, b) => a + b);
    averageFps.value = sum / fpsList.length;
  }

  bool get isPersonDetected => (person.value?.score ?? 0.0) > minConfidence;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initHelper();
    });

    // person.listen(videoRecorder);
  }

  // videoRecorder(Person? value) async {
  //   if (isPersonDetected && autoRecording.value) {
  //     // if not recording then start recording
  //     if (!_isRecording) {
  //       _isRecording = true;
  //       // start video recording
  //       _cameraController!.startVideoRecording();
  //     }
  //   } else {
  //     // if recording then stop recording
  //     if (_isRecording && autoRecording.value) {
  //       _isRecording = false;
  //       // stop video recording
  //       final video = await _cameraController!.stopVideoRecording();
  //       // save video to gallery using path_provider
  //       final directory = await getApplicationDocumentsDirectory();
  //       final path = directory.path;
  //       final fileName = DateTime.now().toIso8601String();
  //       final filePath = '$path/$fileName.mp4';
  //       await video.saveTo(filePath);
  //       // ignore: use_build_context_synchronously
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text(
  //             "Video Saved to Gallery",
  //           ),
  //         ),
  //       );
  //     } // else do nothing
  //   }
  // }

  // // Save the image on trigger
  // Future<void> saveImage() async {
  //   if (_cameraController == null) return;
  //   final image = await _cameraController!.takePicture();
  //   // save image to gallery using path_provider
  //   final directory = await getApplicationDocumentsDirectory();
  //   final path = directory.path;
  //   final fileName = DateTime.now().toIso8601String();
  //   final filePath = '$path/$fileName.png';
  //   await image.saveTo(filePath);
  // }

  // handle app lifecycle state change (pause/resume)
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        // _cameraController?.stopVideoRecording();
        // _isRecording = false;
        _cameraController?.stopImageStream();
        break;
      case AppLifecycleState.resumed:
        if (_cameraController != null &&
            !_cameraController!.value.isStreamingImages) {
          await _cameraController!.startImageStream(_imageAnalysis);
        }
        break;
      default:
    }
  }

  // camera widget to display camera preview and person
  Widget resultWidget(context) {
    if (_cameraController == null) return Container();

    final scale = MediaQuery.of(context).size.width /
        _cameraController!.value.previewSize!.height;

    const radius = 35.0;

    return Column(
      children: [
        Stack(
          children: [
            Stack(
              children: [
                ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: CameraPreview(_cameraController!)),
                Positioned.fill(
                  child: Obx(
                    () => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isPersonDetected
                                ? Colors.red
                                : Colors.transparent,
                            width: 5,
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                        ),
                        padding: EdgeInsets.only(
                          bottom: (person.value?.score ?? 0.0) > .25 ? 20 : 0,
                        ),
                        alignment: Alignment.bottomCenter,
                        // show text if score is greater than 0.25
                        child: (person.value?.score ?? 0.0) > .25
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Person Detected',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Score: ${(person.value?.score ?? 0.0).toStringAsFixed(2)}",
                                  ),
                                ],
                              )
                            : const SizedBox()),
                  ),
                )
              ],
            ),
            Obx(
              () => person.value != null
                  ? Obx(() => CustomPaint(
                        painter: OverlayView(
                          showBox: showBox.value,
                          showSkeleton: showSkeleton.value,
                          showPoints: showPoints.value,
                          scale: scale,
                        )..updatePerson(person.value!),
                      ))
                  : Container(),
            ),
            // Create a small box to show fps and average fps on top right
            Positioned(
              top: 10,
              right: 10,
              child: Obx(
                () => Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "FPS: ${fps.value.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Avg FPS: ${averageFps.value.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Obx(
              () => Container(
                height: radius * 2,
                width: radius * 2,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(radius)),
                  border: Border.all(
                      color: isPersonDetected ? Colors.red : Colors.white,
                      width: 2),
                ),
                child: Obx(
                  () => IconButton(
                    onPressed: () {
                      autoRecording.value = !autoRecording.value;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            autoRecording.value
                                ? "Auto Recording Started"
                                : "Auto Recording Stopped",
                          ),
                        ),
                      );
                    },
                    icon: const FaIcon(FontAwesomeIcons.video),
                    color: autoRecording.value ? Colors.red : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("EyeSpy"),
          actions: [
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                    child: Obx(
                  () => SwitchListTile(
                    value: showBox.value,
                    onChanged: (val) => showBox.value = val,
                    title: const Text("Show Box"),
                  ),
                )),
                PopupMenuItem(
                    child: Obx(
                  () => SwitchListTile(
                    value: showSkeleton.value,
                    onChanged: (val) => showSkeleton.value = val,
                    title: const Text("Show Skeleton"),
                  ),
                )),
                PopupMenuItem(
                    child: Obx(
                  () => SwitchListTile(
                    value: showPoints.value,
                    onChanged: (val) => showPoints.value = val,
                    title: const Text("Show Points"),
                  ),
                )),
              ],
            )
          ],
        ),
        body: resultWidget(context),
      );

  // dispose camera
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    poseEstimationHelper.close();
    person.close();
    fps.close();
    averageFps.close();
    showSkeleton.close();
    showPoints.close();
    showBox.close();
    // showDetails.close();
    autoRecording.close();
    super.dispose();
  }
}

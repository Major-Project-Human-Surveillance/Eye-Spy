import 'package:camera/camera.dart';
import 'package:flutter/material.dart';



late final List<CameraDescription> _cameras;

/// The main entry point of the application.
/// Initializes the Flutter binding and retrieves the available cameras.
/// Runs the `MyApp` widget.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const MyApp());
}

/// The main application widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Pose Estimation',
        theme: ThemeData(useMaterial3: true),
       
      );
}
import 'package:camera/camera.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'home/home_page.dart';

late final List<CameraDescription> _cameras;

/// The main entry point of the application.
/// Initializes the Flutter binding and retrieves the available cameras.
/// Runs the `MyApp` widget.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MyApp());
}

/// The main application widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EyeSpy',
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.hippieBlue, darkIsTrueBlack: true),
        themeMode: ThemeMode.dark,
        home: MyHomePage(cameras: _cameras),
      );
}

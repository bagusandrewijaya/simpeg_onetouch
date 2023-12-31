import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:simpeg_tester/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first,
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: CameraScreen(camera: firstCamera),
    ),
  );
}

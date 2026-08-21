import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'package:yamp/home.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(400, 490),
    titleBarStyle: .hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  await windowManager.setResizable(false);
  await windowManager.setMaximizable(false);

  String? openFilePath = Platform.isWindows && args.isNotEmpty
      ? args.first
      : null;

  runApp(MyApp(openFilePath: openFilePath));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.openFilePath});

  final String? openFilePath;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorScheme: .dark(primary: Colors.white)),
      home: HomePage(openFilePath: openFilePath),
      debugShowCheckedModeBanner: false,
    );
  }
}

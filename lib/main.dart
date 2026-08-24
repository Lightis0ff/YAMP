import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'package:yamp/home.dart';
import 'package:yamp/prefs.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await windowManager.ensureInitialized();

  final customTitleBar =
      (await Prefs.getCustomTitlebar()) ?? Defaults.customTitleBar;
  final windowOptions = WindowOptions(
    size: Size(400, 490),
    titleBarStyle: customTitleBar ? .hidden : .normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  await windowManager.setResizable(false);
  await windowManager.setMaximizable(false);

  String? openFilePath = Platform.isWindows ? args.firstOrNull : null;

  runApp(MyApp(openFilePath: openFilePath));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.openFilePath});

  final String? openFilePath;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: .dark(primary: Colors.white),
        tooltipTheme: TooltipThemeData(
          waitDuration: Duration(milliseconds: 500),
          verticalOffset: 30,
        ),
      ),
      home: HomePage(openFilePath: openFilePath),
      debugShowCheckedModeBanner: false,
    );
  }
}

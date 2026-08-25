import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:window_manager/window_manager.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:media_kit/media_kit.dart';
import 'package:crypto/crypto.dart';

class CurrentMetadata {
  CurrentMetadata({required this.meta, required this.path});

  final AudioMetadata meta;
  final String path;
}

CurrentMetadata? getCurrentMetadata(Playlist playlist) {
  final uri = playlist.medias.isEmpty
      ? null
      : playlist.medias[playlist.index].uri;
  if (uri == null) return null;
  return CurrentMetadata(
    meta: readMetadata(File(uri), getImage: true),
    path: uri,
  );
}

AppBar titlebar(
  BuildContext context, {
  String title = 'YAMP',
  List<Widget>? customButtons,
}) => AppBar(
  leading: IgnorePointer(
    child: Padding(
      padding: .symmetric(vertical: 4),
      child: Image.asset('lib/assets/images/logo.png'),
    ),
  ),
  title: IgnorePointer(child: Text(title, style: TextStyle(fontSize: 15))),
  actions:
      [
            if (customButtons != null) ...(customButtons),
            IconButton(
              onPressed: () => windowManager.minimize(),
              icon: Icon(Symbols.remove),
              padding: .zero,
              style: IconButton.styleFrom(shape: LinearBorder()),
              tooltip: 'Minimize',
            ),
            IconButton(
              onPressed: () => windowManager.close(),
              icon: Icon(Symbols.close),
              padding: .zero,
              style: IconButton.styleFrom(shape: LinearBorder()),
              hoverColor: Colors.red,
              tooltip: 'Close',
            ),
          ]
          .map(
            (a) => Focus(
              descendantsAreFocusable: false,
              canRequestFocus: false,
              child: a,
            ),
          )
          .toList(),
  iconTheme: IconThemeData(size: 20),
  toolbarHeight: 27,
  titleSpacing: 0,
  centerTitle: true,
  shadowColor: Colors.black,
  elevation: 0.75,
  scrolledUnderElevation: 0.75,
  flexibleSpace: GestureDetector(
    onPanStart: (details) => windowManager.startDragging(),
  ),
  leadingWidth: 27,
);

AlertDialog styledAlertDialog(
  BuildContext context, {
  Widget? title,
  Widget? content,
  List<Widget>? actions,
}) => AlertDialog(
  title: Container(color: Colors.white10, padding: .all(10), child: title),
  titleTextStyle: Theme.of(context).textTheme.headlineSmall,
  titlePadding: .zero,
  content: content,
  contentTextStyle: Theme.of(context).textTheme.bodyLarge,
  contentPadding: .all(10),
  actions: actions,
  actionsPadding: .all(10),
  shape: RoundedRectangleBorder(borderRadius: .circular(15)),
  clipBehavior: .hardEdge,
);

String durationString(Duration duration, {bool milliseconds = false}) {
  String negativeSign = duration.isNegative ? '-' : '';
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String threeDigits(int n) => n.toString().padLeft(3, '0');
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
  String threeDigitMilliseconds = milliseconds
      ? '.${threeDigits(duration.inMilliseconds.remainder(1000).abs())}'
      : '';
  return '$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds$threeDigitMilliseconds';
}

int stringToRange(String text, int min, int max, {bool format = true}) {
  if (min >= max) {
    throw ArgumentError(
      'The minimum value must be less than the maximum value',
    );
  }

  if (text.isEmpty) return min;

  final digest = sha1
      .convert(utf8.encode(format ? text.toLowerCase().trim() : text))
      .toString()
      .substring(0, 6);
  final decimal = int.parse('0x$digest');

  return mapValue(
    decimal.toDouble(),
    0,
    16777215,
    0,
    coverColors.length - 1,
  ).toInt();
}

const coverColors = [
  Color(0xFFD40000),
  Color(0xFF0000CD),
  Color(0xFF2E8B57),
  Color(0xFFDAA520),

  Color(0xFFBDB76B),
  Color(0xFFB0E0E6),
  Color(0xFF5F9EA0),
  Color(0xFFCD853F),

  Color(0xFFFFD700),
  Color(0xFF1E90FF),
  Color(0xFF32CD32),
  Color(0xFFDC143C),
];

double mapValue(
  double value,
  double inMin,
  double inMax,
  double outMin,
  double outMax,
) {
  return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin);
}

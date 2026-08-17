import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:media_kit/media_kit.dart';

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

String printDuration(Duration duration, {bool milliseconds = false}) {
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

int stringToRange(String text, int min, int max) {
  if (min >= max) {
    throw ArgumentError(
      'The minimum value must be less than the maximum value',
    );
  }

  if (text.isEmpty) return min;

  int hash = 0;
  for (int i = 0; i < text.length; i++) {
    hash = (hash * 31) + text.codeUnitAt(i);
    hash = hash.toUnsigned(32);
  }

  int rangeSize = max - min + 1;
  return min + (hash % rangeSize);
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

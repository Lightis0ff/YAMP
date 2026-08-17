import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:yamp/utils.dart';
import 'package:yamp/vinyl.dart';

import 'image_button.dart';

class HomePage extends StatefulWidget {
  const new({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final player = Player(configuration: PlayerConfiguration(pitch: true));
  Duration _scrubAccumulator = Duration.zero;
  Timer? _scrubTimer;
  bool _wasPlayingBeforeScrub = false;

  void pickSong() async {
    final pickedFile = await FilePicker.pickFile(type: .audio);
    if (pickedFile == null || pickedFile.path == null) return;

    final file = File(pickedFile.path!);
    player.open(Media(file.path));
  }

  void _handleScrub(double deltaAngle, double angularVelocity) {
    // Base rate, boosted the faster you're spinning
    final speedBoost = 1 + (angularVelocity.abs() * 2.0).clamp(0.0, 12.0);
    final secondsPerRotation = 3.0 * speedBoost;

    final deltaMs = (deltaAngle / (2 * math.pi) * secondsPerRotation * 1000)
        .round();
    _scrubAccumulator += Duration(milliseconds: deltaMs);

    // Throttle -- don't fire seek() on every single pointer-move frame
    _scrubTimer ??= Timer(const Duration(milliseconds: 40), () {
      final position = player.state.position + _scrubAccumulator;
      final duration = player.state.duration;
      final clamped = position < Duration.zero
          ? Duration.zero
          : (position > duration ? duration : position);
      player.seek(clamped);
      _scrubAccumulator = Duration.zero;
      _scrubTimer = null;
    });
  }

  void _handleScrubStart() {
    _wasPlayingBeforeScrub = player.state.playing;
    player.pause();
  }

  void _handleScrubEnd() {
    if (_wasPlayingBeforeScrub) player.play();
  }

  @override
  void dispose() async {
    await player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('YAMP', style: TextStyle(fontSize: 17)),
      //   actions: [
      //     IconButton(
      //       onPressed: () {},
      //       icon: Icon(Icons.remove),
      //       visualDensity: .new(horizontal: -4),
      //     ),
      //     IconButton(
      //       onPressed: () {},
      //       icon: Icon(Icons.close),
      //       visualDensity: .new(horizontal: -4),
      //       hoverColor: Colors.red,
      //     ),
      //   ],
      //   iconTheme: IconThemeData(size: 20),
      //   leading: Padding(
      //     padding: .symmetric(vertical: 5),
      //     child: Image.asset('lib/assets/images/base.png'),
      //   ),
      //   toolbarHeight: 35,
      //   titleSpacing: 0,
      //   centerTitle: true,
      //   shadowColor: Colors.black,
      //   elevation: 0.75,
      // ),
      body:
          // Container(
          //   decoration: BoxDecoration(
          //     image: DecorationImage(
          //       image: AssetImage('lib/assets/images/background.jpg'),
          //       repeat: .repeat,
          //     ),
          //   ),
          //   child:
          StreamBuilder(
            stream: player.stream.playing,
            initialData: player.state.playing,
            builder: (context, playingSnap) {
              final isPlaying = playingSnap.data ?? false;
              return StreamBuilder(
                stream: player.stream.playlist,
                builder: (context, playlistSnap) {
                  final playlist = playlistSnap.data;
                  final currentMetadata = getCurrentMetadata(
                    playlist ?? Playlist([]),
                  );
                  final meta = currentMetadata?.meta;
                  final path = currentMetadata?.path;
                  final title = path != null
                      ? meta?.title ?? p.basename(path)
                      : null;
                  return Padding(
                    padding: .all(5),
                    child: Center(
                      child: Column(
                        mainAxisSize: .min,
                        spacing: 10,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: .circular(5),
                                  ),
                                  padding: .symmetric(
                                    horizontal: 7,
                                    vertical: 5,
                                  ),
                                  child: Column(
                                    spacing: 3,
                                    children: [
                                      Text(
                                        '${title ?? 'No file selected'}${meta?.artist != null ? ' - ${meta!.artist}' : ''}',
                                        style: TextStyle(
                                          fontFamily: 'Pixel 12x10',
                                          color: Color(0xFFEEEEEE),
                                        ),
                                        textAlign: .center,
                                        maxLines: 1,
                                        overflow: .ellipsis,
                                      ),
                                      RepaintBoundary(
                                        child: StreamBuilder(
                                          stream: player.stream.position,
                                          initialData: Duration.zero,
                                          builder: (context, posSnap) {
                                            final position =
                                                posSnap.data ?? Duration.zero;
                                            final duration =
                                                player.state.duration;
                                            return LinearProgressIndicator(
                                              color: Color(0xFFEEEEEE),
                                              backgroundColor:
                                                  Colors.transparent,
                                              minHeight: 1.5,
                                              value:
                                                  position.inMilliseconds /
                                                  (duration.inMilliseconds != 0
                                                      ? duration.inMilliseconds
                                                      : 1),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          RepaintBoundary(
                            child:
                                // Stack(
                                //   alignment: .center,
                                //   children: [
                                //     StreamBuilder(
                                //       stream: player.stream.position,
                                //       initialData: Duration.zero,
                                //       builder: (context, posSnap) {
                                //         final position = posSnap.data ?? Duration.zero;
                                //         final duration = player.state.duration;
                                //         return CircularProgressIndicator(
                                //           value:
                                //               position.inMilliseconds /
                                //               (duration.inMilliseconds != 0
                                //                   ? duration.inMilliseconds
                                //                   : 1),
                                //           constraints: BoxConstraints(
                                //             minWidth: 335,
                                //             minHeight: 335,
                                //           ),
                                //           color: Colors.amber,
                                //         );
                                //       },
                                //     ),
                                Padding(
                                  padding: .symmetric(horizontal: 20),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: VinylDisc(
                                      isPlaying: isPlaying,
                                      onScrub: _handleScrub,
                                      onScrubStart: _handleScrubStart,
                                      onScrubEnd: _handleScrubEnd,
                                      coverColor: title != null
                                          ? coverColors[stringToRange(
                                              title.trim().toLowerCase(),
                                              0,
                                              coverColors.length - 1,
                                            )]
                                          : null,
                                    ),
                                  ),
                                ),
                            //   ],
                            // ),
                          ),
                          Row(
                            spacing: 1,
                            children: [
                              ImageButton(
                                onPressed: isPlaying
                                    ? null
                                    : () => player.play(),
                                buttonName: 'play',
                                isSelected: isPlaying,
                              ),
                              ImageButton(
                                onPressed: isPlaying
                                    ? () => player.pause()
                                    : null,
                                buttonName: 'pause',
                                isSelected: !isPlaying,
                              ),
                              ImageButton(
                                onPressed: () => player.stop(),
                                buttonName: 'stop',
                              ),
                              Spacer(),
                              StreamBuilder(
                                stream: player.stream.position,
                                builder: (context, posSnap) {
                                  final pos = posSnap.data ?? Duration.zero;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF88AD36), //Colors.black
                                      borderRadius: .circular(5),
                                    ),
                                    padding: .symmetric(
                                      horizontal: 5,
                                      vertical: 3,
                                    ),
                                    child: Text(
                                      printDuration(pos),
                                      style: TextStyle(
                                        fontFamily: 'Seven Segment',
                                        fontSize: 18,
                                        color: Color(
                                          0xFF081819,
                                        ), //Color(0xFFEEEEEE)
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 1.5,
                                            color: Color(0x63081819),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: 3),
                              ImageButton(
                                onPressed: pickSong,
                                buttonName: 'folder',
                                borderRadius: 12,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
    );
  }
}

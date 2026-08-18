import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:media_kit/media_kit.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:yamp/utils.dart';
import 'package:yamp/vinyl.dart';

import 'image_button.dart';

class TopMessage {
  const new(
    this.text, {
    this.duration = const Duration(seconds: 3),
    this.color,
  });

  final String text;
  final Duration duration;
  final Color? color;
}

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
  bool? _wasPlayingBeforeFForward;

  bool _dragAndDrop = false;
  Offset _dropPosition = Offset.zero;
  TopMessage? topMessage;

  void pickFile() async {
    final pickedFile = await FilePicker.pickFile(type: .audio);
    if (pickedFile == null || pickedFile.path == null) return;

    setSong(pickedFile.path!);
  }

  void setSong(String path) {
    final file = File(path);
    if (!supportedFileExtensions.contains(p.extension(path))) {
      showTopMessage(
        TopMessage('Unsupported file type', color: Color(0xFFD40000)),
      );
      return;
    }

    player.open(Media(file.path));
  }

  Future<void> showTopMessage(TopMessage message) async {
    setState(() => topMessage = message);
    await Future.delayed(message.duration);
    setState(() => topMessage = null);
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
          Stack(
            children: [
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
                      final coverPicture =
                          meta?.pictures != null && meta!.pictures.isNotEmpty
                          ? meta.pictures[0]
                          : null;
                      return Padding(
                        padding: .all(5),
                        child: Center(
                          child: Column(
                            mainAxisSize: .min,
                            spacing: 10,
                            children: [
                              _titleAndProgressbar(title, meta),
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
                                    Stack(
                                      alignment: .bottomRight,
                                      children: [
                                        StreamBuilder(
                                          stream: player.stream.rate,
                                          initialData: 1.0,
                                          builder: (context, rateSnap) {
                                            final rate = rateSnap.data ?? 1.0;
                                            return Padding(
                                              padding: .symmetric(
                                                horizontal: 20,
                                              ),
                                              child: AspectRatio(
                                                aspectRatio: 1,
                                                child: VinylDisc(
                                                  isPlaying: isPlaying,
                                                  onScrub: _handleScrub,
                                                  onScrubStart:
                                                      _handleScrubStart,
                                                  onScrubEnd: _handleScrubEnd,
                                                  coverColor: title != null
                                                      ? coverColors[stringToRange(
                                                          title
                                                              .trim()
                                                              .toLowerCase(),
                                                          0,
                                                          coverColors.length -
                                                              1,
                                                        )]
                                                      : null,
                                                  rate: rate,
                                                  // coverPicture: coverPicture,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        // Positioned(
                                        //   right: 0,
                                        //   top: 0,
                                        //   child: _playhead(isPlaying),
                                        // ),
                                        StreamBuilder(
                                          stream: player.stream.volume,
                                          initialData: 100.0,
                                          builder: (context, volumeSnap) {
                                            final volume =
                                                volumeSnap.data ?? 100.0;
                                            return _volumeControls(
                                              volume.toInt(),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                //   ],
                                // ),
                              ),
                              _bottomRow(isPlaying),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              dragAndDrop(),
            ],
          ),
    );
  }

  Widget dragAndDrop() {
    return DropTarget(
      onDragEntered: (details) => setState(() => _dragAndDrop = true),
      onDragExited: (details) => setState(() => _dragAndDrop = false),
      onDragUpdated: (details) =>
          setState(() => _dropPosition = details.localPosition),
      onDragDone: (details) => setSong(details.files[0].path),
      child: IgnorePointer(
        // child:
        //     DottedBorder(
        //           options: RoundedRectDottedBorderOptions(
        //             radius: .circular(5),
        //             color: Colors.blue,
        //             strokeWidth: 5,
        //             borderPadding: .all(8),
        //             dashPattern: [15],
        //           ),
        child:
            Stack(
                  children: [
                    Positioned(
                      // TODO: Make the image centered automatically
                      // instead of fixed offset
                      left: _dropPosition.dx - 73,
                      top: _dropPosition.dy - 73,
                      child: Column(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black38,
                                  offset: Offset(0, 5),
                                  blurRadius: 7,
                                ),
                              ],
                              shape: .circle,
                            ),
                            child: Stack(
                              alignment: .center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: coverColors[0],
                                    shape: .circle,
                                  ),
                                  width: 50,
                                  height: 50,
                                ),
                                Image.asset(
                                  'lib/assets/images/base.png',
                                  scale: 7,
                                ),
                              ],
                            ),
                          ),
                          Text('Drop to open file', textAlign: .center),
                        ],
                      ),
                    ),
                  ],
                )
                // )
                .animate(target: _dragAndDrop ? 1 : 0)
                .fade(duration: Duration(milliseconds: 170)),
      ),
    );
  }

  Widget _titleAndProgressbar(String? title, AudioMetadata? meta) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: .circular(5),
            ),
            padding: .symmetric(horizontal: 7, vertical: 5),
            child: Column(
              spacing: 3,
              children: [
                TextScroll(
                  topMessage?.text ??
                      '${title ?? 'No file selected'}${meta?.artist != null ? ' - ${meta!.artist}' : ''}',
                  style: TextStyle(
                    fontFamily: 'Pixel 12x10',
                    color: topMessage?.color ?? Color(0xFFEEEEEE),
                  ),
                  textAlign: .center,
                  velocity: Velocity(pixelsPerSecond: Offset(30, 0)),
                  intervalSpaces: 8,
                  pauseBetween: Duration(seconds: 2),
                  fadedBorder: true,
                  fadedBorderWidth: 0.05,
                  fadeBorderSide: .right,
                  selectable: true,
                ),
                RepaintBoundary(
                  child: StreamBuilder(
                    stream: player.stream.position,
                    initialData: Duration.zero,
                    builder: (context, posSnap) {
                      final position = posSnap.data ?? Duration.zero;
                      final duration = player.state.duration;
                      return LinearProgressIndicator(
                        color: Color(0xFFEEEEEE),
                        backgroundColor: Colors.transparent,
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
    );
  }

  Widget _playhead(bool isPlaying) {
    return Transform.translate(
      offset: Offset(10, -15),
      child: Image.asset('lib/assets/images/playhead.png', scale: 2)
          .animate(target: isPlaying ? 1 : 0)
          .custom(
            duration: Duration(milliseconds: 250),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 0.3 - 0.3,
                origin: Offset(9, -150) / 2,
                child: child,
              );
            },
          ),
    );
  }

  Widget _volumeControls(int volume) {
    void setVolume(num v) {
      v = v.clamp(0, 100);
      player.setVolume(v.toDouble());
    }

    return Column(
      crossAxisAlignment: .end,
      children: [
        HoldImageButton(
          buttonName: 'volumeUp',
          onHold: () => setVolume(volume + 2),
          scale: 7,
          padding: false,
        ),
        Row(
          mainAxisSize: .min,
          children: [
            HoldImageButton(
              buttonName: 'volumeDown',
              onHold: () => setVolume(volume - 2),
              scale: 7,
              padding: false,
            ),
            RepaintBoundary(
              child: Container(
                width: 40,
                padding: .only(left: 2),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: .circular(4),
                  ),
                  padding: .fromLTRB(0, 2, 4, 2),
                  child: Text(
                    volume.toString(),
                    style: TextStyle(
                      fontFamily: 'Seven Segment',
                      color: Color(0xFFE0E0E0),
                    ),
                    textAlign: .end,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bottomRow(bool isPlaying) {
    return Row(
      spacing: 1,
      children: [
        ImageButton(
          onPressed: isPlaying ? null : () => player.play(),
          buttonName: 'play',
          isSelected: isPlaying,
        ),
        HoldImageButton(
          buttonName: 'fastForward',
          onHold: () {
            _wasPlayingBeforeFForward ??= isPlaying;
            if (!isPlaying) player.play();
            player.setRate(2.5);
            player.setPitch(1.4);
          },
          onCancel: () {
            if (_wasPlayingBeforeFForward == false) player.pause();
            player.setRate(1);
            player.setPitch(1);
            _wasPlayingBeforeFForward = null;
          },
          onPressed: () {},
        ),
        ImageButton(
          onPressed: isPlaying ? () => player.pause() : null,
          buttonName: 'pause',
          isSelected: !isPlaying,
        ),
        ImageButton(onPressed: () => player.stop(), buttonName: 'stop'),
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
              padding: .symmetric(horizontal: 5, vertical: 3),
              child: Text(
                printDuration(pos),
                style: TextStyle(
                  fontFamily: 'Seven Segment',
                  fontSize: 18,
                  color: Color(0xFF081819), //Color(0xFFEEEEEE)
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
          onPressed: pickFile,
          buttonName: 'folder',
          borderRadius: 12,
        ),
      ],
    );
  }
}

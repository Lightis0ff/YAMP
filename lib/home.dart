import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:media_kit/media_kit.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:yamp/prefs.dart';
import 'package:yamp/settings.dart';
import 'package:yamp/utils.dart';
import 'package:yamp/vinyl.dart';

import 'image_button.dart';

enum TopMessageType {
  normal(Color(0xFFEEEEEE)),
  success(Color(0xFF00FF00)),
  error(Color(0xFFD40000));

  const TopMessageType(this.color);
  final Color color;
}

class TopMessage {
  const new(
    this.text, {
    this.duration = const Duration(seconds: 3),
    this.type = .normal,
  });

  final String text;
  final Duration duration;
  final TopMessageType type;
}

class HomePage extends StatefulWidget {
  const new({super.key, required this.openFilePath});

  final String? openFilePath;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final player = Player(configuration: PlayerConfiguration(pitch: true));
  Duration _scrubAccumulator = Duration.zero;
  Timer? _scrubTimer;
  bool _wasPlayingBeforeScrub = false;
  bool? _wasPlayingBeforeFForward;

  bool _isScrubbing = false;
  bool _dragAndDrop = false;
  Offset _dropPosition = Offset.zero;
  TopMessage? _topMessage;
  Timer? _topMessageTimer;

  var showFForwardButton = Defaults.showFForwardButton;
  var fastForwardSpeed = Defaults.fastForwardSpeed;
  var fastForwardPitch = Defaults.fastForwardPitch;
  var customTitleBar = Defaults.customTitleBar;

  void _pickFile() async {
    final pickedFile = await FilePicker.pickFile(type: .audio);
    if (pickedFile == null || pickedFile.path == null) return;

    _setSong(pickedFile.path!);
  }

  void _setSong(String path) {
    try {
      final file = File(path);
      if (!supportedFileExtensions.contains(p.extension(path))) {
        _showTopMessage(TopMessage('Unsupported file type', type: .error));
        return;
      }
      player.open(Media(file.path));
    } catch (e) {
      _showTopMessage(TopMessage('Error', type: .error));
      return;
    }
  }

  Future<void> _showTopMessage(TopMessage message) async {
    setState(() => _topMessage = message);
    // Timer(message.duration, () => setState(() => _topMessage = null));
    _topMessageTimer?.cancel();
    _topMessageTimer = Timer(
      message.duration,
      () => setState(() => _topMessage = null),
    );
  }

  @override
  void initState() {
    ServicesBinding.instance.keyboard.addHandler(_onKeyPress);
    if (widget.openFilePath != null && widget.openFilePath!.isNotEmpty) {
      _setSong(widget.openFilePath!);
    }
    _getSettings();
    super.initState();
  }

  Future<void> _getSettings() async {
    final sffb = await Prefs.getShowFForwardButton();
    final ffs = await Prefs.getFastForwardSpeed();
    final ffp = await Prefs.getFastForwardPitch();
    final ctb = await Prefs.getCustomTitlebar();
    setState(() {
      showFForwardButton = sffb ?? showFForwardButton;
      fastForwardSpeed = ffs ?? fastForwardSpeed;
      fastForwardPitch = ffp ?? fastForwardPitch;
      customTitleBar = ctb ?? customTitleBar;
    });
    _syncDefaultAudioDevice(player.state.audioDevices);

    player.stream.audioDevices.listen(
      (event) => _syncDefaultAudioDevice(event),
    );
  }

  Future<void> _syncDefaultAudioDevice(List<AudioDevice> devices) async {
    final dad = await Prefs.getDefaultAudioDevice();
    player.setAudioDevice(
      devices.firstWhere((d) => d.name == dad, orElse: () => .auto()),
    );
  }

  Future<void> openSettings(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) =>
          Dialog.fullscreen(child: SettingsTab(player: player)),
    );
    await _getSettings();
  }

  bool _onKeyPress(KeyEvent event) {
    final key = event.logicalKey;

    void seek(int seconds) {
      _seekClamped(
        player.state.position + Duration(seconds: seconds),
        player.state.duration,
      );
    }

    if (event is KeyDownEvent) {
      if (key == .space && !_isScrubbing) {
        player.playOrPause();
      } else if (key == .arrowUp) {
        _setVolume(player.state.volume + 2);
      } else if (key == .arrowDown) {
        _setVolume(player.state.volume - 2);
      } else if (key == .arrowLeft) {
        seek(-10);
      } else if (key == .arrowRight) {
        seek(10);
      }
    } else if (event is KeyRepeatEvent) {
      if (key == .arrowUp) {
        _setVolume(player.state.volume + 2);
      } else if (key == .arrowDown) {
        _setVolume(player.state.volume - 2);
      } else if (key == .arrowLeft) {
        seek(-10);
      } else if (key == .arrowRight) {
        seek(10);
      }
    }

    return false;
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
      _seekClamped(position, duration);
      _scrubAccumulator = Duration.zero;
      _scrubTimer = null;
    });
  }

  void _seekClamped(Duration position, Duration duration) {
    final clamped = position < Duration.zero
        ? Duration.zero
        : (position > duration ? duration : position);
    player.seek(clamped);
  }

  void _handleScrubStart() {
    _wasPlayingBeforeScrub = player.state.playing;
    player.pause();
    _isScrubbing = true;
  }

  void _handleScrubEnd() {
    if (_wasPlayingBeforeScrub) player.play();
    _isScrubbing = false;
  }

  @override
  void dispose() async {
    await player.dispose();
    ServicesBinding.instance.keyboard.removeHandler(_onKeyPress);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customTitleBar
          ? titlebar(
              context,
              customButtons: [
                IconButton(
                  onPressed: () => openSettings(context),
                  icon: Icon(Symbols.more_horiz, weight: 600),
                  padding: .zero,
                  style: IconButton.styleFrom(shape: LinearBorder()),
                  tooltip: 'Settings',
                ),
              ],
            )
          : null,
      body: Stack(
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
                  CurrentMetadata? currentMetadata;
                  try {
                    currentMetadata = getCurrentMetadata(
                      playlist ?? Playlist([]),
                    );
                  } catch (e) {
                    _showTopMessage(
                      TopMessage('Error reading metadata', type: .error),
                    );
                  }
                  final meta = currentMetadata?.meta;
                  final path = currentMetadata?.path;
                  final title = path != null
                      ? meta?.title ?? p.basename(path)
                      : null;
                  // final coverPicture =
                  //     meta?.pictures != null && meta!.pictures.isNotEmpty
                  //     ? meta.pictures.first
                  //     : null;
                  return Padding(
                    padding: .all(5),
                    child: Center(
                      child: Column(
                        mainAxisSize: .min,
                        spacing: 10,
                        children: [
                          _titleAndProgressbar(title, meta),
                          RepaintBoundary(
                            child: Stack(
                              alignment: .bottomRight,
                              children: [
                                StreamBuilder(
                                  stream: player.stream.rate,
                                  initialData: 1.0,
                                  builder: (context, rateSnap) {
                                    final rate = rateSnap.data ?? 1.0;
                                    return _discContainer(
                                      isPlaying,
                                      title,
                                      rate,
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
                                    final volume = volumeSnap.data ?? 100.0;
                                    return _volumeControls(volume.toInt());
                                  },
                                ),
                                if (!customTitleBar)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: ImageButton(
                                      onPressed: () => openSettings(context),
                                      buttonName: 'settings',
                                      tooltip: 'Settings',
                                    ),
                                  ),
                              ],
                            ),
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
      onDragDone: (details) => _setSong(details.files.first.path),
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
                                    color: coverColors.first,
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
            constraints: BoxConstraints(maxHeight: 36.5),
            padding: .symmetric(horizontal: 7, vertical: 5),
            child: Column(
              spacing: 3,
              children: [
                TextScroll(
                  _topMessage?.text ??
                      '${title ?? 'No file selected'}${meta?.artist != null ? ' - ${meta!.artist}' : ''}',
                  style: TextStyle(
                    fontFamily: 'Pixel 12x10',
                    color: _topMessage?.type.color ?? Color(0xFFEEEEEE),
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

  // Widget _playhead(bool isPlaying) {
  //   return Transform.translate(
  //     offset: Offset(10, -15),
  //     child: Image.asset('lib/assets/images/playhead.png', scale: 2)
  //         .animate(target: isPlaying ? 1 : 0)
  //         .custom(
  //           duration: Duration(milliseconds: 250),
  //           builder: (context, value, child) {
  //             return Transform.rotate(
  //               angle: value * 0.3 - 0.3,
  //               origin: Offset(9, -150) / 2,
  //               child: child,
  //             );
  //           },
  //         ),
  //   );
  // }

  Widget _discContainer(bool isPlaying, String? title, double rate) {
    return Padding(
      padding: .symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: 1,
        child: VinylDisc(
          isPlaying: isPlaying,
          onScrub: _handleScrub,
          onScrubStart: _handleScrubStart,
          onScrubEnd: _handleScrubEnd,
          coverColor: title != null
              ? coverColors[stringToRange(title, 0, coverColors.length - 1)]
              : null,
          rate: rate,
          // coverPicture: coverPicture,
        ),
      ),
    );
  }

  void _setVolume(num v) {
    v = v.clamp(0, 100);
    player.setVolume(v.toDouble());
  }

  Widget _volumeControls(int volume) {
    return Column(
      crossAxisAlignment: .end,
      children: [
        HoldImageButton(
          buttonName: 'volumeUp',
          onHold: () => _setVolume(volume + 2),
          scale: 7,
          padding: false,
          tooltip: 'Volume up',
        ),
        Row(
          mainAxisSize: .min,
          children: [
            HoldImageButton(
              buttonName: 'volumeDown',
              onHold: () => _setVolume(volume - 2),
              scale: 7,
              padding: false,
              tooltip: 'Volume down',
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
          tooltip: 'Play',
        ),
        if (showFForwardButton)
          HoldImageButton(
            buttonName: 'fastForward',
            tooltip: 'Fast forward',
            onHold: () {
              _wasPlayingBeforeFForward ??= isPlaying;
              if (!isPlaying) player.play();
              player.setRate(fastForwardSpeed);
              player.setPitch(fastForwardPitch);
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
          tooltip: 'Pause',
        ),
        ImageButton(
          onPressed: () => player.stop(),
          buttonName: 'stop',
          tooltip: 'Stop',
        ),
        Spacer(),
        StreamBuilder(
          stream: player.stream.position,
          builder: (context, posSnap) {
            final pos = posSnap.data ?? Duration.zero;
            return Container(
              decoration: BoxDecoration(
                color: Color(0xFF88AD36),
                borderRadius: .circular(5),
              ),
              padding: .symmetric(horizontal: 5, vertical: 3),
              child: Text(
                durationString(pos),
                style: TextStyle(
                  fontFamily: 'Seven Segment',
                  fontSize: 18,
                  color: Color(0xFF081819),
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
          onPressed: _pickFile,
          buttonName: 'folder',
          borderRadius: 12,
          tooltip: 'Select file',
        ),
      ],
    );
  }
}

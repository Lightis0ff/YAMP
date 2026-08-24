import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:holding_gesture/holding_gesture.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:media_kit/media_kit.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yamp/prefs.dart';
import 'package:yamp/utils.dart';

class SettingsCategory {
  const new({required this.name, required this.icon, required this.children});
  final String name;
  final IconData icon;
  final List<SettingsButton> children;
}

class SettingsTab extends StatefulWidget {
  const new({super.key, required this.player});

  final Player player;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final itemScrollController = ItemScrollController();
  final itemPositionsListener = ItemPositionsListener.create();

  var defaultAudioDevice = Defaults.defaultAudioDevice;
  var showFForwardButton = Defaults.showFForwardButton;
  var fastForwardSpeed = Defaults.fastForwardSpeed;
  var fastForwardPitch = Defaults.fastForwardPitch;
  var customTitleBar = Defaults.customTitleBar;

  List<SettingsCategory> get categories => [
    SettingsCategory(
      name: 'Playback',
      icon: Symbols.play_circle,
      children: [
        SettingsDropdownButton(
          label: 'Audio device',
          defaultValue: Defaults.defaultAudioDevice.name,
          items: widget.player.state.audioDevices
              .map(
                (d) => DropdownMenuItem(
                  value: d.name,
                  child: Tooltip(
                    message: d.description,
                    waitDuration: Duration(milliseconds: 100),
                    child: Text(d.description),
                  ),
                ),
              )
              .toList(),
          value: defaultAudioDevice.name,
          onChanged: (value) async {
            await Prefs.setDefaultAudioDevice(value);
            final device = widget.player.state.audioDevices.firstWhere(
              (d) => d.name == value,
              orElse: () => .auto(),
            );
            setState(() => defaultAudioDevice = device);
          },
        ),
        SettingsSwitch(
          label: 'Show fast forward button',
          defaultValue: Defaults.showFForwardButton,
          value: showFForwardButton,
          onChanged: (value) async {
            await Prefs.setShowFForwardButton(value);
            setState(() => showFForwardButton = value);
          },
        ),
        SettingsNumberSelector(
          label: 'Fast forward speed multiplier',
          defaultValue: Defaults.fastForwardSpeed,
          value: fastForwardSpeed,
          step: 0.1,
          precision: 2,
          min: 0.1,
          max: 10.0,
          onChange: (value) async {
            await Prefs.setFastForwardSpeed(value.toDouble());
            setState(() => fastForwardSpeed = value.toDouble());
          },
          onHold: (value) =>
              setState(() => fastForwardSpeed = value.toDouble()),
        ),
        SettingsNumberSelector(
          label: 'Fast forward pitch multiplier',
          defaultValue: Defaults.fastForwardPitch,
          value: fastForwardPitch,
          step: 0.1,
          precision: 2,
          min: 1.0,
          max: 10.0,
          onChange: (value) async {
            await Prefs.setFastForwardPitch(value.toDouble());
            setState(() => fastForwardPitch = value.toDouble());
          },
          onHold: (value) =>
              setState(() => fastForwardPitch = value.toDouble()),
        ),
      ],
    ),
    SettingsCategory(
      name: 'Window',
      icon: Symbols.ad,
      children: [
        SettingsSwitch(
          label: 'Custom titlebar',
          defaultValue: Defaults.customTitleBar,
          value: customTitleBar,
          onChanged: (value) async {
            await Prefs.setCustomTitlebar(value);
            await windowManager.setTitleBarStyle(value ? .hidden : .normal);
            setState(() => customTitleBar = value);
          },
        ),
      ],
    ),
  ];

  @override
  void initState() {
    ServicesBinding.instance.keyboard.addHandler(_onKeyPress);
    () async {
      final dad = await Prefs.getDefaultAudioDevice();
      final sffb = await Prefs.getShowFForwardButton();
      final ffs = await Prefs.getFastForwardSpeed();
      final ffp = await Prefs.getFastForwardPitch();
      final ctb = await Prefs.getCustomTitlebar();
      setState(() {
        defaultAudioDevice = widget.player.state.audioDevices.firstWhere(
          (d) => d.name == dad,
          orElse: () => .auto(),
        );
        showFForwardButton = sffb ?? showFForwardButton;
        fastForwardSpeed = ffs ?? fastForwardSpeed;
        fastForwardPitch = ffp ?? fastForwardPitch;
        customTitleBar = ctb ?? customTitleBar;
      });
    }();
    super.initState();
  }

  bool _onKeyPress(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == .escape) {
      if (FocusScope.of(context).hasFocus) {
        FocusScope.of(context).unfocus();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
    return false;
  }

  @override
  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(_onKeyPress);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customTitleBar
          ? titlebar(
              context,
              title: 'YAMP / Settings',
              customButtons: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Symbols.arrow_back),
                  padding: .zero,
                  style: IconButton.styleFrom(shape: LinearBorder()),
                  tooltip: 'Back',
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: ScrollablePositionedList.separated(
              itemScrollController: itemScrollController,
              itemPositionsListener: itemPositionsListener,
              padding: .all(10),
              itemCount: categories.length + 1,
              itemBuilder: (context, idx) {
                if (idx == 0) {
                  return ValueListenableBuilder(
                    valueListenable: itemPositionsListener.itemPositions,
                    builder: (context, value, _) =>
                        _categorySelector(context, value),
                  );
                }
                final cat = categories.elementAt(idx - 1);
                return Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Icon(cat.icon),
                        Text(
                          cat.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    ...cat.children,
                  ],
                );
              },
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.white12),
            ),
          ),
        ],
      ),
    );
  }

  int getFirstVisibleItem(Iterable<ItemPosition> positions) => positions
      .where((ItemPosition position) => position.itemTrailingEdge > 0)
      .reduce(
        (ItemPosition min, ItemPosition position) =>
            position.itemTrailingEdge < min.itemTrailingEdge ? position : min,
      )
      .index;
  int getLastVisibleItem(Iterable<ItemPosition> positions) => positions
      .where((ItemPosition position) => position.itemLeadingEdge < 1)
      .reduce(
        (ItemPosition max, ItemPosition position) =>
            position.itemLeadingEdge > max.itemLeadingEdge ? position : max,
      )
      .index;

  Widget _categorySelector(
    BuildContext context,
    Iterable<ItemPosition> itemPositions,
  ) {
    final min = itemPositions.isNotEmpty
        ? getFirstVisibleItem(itemPositions) + 1
        : -1;
    final max = itemPositions.isNotEmpty
        ? getLastVisibleItem(itemPositions) + 1
        : -1;
    return Padding(
      padding: .symmetric(horizontal: 3),
      child: Wrap(
        spacing: 5,
        runSpacing: 7,
        alignment: .center,
        children: [
          if (!customTitleBar)
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: CupertinoColors.systemBrown,
                padding: .symmetric(horizontal: 5),
                visualDensity: VisualDensity(vertical: -4),
                enabledMouseCursor: SystemMouseCursors.click,
              ),
              icon: Icon(Symbols.arrow_back, color: Colors.white, size: 14),
              label: Text(
                'Back',
                style: Theme.of(context).textTheme.titleSmall!
                    .merge(TextStyle(color: Colors.white)),
              ),
            ),
          ...categories.map((cat) {
            final idx =
                categories.map((c) => c.name).toList().indexOf(cat.name) + 1;
            final visible = idx >= min && idx <= max;
            return ElevatedButton(
              onPressed: () => itemScrollController.scrollTo(
                index: idx,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: visible
                    ? Color(0xFFC0C0C0)
                    : Color(0xFF262626),
                padding: .symmetric(horizontal: 5),
                visualDensity: VisualDensity(vertical: -4),
                enabledMouseCursor: SystemMouseCursors.click,
              ),
              child: Text(
                cat.name,
                style: Theme.of(context).textTheme.titleSmall!.merge(
                  TextStyle(color: visible ? Colors.black : Color(0xFF8F8F8F)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

abstract class SettingsButton extends StatelessWidget {
  const new({super.key, required this.label, required this.defaultValue});
  final String label;
  final dynamic defaultValue;
}

class SettingsSwitch extends SettingsButton {
  const new({
    super.key,
    required super.label,
    required super.defaultValue,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => onChanged(!value),
      style: TextButton.styleFrom(
        shape: LinearBorder(
          start: LinearBorderEdge(),
          side: BorderSide(
            color: value != defaultValue
                ? CupertinoColors.systemBrown
                : Colors.transparent,
            width: 2,
          ),
        ),
        padding: .fromLTRB(6, 8, 0, 8),
      ),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        spacing: 10,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Transform.scale(
            scale: 0.9,
            child: CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: CupertinoColors.systemBrown,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsNumberSelector extends SettingsButton {
  const new({
    super.key,
    required super.label,
    required super.defaultValue,
    required this.value,
    this.step = 1,
    this.precision = 0,
    required this.onHold,
    required this.onChange,
    this.min,
    this.max,
  });

  final num value;
  final num step;
  final int precision;
  final void Function(num value) onHold;
  final void Function(num value) onChange;
  final num? min;
  final num? max;

  num toPrecisionAndClamp(num n) {
    n = num.parse(n.toStringAsPrecision(precision));
    if (min != null && n < min!) n = min!;
    if (max != null && n > max!) n = max!;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: .fromLTRB(
          left: BorderSide(
            color: value != defaultValue
                ? CupertinoColors.systemBrown
                : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      padding: .symmetric(horizontal: 5, vertical: 10),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        spacing: 10,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Row(
            spacing: 5,
            children: [
              HoldDetector(
                holdTimeout: Duration(milliseconds: 170),
                onHold: () => onHold(toPrecisionAndClamp(value - step)),
                onCancel: () => onChange(toPrecisionAndClamp(value - step)),
                onTap: () => onChange(toPrecisionAndClamp(value - step)),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(Symbols.keyboard_arrow_down),
                  padding: .zero,
                  visualDensity: .compact,
                ),
              ),
              Text(value.toString()),
              HoldDetector(
                holdTimeout: Duration(milliseconds: 170),
                onHold: () => onHold(toPrecisionAndClamp(value + step)),
                onCancel: () => onChange(toPrecisionAndClamp(value + step)),
                onTap: () => onChange(toPrecisionAndClamp(value + step)),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(Symbols.keyboard_arrow_up),
                  padding: .zero,
                  visualDensity: .compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsDropdownButton extends SettingsButton {
  const new({
    super.key,
    required super.label,
    required super.defaultValue,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final List<DropdownMenuItem> items;
  final dynamic value;
  final Function(dynamic value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: .fromLTRB(
          left: BorderSide(
            color: value != defaultValue
                ? CupertinoColors.systemBrown
                : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      padding: .fromLTRB(6, 8, 3, 8),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        spacing: 10,
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Expanded(
            flex: 2,
            child: TextButton(
              style: TextButton.styleFrom(
                side: BorderSide(color: Colors.grey),
                shape: StadiumBorder(),
                padding: .all(8),
              ),
              onPressed: null,
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                  items: items,
                  value: value,
                  onChanged: onChanged,
                  isDense: true,
                  isExpanded: true,
                  borderRadius: .circular(8),
                  // dropdownColor: Theme.brightnessOf(context) == .light
                  //     ? colors.textDark
                  //     : colors.text,
                  icon: Icon(Icons.arrow_drop_down_rounded),
                  style: TextStyle(
                    // color: Theme.brightnessOf(context) == .light
                    //     ? colors.text
                    //     : colors.textDark,
                    fontFamily: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.fontFamily,
                    fontWeight: .w500,
                    overflow: .ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

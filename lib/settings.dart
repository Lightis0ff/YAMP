import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:holding_gesture/holding_gesture.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yamp/main.dart';
import 'package:yamp/prefs.dart';
import 'package:yamp/utils.dart';
import 'package:yamp/update.dart' as updater;

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
  final _itemScrollController = ItemScrollController();
  PackageInfo? packageInfo;

  var defaultAudioDevice = Defaults.defaultAudioDevice;
  var showFForwardButton = Defaults.showFForwardButton;
  var fastForwardSpeed = Defaults.fastForwardSpeed;
  var fastForwardPitch = Defaults.fastForwardPitch;
  var customTitleBar = Defaults.customTitleBar;
  var autoCheckUpdates = Defaults.autoCheckUpdates;

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
    SettingsCategory(
      name: 'Updates',
      icon: Symbols.update,
      children: [
        SettingsSwitch(
          label: 'Automatically check for updates',
          description: '(when opening YAMP)',
          defaultValue: Defaults.autoCheckUpdates,
          value: autoCheckUpdates,
          onChanged: (value) async {
            await Prefs.setAutoCheckUpdates(value);
            setState(() => autoCheckUpdates = value);
          },
        ),
        SettingsElevatedButton(
          label: 'Manually check for updates',
          description: 'Current version: ${packageInfo?.version ?? 'unknown'}',
          onPressed: () async {
            final updateInfo = await updater.checkForUpdate();
            if (!mounted) return;
            if (updateInfo.updateAvailable) {
              updater.showUpdateModal(context, updateInfo);
            } else {
              updater.showUpdateNotNeededModal(context);
            }
          },
          buttonText: 'Check now',
        ),
      ],
    ),
    SettingsCategory(
      name: 'Other',
      icon: Symbols.pending,
      children: [
        SettingsElevatedButton(
          label: 'Wiew GitHub repository',
          onPressed: () =>
              launchUrl(Uri.parse('https://github.com/Lightis0ff/yamp/')),
          buttonText: 'View',
          icon: Symbols.open_in_new,
          iconAlignment: .end,
        ),
        SettingsElevatedButton(
          label: 'Submit a new issue',
          onPressed: () => launchUrl(
            Uri.parse('https://github.com/Lightis0ff/yamp/issues/new/'),
          ),
          buttonText: 'Submit',
          icon: Symbols.open_in_new,
          iconAlignment: .end,
        ),
        SettingsElevatedButton(
          label: 'About YAMP',
          onPressed: () => showAdaptiveAboutDialog(
            context: context,
            applicationName: 'YAMP',
            applicationIcon: Image.asset(
              'lib/assets/images/logo.png',
              height: 36,
              width: 36,
            ),
            applicationVersion: packageInfo?.version,
            children: [
              Text('YAMP - The fancy music player.'),
              Text('Made by Lightis0ff:'),
              InkWell(
                onTap: () =>
                    launchUrl(Uri.parse('https://github.com/Lightis0ff/')),
                mouseCursor: SystemMouseCursors.click,
                child: Text(
                  'https://github.com/Lightis0ff/',
                  style: TextStyle(color: mainColor),
                ),
              ),
            ],
          ),
          buttonText: 'Show',
          icon: Symbols.info,
          iconAlignment: .end,
        ),
        SettingsElevatedButton(
          label: 'Reset all settings',
          description: 'This will close the window',
          onPressed: () async {
            if (!mounted) return;
            await SharedPreferencesAsync().clear();
            windowManager.close();
          },
          buttonText: 'Reset',
          confirmation: true,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    ServicesBinding.instance.keyboard.addHandler(_onKeyPress);
    () async {
      packageInfo = await PackageInfo.fromPlatform();

      final dad = await Prefs.getDefaultAudioDevice();
      final sffb = await Prefs.getShowFForwardButton();
      final ffs = await Prefs.getFastForwardSpeed();
      final ffp = await Prefs.getFastForwardPitch();
      final ctb = await Prefs.getCustomTitlebar();
      final acu = await Prefs.getAutoCheckUpdates();
      setState(() {
        defaultAudioDevice = widget.player.state.audioDevices.firstWhere(
          (d) => d.name == dad,
          orElse: () => .auto(),
        );
        showFForwardButton = sffb ?? showFForwardButton;
        fastForwardSpeed = ffs ?? fastForwardSpeed;
        fastForwardPitch = ffp ?? fastForwardPitch;
        customTitleBar = ctb ?? customTitleBar;
        autoCheckUpdates = acu ?? autoCheckUpdates;
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
              tab: 'Settings',
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
              itemScrollController: _itemScrollController,
              padding: .all(10),
              itemCount: categories.length + 1,
              itemBuilder: (context, idx) {
                if (idx == 0) return _categorySelector(context);
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
                    SizedBox(height: 3),
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

  Widget _categorySelector(BuildContext context) {
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
                backgroundColor: mainColor,
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
            return ElevatedButton(
              onPressed: () => _itemScrollController.scrollTo(
                index: idx,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF313131),
                padding: .symmetric(horizontal: 5),
                visualDensity: VisualDensity(vertical: -4),
                enabledMouseCursor: SystemMouseCursors.click,
              ),
              child: Text(
                cat.name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            );
          }),
        ],
      ),
    );
  }
}

abstract class SettingsButton extends StatelessWidget {
  const new({
    super.key,
    required this.label,
    this.description,
    this.defaultValue,
  });
  final String label;
  final String? description;
  final dynamic defaultValue;
}

class SettingsSwitch extends SettingsButton {
  const new({
    super.key,
    required super.label,
    super.description,
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
            color: value != defaultValue ? mainColor : Colors.transparent,
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
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyLarge),
                if (description != null)
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: mainColor,
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
    super.description,
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
            color: value != defaultValue ? mainColor : Colors.transparent,
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
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyLarge),
                if (description != null)
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
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

class SettingsElevatedButton extends SettingsButton {
  const new({
    super.key,
    required super.label,
    super.description,
    required this.onPressed,
    required this.buttonText,
    this.highlited = false,
    this.confirmation = false,
    this.icon,
    this.iconAlignment,
  });

  final void Function()? onPressed;
  final String buttonText;
  final bool highlited;
  final bool confirmation;
  final IconData? icon;
  final IconAlignment? iconAlignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: .symmetric(horizontal: 5, vertical: 10),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        spacing: 10,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyLarge),
                if (description != null)
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: confirmation
                ? () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => styledAlertDialog(
                        context,
                        title: Text('Are you sure?'),
                        actions: [
                          actionOutlineButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            text: 'Cancel',
                          ),
                          actionElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            text: 'Ok',
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && onPressed != null) onPressed!();
                  }
                : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: highlited
                  ? mainColor
                  : Theme.of(context).focusColor,
              shape: RoundedRectangleBorder(borderRadius: .circular(8)),
              visualDensity: VisualDensity(vertical: -2),
              padding: .symmetric(horizontal: 8),
            ),
            label: Text(buttonText),
            icon: icon != null ? Icon(icon) : null,
            iconAlignment: iconAlignment,
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
    super.description,
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
            color: value != defaultValue ? mainColor : Colors.transparent,
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
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyLarge),
                if (description != null)
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
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

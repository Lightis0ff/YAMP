import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:holding_gesture/holding_gesture.dart';

class ImageButton extends StatefulWidget {
  const new({
    super.key,
    required this.onPressed,
    required this.buttonName,
    this.isSelected,
    this.scale = 6,
    this.tooltip,
    this.borderRadius,
  });

  final void Function()? onPressed;
  final String buttonName;
  final bool? isSelected;
  // final String? selectedAssetName;
  final double scale;
  final String? tooltip;
  final double? borderRadius;

  @override
  State<ImageButton> createState() => _ImageButtonState();
}

class _ImageButtonState extends State<ImageButton> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      descendantsAreFocusable: false,
      canRequestFocus: false,
      child:
          IconButton(
                onPressed: widget.onPressed,
                padding: .zero,
                icon: Image.asset(
                  'lib/assets/images/buttons/${widget.buttonName}Button.png',
                  scale: widget.scale,
                ),
                isSelected: widget.isSelected,
                selectedIcon: widget.isSelected != null
                    ? Image.asset(
                        'lib/assets/images/buttons/${widget.buttonName}ButtonPressed.png',
                        scale: widget.scale,
                      )
                    : null,
                tooltip: widget.tooltip,
                // mouseCursor: SystemMouseCursors.click,
                onHover: (value) => setState(() => isHovering = value),
              )
              .animate(target: isHovering && widget.isSelected != true ? 1 : 0)
              .custom(
                duration: Duration(milliseconds: 100),
                builder: (context, value, child) {
                  Widget background = Container(
                    color: Color(0xFF5A5A5A).withAlpha((255 * value).toInt()),
                    padding: .all(1.5),
                    child: child,
                  );
                  if (widget.borderRadius != null) {
                    return ClipRRect(
                      borderRadius: .circular(widget.borderRadius!),
                      clipBehavior: .antiAlias,
                      child: background,
                    );
                  } else {
                    return ClipOval(
                      clipBehavior: .antiAlias,
                      child: background,
                    );
                  }
                },
              ),
    );
  }
}

class HoldImageButton extends StatefulWidget {
  const new({
    super.key,
    required this.buttonName,
    required this.onHold,
    this.onPressed,
    this.onCancel,
    this.scale = 6,
    this.tooltip,
    this.borderRadius,
    this.padding = true,
  });

  final String buttonName;
  final void Function() onHold;
  final void Function()? onCancel;
  final void Function()? onPressed;
  final double scale;
  final String? tooltip;
  final double? borderRadius;
  final bool padding;

  @override
  State<HoldImageButton> createState() => _HoldImageButtonState();
}

class _HoldImageButtonState extends State<HoldImageButton> {
  bool isHovering = false;
  bool isHolding = false;

  @override
  Widget build(BuildContext context) {
    return HoldDetector(
      onHold: () {
        widget.onHold();
        setState(() => isHolding = true);
      },
      onCancel: () {
        if (widget.onCancel != null) widget.onCancel!();
        setState(() => isHolding = false);
      },
      holdTimeout: Duration(milliseconds: 25),
      child: Focus(
        descendantsAreFocusable: false,
        canRequestFocus: false,
        child:
            IconButton(
                  onPressed:
                      widget.onPressed ??
                      () {
                        widget.onHold();
                        setState(() => isHolding = false);
                      },
                  padding: .zero,
                  icon: Image.asset(
                    'lib/assets/images/buttons/${widget.buttonName}Button.png',
                    scale: widget.scale,
                  ),
                  isSelected: isHolding,
                  selectedIcon: Image.asset(
                    'lib/assets/images/buttons/${widget.buttonName}ButtonPressed.png',
                    scale: widget.scale,
                  ),
                  tooltip: widget.tooltip,
                  // mouseCursor: SystemMouseCursors.click,
                  onHover: (value) => setState(() => isHovering = value),
                )
                .animate(target: isHovering && !isHolding ? 1 : 0)
                .custom(
                  duration: Duration(milliseconds: 100),
                  builder: (context, value, child) {
                    Widget background = Container(
                      color: Color(0xFF5A5A5A).withAlpha((255 * value).toInt()),
                      padding: widget.padding ? .all(1.5) : null,
                      child: child,
                    );
                    if (widget.borderRadius != null) {
                      return ClipRRect(
                        borderRadius: .circular(widget.borderRadius!),
                        clipBehavior: .antiAlias,
                        child: background,
                      );
                    } else {
                      return ClipOval(
                        clipBehavior: .antiAlias,
                        child: background,
                      );
                    }
                  },
                ),
      ),
    );
  }
}

class DoubleImageButton extends StatefulWidget {
  const new({
    super.key,
    required this.onPressed,
    required this.buttonNames,
    this.scale = 6,
    this.tooltips,
    this.spacing = 2,
  });

  final List<void Function()?> onPressed;
  final List<String> buttonNames;
  final double scale;
  final List<String>? tooltips;
  final double spacing;

  @override
  State<DoubleImageButton> createState() => _DoubleImageButtonState();
}

class _DoubleImageButtonState extends State<DoubleImageButton> {
  List<bool> isHovering = List.filled(2, false);

  @override
  void initState() {
    assert(
      widget.buttonNames.length == 2,
      'The length of buttonNames must be 2',
    );
    assert(widget.onPressed.length == 2, 'The length of onPressed must be 2');
    if (widget.tooltips != null) {
      assert(widget.tooltips?.length == 2, 'The length of tooltips must be 2');
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      descendantsAreFocusable: false,
      canRequestFocus: false,
      child: Row(
        spacing: widget.spacing,
        children: widget.buttonNames.map((buttonName) {
          final idx = widget.buttonNames.indexOf(buttonName);
          final onPressed = widget.onPressed.elementAt(idx);
          final tooltip = widget.tooltips?.elementAt(idx);
          return IconButton(
                onPressed: onPressed,
                padding: .zero,
                icon: Image.asset(
                  'lib/assets/images/buttons/${buttonName}HalfButton.png',
                  scale: widget.scale,
                ),
                tooltip: tooltip,
                // mouseCursor: SystemMouseCursors.click,
                onHover: (value) => setState(() => isHovering[idx] = value),
                constraints: .tightFor(),
              )
              .animate(target: isHovering[idx] ? 1 : 0)
              .custom(
                duration: Duration(milliseconds: 100),
                builder: (context, value, child) {
                  return ClipRRect(
                    borderRadius: idx == 0
                        ? .only(
                            topLeft: .circular(100),
                            bottomLeft: .circular(100),
                            topRight: .circular(13),
                            bottomRight: .circular(13),
                          )
                        : .only(
                            topRight: .circular(100),
                            bottomRight: .circular(100),
                            topLeft: .circular(13),
                            bottomLeft: .circular(13),
                          ),
                    clipBehavior: .antiAlias,
                    child: Container(
                      color: Color(0xFF5A5A5A).withAlpha((255 * value).toInt()),
                      padding: .all(1.5),
                      child: child,
                    ),
                  );
                },
              );
        }).toList(),
      ),
    );
  }
}

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

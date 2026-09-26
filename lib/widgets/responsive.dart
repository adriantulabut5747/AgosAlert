import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// RESPONSIVE — one app for phones, tablets, and desktop browsers
/// ============================================================
///
/// Screen widths (in logical pixels, what Flutter calls "dp"):
///   phone    under 600    bottom nav, one column (the original layout)
///   tablet   600 – 1023   top nav with icons only
///   desktop  1024 and up  top nav with labels, content up to 1200 wide
const double kTabletWidth = 600;
const double kDesktopWidth = 1024;

/// Content never gets wider than this, even on a huge monitor: long lines
/// and far-apart columns are hard to read.
const double kPageMaxWidth = 1200;

enum ScreenSize { phone, tablet, desktop }

/// Which layout to use for the current window.
/// MediaQuery.sizeOf only rebuilds the widget when the window SIZE
/// changes (not on every keyboard or padding change).
ScreenSize screenSizeOf(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w >= kDesktopWidth) return ScreenSize.desktop;
  if (w >= kTabletWidth) return ScreenSize.tablet;
  return ScreenSize.phone;
}

/// True on tablets and desktops: top nav, popups instead of bottom sheets.
bool isWideScreen(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kTabletWidth;

/// Padding for a tab's scrolling content. On phones: the usual 20 px sides
/// and room at the bottom for the floating nav bar. On wider screens the
/// side padding grows so the content sits in the middle, at most
/// [kPageMaxWidth] wide, while the scrollbar stays at the window's edge.
EdgeInsets pagePadding(BuildContext context, {double phoneTop = 8}) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < kTabletWidth) return EdgeInsets.fromLTRB(20, phoneTop, 20, 120);
  final side = math.max(32.0, (w - kPageMaxWidth) / 2);
  return EdgeInsets.fromLTRB(side, 28, side, 48);
}

/// Two columns side by side when there's room ([minWidth] or more),
/// otherwise one column: [left]'s widgets first, then [right]'s.
/// [leftFlex] : [rightFlex] is how the width is shared, e.g. 8 : 4.
class TwoColumns extends StatelessWidget {
  final List<Widget> left;
  final List<Widget> right;
  final int leftFlex;
  final int rightFlex;
  final double minWidth;
  final double spacing;
  const TwoColumns({
    required this.left,
    required this.right,
    this.leftFlex = 1,
    this.rightFlex = 1,
    this.minWidth = 880,
    this.spacing = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < minWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: spacing,
            children: [...left, ...right],
          );
        }
        Widget column(List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: spacing,
          children: children,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: spacing,
          children: [
            Expanded(flex: leftFlex, child: column(left)),
            Expanded(flex: rightFlex, child: column(right)),
          ],
        );
      },
    );
  }
}

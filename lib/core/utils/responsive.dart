import 'dart:io';

import 'package:flutter/widgets.dart';

const phoneWidth = 560.0;

const railWidth = 640.0;

const railPageWidth = 680.0;

const splitWidth = 900.0;

const wideWidth = 1060.0;

const paneWidth = 480.0;

const compactPaneWidth = 400.0;

const detailWidth = 900.0;

const columnsWidth = 1000.0;

bool isWideLayout(BuildContext context) =>
    !Platform.isAndroid && MediaQuery.sizeOf(context).width >= splitWidth;

bool hasSideRail(BuildContext context) =>
    !Platform.isAndroid && MediaQuery.sizeOf(context).width >= railWidth;

bool isCompactRail(BuildContext context) =>
    MediaQuery.sizeOf(context).width < wideWidth;

bool stackedRows(BuildContext context) =>
    MediaQuery.sizeOf(context).width <
    360 * MediaQuery.textScalerOf(context).scale(1);

bool stackedValue(BuildContext context, String? value) {
  if (value == null) return false;
  if (stackedRows(context)) return true;
  final painter = TextPainter(
    text: TextSpan(
      text: value,
      style: DefaultTextStyle.of(context)
          .style
          .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    textScaler: MediaQuery.textScalerOf(context),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  final room = MediaQuery.sizeOf(context).width.clamp(0.0, railPageWidth);
  return painter.width > room * 0.4;
}

bool bareRows(BuildContext context) =>
    MediaQuery.sizeOf(context).width <
    240 * MediaQuery.textScalerOf(context).scale(1);

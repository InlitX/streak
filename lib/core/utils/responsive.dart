import 'dart:io';

import 'package:flutter/widgets.dart';

const phoneWidth = 560.0;

const wideWidth = 1060.0;

const paneWidth = 480.0;

const detailWidth = 900.0;

const columnsWidth = 1000.0;

bool isWideLayout(BuildContext context) =>
    !Platform.isAndroid && MediaQuery.sizeOf(context).width >= wideWidth;

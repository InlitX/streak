import 'package:flutter/widgets.dart';
import 'package:streak/core/utils/app_dirs.dart';

const phoneWidth = 560.0;

const wideWidth = 1060.0;

const paneWidth = 480.0;

const detailWidth = 900.0;

const columnsWidth = 1000.0;

bool isWideLayout(BuildContext context) =>
    !isMobile && MediaQuery.sizeOf(context).width >= wideWidth;

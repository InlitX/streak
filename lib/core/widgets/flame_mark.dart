import 'package:flutter/material.dart';

class FlameMark extends StatelessWidget {
  const FlameMark({
    super.key,
    required this.lit,
    required this.color,
    required this.size,
  });

  final bool lit;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _FlamePainter(lit: lit, color: color)),
      );
}

class _FlamePainter extends CustomPainter {
  _FlamePainter({required this.lit, required this.color});

  final bool lit;
  final Color color;

  static final _outer = _parse(_fill);
  static final _ring = _parse(_outline);
  static const _box = Rect.fromLTWH(4, 2, 16, 20);
  static const _core = [Color(0xFFFFF6D6), Color(0xFFFFD66B)];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    if (!lit) {
      canvas.drawPath(_ring, Paint()..color = color.withValues(alpha: 0.45));
      return;
    }
    canvas.drawPath(
      _outer,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );
    canvas.drawPath(
      _outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.2)!,
          ],
        ).createShader(_box),
    );
    canvas
      ..save()
      ..translate(12, 21.2)
      ..scale(0.5)
      ..translate(-12, -21.2)
      ..drawPath(
        _outer,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: _core,
          ).createShader(_box),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_FlamePainter old) =>
      old.lit != lit || old.color != color;
}

Path _parse(String data) {
  final path = Path();
  final tokens = RegExp(r'[MLCZ]|-?\d*\.?\d+')
      .allMatches(data)
      .map((m) => m.group(0)!)
      .toList();
  var i = 0;
  var command = 'M';
  double next() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    if (RegExp(r'[MLCZ]').hasMatch(tokens[i])) command = tokens[i++];
    switch (command) {
      case 'M':
        path.moveTo(next(), next());
        command = 'L';
      case 'L':
        path.lineTo(next(), next());
      case 'C':
        path.cubicTo(next(), next(), next(), next(), next(), next());
      case 'Z':
        path.close();
    }
  }
  return path;
}

const fluentIconsLicense = '''MIT License

Copyright (c) 2020 Microsoft Corporation

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''';

const _fill =
    'M6.15636 9.3231L6.15395 9.32491L6.15 9.3279L6.13963 9.33586C6.13164 9.34204 6.12151 9.34999 6.10942 9.35973C6.08524 9.37919 6.05314 9.40581 6.01442 9.43966C5.93703 9.50732 5.83284 9.6042 5.71236 9.73104C5.47171 9.98437 5.16368 10.3598 4.8751 10.8629C4.29291 11.8779 3.80368 13.3906 4.07868 15.4142C4.34997 17.4107 5.18833 19.0801 6.60711 20.244C8.02084 21.4038 9.93533 22 12.25 22C14.6375 22 16.5425 21.1054 17.8042 19.5699C19.0544 18.0486 19.6122 15.9741 19.4787 13.706C19.3508 11.5302 18.1656 9.87945 17.1188 8.42123C17.0177 8.28043 16.9179 8.14142 16.8205 8.00391C15.6785 6.39222 14.7768 4.90657 14.9959 2.82863C15.0182 2.61721 14.9497 2.40625 14.8075 2.24824C14.6652 2.09023 14.4626 2 14.25 2C13.868 2 13.4309 2.11822 13.0077 2.29599C12.5715 2.47923 12.0984 2.74751 11.6351 3.09694C10.7104 3.79438 9.78589 4.84563 9.29236 6.25159C8.80006 7.65408 9.04947 8.99089 9.41008 9.9632C9.64689 10.6017 9.39005 11.233 9.00347 11.4165C8.66159 11.5789 8.25252 11.4427 8.07619 11.1078L7.26887 9.57452C7.16673 9.38052 6.98481 9.24093 6.77099 9.19248C6.55717 9.14403 6.33215 9.19209 6.15636 9.3231Z';

const _outline =
    'M12.5383 4.29449C12.8615 4.05075 13.182 3.86356 13.4688 3.73169C13.5555 5.85881 14.5955 7.45829 15.5965 8.87109C15.6881 9.00031 15.779 9.12767 15.8688 9.25354C16.9522 10.7721 17.8801 12.0725 17.9813 13.794C18.0979 15.7759 17.6036 17.4514 16.6453 18.6176C15.6986 19.7696 14.2385 20.5 12.25 20.5C10.1887 20.5 8.6396 19.9712 7.55849 19.0843C6.48244 18.2015 5.79472 16.9026 5.56502 15.2123C5.33902 13.5492 5.74149 12.3672 6.17625 11.6092C6.26176 11.4601 6.34906 11.3266 6.43394 11.2084L6.74894 11.8066C7.29998 12.8532 8.57839 13.2789 9.64684 12.7716C10.9525 12.1516 11.2311 10.5595 10.8165 9.4416C10.5264 8.65954 10.3721 7.70456 10.7077 6.74841C11.084 5.67629 11.7985 4.85253 12.5383 4.29449ZM6.15636 9.3231L6.15395 9.32491L6.15 9.3279L6.13963 9.33586C6.13164 9.34204 6.12151 9.34999 6.10942 9.35973C6.08524 9.37919 6.05314 9.40581 6.01442 9.43966C5.93703 9.50732 5.83284 9.6042 5.71236 9.73104C5.47171 9.98437 5.16368 10.3598 4.8751 10.8629C4.29291 11.8779 3.80368 13.3906 4.07868 15.4142C4.34997 17.4107 5.18833 19.0801 6.60711 20.244C8.02084 21.4038 9.93533 22 12.25 22C14.6375 22 16.5425 21.1054 17.8042 19.5699C19.0544 18.0486 19.6122 15.9741 19.4787 13.706C19.3508 11.5302 18.1656 9.87945 17.1188 8.42123C17.0177 8.28043 16.9179 8.14142 16.8205 8.00391C15.6785 6.39222 14.7768 4.90657 14.9959 2.82863C15.0182 2.61721 14.9497 2.40625 14.8075 2.24824C14.6652 2.09023 14.4626 2 14.25 2C13.868 2 13.4309 2.11822 13.0077 2.29599C12.5715 2.47923 12.0984 2.74751 11.6351 3.09694C10.7104 3.79438 9.78589 4.84563 9.29236 6.25159C8.80006 7.65408 9.04947 8.99089 9.41008 9.9632C9.64689 10.6017 9.39005 11.233 9.00347 11.4165C8.66159 11.5789 8.25252 11.4427 8.07619 11.1078L7.26887 9.57452C7.16673 9.38052 6.98481 9.24093 6.77099 9.19248C6.55717 9.14403 6.33215 9.19209 6.15636 9.3231Z';

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class SvgPathClipper extends CustomClipper<Path> {
  final String svgPath;
  final double svgWidth;
  final double svgHeight;

  SvgPathClipper({
    required this.svgPath,
    required this.svgWidth,
    required this.svgHeight,
  });

  @override
  Path getClip(Size size) {
    final path = parseSvgPathData(svgPath);
    final Matrix4 matrix = Matrix4.identity();
    matrix.scale(size.width / svgWidth, size.height / svgHeight);
    return path.transform(matrix.storage);
  }

  @override
  bool shouldReclip(covariant SvgPathClipper oldClipper) {
    return svgPath != oldClipper.svgPath ||
        svgWidth != oldClipper.svgWidth ||
        svgHeight != oldClipper.svgHeight;
  }
}
import 'package:flutter/material.dart';

import '../../model/map_part.dart';
import 'svg_path_clipper.dart';

class SvgPathWidget extends StatelessWidget {
  final MapPart part;
  final bool isSelected;
  final ValueChanged<MapPart> onSelected;
  final double svgWidth;
  final double svgHeight;

  const SvgPathWidget({
    super.key,
    required this.part,
    required this.isSelected,
    required this.onSelected,
    required this.svgWidth,
    required this.svgHeight,
  });

  @override
  Widget build(BuildContext context) {
    final colorString = part.attributes['color'] ?? 'BDBDBD';
    final color = Color(int.parse("0xFF$colorString"));

    return ClipPath(
      clipper: SvgPathClipper(
        svgPath: part.pathData,
        svgWidth: svgWidth,
        svgHeight: svgHeight,
      ),
      child: GestureDetector(
        onTap: () => onSelected(part),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.red : color.withValues(alpha: 0.8),
            border:
            isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
          ),
        ),
      ),
    );
  }
}
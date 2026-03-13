import 'package:flutter/material.dart';
import 'package:spritewidget/spritewidget.dart';

/// A Node that represents a block puzzle shape made of multiple square blocks.
class BlockShapeNode extends Node {
  final List<List<int>> shape;
  final double blockSize;
  final Color color;

  BlockShapeNode({
    required this.shape,
    this.blockSize = 40.0,
    this.color = Colors.orange,
  }) {
    _initBlocks();
  }

  void _initBlocks() {
    for (int y = 0; y < shape.length; y++) {
      for (int x = 0; x < shape[y].length; x++) {
        if (shape[y][x] == 1) {
          final block = _SingleBlockNode(
            size: Size(blockSize, blockSize),
            color: color,
          );
          block.position = Offset(x * blockSize, y * blockSize);
          addChild(block);
        }
      }
    }
  }
}

/// Helper node for a single square block within a shape
class _SingleBlockNode extends Node {
  final Size size;
  final Color color;

  _SingleBlockNode({required this.size, required this.color});

  @override
  void paint(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw main block
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8));
    canvas.drawRRect(rrect, paint);
    
    // Add a simple highlight/bevel effect
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.width - 12, 10),
        const Radius.circular(4),
      ),
      highlightPaint,
    );
  }
}

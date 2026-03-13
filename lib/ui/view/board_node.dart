import 'package:blockinity/ui/view/animation_nodes.dart';
import 'package:flutter/material.dart';
import 'package:spritewidget/spritewidget.dart';

class BoardNode extends Node {
  final int rows;
  final int cols;
  final double cellSize;
  final double padding;

  // Grid state: stores the color of each cell, null if empty
  late List<List<Color?>> _grid;

  // Preview state
  List<List<int>>? _previewShape;
  Offset? _previewPos; // grid row, col
  Color? _previewColor;

  BoardNode({
    this.rows = 10,
    this.cols = 8,
    this.cellSize = 45.0,
    this.padding = 1.0,
  }) {
    _grid = List.generate(rows, (r) => List.generate(cols, (c) => null));
  }

  void updateGrid(List<List<Color?>> newGrid) {
    _grid = newGrid;
  }

  void playPlacementEffect(int row, int col, Color color) {
    final effect = EffectNode(color);
    effect.position = Offset(
      col * cellSize + cellSize / 2,
      row * cellSize + cellSize / 2,
    );
    addChild(effect);

    // Correct SpriteWidget motion usage
    motions.run(
      MotionSequence(motions: [
        MotionTween<double>(
          setter: (v) => scale = v,
          start: 1.0,
          end: 1.03,
          duration: 0.1,
        ),
        MotionTween<double>(
          setter: (v) => scale = v,
          start: 1.03,
          end: 1.0,
          duration: 0.1,
        ),
      ]),
    );
  }

  void playLineClearEffect(int index, bool isRow) {
    for (int i = 0; i < (isRow ? cols : rows); i++) {
      final effect = EffectNode(Colors.white);
      effect.position = Offset(
        (isRow ? i : index) * cellSize + cellSize / 2,
        (isRow ? index : i) * cellSize + cellSize / 2,
      );
      addChild(effect);
    }
  }

  void updatePreview(List<List<int>>? shape, Offset? pos, Color? color) {
    _previewShape = shape;
    _previewPos = pos;
    _previewColor = color;
  }

  @override
  void paint(Canvas canvas) {
    // 1. Draw individual grid cells
    final emptyCellPaint = Paint()
      ..color = const Color(0xffF1F5F9).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(
          c * cellSize + padding,
          r * cellSize + padding,
          cellSize - (padding * 2),
          cellSize - (padding * 2),
        );

        final cellColor = _grid[r][c];

        // Check if this cell is part of the preview
        bool isPreview = false;
        if (_previewShape != null && _previewPos != null) {
          int startR = _previewPos!.dx.toInt();
          int startC = _previewPos!.dy.toInt();

          int relativeR = r - startR;
          int relativeC = c - startC;

          if (relativeR >= 0 &&
              relativeR < _previewShape!.length &&
              relativeC >= 0 &&
              relativeC < _previewShape![0].length) {
            if (_previewShape![relativeR][relativeC] == 1) {
              isPreview = true;
            }
          }
        }

        if (cellColor != null || isPreview) {
          // Draw premium occupied block matching _SingleBlockNode
          final blockPaint = Paint()
            ..color = isPreview
                ? (_previewColor ?? Colors.grey).withOpacity(0.4)
                : cellColor!
            ..style = PaintingStyle.fill;

          final rrect = RRect.fromRectAndRadius(
            rect.deflate(2),
            const Radius.circular(8),
          );
          canvas.drawRRect(rrect, blockPaint);

          // Add bevel highlight
          final highlightPaint = Paint()
            ..color = Colors.white.withOpacity(isPreview ? 0.1 : 0.3)
            ..style = PaintingStyle.fill;

          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(rect.left + 4, rect.top + 4, rect.width - 12, 10),
              const Radius.circular(4),
            ),
            highlightPaint,
          );
        } else {
          // Draw empty cell
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            emptyCellPaint,
          );
        }
      }
    }

    // 2. Draw outer premium border
    final borderPaint = Paint()
      ..color = const Color(0xffD1D5DB).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final boardRect = Rect.fromLTWH(0, 0, cols * cellSize, rows * cellSize);

    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.inflate(2), const Radius.circular(16)),
      borderPaint,
    );
  }
}

import 'dart:ui' as ui;
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
  late List<List<bool>> _cartoonsGrid;
  ui.Image? cartoonImage;

  // Preview state
  List<List<int>>? _previewShape;
  Offset? _previewPos; // grid row, col
  Color? _previewColor;
  bool _isPreviewValid = true;

  BoardNode({
    this.rows = 10,
    this.cols = 8,
    this.cellSize = 45.0,
    this.padding = 1.0,
  }) {
    _grid = List.generate(rows, (r) => List.generate(cols, (c) => null));
    _cartoonsGrid = List.generate(
      rows,
      (r) => List.generate(cols, (c) => false),
    );
  }

  void updateGrid(List<List<Color?>> newGrid, List<List<bool>> newCartoons) {
    _grid = newGrid;
    _cartoonsGrid = newCartoons;
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
      MotionSequence(
        motions: [
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
        ],
      ),
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

  void spawnParticleEffect(int row, int col, Color color) {
    final effect = EffectNode(color);
    effect.position = Offset(
      col * cellSize + cellSize / 2,
      row * cellSize + cellSize / 2,
    );
    addChild(effect);
  }

  void playBlastEffect(int row, int col, Color color, int intensity) {
    final effect = BlastEffectNode(color, intensity: intensity);
    effect.position = Offset(
      col * cellSize + cellSize / 2,
      row * cellSize + cellSize / 2,
    );
    addChild(effect);
  }

  void playComboFeedback(String text, Color color, double scale) {
    final node = ComboTextNode(text, color, scale: scale);
    // Place in the middle upper part of the board
    node.position = Offset(cols * cellSize / 2, rows * cellSize / 3);
    addChild(node);
  }

  void playCartoonCollectEffect(int row, int col, ui.Image image) {
    final texture = SpriteTexture(image);
    final sprite = Sprite(texture: texture);

    final double targetWidth = cellSize - (padding * 2) + 15;
    // Approximate scale to match the painted rect
    sprite.scale = targetWidth / image.width;

    // Position correctly in center of cell, moved slightly up for the taller target
    sprite.position = Offset(
      col * cellSize + cellSize / 2,
      row * cellSize + cellSize / 2 - 7.5,
    );

    addChild(sprite);

    // Use SpriteWidget motions for collection animation
    motions.run(
      MotionSequence(
        motions: [
          MotionGroup(
            motions: [
              MotionTween<double>(
                setter: (v) => sprite.position = Offset(sprite.position.dx, v),
                start: sprite.position.dy,
                end: sprite.position.dy - 60,
                duration: 0.6,
                curve: Curves.easeOut,
              ),
              MotionTween<double>(
                setter: (v) => sprite.scale = v,
                start: sprite.scale,
                end: sprite.scale * 1.5,
                duration: 0.6,
                curve: Curves.easeOut,
              ),
              MotionTween<double>(
                setter: (v) => sprite.opacity = v,
                start: 1.0,
                end: 0.0,
                duration: 0.6,
                curve: Curves.easeIn,
              ),
            ],
          ),
          MotionCallFunction(callback: () => sprite.removeFromParent()),
        ],
      ),
    );
  }

  void updatePreview(List<List<int>>? shape, Offset? pos, Color? color, {bool isValid = true}) {
    _previewShape = shape;
    _previewPos = pos;
    _previewColor = color;
    _isPreviewValid = isValid;
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
                ? (_isPreviewValid ? Colors.greenAccent : Colors.red).withOpacity(0.4)
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
              Rect.fromLTWH(rect.left + rect.width * 0.1, rect.top + rect.height * 0.1, rect.width * 0.7, rect.height * 0.25),
              Radius.circular(rect.width * 0.1),
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

        // Draw the cartoon target centered inside the cell
        if (_cartoonsGrid[r][c] && cartoonImage != null) {
          final double imgSize = cellSize * 1.5;
          final double centerX = c * cellSize + cellSize / 2;
          final double centerY = r * cellSize + cellSize / 2;
          final targetRect = Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: imgSize,
            height: imgSize,
          );
          canvas.drawImageRect(
            cartoonImage!,
            Rect.fromLTWH(
              0,
              0,
              cartoonImage!.width.toDouble(),
              cartoonImage!.height.toDouble(),
            ),
            targetRect,
            Paint(),
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

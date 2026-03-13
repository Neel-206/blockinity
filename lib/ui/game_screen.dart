import 'dart:math';
import 'package:blockinity/Controller/level_controller.dart';
import 'package:blockinity/theme/app_colors.dart';
import 'package:blockinity/ui/view/animation_nodes.dart';
import 'package:blockinity/ui/view/block_sprite_node.dart';
import 'package:blockinity/ui/view/board_node.dart';
import 'package:blockinity/ui/view/game_shapes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spritewidget/spritewidget.dart';

class NextBlockItem {
  final List<List<int>> shape;
  final Color color;
  final int id;

  NextBlockItem({required this.shape, required this.color, required this.id});
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late NodeWithSize rootNode;
  late NodeWithSize bgNode;
  late BoardNode boardNode;
  final Random _random = Random();
  int _score = 0;
  int _currentLevel = 1;

  int get _targetScore => _currentLevel * 500; // Example target: 500, 1000, 1500...

  final int rows = 10;
  final int cols = 8;
  late List<List<Color?>> boardState;

  List<NextBlockItem> nextBlocks = [];
  int _idCounter = 0;

  NextBlockItem? _draggingItem;
  Offset _dragPosition = Offset.zero;
  Offset _dragOffset = Offset.zero;
  final GlobalKey _boardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentLevel = Get.arguments ?? 1;
    boardState = List.generate(rows, (_) => List.generate(cols, (_) => null));
    rootNode = NodeWithSize(const Size(400, 500));

    bgNode = NodeWithSize(const Size(400, 800));
    final bgLayer = BackgroundLayerNode(const Size(400, 800));
    bgNode.addChild(bgLayer);

    _setupGameArena();
    _fillNextBlocks();
  }

  void _setupGameArena() {
    boardNode = BoardNode(rows: rows, cols: cols, cellSize: 45.0, padding: 1.5);
    boardNode.position = const Offset(20, 20);
    rootNode.addChild(boardNode);
  }

  void _fillNextBlocks() {
    final List<Color> shapeColors = [
      const Color(0xff00BCD4),
      AppColors.primary,
      const Color(0xff8BC34A),
      const Color(0xffE91E63),
      const Color(0xff9C27B0),
      const Color(0xff2196F3),
    ];

    while (nextBlocks.length < 3) {
      List<List<int>> shape = GameShapes.getRandomShapeWeighted();
      bool possible = false;
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (_canPlace(shape, r, c)) {
            possible = true;
            break;
          }
        }
        if (possible) break;
      }

      if (possible) {
        nextBlocks.add(
          NextBlockItem(
            shape: shape,
            color: shapeColors[_random.nextInt(shapeColors.length)],
            id: _idCounter++,
          ),
        );
      } else {
        _checkGameOver();
      }
    }
  }

  void _checkGameOver() {
    bool canPlaceAny = false;
    for (var item in nextBlocks) {
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (_canPlace(item.shape, r, c)) {
            canPlaceAny = true;
            break;
          }
        }
        if (canPlaceAny) break;
      }
      if (canPlaceAny) break;
    }

    if (!canPlaceAny && nextBlocks.isNotEmpty) {
      Get.dialog(
        AlertDialog(
          title: const Text('Game Over'),
          content: Text('Your score: $_score'),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                _resetGame();
              },
              child: const Text('Restart'),
            ),
          ],
        ),
      );
    }
  }

  void _resetGame() {
    setState(() {
      boardState = List.generate(rows, (_) => List.generate(cols, (_) => null));
      boardNode.updateGrid(boardState);
      _score = 0;
      _currentLevel = 1;
      nextBlocks.clear();
      _fillNextBlocks();
    });
  }

  void _checkLevelProgression() {
    if (_score >= _targetScore) {
      _showLevelUpDialog();
    }
  }

  void _showLevelUpDialog() {
    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        backgroundColor: const Color(0xffF8F9FB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            'LEVEL UP!',
            style: GoogleFonts.sourGummy(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Goal Reached!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xff475569),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Welcome to Level ${_currentLevel + 1}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xff64748B),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                _nextLevel();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
              ),
              child: const Text('CONTINUE'),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _nextLevel() {
    // Persistent progress update
    Get.find<LevelController>().completeLevel(_currentLevel);

    setState(() {
      _currentLevel++;
      // Optional: Clear board or keep it?
    });
  }

  bool _canPlace(List<List<int>> shape, int row, int col) {
    for (int r = 0; r < shape.length; r++) {
      for (int c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 1) {
          int targetR = row + r;
          int targetC = col + c;
          if (targetR < 0 || targetR >= rows || targetC < 0 || targetC >= cols)
            return false;
          if (boardState[targetR][targetC] != null) return false;
        }
      }
    }
    return true;
  }

  void _placeShape(NextBlockItem item, int row, int col) {
    setState(() {
      for (int r = 0; r < item.shape.length; r++) {
        for (int c = 0; c < item.shape[r].length; c++) {
          if (item.shape[r][c] == 1) {
            boardState[row + r][col + c] = item.color;
          }
        }
      }
      boardNode.playPlacementEffect(row, col, item.color);
      _score += 10;
      nextBlocks.removeWhere((b) => b.id == item.id);
      _fillNextBlocks();
      boardNode.updateGrid(boardState);
      _checkLines();
      _checkLevelProgression();
    });
  }

  void _checkLines() {
    List<int> fullRows = [];
    for (int r = 0; r < rows; r++) {
      bool full = true;
      for (int c = 0; c < cols; c++) {
        if (boardState[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) fullRows.add(r);
    }

    List<int> fullCols = [];
    for (int c = 0; c < cols; c++) {
      bool full = true;
      for (int r = 0; r < rows; r++) {
        if (boardState[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) fullCols.add(c);
    }

    if (fullRows.isNotEmpty || fullCols.isNotEmpty) {
      setState(() {
        for (var r in fullRows) {
          for (int c = 0; c < cols; c++) boardState[r][c] = null;
          boardNode.playLineClearEffect(r, true);
        }
        for (var c in fullCols) {
          for (int r = 0; r < rows; r++) boardState[r][c] = null;
          boardNode.playLineClearEffect(c, false);
        }
        _score += (fullRows.length + fullCols.length) * 100;
        boardNode.updateGrid(boardState);
        _checkLevelProgression();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SpriteWidget(
                bgNode,
                transformMode: SpriteBoxTransformMode.letterbox,
              ),
            ),
            Column(
              children: [
                _buildHeader(_currentLevel),
                const SizedBox(height: 10),
                _buildProgressBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildDragTarget(),
                  ),
                ),
                _buildNextBlocksSection(),
                const SizedBox(height: 50),
              ],
            ),
            if (_draggingItem != null)
              Positioned(
                left: _dragPosition.dx - _dragOffset.dx,
                top: _dragPosition.dy - _dragOffset.dy,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.9,
                    child: _buildMiniShape(
                      _draggingItem!.shape,
                      _draggingItem!.color,
                      blockSize: 45.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int level) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPauseButton(),
          Column(
            children: [
              Text(
                'Blockinity',
                style: GoogleFonts.sourGummy(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LEVEL  ',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xff94A3B8),
                      letterSpacing: 1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF1E2DB),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '$level',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xff1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'SCORE',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xff94A3B8),
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '$_score',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xff1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    double progress = (_score / _targetScore).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GOAL: $_targetScore',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff94A3B8),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xffE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton() => Container(
    width: 55,
    height: 55,
    decoration: const BoxDecoration(
      color: Color(0xffE2EAF4),
      shape: BoxShape.circle,
    ),
    child: IconButton(
      onPressed: () => Get.back(),
      icon: const Icon(Icons.pause, color: Color(0xff2D3748), size: 28),
    ),
  );

  Widget _buildDragTarget() => ClipRRect(
    key: _boardKey,
    borderRadius: BorderRadius.circular(20),
    child: SpriteWidget(
      rootNode,
      transformMode: SpriteBoxTransformMode.letterbox,
    ),
  );

  Widget _buildNextBlocksSection() => Column(
    children: [
      const SizedBox(height: 25),
      Text(
        'NEXT BLOCKS',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: const Color(0xff94A3B8),
          letterSpacing: 2.5,
        ),
      ),
      const SizedBox(height: 15),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xffF1F5F9).withOpacity(0.8),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: nextBlocks
              .map(
                (item) => SizedBox(
                  width: 90,
                  child: Center(child: _buildDraggableShape(item)),
                ),
              )
              .toList(),
        ),
      ),
    ],
  );

  Widget _buildDraggableShape(NextBlockItem item) {
    bool isDragging = _draggingItem?.id == item.id;
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _draggingItem = item;
          _dragPosition = details.globalPosition;
          double width = item.shape[0].length * 45.0;
          double height = item.shape.length * 45.0;
          _dragOffset = Offset(width / 2, height + 60);
          boardNode.updatePreview(null, null, null);
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _dragPosition = details.globalPosition;
          _updateHoverPreview();
        });
      },
      onPanEnd: (details) {
        _handleDrop();
        boardNode.updatePreview(null, null, null);
      },
      onPanCancel: () {
        setState(() {
          _draggingItem = null;
        });
      },
      child: Opacity(
        opacity: isDragging ? 0.3 : 1.0,
        child: _buildMiniShape(item.shape, item.color, blockSize: 24.0),
      ),
    );
  }

  void _updateHoverPreview() {
    if (_draggingItem == null) return;
    final RenderBox? boardBox =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox != null) {
      final Offset topLeftGlobal = _dragPosition - _dragOffset;
      final Offset localPos = boardBox.globalToLocal(topLeftGlobal);
      final Size size = boardBox.size;
      double scale = min(size.width / 400.0, size.height / 500.0);
      double offsetX = (size.width - 400.0 * scale) / 2.0;
      double offsetY = (size.height - 500.0 * scale) / 2.0;
      double spriteX = (localPos.dx - offsetX) / scale;
      double spriteY = (localPos.dy - offsetY) / scale;
      int col = ((spriteX - 20) / 45.0).round();
      int row = ((spriteY - 20) / 45.0).round();
      if (_canPlace(_draggingItem!.shape, row, col)) {
        boardNode.updatePreview(
          _draggingItem!.shape,
          Offset(row.toDouble(), col.toDouble()),
          _draggingItem!.color,
        );
      } else {
        boardNode.updatePreview(null, null, null);
      }
    }
  }

  void _handleDrop() {
    if (_draggingItem == null) return;
    final RenderBox? boardBox =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox != null) {
      final Offset topLeftGlobal = _dragPosition - _dragOffset;
      final Offset localPos = boardBox.globalToLocal(topLeftGlobal);
      final Size size = boardBox.size;
      double scale = min(size.width / 400.0, size.height / 500.0);
      double offsetX = (size.width - 400.0 * scale) / 2.0;
      double offsetY = (size.height - 500.0 * scale) / 2.0;
      double spriteX = (localPos.dx - offsetX) / scale;
      double spriteY = (localPos.dy - offsetY) / scale;
      int col = ((spriteX - 20) / 45.0).round();
      int row = ((spriteY - 20) / 45.0).round();
      if (_canPlace(_draggingItem!.shape, row, col))
        _placeShape(_draggingItem!, row, col);
    }
    setState(() {
      _draggingItem = null;
    });
  }

  Widget _buildMiniShape(
    List<List<int>> matrix,
    Color color, {
    double blockSize = 24.0,
  }) {
    int rows = matrix.length;
    int cols = matrix[0].length;
    Size totalSize = Size(cols * blockSize, rows * blockSize);
    final root = NodeWithSize(totalSize);
    final shapeNode = BlockShapeNode(
      shape: matrix,
      color: color,
      blockSize: blockSize,
    );
    root.addChild(shapeNode);

    // Correct SpriteWidget motion usage
    shapeNode.motions.run(
      MotionRepeatForever(
        motion: MotionSequence(
          motions: [
            MotionTween<double>(
              setter: (v) => shapeNode.scale = v,
              start: 1.0,
              end: 1.05,
              duration: 1.2,
              curve: Curves.easeInOut,
            ),
            MotionTween<double>(
              setter: (v) => shapeNode.scale = v,
              start: 1.05,
              end: 1.0,
              duration: 1.2,
              curve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      width: totalSize.width,
      height: totalSize.height,
      child: SpriteWidget(
        root,
        transformMode: SpriteBoxTransformMode.scaleToFit,
      ),
    );
  }
}
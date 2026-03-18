import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui' as ui;
import 'package:blockinity/Controller/level_controller.dart';
import 'package:blockinity/Controller/player_controller.dart';
import 'package:blockinity/Services/daily_challenge_service.dart';
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
  // final Random _random = Random();

  late Random _blockRandom;
  int _score = 0;
  int _combo = 0;
  int _currentLevel = 1;

  // Challenge mode fields
  bool _isChallenge = false;
  int _challengeSeed = 0;
  int _challengeTargetScore = 0;
  int _challengeTargetCartoons = 0;
  // int _challengeObstacles = 0; // Removed unused field
  int _challengeCoinReward = 0;
  int _challengeGemReward = 0;

  int get _targetScore =>
      _isChallenge ? _challengeTargetScore : 200 + ((_currentLevel - 1) * 150);
  // int get _obstacleCount => 0; // Removed unused getter

  final int rows = 10;
  final int cols = 8;
  late List<List<Color?>> boardState;
  late List<List<bool>> cartoonsGrid;
  ui.Image? _cartoonImage;
  int _collectedCartoons = 0;
  int get _targetCartoons => _isChallenge
      ? _challengeTargetCartoons
      : min(3 + (_currentLevel ~/ 2), 10);

  List<NextBlockItem> nextBlocks = [];
  int _idCounter = 0;

  NextBlockItem? _draggingItem;
  Offset _dragPosition = Offset.zero;
  Offset _dragOffset = Offset.zero;
  final GlobalKey _boardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _isChallenge = true;
      _challengeSeed = args['challengeSeed'] as int;
      _challengeTargetScore = args['targetScore'] as int;
      _challengeTargetCartoons = args['targetCartoons'] as int;
      // _challengeObstacles = args['obstacles'] as int; // Removed unused extraction
      _challengeCoinReward = args['coinReward'] as int;
      _challengeGemReward = args['gemReward'] as int;
      _blockRandom = Random(_challengeSeed);
    } else {
      _currentLevel = (args as int?) ?? 1;
      _blockRandom = Random(_currentLevel * 1013 + 7); // seeded per level
    }
    boardState = List.generate(rows, (_) => List.generate(cols, (_) => null));
    cartoonsGrid = List.generate(
      rows,
      (_) => List.generate(cols, (_) => false),
    );
    rootNode = NodeWithSize(const Size(400, 500));

    bgNode = NodeWithSize(const Size(800, 800));
    final bgLayer = BackgroundLayerNode(const Size(400, 800));
    bgNode.addChild(bgLayer);

    _setupGameArena();
    // _placeObstacles(); // Removed gray blocks as per user request
    _setupTargets();
    _loadCartoonImage();
    _fillNextBlocks();
  }

  void _setupGameArena() {
    boardNode = BoardNode(rows: rows, cols: cols, cellSize: 45.0, padding: 1.5);
    boardNode.position = const Offset(20, 20);
    boardNode.updateGrid(boardState, cartoonsGrid);
    rootNode.addChild(boardNode);
  }

  Future<void> _loadCartoonImage() async {
    try {
      final data = await rootBundle.load('images/splash.png');
      final bytes = data.buffer.asUint8List();
      ui.decodeImageFromList(bytes, (image) {
        if (mounted) {
          setState(() {
            _cartoonImage = image;
            boardNode.cartoonImage = _cartoonImage;
          });
        }
      });
    } catch (e) {
      debugPrint("Error loading image: $e");
    }
  }

  // Removed _placeObstacles function as per user request

  void _setupTargets() {
    List<Offset> positions = [];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (boardState[r][c] == null) {
          positions.add(Offset(r.toDouble(), c.toDouble()));
        }
      }
    }

    // Shuffle with seed
    positions.shuffle(Random(_currentLevel * 1009 + 3));

    // Improvement 3: Priority-based placement for early levels
    if (_currentLevel < 10) {
      // Prioritize center cells for "Easy" placement
      positions.sort((a, b) {
        bool aInCenter = _isCenter(a.dx.toInt(), a.dy.toInt());
        bool bInCenter = _isCenter(b.dx.toInt(), b.dy.toInt());
        if (aInCenter && !bInCenter) return -1;
        if (!aInCenter && bInCenter) return 1;
        return 0;
      });
    }

    // Place cartoons with Improvement 2 (no clustering) logic
    int placedCount = 0;
    // 1st Pass: Try to place far apart (using isNearExisting improvement)
    for (var pos in positions) {
      if (placedCount >= _targetCartoons) break;
      int r = pos.dx.toInt();
      int c = pos.dy.toInt();
      if (!_isNearExisting(r, c)) {
        cartoonsGrid[r][c] = true;
        placedCount++;
      }
    }

    // 2nd Pass: Fill remaining if needed (fallback to allow clustering)
    if (placedCount < _targetCartoons) {
      for (var pos in positions) {
        if (placedCount >= _targetCartoons) break;
        int r = pos.dx.toInt();
        int c = pos.dy.toInt();
        if (!cartoonsGrid[r][c]) {
          cartoonsGrid[r][c] = true;
          placedCount++;
        }
      }
    }
  }

  bool _isNearExisting(int r, int c) {
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        int nr = r + i;
        int nc = c + j;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
          if (cartoonsGrid[nr][nc]) return true;
        }
      }
    }
    return false;
  }

  bool _isCenter(int r, int c) {
    // Defines center rows and columns for easy levels (Improvement 3)
    return r >= 3 && r <= 6 && c >= 2 && c <= 5;
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

    // Only generate new blocks when all previous ones are placed
    if (nextBlocks.isNotEmpty) {
      _checkGameOver();
      return;
    }

    // 1. Analyze the grid: Find all possible shapes and their placement scores
    List<MapEntry<List<List<int>>, double>> candidates = [];
    for (var shape in GameShapes.allShapes) {
      double bestScoreForShape = -1.0;
      bool isPossible = false;

      // Evaluate every possible position for this shape
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (_canPlace(shape, r, c)) {
            isPossible = true;
            double currentScore = _calculatePlacementScore(shape, r, c);
            if (currentScore > bestScoreForShape) {
              bestScoreForShape = currentScore;
            }
          }
        }
      }

      if (isPossible) {
        candidates.add(MapEntry(shape, bestScoreForShape));
      }
    }

    // If no blocks can be placed, the game will trigger Game Over in _checkGameOver
    if (candidates.isEmpty) {
      _checkGameOver();
      return;
    }

    // Sort candidates by score (highest score = most "needed" or "helpful" block)
    candidates.sort((a, b) => b.value.compareTo(a.value));

    // 2. Pick 3 blocks with guaranteed diversity
    // Slot 0: Strategic Help (Top performer)
    if (candidates.isNotEmpty) {
      int range = min(3, candidates.length);
      var best = candidates[_blockRandom.nextInt(range)].key;
      nextBlocks.add(_createBlockItem(best, shapeColors));
    }

    // Slot 1: Forced Small/Medium for versatility
    var versatileCandidates = candidates.where((e) {
      int size = 0;
      for (var r in e.key) {
        for (var v in r) if (v == 1) size++;
      }
      return size <= 3;
    }).toList();

    if (versatileCandidates.isNotEmpty) {
      nextBlocks.add(
        _createBlockItem(
          versatileCandidates[_blockRandom.nextInt(versatileCandidates.length)]
              .key,
          shapeColors,
        ),
      );
    } else if (candidates.length > 2) {
      // Fallback: Pick a different one from Slot 0
      nextBlocks.add(_createBlockItem(candidates[1].key, shapeColors));
    }

    // Slot 2: Pure Random distribution from all possible shapes
    if (candidates.isNotEmpty) {
      nextBlocks.add(
        _createBlockItem(
          candidates[_blockRandom.nextInt(candidates.length)].key,
          shapeColors,
        ),
      );
    }

    _checkGameOver();
  }

  NextBlockItem _createBlockItem(List<List<int>> shape, List<Color> colors) {
    return NextBlockItem(
      shape: shape,
      color: colors[_blockRandom.nextInt(colors.length)],
      id: _idCounter++,
    );
  }

  /// Calculates a "fit score" for a shape at a specific position.
  /// Higher score means the block helps clear lines or fits tightly into the current grid.
  double _calculatePlacementScore(List<List<int>> shape, int row, int col) {
    double score = 0;

    // 1. Line Progress & Completion Analysis
    // Reward blocks that complete lines or get them closer to completion (Analyzing the grid's "need").
    for (int r = 0; r < shape.length; r++) {
      int targetR = row + r;
      int existingInRow = 0;
      for (int c = 0; c < cols; c++) {
        if (boardState[targetR][c] != null || cartoonsGrid[targetR][c]) {
          existingInRow++;
        }
      }

      int addedInRow = 0;
      for (int c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 1) addedInRow++;
      }

      int totalAfter = existingInRow + addedInRow;
      if (totalAfter == cols) {
        score += 200; // Massive bonus for clearing a line
      } else {
        // High reward for filling lines that are already "needed"
        score += (totalAfter * 5.0);
      }
    }

    // Same for Columns
    for (int c = 0; c < shape[0].length; c++) {
      int targetC = col + c;
      int existingInCol = 0;
      for (int r = 0; r < rows; r++) {
        if (boardState[r][targetC] != null || cartoonsGrid[r][targetC]) {
          existingInCol++;
        }
      }

      int addedInCol = 0;
      for (int r = 0; r < shape.length; r++) {
        if (shape[r][c] == 1) addedInCol++;
      }

      int totalAfter = existingInCol + addedInCol;
      if (totalAfter == rows) {
        score += 200;
      } else {
        score += (totalAfter * 5.0);
      }
    }

    // 2. Adjacency & "Tightness" (Rewards filling gaps in the space)
    int adjacencyCount = 0;
    for (int r = 0; r < shape.length; r++) {
      for (int c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 1) {
          int tr = row + r;
          int tc = col + c;

          final neighbors = [
            [-1, 0],
            [1, 0],
            [0, -1],
            [0, 1],
          ];
          for (var dir in neighbors) {
            int nr = tr + dir[0];
            int nc = tc + dir[1];
            if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) {
              adjacencyCount +=
                  2; // Wall adjacency is great for space efficiency
            } else if (boardState[nr][nc] != null || cartoonsGrid[nr][nc]) {
              adjacencyCount += 3; // Filling gaps next to blocks is critical
            }
          }
        }
      }
    }
    score += adjacencyCount * 2.5;

    // 3. Size Balance
    int shapeSize = 0;
    for (var rList in shape) {
      for (var val in rList) {
        if (val == 1) shapeSize++;
      }
    }

    // Instead of rewarding large sizes, we give a slight boost to smaller blocks
    // to keep them frequent, and larger blocks are only favored if they clear lines.
    if (shapeSize <= 2) {
      score += 15.0; // Flat bonus for small, versatile shapes
    }

    return score;
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
      Get.find<PlayerController>().addScore(_score);
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
      cartoonsGrid = List.generate(
        rows,
        (_) => List.generate(cols, (_) => false),
      );
      // _placeObstacles(); // Removed gray blocks as per user request
      _setupTargets();
      boardNode.updateGrid(boardState, cartoonsGrid);
      _score = 0;
      _combo = 0;
      _collectedCartoons = 0;
      nextBlocks.clear();
      _blockRandom = _isChallenge
          ? Random(_challengeSeed)
          : Random(_currentLevel * 1013 + 7); // reset block sequence
      _fillNextBlocks();
    });
  }

  void _checkLevelProgression() {
    if (_score >= _targetScore && _collectedCartoons >= _targetCartoons) {
      if (_isChallenge) {
        _showChallengeCompleteDialog();
      } else {
        _showLevelUpDialog();
      }
    }
  }

  void _showChallengeCompleteDialog() {
    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        backgroundColor: const Color(0xffF8F9FB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            'CHALLENGE MET!',
            style: GoogleFonts.sourGummy(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.success,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You beat today\'s puzzle!',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xff475569),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '+$_challengeCoinReward 🪙',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '+$_challengeGemReward 💎',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () async {
                Get.back(); // close dialog

                final pc = Get.find<PlayerController>();
                pc.addCoins(_challengeCoinReward);
                pc.addGems(_challengeGemReward);
                await DailyChallengeService().markTodayCompleted();

                Get.back(); // return to home screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
              ),
              child: const Text('CLAIM & EXIT'),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
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

    // Reward player gems and coins for completing a level
    Get.find<PlayerController>().completeLevel(_currentLevel);
    Get.find<PlayerController>().addCoins(50);

    setState(() {
      _currentLevel++;
      boardState = List.generate(rows, (_) => List.generate(cols, (_) => null));
      cartoonsGrid = List.generate(
        rows,
        (_) => List.generate(cols, (_) => false),
      );
      // _placeObstacles(); // Removed gray blocks as per user request
      _setupTargets();
      boardNode.updateGrid(boardState, cartoonsGrid);
      _score = 0;
      _combo = 0;
      _collectedCartoons = 0;
      nextBlocks.clear();
      _blockRandom = Random(
        _currentLevel * 1013 + 7,
      ); // reset block sequence for new level
      _fillNextBlocks();
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
          if (boardState[targetR][targetC] != null ||
              cartoonsGrid[targetR][targetC])
            return false;
        }
      }
    }
    return true;
  }

  void _placeShape(NextBlockItem item, int row, int col) {
    setState(() {
      int cellsPlaced = 0;
      for (int r = 0; r < item.shape.length; r++) {
        for (int c = 0; c < item.shape[r].length; c++) {
          if (item.shape[r][c] == 1) {
            boardState[row + r][col + c] = item.color;
            cellsPlaced++;
          }
        }
      }
      boardNode.playPlacementEffect(row, col, item.color);
      // New logic: placement + cells + 5 bonus
      _score += cellsPlaced + 5;
      Get.find<PlayerController>().addBlocksCleared(cellsPlaced);

      nextBlocks.removeWhere((b) => b.id == item.id);

      // Update the board first to show the placed block
      boardNode.updateGrid(boardState, cartoonsGrid);

      // IMPORTANT: Clear lines BEFORE checking for game over.
      // Clearing lines frees up space, preventing premature game over.
      _checkLines();

      // Now fill blocks or check if remaining ones can fit
      _fillNextBlocks();

      _checkLevelProgression();
    });
  }

  void _checkLines() {
    List<int> fullRows = [];
    for (int r = 0; r < rows; r++) {
      bool full = true;
      for (int c = 0; c < cols; c++) {
        if (boardState[r][c] == null && !cartoonsGrid[r][c]) {
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
        if (boardState[r][c] == null && !cartoonsGrid[r][c]) {
          full = false;
          break;
        }
      }
      if (full) fullCols.add(c);
    }

    int linesCleared = fullRows.length + fullCols.length;

    if (linesCleared > 0) {
      setState(() {
        Set<String> collectedThisTurn = {};
        for (var r in fullRows) {
          for (int c = 0; c < cols; c++) {
            boardState[r][c] = null;
            if (cartoonsGrid[r][c]) collectedThisTurn.add('$r,$c');
          }
          boardNode.playLineClearEffect(r, true);
        }
        for (var c in fullCols) {
          for (int r = 0; r < rows; r++) {
            boardState[r][c] = null;
            if (cartoonsGrid[r][c]) collectedThisTurn.add('$r,$c');
          }
          boardNode.playLineClearEffect(c, false);
        }

        for (var key in collectedThisTurn) {
          var parts = key.split(',');
          _collectCartoon(int.parse(parts[0]), int.parse(parts[1]));
        }

        // Cartoon collection score (20 pts per cartoon)
        if (collectedThisTurn.isNotEmpty) {
          _score += collectedThisTurn.length * 20;
        }

        // Line clear score logic (User specified)
        if (linesCleared == 1) _score += 10;
        if (linesCleared == 2) _score += 30;
        if (linesCleared == 3) _score += 60;
        if (linesCleared >= 4) _score += 100;

        // Combo update
        _combo++;
        if (_combo > 1) {
          _score += _combo * 10; // Combo score
        } else {
          _score += 10; // First combo gives 10 per the logic Example logic
        }

        // Coins rewards
        int earnedCoins = linesCleared * 5;
        if (_combo > 1) {
          earnedCoins += 10; // Combo clear coins
        }

        Get.find<PlayerController>().addCoins(earnedCoins);
        Get.find<PlayerController>().addScore(_score);

        boardNode.updateGrid(boardState, cartoonsGrid);
      });
    } else {
      _combo = 0; // Reset combo if no line cleared
    }
  }

  void _collectCartoon(int r, int c) {
    setState(() {
      cartoonsGrid[r][c] = false;
      _collectedCartoons++;

      // 1. Play "Sparkle" Particle Effect
      boardNode.spawnParticleEffect(
        r,
        c,
        const Color(0xffFDBA74),
      ); // Light orange sparkle

      // 2. Play Main Cartoon Sprite Animation (Float & Fade)
      if (_cartoonImage != null) {
        boardNode.playCartoonCollectEffect(r, c, _cartoonImage!);
      }
    });
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
                'GOAL: $_targetScore | CARTOONS: $_collectedCartoons/$_targetCartoons',
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
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

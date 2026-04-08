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
import 'package:blockinity/ui/game_over.dart';
import 'package:blockinity/ui/view/transition_nodes.dart';
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
  NodeWithSize? transitionNode;
  // final Random _random = Random();

  late Random _blockRandom;
  int _score = 0;
  int _combo = 0;
  int _currentLevel = 1;
  int _coinsEarnedInLevel = 0;
  int _gemsEarnedInLevel = 0;

  // Challenge mode fields
  bool _isChallenge = false;
  int _challengeSeed = 0;
  int _challengeTargetScore = 0;
  int _challengeTargetCartoons = 0;
  // int _challengeObstacles = 0; // Removed unused field
  int _challengeCoinReward = 0;
  int _challengeGemReward = 0;
  DateTime? _challengeDate;
  int _challengeTargetLines = 0;
  int _challengeTargetCombos = 0;
  int _challengeTargetPerfectFits = 0;

  int _linesClearedInLevel = 0;
  int _combosAchievedInLevel = 0;
  int _perfectFitsInLevel = 0;
  bool _levelCleared = false;

  int get _targetScore =>
      _isChallenge ? _challengeTargetScore : 200 + ((_currentLevel - 1) * 200);
  // int get _obstacleCount => 0; // Removed unused getter

  final int rows = 10;
  final int cols = 8;
  late List<List<Color?>> boardState;
  late List<List<bool>> cartoonsGrid;
  late List<List<bool>> frozenCartoonsGrid;
  ui.Image? _cartoonImage;
  int _collectedCartoons = 0;
  int get _targetCartoons => _isChallenge
      ? _challengeTargetCartoons
      : min(3 + (_currentLevel ~/ 1.5).toInt(), 15);

  List<NextBlockItem> nextBlocks = [];
  int _idCounter = 0;

  NextBlockItem? _draggingItem;
  Offset _dragPosition = Offset.zero;
  Offset _dragOffset = Offset.zero;
  final GlobalKey _boardKey = GlobalKey();

  // Advanced Scoring logic
  int _chain = 0;
  DateTime? _lastPlacementTime;

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
      _challengeDate = args['challengeDate'] as DateTime?;
      _challengeTargetLines = args['targetLines'] ?? 0;
      _challengeTargetCombos = args['targetCombos'] ?? 0;
      _challengeTargetPerfectFits = args['targetPerfectFits'] ?? 0;
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
    frozenCartoonsGrid = List.generate(
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
    boardNode.updateGrid(boardState, cartoonsGrid, frozenCartoonsGrid);
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
            boardNode.updateGrid(boardState, cartoonsGrid, frozenCartoonsGrid);
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
    if (_currentLevel < 6) {
      // Prioritize center cells for "Easy" placement only for very early levels
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
        // Improvement: Freeze targets in higher levels
        if (_currentLevel > 15) {
          // Increase freeze probability with level
          double freezeProb = min(0.3 + (_currentLevel / 150), 0.8);
          if (_blockRandom.nextDouble() < freezeProb) {
            frozenCartoonsGrid[r][c] = true;
          }
        }
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
          if (_currentLevel > 30 && _blockRandom.nextDouble() < 0.5) {
            frozenCartoonsGrid[r][c] = true;
          }
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
      // Difficulty Scaling: Increase range of candidates as level increases
      int range = 2; // Default: very helpful
      if (_currentLevel > 20) {
        range = 10;
      } else if (_currentLevel > 10) {
        range = 6;
      } else if (_currentLevel > 5) {
        range = 4;
      }

      range = min(range, candidates.length);
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

    // Slot 1: Guaranteed Small/Versatile block (Always size <= 3)
    if (versatileCandidates.isNotEmpty) {
      // Pick a small block for versatility
      nextBlocks.add(
        _createBlockItem(
          versatileCandidates[_blockRandom.nextInt(versatileCandidates.length)]
              .key,
          shapeColors,
        ),
      );
    } else if (candidates.isNotEmpty) {
      // Fallback if no specific small blocks are found
      nextBlocks.add(_createBlockItem(candidates[0].key, shapeColors));
    }

    // Slot 2: Higher chance for small-to-medium blocks (Mindful variety)
    if (candidates.isNotEmpty) {
      // 70% chance to pick another versatile/small block if available
      if (_blockRandom.nextDouble() < 0.7 && versatileCandidates.isNotEmpty) {
        nextBlocks.add(
          _createBlockItem(
            versatileCandidates[_blockRandom.nextInt(
                  versatileCandidates.length,
                )]
                .key,
            shapeColors,
          ),
        );
      } else {
        // Otherwise pick from the top 5 candidates
        int range = min(5, candidates.length);
        nextBlocks.add(
          _createBlockItem(
            candidates[_blockRandom.nextInt(range)].key,
            shapeColors,
          ),
        );
      }
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

    // 1. Multi-Line & Multi-Column Completion Analysis
    int linesCompleted = 0;

    // Check Rows completion
    for (int r = 0; r < shape.length; r++) {
      int targetR = row + r;
      if (targetR >= rows) continue;

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

      if (existingInRow + addedInRow == cols) {
        linesCompleted++;
      }
    }

    // Check Columns completion
    for (int c = 0; c < shape[0].length; c++) {
      int targetC = col + c;
      if (targetC >= cols) continue;

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

      if (existingInCol + addedInCol == rows) {
        linesCompleted++;
      }
    }

    // Reward for completing lines
    if (linesCompleted >= 3) {
      score += 3000; // Super high priority for Triple+ clears
    } else if (linesCompleted == 2) {
      score += 1200; // High priority for Double clears
    } else if (linesCompleted == 1) {
      score += 400; // Basic priority for Single clears
    }

    // 2. Filling "Gaps" (Reward for filling lines that are ALMOST full)
    // This helps set up future combos
    for (int r = 0; r < shape.length; r++) {
      int targetR = row + r;
      if (targetR >= rows) continue;
      int count = 0;
      for (int c = 0; c < cols; c++)
        if (boardState[targetR][c] != null) count++;
      if (count >= cols - 2) score += 50; // Points for nearing completion
    }

    // 3. Adjacency & "Tightness"
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
              adjacencyCount += 2;
            } else if (boardState[nr][nc] != null || cartoonsGrid[nr][nc]) {
              adjacencyCount += 3;
            }
          }
        }
      }
    }
    score += adjacencyCount * 2.5;

    // 4. Hole Penalty & Smoothness (Analyze empty space strategically)
    // Penalize creating 1x1 holes (very hard to fill)
    int holesCreated = 0;
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
            if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
              // If neighbor is empty now, check if it's trapped
              if (boardState[nr][nc] == null && !cartoonsGrid[nr][nc]) {
                bool isTrapped = true;
                for (var d in neighbors) {
                  int nnr = nr + d[0];
                  int nnc = nc + d[1];
                  if (nnr >= 0 && nnr < rows && nnc >= 0 && nnc < cols) {
                    // Check if it will be surrounded after this placement
                    bool willBeOccupied =
                        (nnr >= row &&
                        nnr < row + shape.length &&
                        nnc >= col &&
                        nnc < col + shape[0].length &&
                        shape[nnr - row][nnc - col] == 1);
                    if (boardState[nnr][nnc] == null &&
                        !cartoonsGrid[nnr][nnc] &&
                        !willBeOccupied) {
                      isTrapped = false;
                      break;
                    }
                  }
                }
                if (isTrapped) holesCreated++;
              }
            }
          }
        }
      }
    }
    score -= holesCreated * 40; // Heavy penalty for creating holes

    // 5. Grid Height Analysis (Keep board 'low' or 'compact' for strategy)
    int maxHeight = 0;
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        if (boardState[r][c] != null || cartoonsGrid[r][c]) {
          maxHeight = max(maxHeight, rows - r);
          break;
        }
      }
    }
    score -= maxHeight * 5; // Reward keeping a low profile

    // 6. Neighboring Cartoons (Direct strategy for modern target)
    int cartoonNeighbors = 0;
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
            if (nr >= 0 &&
                nr < rows &&
                nc >= 0 &&
                nc < cols &&
                cartoonsGrid[nr][nc]) {
              cartoonNeighbors++;
            }
          }
        }
      }
    }
    score += cartoonNeighbors * 15; // Reward being near targets

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
      _showTransitionOverlay(isWin: false);
    }
  }

  void _showTransitionOverlay({required bool isWin, bool isWorldClear = false}) {
    setState(() {
      final size = MediaQuery.of(context).size;
      transitionNode = NodeWithSize(size);
      
      if (isWorldClear) {
        int nextWorldIndex = (_currentLevel ~/ 20); // 1 for level 20
        String worldName = "World ${nextWorldIndex + 1}";
        transitionNode!.addChild(
          WorldUnlockNode(
            size: size,
            worldTitle: "NEW WORLD UNLOCKED!\n$worldName",
            onComplete: () {
              setState(() => transitionNode = null);
              _navigateToWorldScreen();
            },
          ),
        );
      } else {
        transitionNode!.addChild(
          LevelCompleteNode(
            size: size,
            isWin: isWin,
            onComplete: () {
              setState(() => transitionNode = null);
              if (isWin) {
                _actualShowLevelUpDialog();
              } else {
                _actualShowGameOver();
              }
            },
          ),
        );
      }
    });
  }

  void _navigateToWorldScreen() {
    int nextWorldIndex = (_currentLevel ~/ 20); // 1 for level 20
    Get.toNamed('/world', arguments: {
      'justUnlocked': true,
      'unlockedWorldIndex': nextWorldIndex, // Pass index of the NEW world
    });
  }

  void _actualShowGameOver() {
    Get.to(
      () => const GameOver(),
      arguments: {
        'score': _score,
        'bestScore': Get.find<PlayerController>().highestScore.value,
        'level': _currentLevel,
        'stars': 0, // No stars on loss
        'levelProgress': _isChallenge
            ? (_score / _targetScore).clamp(0.0, 1.0)
            : (_collectedCartoons / _targetCartoons).clamp(0.0, 1.0),
        'isWin': false,
        'earnedCoins': _coinsEarnedInLevel,
        'earnedGems': _gemsEarnedInLevel,
      },
    )?.then((result) {
      if (result == 'retry') {
        _resetGame();
      } else if (result == 'next' && _score >= _targetScore) {
        _nextLevel();
      } else {
        Get.back(); // Go home
      }
    });
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
      boardNode.updateGrid(boardState, cartoonsGrid, frozenCartoonsGrid);
      _score = 0;
      _combo = 0;
      _coinsEarnedInLevel = 0;
      _collectedCartoons = 0;
      _linesClearedInLevel = 0;
      _combosAchievedInLevel = 0;
      _combosAchievedInLevel = 0;
      _perfectFitsInLevel = 0;
      _levelCleared = false;
      nextBlocks.clear();
      _blockRandom = _isChallenge
          ? Random(_challengeSeed)
          : Random(_currentLevel * 1013 + 7); // reset block sequence
      _fillNextBlocks();
    });
  }

  Future<void> _checkLevelProgression() async {
    bool scoreMet = !_isChallenge || _score >= _targetScore;
    bool cartoonsMet = _collectedCartoons >= _targetCartoons;

    // Additional challenge objectives
    bool linesMet =
        !_isChallenge || _linesClearedInLevel >= _challengeTargetLines;
    bool combosMet =
        !_isChallenge || _combosAchievedInLevel >= _challengeTargetCombos;
    bool fitsMet =
        !_isChallenge || _perfectFitsInLevel >= _challengeTargetPerfectFits;

    if (scoreMet && cartoonsMet && linesMet && combosMet && fitsMet) {
      if (_levelCleared) return;
      _levelCleared = true;

      if (_isChallenge) {
        _showChallengeCompleteDialog();
      } else {
        // Persistent progress update immediately - now awaited to ensure reliability
        await _persistLevelCompletion();

        if (_currentLevel % 20 == 0) {
          _showTransitionOverlay(isWin: true, isWorldClear: true);
        } else {
          _showTransitionOverlay(isWin: true);
        }
      }
    }
  }

  Future<void> _persistLevelCompletion() async {
    try {
      final levelCtrl = Get.find<LevelController>();
      final playerCtrl = Get.find<PlayerController>();

      // Update controllers (Rx state updates synchronously)
      await levelCtrl.completeLevel(_currentLevel);
      playerCtrl.completeLevel(_currentLevel);
      playerCtrl.addCoins(50); // Level clear reward

      debugPrint('Level $_currentLevel completion persisted successfully.');
    } catch (e) {
      debugPrint('Error persisting level completion: $e');
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
                final pc = Get.find<PlayerController>();
                pc.addCoins(_challengeCoinReward);
                pc.addGems(_challengeGemReward);

                // Show a loading indicator if necessary or just await the fast DB call
                if (_challengeDate != null) {
                  await DailyChallengeService().markCompleted(_challengeDate!);
                } else {
                  await DailyChallengeService().markTodayCompleted();
                }

                // Explicitly return to the challenges calendar screen
                Get.until(
                  (route) =>
                      Get.currentRoute == '/challenges' ||
                      route.settings.name == '/challenges',
                );
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

  void _actualShowLevelUpDialog() {
    Get.to(
      () => const GameOver(),
      arguments: {
        'score': _score,
        'bestScore': Get.find<PlayerController>().highestScore.value,
        'level': _currentLevel,
        'stars': 3, // Full stars on level clear
        'levelProgress': 1.0,
        'isWin': true,
        'earnedCoins': _coinsEarnedInLevel + 50, // Including level clear bonus
        'earnedGems': _gemsEarnedInLevel + 1, // Including level clear gem bonus
      },
    )?.then((result) {
      if (result == 'retry') {
        _resetGame();
      } else if (result == 'next') {
        _nextLevel();
      } else {
        Get.back(); // Go home
      }
    });
  }

  void _nextLevel() {
    setState(() {
      _levelCleared = false;
      _currentLevel++;
      boardState = List.generate(rows, (_) => List.generate(cols, (_) => null));
      cartoonsGrid = List.generate(
        rows,
        (_) => List.generate(cols, (_) => false),
      );
      // _placeObstacles(); // Removed gray blocks as per user request
      _setupTargets();
      boardNode.updateGrid(boardState, cartoonsGrid, frozenCartoonsGrid);
      _score = 0;
      _combo = 0;
      _coinsEarnedInLevel = 0;
      _collectedCartoons = 0;
      _linesClearedInLevel = 0;
      _combosAchievedInLevel = 0;
      _perfectFitsInLevel = 0;
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
          if (targetR < 0 || targetR >= rows || targetC < 0 || targetC >= cols) {
            return false;
          }
          if (boardState[targetR][targetC] != null ||
              cartoonsGrid[targetR][targetC]) {
            return false;
          }
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

      // Block placement score with increased size multiplier
      double sizeMultiplier = 1.0;
      if (cellsPlaced >= 9) {
        sizeMultiplier = 3.0;
      } else if (cellsPlaced >= 5) {
        sizeMultiplier = 2.5;
      } else if (cellsPlaced >= 4) {
        sizeMultiplier = 2.0;
      } else if (cellsPlaced >= 3) {
        sizeMultiplier = 1.5;
      }

      _score += (cellsPlaced * sizeMultiplier).toInt();

      // Smart Placement Bonus (Tight Fit - increased)
      int adjacentCount = 0;
      int totalOuterEdges = 0;
      bool isCornerOrEdge = false;
      for (int r = 0; r < item.shape.length; r++) {
        for (int c = 0; c < item.shape[r].length; c++) {
          if (item.shape[r][c] == 1) {
            int tr = row + r;
            int tc = col + c;

            // 4. Edge / Corner Bonus - increased
            if (tr == 0 || tr == rows - 1 || tc == 0 || tc == cols - 1) {
              isCornerOrEdge = true;
            }

            final neighbors = [
              [-1, 0],
              [1, 0],
              [0, -1],
              [0, 1],
            ];
            for (var dir in neighbors) {
              int nr = tr + dir[0];
              int nc = tc + dir[1];
              totalOuterEdges++;
              if (nr < 0 ||
                  nr >= rows ||
                  nc < 0 ||
                  nc >= cols ||
                  boardState[nr][nc] != null ||
                  cartoonsGrid[nr][nc]) {
                adjacentCount++;
              }
            }
          }
        }
      }
      // Tight fit bonus - increased to +10
      if (totalOuterEdges > 0 && (adjacentCount / totalOuterEdges) > 0.7) {
        _score += 10;
        _perfectFitsInLevel++;
      }

      // Edge / Corner addition - increased to +5
      if (isCornerOrEdge) _score += 5;

      // 5. Chain Bonus (Fast Placement - increased)
      final now = DateTime.now();
      if (_lastPlacementTime != null &&
          now.difference(_lastPlacementTime!).inSeconds < 3) {
        _chain++;
        _score += _chain * 5; // Multiplied chain bonus
      } else {
        _chain = 0;
      }
      _lastPlacementTime = now;

      // 6. Future Benefit Bonus (Completes a line soon - increased)
      bool helpsCompleteLine = false;
      // Check involved rows
      for (int r = 0; r < item.shape.length; r++) {
        int tr = row + r;
        if (tr >= rows) continue;
        int count = 0;
        for (int c = 0; c < cols; c++) {
          if (boardState[tr][c] != null || cartoonsGrid[tr][c]) count++;
        }
        if (count == cols - 1 || count == cols - 2) helpsCompleteLine = true;
      }
      if (helpsCompleteLine) _score += 10;

      Get.find<PlayerController>().addBlocksCleared(cellsPlaced);

      nextBlocks.removeWhere((b) => b.id == item.id);

      // Update the board first to show the placed block
      boardNode.updateGrid(boardState, cartoonsGrid, frozenCartoonsGrid);

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
          _interactWithTarget(int.parse(parts[0]), int.parse(parts[1]));
        }

        // Cartoon collection score - increased to 50 pts per cartoon
        if (collectedThisTurn.isNotEmpty) {
          _score += collectedThisTurn.length * 50;
        }

        // Cross Clear Bonus (Clearing rows and columns simultaneously)
        bool isCrossClear = fullRows.isNotEmpty && fullCols.isNotEmpty;
        if (isCrossClear) {
          _score += 50;
        }

        // Line clear score logic (Dramatically increased rewards)
        if (linesCleared == 1) {
          _score += 20;
        } else if (linesCleared == 2){
          _score += 80;}
        else if (linesCleared == 3){
          _score += 180;}
        else if (linesCleared >= 4){
          _score += 400;}

        // Multi-Line Bonus - increased to +20 per extra line
        if (linesCleared > 1) {
          _score += (linesCleared - 1) * 20;
        }

        // --- COMBO BLAST LOGIC ---
        _combo++;
        if (_combo > 1) {
          _combosAchievedInLevel++;
        }
        // User requested: score += combo * 10
        _score += _combo * 10;

        // Visual Feedback & Blast Effects
        _handleComboEffects(
          fullRows.isNotEmpty ? fullRows[0] : 0,
          fullCols.isNotEmpty ? fullCols[0] : 0,
        );

        _linesClearedInLevel += linesCleared;

        // Big Clear Bonus (Triple / Quadruple clears - increased to 50)
        if (linesCleared >= 3) {
          _score += 50;
        }

        // Coins rewards
        int earnedCoins = linesCleared * 5;
        if (_combo > 1) {
          earnedCoins += 10; // Combo clear coins
        }

        _coinsEarnedInLevel += earnedCoins;
        Get.find<PlayerController>().addCoins(earnedCoins);
        Get.find<PlayerController>().addScore(_score);

        boardNode.updateGrid(boardState, cartoonsGrid, frozenCartoonsGrid);

        // 6. Board Clear Bonus - increased to +500 jackpot
        bool isBoardEmpty = true;
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            if (boardState[r][c] != null || cartoonsGrid[r][c]) {
              isBoardEmpty = false;
              break;
            }
          }
          if (!isBoardEmpty) break;
        }
        if (isBoardEmpty) {
          _score += 500; // Super Jackpot
        }
      });
    } else {
      _combo = 0; // Reset combo if no line cleared
    }
  }

  void _handleComboEffects(int seedRow, int seedCol) {
    String? title;
    String? subtitle;
    Color color = AppColors.primary;

    if (_combo == 2) {
      title = "Nice!";
      subtitle = "Combo x2 ✨";
      color = Colors.blueAccent;
    } else if (_combo == 3) {
      title = "Great!";
      subtitle = "Combo x3 🔥";
      color = Colors.orange;
      boardNode.playBlastEffect(seedRow, seedCol, Colors.orange, 1);
    } else if (_combo == 5) {
      title = "Amazing!";
      subtitle = "Combo x5 💥";
      color = Colors.red;
      boardNode.playBlastEffect(seedRow, seedCol, Colors.red, 2);
      _triggerAutoClear();
    } else if (_combo >= 7) {
      title = "UNSTOPPABLE!";
      subtitle = "Combo x$_combo 🔥🔥";
      color = Colors.deepPurple;
      boardNode.playBlastEffect(seedRow, seedCol, Colors.deepPurple, 3);
    }

    if (title != null) {
      boardNode.playComboFeedback(
        "$title\n$subtitle",
        color,
        _combo >= 5 ? 1.4 : 1.0,
      );
    }
  }

  void _triggerAutoClear() {
    // Blast x5: Auto clear 1 random row
    int randomRow = Random().nextInt(rows);
    setState(() {
      for (int c = 0; c < cols; c++) {
          if (boardState[randomRow][c] != null) {
            boardState[randomRow][c] = null;
          }
          if (cartoonsGrid[randomRow][c]) {
            _interactWithTarget(randomRow, c);
          }
        }
      boardNode.playLineClearEffect(randomRow, true);
      boardNode.updateGrid(boardState, cartoonsGrid, frozenCartoonsGrid);
      _score += 100; // Bonus for auto clear
    });
  }

  void _interactWithTarget(int r, int c) {
    if (frozenCartoonsGrid[r][c]) {
      setState(() {
        frozenCartoonsGrid[r][c] = false;
        // Shatter/Unfreeze glass effect
        boardNode.playGlassBreakEffect(r, c);
        boardNode.updateGrid(boardState, cartoonsGrid, frozenCartoonsGrid);
      });
    } else {
      _collectCartoon(r, c);
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
    return WillPopScope(
      onWillPop: () {
        return _alertDailog();
      },
      child: Scaffold(
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
              if (transitionNode != null)
                Positioned.fill(
                  child: SpriteWidget(
                    transitionNode!,
                    transformMode: SpriteBoxTransformMode.letterbox,
                  ),
                ),
            ],
          ),
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
    double progress = _isChallenge
        ? (_score / _targetScore).clamp(0.0, 1.0)
        : (_collectedCartoons / _targetCartoons).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _buildTargetString(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
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

  String _buildTargetString() {
    if (!_isChallenge) {
      return 'TARGET: $_collectedCartoons/$_targetCartoons';
    }

    List<String> targets = [];
    targets.add('SCORE: $_score/$_challengeTargetScore');
    targets.add('TARGETS: $_collectedCartoons/$_challengeTargetCartoons');
    if (_challengeTargetLines > 0) {
      targets.add('LINES: $_linesClearedInLevel/$_challengeTargetLines');
    }
    if (_challengeTargetCombos > 0) {
      targets.add('COMBOS: $_combosAchievedInLevel/$_challengeTargetCombos');
    }
    if (_challengeTargetPerfectFits > 0) {
      targets.add('PERFECT: $_perfectFitsInLevel/$_challengeTargetPerfectFits');
    }

    return targets.join(' | ');
  }

  Widget _buildPauseButton() => Container(
    width: 55,
    height: 55,
    decoration: const BoxDecoration(
      color: Color(0xffE2EAF4),
      shape: BoxShape.circle,
    ),
    child: IconButton(
      onPressed: () {
        _alertDailog();
      },
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: Color(0xff2D3748),
        size: 28,
      ),
    ),
  );

  Future<bool> _alertDailog() async {
    final result = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Are you sure?',
                style: GoogleFonts.sourGummy(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff475569),
                ),
                
              ),
              content: Text(
                'You want to leave the game?',
                style: GoogleFonts.sourGummy(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff475569),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'No',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xff475569),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    Get.back(); // Go back to previous screen
                  },
                  child: Text(
                    'Yes',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:  AppColors.primary,
                    ),
                  ),
                ),
              ],
              );
          },
        );
    return result ?? false;
  }

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
        opacity: isDragging ? 0.0 : 1.0,
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
      double exactCol = (spriteX - 20) / 45.0;
      double exactRow = (spriteY - 20) / 45.0;
      int col = exactCol.round();
      int row = exactRow.round();

      // Show preview if we are over the board area
      if (row >= -2 && row < rows + 2 && col >= -2 && col < cols + 2) {
        bool isValid = _canPlace(_draggingItem!.shape, row, col);
        boardNode.updatePreview(
          _draggingItem!.shape,
          Offset(row.toDouble(), col.toDouble()),
          _draggingItem!.color,
          isValid: isValid,
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
      if (_canPlace(_draggingItem!.shape, row, col)) {
        _placeShape(_draggingItem!, row, col);
      }
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

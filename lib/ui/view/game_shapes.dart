import 'dart:math';

class GameShapes {
  // --- Small Shapes (1-3 blocks) ---
  static const List<List<int>> single = [
    [1],
  ];
  static const List<List<int>> duoHorizontal = [
    [1, 1],
  ];
  static const List<List<int>> duoVertical = [
    [1],
    [1],
  ];
  static const List<List<int>> cornerSmall = [
    [1, 1],
    [1, 0],
  ];

  // --- Medium Shapes (4 blocks) ---
  static const List<List<int>> tShape = [
    [1, 1, 1],
    [0, 1, 0],
  ];
  static const List<List<int>> lShape = [
    [1, 0],
    [1, 0],
    [1, 1],
  ];
  static const List<List<int>> square = [
    [1, 1],
    [1, 1],
  ];
  static const List<List<int>> line4 = [
    [1, 1, 1, 1],
  ];
  static const List<List<int>> zShape = [
    [1, 1, 0],
    [0, 1, 1],
  ];
  static const List<List<int>> sShape = [
    [0, 1, 1],
    [1, 1, 0],
  ];

  // --- Large Shapes (5+ blocks) ---
  static const List<List<int>> line5 = [
    [1, 1, 1, 1, 1],
  ];
  static const List<List<int>> lShapeLarge = [
    [1, 0, 0],
    [1, 0, 0],
    [1, 1, 1],
  ];
  static const List<List<int>> cross = [
    [0, 1, 0],
    [1, 1, 1],
    [0, 1, 0],
  ];
  static const List<List<int>> bigSquare = [
    [1, 1, 1],
    [1, 1, 1],
    [1, 1, 1],
  ];

  static const List<List<List<int>>> smallShapes = [
    single,
    duoHorizontal,
    duoVertical,
    cornerSmall,
  ];
  static const List<List<List<int>>> mediumShapes = [
    tShape,
    lShape,
    square,
    line4,
    zShape,
    sShape,
  ];
  static const List<List<List<int>>> largeShapes = [
    line5,
    lShapeLarge,
    cross,
    bigSquare,
  ];

  static const List<List<List<int>>> allShapes = [
    ...smallShapes,
    ...mediumShapes,
    ...largeShapes,
  ];

  static List<List<int>> getRandomShapeWeighted() {
    final random = Random();
    int r = random.nextInt(100);

    if (r < 50) {
      // 50% Small
      return smallShapes[random.nextInt(smallShapes.length)];
    } else if (r < 85) {
      // 35% Medium
      return mediumShapes[random.nextInt(mediumShapes.length)];
    } else {
      // 15% Large
      return largeShapes[random.nextInt(largeShapes.length)];
    }
  }

  static List<List<int>> getRandomShape() {
    final random = Random();
    return allShapes[random.nextInt(allShapes.length)];
  }
}

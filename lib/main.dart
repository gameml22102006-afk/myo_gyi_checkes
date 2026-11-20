import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyoGyiCheckersApp());
}

class MyoGyiCheckersApp extends StatelessWidget {
  const MyoGyiCheckersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'မျိုးကြီး ကျားကွက်',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFF2C1E16),
      ),
      home: const HomeScreen(),
    );
  }
}

enum Difficulty { easy, normal, hard }

// 1. ပင်မစာမျက်နှာ (Home Screen)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 50),
            // ဂိမ်းနာမည် "မျိုးကြီး"
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.shade700,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'မျိုးကြီး',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(3.0, 3.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'မြန်မာ့ရိုးရာ ကျားကွက်',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),

            // အောက်နားက Easy, Normal, Hard ခလုတ်များ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'အဆင့်ရွေးချယ်ပါ (Select Mode)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildModeButton(
                    context,
                    'EASY',
                    Colors.green.shade600,
                    Difficulty.easy,
                  ),
                  const SizedBox(height: 12),
                  _buildModeButton(
                    context,
                    'NORMAL',
                    Colors.orange.shade700,
                    Difficulty.normal,
                  ),
                  const SizedBox(height: 12),
                  _buildModeButton(
                    context,
                    'HARD',
                    Colors.red.shade700,
                    Difficulty.hard,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
      BuildContext context, String label, Color color, Difficulty difficulty) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(difficulty: difficulty),
          ),
        );
      },
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ကျားကောင် Data Model
class Piece {
  final bool isPlayer; // true = Player (အနီ), false = Bot (အနက်)
  bool isKing; // ကျား ဖြစ်/မဖြစ်

  Piece({required this.isPlayer, this.isKing = false});
}

// ရွှေ့နိုင်သော အကွက် Model
class Move {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final int? capturedRow;
  final int? capturedCol;

  Move({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    this.capturedRow,
    this.capturedCol,
  });

  bool get isCapture => capturedRow != null && capturedCol != null;
}

// 2. ဂိမ်းကစားမည့် စာမျက်နှာ (Game Screen)
class GameScreen extends StatefulWidget {
  final Difficulty difficulty;

  const GameScreen({super.key, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // 8x8 ဇယားကွက်
  late List<List<Piece?>> board;
  bool isPlayerTurn = true;
  int? selectedRow;
  int? selectedCol;
  List<Move> validMoves = [];
  String statusText = 'သင့်အလှည့် (အနီ)';
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    _initBoard();
  }

  // ဇယားကွက် စတင်ခင်းကျင်းခြင်း
  // ညာဘက်အောက်ထောင့် (7,7) ကို ဆန်တာလိုင်း (အကွက်ဖြူ) ထားထားသည်
  void _initBoard() {
    board = List.generate(8, (_) => List.filled(8, null));
    isPlayerTurn = true;
    selectedRow = null;
    selectedCol = null;
    validMoves = [];
    isGameOver = false;
    statusText = 'သင့်အလှည့် (အနီ)';

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        // (row + col) % 2 == 0 ဖြစ်သော အကွက်များတွင် အကောင်များချမည်
        // ထိုသို့ချခြင်းဖြင့် ညာဘက်အောက်ထောင့် (7,7) သည် ကစားကွက် (ဆန်တာလိုင်း) ဖြစ်သွားမည်
        if ((row + col) % 2 == 0) {
          if (row < 3) {
            board[row][col] = Piece(isPlayer: false); // Bot အကောင်များ (အပေါ်)
          } else if (row > 4) {
            board[row][col] = Piece(isPlayer: true); // Player အကောင်များ (အောက်)
          }
        }
      }
    }
  }

  // အကွက်တစ်ခုချင်းစီအတွက် ရွှေ့နိုင်သော လမ်းကြောင်းများ တွက်ချက်ခြင်း
  List<Move> _getValidMovesForPiece(int row, int col, List<List<Piece?>> currentBoard) {
    Piece? piece = currentBoard[row][col];
    if (piece == null) return [];

    List<Move> moves = [];
    List<int> rowDirs = [];

    // ကျားဖြစ်ရင် အရှေ့ရော အနောက်ပါ သွားလို့ရမယ်
    if (piece.isKing) {
      rowDirs = [-1, 1];
    } else {
      // ရိုးရိုးအကောင်ဆိုရင် နောက်ပြန်သွားလို့မရပါ (Player က အပေါ် -1၊ Bot က အောက် +1)
      rowDirs = piece.isPlayer ? [-1] : [1];
    }

    List<int> colDirs = [-1, 1];

    for (int rDir in rowDirs) {
      for (int cDir in colDirs) {
        int nextRow = row + rDir;
        int nextCol = col + cDir;

        if (_isInBounds(nextRow, nextCol)) {
          // ၁။ ရိုးရိုးရွှေ့ခြင်း (ဘေးကွက်လွတ်နေလျှင်)
          if (currentBoard[nextRow][nextCol] == null) {
            moves.add(Move(
              fromRow: row,
              fromCol: col,
              toRow: nextRow,
              toCol: nextCol,
            ));
          }
          // ၂။ ကျော်စားခြင်း (ရန်သူ့အကောင်ရှိပြီး သူ့နောက်ကွက် လွတ်နေလျှင်)
          else if (currentBoard[nextRow][nextCol]!.isPlayer != piece.isPlayer) {
            int jumpRow = nextRow + rDir;
            int jumpCol = nextCol + cDir;
            if (_isInBounds(jumpRow, jumpCol) && currentBoard[jumpRow][jumpCol] == null) {
              moves.add(Move(
                fromRow: row,
                fromCol: col,
                toRow: jumpRow,
                toCol: jumpCol,
                capturedRow: nextRow,
                capturedCol: nextCol,
              ));
            }
          }
        }
      }
    }
    return moves;
  }

  bool _isInBounds(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  // Player မှ အကွက်ကို နှိပ်လိုက်သောအခါ
  void _onTileTap(int row, int col) {
    if (!isPlayerTurn || isGameOver) return;

    // ရွေးထားပြီးသား အကောင်ကို ရွှေ့မည့်အကွက် နှိပ်လိုက်လျှင်
    for (Move move in validMoves) {
      if (move.toRow == row && move.toCol == col) {
        _executeMove(move);
        return;
      }
    }

    // ကိုယ့်အကောင်ကို ပြန်ရွေးလျှင်
    Piece? tappedPiece = board[row][col];
    if (tappedPiece != null && tappedPiece.isPlayer) {
      setState(() {
        selectedRow = row;
        selectedCol = col;
        validMoves = _getValidMovesForPiece(row, col, board);
      });
    } else {
      setState(() {
        selectedRow = null;
        selectedCol = null;
        validMoves = [];
      });
    }
  }

  // အကွက်ရွှေ့ခြင်းကို အတည်ပြုလုပ်ဆောင်ခြင်း
  void _executeMove(Move move) {
    setState(() {
      Piece piece = board[move.fromRow][move.fromCol]!;
      board[move.toRow][move.toCol] = piece;
      board[move.fromRow][move.fromCol] = null;

      // စားလိုက်သော အကောင်ရှိလျှင် ဖယ်ရှားမည်
      if (move.isCapture) {
        board[move.capturedRow!][move.capturedCol!] = null;
      }

      // တစ်ဖက်စွန်းရောက်လျှင် "ကျား (King)" ဖြစ်သွားမည်
      if (piece.isPlayer && move.toRow == 0) {
        piece.isKing = true;
      } else if (!piece.isPlayer && move.toRow == 7) {
        piece.isKing = true;
      }

      selectedRow = null;
      selectedCol = null;
      validMoves = [];

      // နိုင်/ရှုံး စစ်ဆေးခြင်း
      if (_checkGameOver()) return;

      isPlayerTurn = !isPlayerTurn;
      statusText = isPlayerTurn ? 'သင့်အလှည့် (အနီ)' : 'Bot စဉ်းစားနေသည်...';
    });

    // Bot အလှည့်ဖြစ်ပါက ခဏစောင့်ပြီး ရွှေ့ခိုင်းမည်
    if (!isPlayerTurn && !isGameOver) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _makeBotMove();
      });
    }
  }

  // Bot (AI) ၏ ရွှေ့ကွက်များ (Easy, Normal, Hard)
  void _makeBotMove() {
    if (isGameOver) return;

    List<Move> allBotMoves = [];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c] != null && !board[r][c]!.isPlayer) {
          allBotMoves.addAll(_getValidMovesForPiece(r, c, board));
        }
      }
    }

    if (allBotMoves.isEmpty) {
      _endGame('ဂုဏ်ယူပါတယ်! သင် အနိုင်ရရှိပါတယ် 🎉');
      return;
    }

    Move chosenMove;
    final random = Random();

    if (widget.difficulty == Difficulty.easy) {
      // Easy: ကြုံရာကျပန်း ရွှေ့မည်
      chosenMove = allBotMoves[random.nextInt(allBotMoves.length)];
    } else if (widget.difficulty == Difficulty.normal) {
      // Normal: စားကွက်ရှိရင် ဦးစားပေးစားမည်၊ မရှိရင် ကျပန်းရွှေ့မည်
      List<Move> captureMoves = allBotMoves.where((m) => m.isCapture).toList();
      if (captureMoves.isNotEmpty) {
        chosenMove = captureMoves[random.nextInt(captureMoves.length)];
      } else {
        chosenMove = allBotMoves[random.nextInt(allBotMoves.length)];
      }
    } else {
      // Hard: စားကွက် + ကျားဖြစ်မည့်အကွက် + အစားမခံရမည့်အကွက်ကို ဦးစားပေးတွက်ချက်မည်
      chosenMove = _getBestMoveForHardBot(allBotMoves);
    }

    _executeMove(chosenMove);
  }

  // Hard Mode အတွက် အကောင်းဆုံးအကွက် ရှာဖွေခြင်း
  Move _getBestMoveForHardBot(List<Move> moves) {
    Move bestMove = moves.first;
    int bestScore = -9999;
    final random = Random();

    for (Move move in moves) {
      int score = 0;
      if (move.isCapture) score += 50; // စားနိုင်ရင် အမှတ်ပေးမယ်
      if (move.toRow == 7) score += 30; // ကျားဖြစ်မယ့်အကွက်ဆို အမှတ်ပေးမယ်
      if (move.toCol == 0 || move.toCol == 7) score += 10; // ဘေးဘောင်ကပ်ရင် ပိုလုံခြုံလို့ အမှတ်ပေးမယ်

      // အမှတ်တူနေရင် နည်းနည်းကျပန်းဆန်အောင် random ထည့်ပေါင်းမယ်
      score += random.nextInt(10);

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    return bestMove;
  }

  // နိုင်/ရှုံး စစ်ဆေးခြင်း
  bool _checkGameOver() {
    int playerPieces = 0;
    int botPieces = 0;
    bool playerHasMoves = false;
    bool botHasMoves = false;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        Piece? p = board[r][c];
        if (p != null) {
          if (p.isPlayer) {
            playerPieces++;
            if (_getValidMovesForPiece(r, c, board).isNotEmpty) {
              playerHasMoves = true;
            }
          } else {
            botPieces++;
            if (_getValidMovesForPiece(r, c, board).isNotEmpty) {
              botHasMoves = true;
            }
          }
        }
      }
    }

    if (botPieces == 0 || !botHasMoves) {
      _endGame('ဂုဏ်ယူပါတယ်! သင် အနိုင်ရရှိပါတယ် 🎉');
      return true;
    } else if (playerPieces == 0 || !playerHasMoves) {
      _endGame('Bot အနိုင်ရသွားပါပြီ 😢');
      return true;
    }
    return false;
  }

  void _endGame(String message) {
    setState(() {
      isGameOver = true;
      statusText = message;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('ပွဲပြီးဆုံးပါပြီ'),
        content: Text(message, style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _initBoard();
              });
            },
            child: const Text('ပြန်ဆော့မည်'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('ပင်မစာမျက်နှာသို့'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String modeName = widget.difficulty.name.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text('မျိုးကြီး ($modeName)'),
        backgroundColor: const Color(0xFF1E130C),
        foregroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'အစကပြန်စမည်',
            onPressed: () {
              setState(() {
                _initBoard();
              });
            },
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // လက်ရှိအခြေအနေ ပြသည့် စာသား
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 8x8 ကျားကွက် ဇယားခုံ
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber.shade800, width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                  ),
                  itemCount: 64,
                  itemBuilder: (context, index) {
                    int row = index ~/ 8;
                    int col = index % 8;

                    // ညာဘက်အောက်ထောင့် (7,7) ကို အဖြူကွက် (ဆန်တာလိုင်း) ဖြစ်စေရန်
                    bool isPlayableSquare = (row + col) % 2 == 0;
                    bool isSelected = selectedRow == row && selectedCol == col;
                    bool isValidDest =
                        validMoves.any((m) => m.toRow == row && m.toCol == col);

                    Color tileColor;
                    if (isSelected) {
                      tileColor = Colors.amber.shade400;
                    } else if (isValidDest) {
                      tileColor = Colors.green.shade400;
                    } else if (isPlayableSquare) {
                      tileColor = const Color(0xFFF0D9B5); // ဆန်တာလိုင်း/ကစားကွက် (အလင်းရောင်)
                    } else {
                      tileColor = const Color(0xFF7B4B2A); // အမှောင်ကွက်
                    }

                    Piece? piece = board[row][col];

                    return GestureDetector(
                      onTap: () => _onTileTap(row, col),
                      child: Container(
                        color: tileColor,
                        child: Center(
                          child: piece != null
                              ? _buildPieceWidget(piece)
                              : (isValidDest
                                  ? Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade900.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),
          const Text(
            'မှတ်ချက် - ကျားဖြစ်သွားလျှင် ပတ်လည်သွားနိုင်သည်',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ကျားကောင် ဒီဇိုင်း
  Widget _buildPieceWidget(Piece piece) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: piece.isPlayer ? Colors.red.shade700 : Colors.grey.shade900,
        border: Border.all(
          color: piece.isKing ? Colors.amber : Colors.white70,
          width: piece.isKing ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: piece.isKing
          ? const Icon(
              Icons.star, // ကျားဖြစ်သွားရင် ကြယ်ပွင့်သင်္ကေတ ပေါ်မည်
              color: Colors.amber,
              size: 20,
            )
          : null,
    );
  }
}

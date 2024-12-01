import 'package:flutter/material.dart';
import 'dart:async';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MemoryGame(),
    );
  }
}

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  List<bool> revealed = [];
  int timeLeft = 30;
  int score = 0;
  int attempts = 3;
  int currentLevel = 1;
  Timer? timer;
  int firstSelected = -1;
  List<String> level2Images = [];
  List<String> level1Images = [];
  bool allRevealed = false;


  final Map<String, String> parentChildPairs = {
    "assets/lion.png": "assets/cub.png",
    "assets/dog.png": "assets/puppy.png",
    "assets/cat.png": "assets/kitten.png",
    "assets/elephant.png": "assets/calf.png",
  };

  @override
  void initState() {
    startLevel();
    super.initState();
  }

  startLevel() async {
    timeLeft = 30;
    level1Images = [
      "assets/icons/1.png",
      "assets/icons/2.png",
      "assets/icons/3.png",
      "assets/icons/4.png",
      "assets/icons/5.png",
      "assets/icons/6.png",
      "assets/icons/7.png",
      "assets/icons/8.png"
    ];
    level2Images = [
      "assets/lion.png",
      "assets/cub.png",
      "assets/dog.png",
      "assets/puppy.png",
      "assets/cat.png",
      "assets/kitten.png",
      "assets/elephant.png",
      "assets/calf.png"
    ];
    level1Images = [...level1Images, ...level1Images]..shuffle();
    level2Images = [...level2Images, ...level2Images]..shuffle();

    setState(() {
      revealed = List<bool>.filled(16, true);
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      revealed = List<bool>.filled(16, false);
    });
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          timer.cancel();
          showGameOverDialog();
        }
      });
    });
  }

  void showGameOverDialog(
      {bool win = false, bool firstLevelCompleted = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(win
            ? "You Win!"
            : firstLevelCompleted
            ? "You've completed the first level"
            : "Game Over"),
        content: Text(win || firstLevelCompleted
            ? "Congratulations! Your score: $score"
            : "Better luck next time! Your score: $score"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (firstLevelCompleted) {
                currentLevel++;
                attempts = 3;
                firstSelected = -1;
                startLevel();
              } else {
                firstSelected = -1;
                currentLevel = 1;
                score = 0;
                attempts = 3;
                startLevel();
              }
            },
            child: Text(firstLevelCompleted ? "Level 2" : "Play Again"),
          ),
        ],
      ),
    );
  }

  revealCard(int index) async {
    if (!revealed[index]) {
      setState(() {
        revealed[index] = true;
      });

      if (firstSelected == -1) {
        firstSelected = index;
      } else {
        if (currentLevel == 1) {
          if (level1Images[firstSelected] == level1Images[index]) {
            score += 10;
            firstSelected = -1;
            revealed[index] = true;
            if (!revealed.contains(false)) {
              timer?.cancel();
              showGameOverDialog(firstLevelCompleted: true);
            }
          } else {
            attempts--;
            if (attempts != 0) {
              await Future.delayed(const Duration(milliseconds: 500));
              setState(() {
                revealed[firstSelected] = false;
                revealed[index] = false;
              });
              firstSelected = -1;
            } else {
              timer?.cancel();
              showGameOverDialog();
            }
          }
        } else {
          String firstImage = level2Images[firstSelected];
          String secondImage = level2Images[index];
          bool isPair =
              parentChildPairs[firstImage] == secondImage ||
                  parentChildPairs[secondImage] == firstImage;

          if (isPair) {
            score += 10;
            firstSelected = -1;
            revealed[index] = true;
            if (!revealed.contains(false)) {
              timer?.cancel();
              showGameOverDialog(win: true);
            }
          } else {
            attempts--;
            if (attempts != 0) {
              await Future.delayed(const Duration(milliseconds: 500));
              setState(() {
                revealed[firstSelected] = false;
                revealed[index] = false;
              });
              firstSelected = -1;
            } else {
              timer?.cancel();
              showGameOverDialog();
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.all(8),
            child: const Text("Memory Game")),
        backgroundColor: Colors.purpleAccent,
        centerTitle: true,
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Level: $currentLevel",
                      style: const TextStyle(fontSize: 18)),
                  Text("Time: $timeLeft", style: const TextStyle(fontSize: 18)),
                  Text("Score: $score", style: const TextStyle(fontSize: 18)),
                  Text("Attempts: $attempts",
                      style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: 16,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, childAspectRatio: 1),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          revealCard(index);
                        },
                        child: Card(
                          color: revealed[index]
                              ? Colors.white
                              : Colors.purpleAccent,
                          child: revealed[index]
                              ? Image.asset(currentLevel == 1
                              ? level1Images[index]
                              : level2Images[index])
                              : const Icon(
                            Icons.question_mark_rounded,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }),
              ),
            ),
            GestureDetector(
              onTap: () async {
                List<bool> temp = [];
                setState(() {
                  temp = revealed;
                  timeLeft = 30;
                });
                revealed = List<bool>.filled(16, true);
                await Future.delayed(const Duration(seconds: 2));
                setState(() {
                  revealed = temp;
                });
              },
              child: Container(
                width: 200,
                height: 60,
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "Hint",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
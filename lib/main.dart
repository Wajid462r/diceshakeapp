import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const DiceShakeApp());
}

class DiceShakeApp extends StatelessWidget {
  const DiceShakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dice Shake',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const DiceScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> with TickerProviderStateMixin {
  final Random _random = Random();
  int _diceValue1 = 1;
  int _diceValue2 = 1;
  int _numberOfDice = 2;
  bool _isRolling = false;
  
  // Parametri per la rilevazione dello shake
  static const double _shakeThreshold = 15.0;
  DateTime? _lastShakeTime;
  static const int _shakeCooldownMs = 1000;
  
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Inizializza l'animazione
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Avvia il listener dell'accelerometro
    _startAccelerometerListener();
  }

  void _startAccelerometerListener() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      // Calcola la magnitudine dell'accelerazione
      double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z
      );
      
      // Rileva lo shake
      if (acceleration > _shakeThreshold && !_isRolling) {
        final now = DateTime.now();
        if (_lastShakeTime == null || 
            now.difference(_lastShakeTime!).inMilliseconds > _shakeCooldownMs) {
          _lastShakeTime = now;
          _rollDice();
        }
      }
    });
  }

  void _rollDice() {
    if (_isRolling) return;
    
    setState(() {
      _isRolling = true;
    });
    
    // Avvia l'animazione
    _animationController.forward(from: 0);
    
    // Simula il lancio dei dadi con animazione
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (timer.tick >= 10) {
        timer.cancel();
        setState(() {
          _isRolling = false;
        });
      } else {
        setState(() {
          _diceValue1 = _random.nextInt(6) + 1;
          if (_numberOfDice == 2) {
            _diceValue2 = _random.nextInt(6) + 1;
          }
        });
      }
    });
  }

  Widget _buildDice(int value) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _isRolling ? _rotationAnimation.value : 0,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _buildDiceDots(value),
          ),
        );
      },
    );
  }

  Widget _buildDiceDots(int value) {
    return Center(
      child: _getDicePattern(value),
    );
  }

  Widget _getDicePattern(int value) {
    const double dotSize = 18.0;
    const Color dotColor = Colors.red;

    Widget dot() => Container(
      width: dotSize,
      height: dotSize,
      decoration: const BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
    );

    Widget spacer() => const SizedBox(width: 20, height: 20);

    switch (value) {
      case 1:
        return dot();
      case 2:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [dot(), spacer()]),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [spacer(), dot()]),
          ],
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [dot(), spacer()]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [dot()]),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [spacer(), dot()]),
          ],
        );
      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [dot(), dot()]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [dot(), dot()]),
          ],
        );
      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [dot(), dot()]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [dot()]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [dot(), dot()]),
          ],
        );
      case 6:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [dot(), dot()]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [dot(), dot()]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [dot(), dot()]),
          ],
        );
      default:
        return dot();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎲 Dice Shake'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade400,
              Colors.red.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Titolo
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Scuoti il dispositivo\nper lanciare i dadi!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Dadi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDice(_diceValue1),
                  if (_numberOfDice == 2) _buildDice(_diceValue2),
                ],
              ),
              
              // Totale
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'TOTALE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _numberOfDice == 2 
                          ? (_diceValue1 + _diceValue2).toString()
                          : _diceValue1.toString(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Controlli
              Column(
                children: [
                  // Pulsante lancio manuale
                  ElevatedButton.icon(
                    onPressed: _isRolling ? null : _rollDice,
                    icon: const Icon(Icons.casino, size: 28),
                    label: const Text(
                      'Lancia manualmente',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Selector numero dadi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Numero dadi:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 15),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 1, label: Text('1')),
                          ButtonSegment(value: 2, label: Text('2')),
                        ],
                        selected: {_numberOfDice},
                        onSelectionChanged: (Set<int> newSelection) {
                          setState(() {
                            _numberOfDice = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.selected)) {
                                return Colors.white;
                              }
                              return Colors.red.shade300;
                            },
                          ),
                          foregroundColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.selected)) {
                                return Colors.red;
                              }
                              return Colors.white;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}

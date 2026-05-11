import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DiceShakeApp());
}

class DiceShakeApp extends StatelessWidget {
  const DiceShakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dice Shake',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1F1F2E),
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F2E),
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const DiceScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/dice_shake.db';
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE dice_rolls(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            dice_values TEXT NOT NULL,
            total INTEGER NOT NULL,
            dice_sides TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertRoll(List<int> values, int total, List<int> diceSides) async {
    final db = await database;
    await db.insert(
      'dice_rolls',
      {
        'dice_values': jsonEncode(values),
        'total': total,
        'dice_sides': jsonEncode(diceSides),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getRolls() async {
    final db = await database;
    return await db.query('dice_rolls', orderBy: 'timestamp DESC');
  }

  Future<void> deleteAllRolls() async {
    final db = await database;
    await db.delete('dice_rolls');
  }
}

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> with TickerProviderStateMixin {
  final Random _random = Random();
  final DatabaseHelper _db = DatabaseHelper();
  
  late List<int> _diceValues;
  late List<int> _diceSides;
  int _numberOfDice = 2;
  bool _isRolling = false;
  bool _accelerometerEnabled = false;
  List<Map<String, dynamic>> _rollHistory = [];
  
  static const double _shakeThreshold = 15.0;
  DateTime? _lastShakeTime;
  static const int _shakeCooldownMs = 1000;
  
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _diceSides = List<int>.filled(_numberOfDice, 6);
    _diceValues = List<int>.filled(_numberOfDice, 1);
    
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
    
    _loadRollHistory();
  }

  Future<void> _loadRollHistory() async {
    final rolls = await _db.getRolls();
    setState(() {
      _rollHistory = rolls;
    });
  }

  void _startAccelerometerListener() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (!_accelerometerEnabled) return;
      
      double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z
      );
      
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
    
    _animationController.forward(from: 0);
    
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (timer.tick >= 10) {
        timer.cancel();
        setState(() {
          _isRolling = false;
        });
        
        final totalValue = _diceValues.reduce((a, b) => a + b);
        _db.insertRoll(_diceValues.toList(), totalValue, _diceSides.toList());
        _loadRollHistory();
      } else {
        setState(() {
          for (int i = 0; i < _numberOfDice; i++) {
            _diceValues[i] = _random.nextInt(_diceSides[i]) + 1;
          }
        });
      }
    });
  }

  void _changeNumberOfDice(int newNumber) {
    setState(() {
      _numberOfDice = newNumber;
      _diceSides = List<int>.filled(newNumber, 6);
      _diceValues = List<int>.filled(newNumber, 1);
    });
  }

  void _showDiceConfigDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return DiceConfigDialog(
          numberOfDice: _numberOfDice,
          diceSides: _diceSides,
          onConfigChanged: (newSides) {
            setState(() {
              _diceSides = newSides;
              _diceValues = List<int>.filled(_numberOfDice, 1);
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _showClearConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancellare cronologia?'),
          content: const Text('Sei sicuro di voler eliminare tutti i lanci salvati? Questa azione non può essere annullata.'),
          backgroundColor: const Color(0xFF1F1F2E),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                _db.deleteAllRolls();
                _loadRollHistory();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cronologia eliminata')),
                );
              },
              child: const Text('Elimina', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDice(int value, int sides) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _isRolling ? _rotationAnimation.value : 0,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF00D9FF), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D9FF).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _buildDiceDots(value, sides),
          ),
        );
      },
    );
  }

  Widget _buildDiceDots(int value, int sides) {
    return Center(
      child: _getDicePattern(value, sides),
    );
  }

  Widget _getDicePattern(int value, int sides) {
    const double dotSize = 14.0;
    const Color dotColor = Color(0xFF00D9FF);

    Widget dot() => Container(
      width: dotSize,
      height: dotSize,
      decoration: const BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
    );

    Widget spacer() => const SizedBox(width: 15, height: 15);

    if (sides <= 6) {
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
    } else {
      return Center(
        child: Text(
          value.toString(),
          style: const TextStyle(
            color: dotColor,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = _diceValues.isEmpty ? 0 : _diceValues.reduce((a, b) => a + b);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎲 Dice Shake'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showClearConfirmDialog,
            tooltip: 'Cancella cronologia',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Scuoti il dispositivo\nper lanciare i dadi!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Dadi
                    Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      alignment: WrapAlignment.center,
                      children: List.generate(
                        _numberOfDice,
                        (index) => _buildDice(_diceValues[index], _diceSides[index]),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Totale
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00D9FF), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D9FF).withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'TOTALE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            totalValue.toString(),
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00D9FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Toggle Accelerometro
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00D9FF), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Accelerometro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: _accelerometerEnabled,
                            onChanged: (value) {
                              setState(() {
                                _accelerometerEnabled = value;
                                if (value) {
                                  _startAccelerometerListener();
                                } else {
                                  _accelerometerSubscription?.cancel();
                                }
                              });
                            },
                            activeColor: const Color(0xFF00D9FF),
                            activeTrackColor: const Color(0xFF00D9FF).withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Pulsante lancio manuale
                    ElevatedButton.icon(
                      onPressed: _isRolling ? null : _rollDice,
                      icon: const Icon(Icons.casino, size: 24),
                      label: const Text(
                        'Lancia manualmente',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF),
                        foregroundColor: const Color(0xFF0F0F1E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Selector numero dadi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Numero dadi:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 1, label: Text('1')),
                            ButtonSegment(value: 2, label: Text('2')),
                            ButtonSegment(value: 3, label: Text('3')),
                          ],
                          selected: {_numberOfDice},
                          onSelectionChanged: (Set<int> newSelection) {
                            _changeNumberOfDice(newSelection.first);
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return const Color(0xFF00D9FF);
                                }
                                return const Color(0xFF2A2A3E);
                              },
                            ),
                            foregroundColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return const Color(0xFF0F0F1E);
                                }
                                return Colors.white70;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Pulsante configurazione dadi
                    OutlinedButton.icon(
                      onPressed: _showDiceConfigDialog,
                      icon: const Icon(Icons.settings, size: 20, color: Color(0xFF00D9FF)),
                      label: const Text(
                        'Configura dadi',
                        style: TextStyle(color: Color(0xFF00D9FF), fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF00D9FF), width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Cronologia
              if (_rollHistory.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Cronologia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2A3E), width: 1),
                    ),
                    child: Column(
                      children: List.generate(
                        _rollHistory.length > 10 ? 10 : _rollHistory.length,
                        (index) {
                          final roll = _rollHistory[index];
                          final values = List<int>.from(jsonDecode(roll['dice_values']));
                          final total = roll['total'];
                          final timestamp = DateTime.fromMillisecondsSinceEpoch(roll['timestamp']);
                          final formattedTime = DateFormat('HH:mm:ss').format(timestamp);
                          
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      values.join(', '),
                                      style: const TextStyle(
                                        color: Color(0xFF00D9FF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Totale: $total',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          formattedTime,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (index < (_rollHistory.length > 10 ? 9 : _rollHistory.length - 1))
                                const Divider(
                                  color: Color(0xFF2A2A3E),
                                  height: 0,
                                  indent: 12,
                                  endIndent: 12,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
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

class DiceConfigDialog extends StatefulWidget {
  final int numberOfDice;
  final List<int> diceSides;
  final Function(List<int>) onConfigChanged;

  const DiceConfigDialog({
    required this.numberOfDice,
    required this.diceSides,
    required this.onConfigChanged,
    super.key,
  });

  @override
  State<DiceConfigDialog> createState() => _DiceConfigDialogState();
}

class _DiceConfigDialogState extends State<DiceConfigDialog> {
  late List<int> _tempSides;

  @override
  void initState() {
    super.initState();
    _tempSides = List<int>.from(widget.diceSides);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configura dadi'),
      backgroundColor: const Color(0xFF1F1F2E),
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            widget.numberOfDice,
            (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dado ${index + 1}:',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00D9FF), width: 1),
                      ),
                      child: DropdownButton<int>(
                        value: _tempSides[index],
                        isExpanded: true,
                        underline: Container(),
                        dropdownColor: const Color(0xFF1F1F2E),
                        items: List.generate(10, (i) => i + 1).map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'D$value',
                                style: const TextStyle(color: Color(0xFF00D9FF)),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _tempSides[index] = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () {
            widget.onConfigChanged(_tempSides);
          },
          child: const Text('Conferma', style: TextStyle(color: Color(0xFF00D9FF))),
        ),
      ],
    );
  }
}

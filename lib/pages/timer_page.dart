import 'dart:async';
import 'package:flutter/material.dart';
import '../data/database_service.dart';
import '../widgets/name_tile.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  final List<String> names = [
    'Cesar', 'Giovanni', 'Vlads', 'Joao', 'Lara',
    'Haikal', 'Iago', 'Alexandre', 'Cris'
  ];
  final Map<String, String> completedTimes = {};

  final _dbService = DatabaseService();

  Timer? _individualTimer;
  Timer? _globalTimer;
  int _individualSeconds = 120;
  int _globalSeconds = 0;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _dbService.init();
    _startGlobalTimer();
  }

  void _startGlobalTimer() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _globalSeconds++);
    });
  }

  void _toggleIndividualTimer() {
    if (_running) {
      _stopIndividualTimer();
    } else {
      _startIndividualTimer();
    }
  }

  void _startIndividualTimer() {
    setState(() => _running = true);
    _individualTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _individualSeconds--);
    });
  }

  void _stopIndividualTimer() {
    _individualTimer?.cancel();
    setState(() => _running = false);

    int timeUsed = 120 - _individualSeconds;
    final formattedUsedTime = _formatTime(timeUsed);

    for (var name in names) {
      if (!completedTimes.containsKey(name)) {
        completedTimes[name] = formattedUsedTime;
        break;
      }
    }

    _individualSeconds = 120;
  }

  void _resetAll() {
    _individualTimer?.cancel();
    _globalTimer?.cancel();

    setState(() {
      _running = false;
      _individualSeconds = 120;
      _globalSeconds = 0;
      completedTimes.clear();
    });

    _startGlobalTimer();
  }

  Future<void> _saveTimesToDb() async {
    for (var entry in completedTimes.entries) {
      final parts = entry.value.split(':');
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      final total = minutes * 60 + seconds;

      await _dbService.insertEntry(entry.key, total);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tempos salvos com sucesso!')),
      );
    }
  }

  Future<void> _showRanking() async {
    final result = await _dbService.getRanking();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ranking da Sprint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: result.map((row) {
            final name = row['name'] as String;
            final total = row['total'] as int;
            final time = _formatTime(total);
            return ListTile(
              title: Text(name),
              trailing: Text(time),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final negative = seconds < 0;
    final absSeconds = seconds.abs();
    final minutes = (absSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (absSeconds % 60).toString().padLeft(2, '0');
    return '${negative ? '-' : ''}$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final individualColor = _individualSeconds < 0 ? Colors.red : Colors.black;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lista de nomes
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: names.map((name) {
                    final time = completedTimes[name] ?? '--:--';

                    bool isOverLimit = false;
                    if (completedTimes.containsKey(name)) {
                      final parts = completedTimes[name]!.split(':');
                      final usedMinutes = int.tryParse(parts[0]) ?? 0;
                      final usedSeconds = int.tryParse(parts[1]) ?? 0;
                      isOverLimit = (usedMinutes * 60 + usedSeconds) > 120;
                    }

                    final isCurrent = !completedTimes.containsKey(name) &&
                        completedTimes.length == names.indexOf(name);

                    return NameTile(
                      name: name,
                      time: time,
                      isOverLimit: isOverLimit,
                      isCurrent: isCurrent,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 32),
            // Controles
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Global: ${_formatTime(_globalSeconds)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                      margin: const EdgeInsets.only(bottom: 36),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatTime(_individualSeconds),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: individualColor,
                        ),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ElevatedButton(
                        onPressed: _toggleIndividualTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _running ? Colors.red : Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: Text(_running ? 'Stop' : 'Start', style: const TextStyle(fontSize: 20)),
                      ),
                      ElevatedButton(
                        onPressed: _resetAll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Reset', style: TextStyle(fontSize: 20)),
                      ),
                      ElevatedButton(
                        onPressed: _saveTimesToDb,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Salvar', style: TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: _showRanking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Resultado', style: TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

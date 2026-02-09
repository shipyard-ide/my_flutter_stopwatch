import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stopwatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const StopwatchPage(),
    );
  }
}

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  late Stopwatch _stopwatch;
  Timer? _timer;
  final List<Duration> _laps = [];

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {});
    });
  }

  void _toggleStartPause() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _timer?.cancel();
      } else {
        _stopwatch.start();
        _startTimer();
      }
    });
  }

  void _reset() {
    setState(() {
      _stopwatch.stop();
      _stopwatch.reset();
      _timer?.cancel();
      _laps.clear();
    });
  }

  void _addLap() {
    if (_stopwatch.isRunning) {
      setState(() {
        _laps.insert(0, _stopwatch.elapsed);
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final centiseconds =
        twoDigits((duration.inMilliseconds.remainder(1000) ~/ 10));
    return '$hours:$minutes:$seconds.$centiseconds';
  }

  /// Compute per-lap split durations and find best/worst indices
  List<Duration> get _lapSplits {
    final splits = <Duration>[];
    for (int i = 0; i < _laps.length; i++) {
      final previousLapTime = i < _laps.length - 1 ? _laps[i + 1] : Duration.zero;
      splits.add(_laps[i] - previousLapTime);
    }
    return splits;
  }

  int? get _bestLapIndex {
    if (_laps.length < 2) return null;
    final splits = _lapSplits;
    int best = 0;
    for (int i = 1; i < splits.length; i++) {
      if (splits[i] < splits[best]) best = i;
    }
    return best;
  }

  int? get _worstLapIndex {
    if (_laps.length < 2) return null;
    final splits = _lapSplits;
    int worst = 0;
    for (int i = 1; i < splits.length; i++) {
      if (splits[i] > splits[worst]) worst = i;
    }
    return worst;
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _stopwatch.elapsed;
    final isRunning = _stopwatch.isRunning;
    final bestIdx = _bestLapIndex;
    final worstIdx = _worstLapIndex;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Stopwatch'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          // Timer display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _formatDuration(elapsed),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                onPressed: isRunning
                    ? _addLap
                    : (_stopwatch.elapsedMilliseconds > 0 ? _reset : null),
                icon: isRunning ? Icons.flag : Icons.refresh,
                label: isRunning ? 'Lap' : 'Reset',
                isPrimary: false,
              ),
              const SizedBox(width: 24),
              _buildControlButton(
                onPressed: _toggleStartPause,
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                label: isRunning ? 'Pause' : 'Start',
                isPrimary: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Laps list
          if (_laps.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'Laps',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (bestIdx != null) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Best',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(width: 12),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Worst',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    '${_laps.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _laps.length,
                itemBuilder: (context, index) {
                  final lapNumber = _laps.length - index;
                  final lapTime = _laps[index];
                  final previousLapTime =
                      index < _laps.length - 1 ? _laps[index + 1] : Duration.zero;
                  final lapDuration = lapTime - previousLapTime;

                  final isBest = index == bestIdx;
                  final isWorst = index == worstIdx;

                  Color? highlightColor;
                  IconData? badgeIcon;
                  if (isBest) {
                    highlightColor = Colors.green;
                    badgeIcon = Icons.bolt;
                  } else if (isWorst) {
                    highlightColor = Colors.red;
                    badgeIcon = Icons.trending_down;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: highlightColor != null
                          ? Border.all(color: highlightColor.withOpacity(0.6), width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: highlightColor?.withOpacity(0.2) ??
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: highlightColor != null
                                ? Icon(badgeIcon, size: 20, color: highlightColor)
                                : Text(
                                    '$lapNumber',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDuration(lapTime),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w500,
                                  color: highlightColor,
                                ),
                              ),
                              Text(
                                '+${_formatDuration(lapDuration)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'monospace',
                                  color: highlightColor?.withOpacity(0.7) ??
                                      Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (highlightColor != null)
                          Text(
                            isBest ? 'BEST' : 'WORST',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: highlightColor,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Press Start to begin',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    final isEnabled = onPressed != null;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnabled
                ? (isPrimary
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest)
                : Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(40),
              child: Center(
                child: Icon(
                  icon,
                  size: 36,
                  color: isEnabled
                      ? (isPrimary
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant)
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isEnabled
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

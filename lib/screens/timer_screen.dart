import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // Controllers cho việc nhập liệu
  final TextEditingController _minController = TextEditingController(text: '0');
  final TextEditingController _secController = TextEditingController(text: '0');

  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  Duration _initialTime = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;
  DateTime? _endTime;

  final NotificationService _notificationService = NotificationService();
  final int _timerNotificationId = 1001;

  @override
  void initState() {
    super.initState();
    _notificationService.requestExactAlarmPermission();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _minController.dispose();
    _secController.dispose();
    super.dispose();
  }

  void _startTimer() {
    int mins = int.tryParse(_minController.text) ?? 0;
    int secs = int.tryParse(_secController.text) ?? 0;
    
    if (mins == 0 && secs == 0) return;

    final duration = Duration(minutes: mins, seconds: secs);
    final endTime = DateTime.now().add(duration);

    setState(() {
      _initialTime = duration;
      _remainingTime = _initialTime;
      _isRunning = true;
      _isPaused = false;
      _endTime = endTime;
    });

    _notificationService.scheduleTimerNotification(
      id: _timerNotificationId,
      title: "Hết giờ!",
      body: "Thời gian tập luyện đã kết thúc.",
      scheduledDate: endTime,
    );

    _tick();
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRunning || _isPaused) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      if (_endTime != null) {
        final remaining = _endTime!.difference(now);
        if (remaining.inMilliseconds <= 0) {
          setState(() {
            _remainingTime = Duration.zero;
            _isRunning = false;
            _isPaused = false;
          });
          timer.cancel();
        } else {
          setState(() {
            _remainingTime = remaining;
          });
        }
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
      _timer?.cancel();
    });
    _notificationService.cancelNotification(_timerNotificationId);
  }

  void _resumeTimer() {
    final newEndTime = DateTime.now().add(_remainingTime);
    setState(() {
      _isPaused = false;
      _endTime = newEndTime;
    });
    
    _notificationService.scheduleTimerNotification(
      id: _timerNotificationId,
      title: "Hết giờ!",
      body: "Thời gian tập luyện đã kết thúc.",
      scheduledDate: newEndTime,
    );
    
    _tick();
  }

  void _resetTimer() {
    setState(() {
      _timer?.cancel();
      _isRunning = false;
      _isPaused = false;
      _remainingTime = Duration.zero;
      _minController.text = '0';
      _secController.text = '0';
    });
    _notificationService.cancelNotification(_timerNotificationId);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hiển thị Countdown
            Text(
              _formatDuration(_remainingTime),
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 48),

            if (!_isRunning) ...[
              // Input fields khi chưa chạy
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeInput(_minController, 'MINS'),
                  const Text(' : ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  _buildTimeInput(_secController, 'SECS'),
                ],
              ),
              const SizedBox(height: 48),
              _buildActionButton(
                label: 'START',
                onPressed: _startTimer,
                color: const Color(0xFF111827),
              ),
            ] else ...[
              // Controls khi đang chạy hoặc pause
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!_isPaused)
                    _buildActionButton(
                      label: 'PAUSE',
                      onPressed: _pauseTimer,
                      color: Colors.orange.shade800,
                    )
                  else
                    _buildActionButton(
                      label: 'RESUME',
                      onPressed: _resumeTimer,
                      color: Colors.green.shade800,
                    ),
                  _buildActionButton(
                    label: 'RESET',
                    onPressed: _resetTimer,
                    color: Colors.red.shade800,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInput(TextEditingController controller, String label) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback onPressed, required Color color}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}

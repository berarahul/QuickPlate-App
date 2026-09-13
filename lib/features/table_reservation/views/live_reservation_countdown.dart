import 'dart:async';
import 'package:flutter/material.dart';

class LiveReservationCountdown extends StatefulWidget {
  final dynamic startTime;
  final dynamic endTime;
  final TextStyle? style;
  final bool compact;
  final VoidCallback? onTimerTick;

  const LiveReservationCountdown({
    super.key,
    required this.startTime,
    required this.endTime,
    this.style,
    this.compact = false,
    this.onTimerTick,
  });

  @override
  State<LiveReservationCountdown> createState() => _LiveReservationCountdownState();
}

class _LiveReservationCountdownState extends State<LiveReservationCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        widget.onTimerTick?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime _parseDateTime(dynamic input) {
    if (input is DateTime) return input;
    if (input is String) {
      final parsed = DateTime.tryParse(input);
      if (parsed != null) return parsed;

      // Handle HH:mm strings by combining with today's date
      final parts = input.split(':');
      if (parts.length >= 2) {
        final now = DateTime.now();
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final start = _parseDateTime(widget.startTime);
    final end = _parseDateTime(widget.endTime);
    final now = DateTime.now();

    if (now.isBefore(start)) {
      final diff = start.difference(now);
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

      if (widget.compact) {
        return Text(
          'Starts in $hours:$minutes:$seconds',
          style: widget.style ??
              const TextStyle(
                color: Colors.blue,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, size: 14, color: Colors.blue),
            const SizedBox(width: 5),
            Text(
              'Starts in $hours:$minutes:$seconds',
              style: widget.style ??
                  const TextStyle(
                    color: Colors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );
    } else if (now.isBefore(end)) {
      final diff = end.difference(now);
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

      if (widget.compact) {
        return Text(
          'Live: $hours:$minutes:$seconds remaining',
          style: widget.style ??
              const TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flash_on_rounded, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Live Slot: $hours:$minutes:$seconds remaining',
              style: widget.style ??
                  const TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Slot Ended',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}

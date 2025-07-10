import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageUtils {
  static String getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.length == 1 && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }

    return '?';
  }

  static Color getAvatarColor(String name) {
    if (name.isEmpty) return Colors.grey;

    final int hashCode = name.hashCode;
    final List<Color> colors = [
      Colors.teal,
      Colors.indigo,
      Colors.orangeAccent,
      Colors.deepPurple,
      Colors.pinkAccent,
      Colors.green,
      Colors.blueGrey,
    ];

    return colors[hashCode.abs() % colors.length];
  }

  static String getFormattedMessageDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }
}

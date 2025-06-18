import 'package:flutter/material.dart';

class NameTile extends StatelessWidget {
  final String name;
  final String time;
  final bool isOverLimit;
  final bool isCurrent;

  const NameTile({
    required this.name,
    required this.time,
    required this.isOverLimit,
    required this.isCurrent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isOverLimit
        ? Colors.red.shade100
        : isCurrent
        ? Colors.blue.shade100
        : Colors.white;

    final textColor = isOverLimit
        ? Colors.red.shade900
        : isCurrent
        ? Colors.blue.shade900
        : Colors.black87;

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 20,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

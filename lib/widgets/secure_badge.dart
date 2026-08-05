import 'package:flutter/material.dart';

class SecureBadge extends StatelessWidget {
  final bool isEncrypted;

  const SecureBadge({super.key, this.isEncrypted = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEncrypted ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
            color: Colors.amber[800],
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            isEncrypted ? 'Secure' : 'Unlocked',
            style: TextStyle(
              color: Colors.amber[900],
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

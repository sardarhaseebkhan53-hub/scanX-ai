import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Notifications screen — displays app notifications with a premium dark
/// glassmorphic design consistent with the ScanX AI theme.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A1E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 48,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications cleared'),
                    backgroundColor: Color(0xFF151D3F),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Icon(Icons.done_all_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background ambient orbs
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.neonPurple.withOpacity(0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.neonBlue.withOpacity(0.12), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _NotificationSection(
                  title: 'Today',
                  items: [
                    _NotificationItem(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: AppColors.neonPurple,
                      iconBg: const Color(0xFF1B1340),
                      title: 'AI Summary Ready',
                      body: 'Your document "Physics Notes.pdf" has been summarized by AI.',
                      time: '2 hours ago',
                      isNew: true,
                    ),
                    _NotificationItem(
                      icon: Icons.cloud_done_rounded,
                      iconColor: AppColors.neonGreen,
                      iconBg: const Color(0xFF052E1A),
                      title: 'Cloud Sync Complete',
                      body: '3 documents successfully backed up to cloud storage.',
                      time: '5 hours ago',
                      isNew: true,
                    ),
                    _NotificationItem(
                      icon: Icons.workspace_premium_rounded,
                      iconColor: AppColors.neonAmber,
                      iconBg: const Color(0xFF3A2A0A),
                      title: 'Premium Offer',
                      body: 'Get 50% off on ScanX Pro annual plan. Limited time only!',
                      time: '8 hours ago',
                      isNew: true,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _NotificationSection(
                  title: 'Yesterday',
                  items: [
                    _NotificationItem(
                      icon: Icons.document_scanner_rounded,
                      iconColor: AppColors.neonCyan,
                      iconBg: const Color(0xFF0A2A2E),
                      title: 'Batch Scan Complete',
                      body: '12 pages scanned and merged into a single PDF document.',
                      time: 'Yesterday, 9:30 PM',
                      isNew: false,
                    ),
                    _NotificationItem(
                      icon: Icons.qr_code_2_rounded,
                      iconColor: AppColors.neonBlue,
                      iconBg: const Color(0xFF0F172E),
                      title: 'QR Code Generated',
                      body: 'Wi-Fi QR code "Office_5G" created successfully.',
                      time: 'Yesterday, 3:15 PM',
                      isNew: false,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _NotificationSection(
                  title: 'Earlier',
                  items: [
                    _NotificationItem(
                      icon: Icons.security_rounded,
                      iconColor: AppColors.neonPurple,
                      iconBg: const Color(0xFF1B1340),
                      title: 'Security Update',
                      body: 'AES-256 vault encryption has been enhanced for all locked documents.',
                      time: '3 days ago',
                      isNew: false,
                    ),
                    _NotificationItem(
                      icon: Icons.translate_rounded,
                      iconColor: AppColors.neonPink,
                      iconBg: const Color(0xFF2A0E22),
                      title: 'Translation Complete',
                      body: 'Document translated from English to Spanish successfully.',
                      time: '5 days ago',
                      isNew: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _NotificationSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;
  final String time;
  final bool isNew;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.time,
    required this.isNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNew
            ? const Color(0xFF12172E).withOpacity(0.96)
            : const Color(0xFF0E1228).withOpacity(0.80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew
              ? AppColors.neonPurple.withOpacity(0.18)
              : Colors.white.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withOpacity(0.35)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    if (isNew)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.neonPurple,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonPurple.withOpacity(0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.60),
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

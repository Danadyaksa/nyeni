import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Profile Header Widget - Avatar, nama, level, XP
class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onEditImage;
  final bool isUploadingImage;

  const ProfileHeader({
    super.key,
    required this.userData,
    required this.onEditImage,
    this.isUploadingImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = userData['avatar_url']?.toString();
    final fullName = userData['full_name']?.toString() ?? 'User';
    final email = userData['email']?.toString() ?? '';
    final level = userData['level'] ?? 1;
    final totalXp = userData['total_xp'] ?? 0;
    final xpTarget = _getXpTarget(level);
    final xpProgress = totalXp % 100;
    final progressPercent = xpProgress / 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF3D5166)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(LucideIcons.user, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              if (isUploadingImage)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: isUploadingImage ? null : onEditImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3E50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            email,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // Level & XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.award, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Level $level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$xpProgress / $xpTarget XP',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getXpTarget(int level) {
    if (level >= 10) return 500;
    if (level >= 9) return 500;
    if (level >= 8) return 450;
    if (level >= 7) return 400;
    if (level >= 6) return 350;
    if (level >= 5) return 300;
    if (level >= 4) return 250;
    if (level >= 3) return 200;
    if (level >= 2) return 150;
    return 100;
  }
}

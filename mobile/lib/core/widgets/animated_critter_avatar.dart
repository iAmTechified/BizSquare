import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/avatar_service.dart';
import 'bizsquare_loader.dart';

class AnimatedCritterAvatar extends StatelessWidget {
  final CritterAvatar avatar;
  final double size;
  final bool isInteractive;
  final bool showGlow;
  final bool showOfflineBadge;
  final VoidCallback? onTap;

  const AnimatedCritterAvatar({
    super.key,
    required this.avatar,
    this.size = 80,
    this.isInteractive = true,
    this.showGlow = true,
    this.showOfflineBadge = false,
    this.onTap,
  });

  Widget _buildAvatarImage() {
    // 1. Local Cached Disk File
    if (avatar.localFilePath != null && avatar.localFilePath!.isNotEmpty) {
      final file = File(avatar.localFilePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(),
        );
      }
    }

    // 2. Pre-bundled Offline Asset
    if (avatar.assetPath.isNotEmpty) {
      return Image.asset(
        avatar.assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackIcon(),
      );
    }

    // 3. Online Network URL with cache
    if (avatar.onlineUrl != null && avatar.onlineUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatar.onlineUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) => Center(
          child: BizSquareLoader(size: size * 0.42),
        ),
        errorWidget: (_, __, ___) => _buildFallbackIcon(),
      );
    }

    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: avatar.accentColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        color: avatar.accentColor,
        size: size * 0.55,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatar.accentColor.withValues(alpha: 0.08),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: avatar.accentColor.withValues(alpha: 0.20),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: _buildAvatarImage(),
      ),
    );

    if (onTap != null && isInteractive) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}

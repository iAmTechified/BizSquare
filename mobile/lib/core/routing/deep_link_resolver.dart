import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Central Deep Link Resolver for BizSquare MVP 1.0 (Section 7)
/// Resolves bizsquare:// custom scheme & https://app.bizsquare.com URLs.
class DeepLinkResolver {
  static const String scheme = 'bizsquare';
  static const String hostDomain = 'app.bizsquare.com';

  /// Resolves raw deep link string into a valid GoRouter target path
  static String? resolvePath(String rawLink) {
    if (rawLink.isEmpty) return null;

    try {
      final uri = Uri.parse(rawLink);

      // Handle custom scheme: bizsquare://path
      if (uri.scheme == scheme) {
        final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
        final authority = uri.authority;

        // bizsquare://contacts/square -> /contacts
        if (authority == 'contacts') {
          if (path == '/square' || path == '/') return '/contacts';
          if (path.startsWith('/')) {
            final id = path.substring(1);
            if (id.isNotEmpty) return '/contacts/details?id=$id';
          }
          return '/contacts';
        }

        // bizsquare://spotlight -> /spotlight
        if (authority == 'spotlight') {
          if (path == '/turn') return '/spotlight/edit-content';
          if (path == '/history') return '/spotlight/history';
          return '/spotlight';
        }

        // bizsquare://settings/permissions -> /permissions-wall
        if (authority == 'settings') {
          if (path.contains('permission') || path.contains('sync')) {
            return '/profile/contact-sync';
          }
          return '/profile';
        }

        // bizsquare://notifications -> /notifications
        if (authority == 'notifications') {
          return '/notifications';
        }

        // Fallback for bizsquare:///path
        return _mapRoutePath(path);
      }

      // Handle Web HTTPS URLs: https://app.bizsquare.com/contacts
      if (uri.scheme == 'https' || uri.scheme == 'http') {
        if (uri.host == hostDomain || uri.host.endsWith('.bizsquare.com')) {
          return _mapRoutePath(uri.path);
        }
      }

      // Handle direct Flutter paths (e.g. /contacts, /spotlight)
      if (rawLink.startsWith('/')) {
        return _mapRoutePath(rawLink);
      }
    } catch (e) {
      debugPrint('[DeepLinkResolver] Parse error for link ($rawLink): $e');
    }

    return '/home';
  }

  /// Maps path string to registered GoRouter destinations
  static String _mapRoutePath(String path) {
    if (path.startsWith('/contacts')) return '/contacts';
    if (path.startsWith('/spotlight/turn')) return '/spotlight/edit-content';
    if (path.startsWith('/spotlight/history')) return '/spotlight/history';
    if (path.startsWith('/spotlight')) return '/spotlight';
    if (path.startsWith('/permissions') || path.contains('sync')) return '/profile/contact-sync';
    if (path.startsWith('/profile')) return '/profile';
    if (path.startsWith('/notifications')) return '/notifications';
    if (path.startsWith('/daily-wall')) return '/daily-wall';
    return '/home';
  }

  /// Navigates to resolved destination with safety checks
  static void navigate(BuildContext context, String rawLink) {
    final targetPath = resolvePath(rawLink);
    if (targetPath != null && targetPath.isNotEmpty) {
      debugPrint('[DeepLinkResolver] Navigating to target: $targetPath (from $rawLink)');
      try {
        GoRouter.of(context).go(targetPath);
      } catch (e) {
        debugPrint('[DeepLinkResolver] Navigation error: $e');
        GoRouter.of(context).go('/home');
      }
    }
  }
}

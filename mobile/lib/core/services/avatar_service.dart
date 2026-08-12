import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class CritterAvatar {
  final String id;
  final String name;
  final String assetPath;
  final String? localFilePath;
  final String? onlineUrl;
  final String personality;
  final String category;
  final Color accentColor;
  final bool isLocal;

  const CritterAvatar({
    required this.id,
    required this.name,
    required this.assetPath,
    this.localFilePath,
    this.onlineUrl,
    required this.personality,
    required this.category,
    required this.accentColor,
    this.isLocal = true,
  });

  bool get isCachedFile => localFilePath != null && File(localFilePath!).existsSync();
}

final avatarServiceProvider = Provider<AvatarService>((ref) {
  return AvatarService();
});

final activeAvatarProvider = StateNotifierProvider<ActiveAvatarNotifier, ActiveAvatarState>((ref) {
  final service = ref.watch(avatarServiceProvider);
  return ActiveAvatarNotifier(service);
});

class ActiveAvatarState {
  final CritterAvatar currentAvatar;
  final bool isDownloading;

  const ActiveAvatarState({
    required this.currentAvatar,
    this.isDownloading = false,
  });

  ActiveAvatarState copyWith({
    CritterAvatar? currentAvatar,
    bool? isDownloading,
  }) {
    return ActiveAvatarState(
      currentAvatar: currentAvatar ?? this.currentAvatar,
      isDownloading: isDownloading ?? this.isDownloading,
    );
  }
}

class ActiveAvatarNotifier extends StateNotifier<ActiveAvatarState> {
  final AvatarService _service;
  static const _storage = FlutterSecureStorage();

  ActiveAvatarNotifier(this._service)
      : super(ActiveAvatarState(currentAvatar: _service.getLocalCritters().first)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final savedId = await _storage.read(key: 'bizsquare_active_avatar_id');
      final savedPath = await _storage.read(key: 'bizsquare_active_avatar_path');
      final savedUrl = await _storage.read(key: 'bizsquare_active_avatar_url');

      if (savedPath != null && File(savedPath).existsSync()) {
        state = state.copyWith(
          currentAvatar: CritterAvatar(
            id: savedId ?? 'cached_custom',
            name: 'Custom Critter',
            assetPath: '',
            localFilePath: savedPath,
            onlineUrl: savedUrl,
            personality: 'Custom Companion',
            category: 'Offline Cached',
            accentColor: const Color(0xFF4338CA),
            isLocal: false,
          ),
        );
      } else if (savedId != null) {
        final match = _service.getLocalCritters().firstWhere(
              (c) => c.id == savedId,
              orElse: () => _service.getLocalCritters().first,
            );
        state = state.copyWith(currentAvatar: match);
      }
    } catch (e) {
      debugPrint('Error loading saved avatar: $e');
    }
  }

  Future<void> selectLocalAvatar(CritterAvatar avatar) async {
    state = state.copyWith(currentAvatar: avatar);
    await _storage.write(key: 'bizsquare_active_avatar_id', value: avatar.id);
    await _storage.delete(key: 'bizsquare_active_avatar_path');
    await _storage.delete(key: 'bizsquare_active_avatar_url');
  }

  Future<bool> selectAndCacheOnlineAvatar({
    required String url,
    required String seed,
    required String style,
  }) async {
    state = state.copyWith(isDownloading: true);
    try {
      final cachedFilePath = await _service.cacheOnlineAvatar(url, seed);
      if (cachedFilePath != null) {
        final newAvatar = CritterAvatar(
          id: 'online_${seed.toLowerCase().replaceAll(' ', '_')}',
          name: seed.isEmpty ? 'Critter' : seed,
          assetPath: '',
          localFilePath: cachedFilePath,
          onlineUrl: url,
          personality: 'Freshly Hatched',
          category: style.toUpperCase(),
          accentColor: const Color(0xFF10B981),
          isLocal: false,
        );

        state = state.copyWith(currentAvatar: newAvatar, isDownloading: false);
        await _storage.write(key: 'bizsquare_active_avatar_id', value: newAvatar.id);
        await _storage.write(key: 'bizsquare_active_avatar_path', value: cachedFilePath);
        await _storage.write(key: 'bizsquare_active_avatar_url', value: url);
        return true;
      }
    } catch (e) {
      debugPrint('Error downloading and caching avatar: $e');
    }
    state = state.copyWith(isDownloading: false);
    return false;
  }
}

class AvatarService {
  final Dio _dio;

  AvatarService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
            ));

  static CritterAvatar getAvatarByIndex(int index) {
    final critters = AvatarService().getLocalCritters();
    if (critters.isEmpty) {
      return const CritterAvatar(
        id: 'critter_01',
        name: 'Sparky',
        assetPath: 'assets/avatars/critter_01.png',
        personality: 'Electric Visionary',
        category: 'Bot',
        accentColor: Color(0xFF0284C7),
      );
    }
    final safeIndex = (index - 1).clamp(0, critters.length - 1);
    return critters[safeIndex];
  }

  static int getIndexForCritter(CritterAvatar critter) {
    final critters = AvatarService().getLocalCritters();
    final idx = critters.indexWhere((c) => c.id == critter.id);
    return idx != -1 ? idx + 1 : 1;
  }

  List<CritterAvatar> getLocalCritters() {
    return const [
      CritterAvatar(
        id: 'critter_01',
        name: 'Sparky',
        assetPath: 'assets/avatars/critter_01.png',
        personality: 'Electric Visionary',
        category: 'Bot',
        accentColor: Color(0xFF0284C7),
      ),
      CritterAvatar(
        id: 'critter_02',
        name: 'Nova',
        assetPath: 'assets/avatars/critter_02.png',
        personality: 'Cosmic Optimizer',
        category: 'Bot',
        accentColor: Color(0xFF7C3AED),
      ),
      CritterAvatar(
        id: 'critter_03',
        name: 'Gizmo',
        assetPath: 'assets/avatars/critter_03.png',
        personality: 'Master Tinkerer',
        category: 'Bot',
        accentColor: Color(0xFF4F46E5),
      ),
      CritterAvatar(
        id: 'critter_04',
        name: 'Echo',
        assetPath: 'assets/avatars/critter_04.png',
        personality: 'Harmonic Whisperer',
        category: 'Bot',
        accentColor: Color(0xFF059669),
      ),
      CritterAvatar(
        id: 'critter_05',
        name: 'Blaze',
        assetPath: 'assets/avatars/critter_05.png',
        personality: 'Fiery Disruptor',
        category: 'Bot',
        accentColor: Color(0xFFDC2626),
      ),
      CritterAvatar(
        id: 'critter_06',
        name: 'Pixel',
        assetPath: 'assets/avatars/critter_06.png',
        personality: 'Digital Precision',
        category: 'Bot',
        accentColor: Color(0xFFD97706),
      ),
      CritterAvatar(
        id: 'critter_07',
        name: 'Quantum',
        assetPath: 'assets/avatars/critter_07.png',
        personality: 'Superposition Strategist',
        category: 'Bot',
        accentColor: Color(0xFF2563EB),
      ),
      CritterAvatar(
        id: 'critter_08',
        name: 'Vortex',
        assetPath: 'assets/avatars/critter_08.png',
        personality: 'Market Magnet',
        category: 'Bot',
        accentColor: Color(0xFF9333EA),
      ),
      CritterAvatar(
        id: 'critter_09',
        name: 'Titan',
        assetPath: 'assets/avatars/critter_09.png',
        personality: 'Unstoppable Anchor',
        category: 'Bot',
        accentColor: Color(0xFF475569),
      ),
      CritterAvatar(
        id: 'critter_10',
        name: 'Aero',
        assetPath: 'assets/avatars/critter_10.png',
        personality: 'Swift Messenger',
        category: 'Bot',
        accentColor: Color(0xFF0891B2),
      ),
      CritterAvatar(
        id: 'critter_11',
        name: 'Apex',
        assetPath: 'assets/avatars/critter_11.png',
        personality: 'Apex Connector',
        category: 'Bot',
        accentColor: Color(0xFF16A34A),
      ),
      CritterAvatar(
        id: 'critter_12',
        name: 'Zenith',
        assetPath: 'assets/avatars/critter_12.png',
        personality: 'High-Altitude Catalyst',
        category: 'Bot',
        accentColor: Color(0xFFE11D48),
      ),
      CritterAvatar(
        id: 'critter_13',
        name: 'Lumina',
        assetPath: 'assets/avatars/critter_13.png',
        personality: 'Clarity Guide',
        category: 'Adventurer',
        accentColor: Color(0xFFF59E0B),
      ),
      CritterAvatar(
        id: 'critter_14',
        name: 'Orion',
        assetPath: 'assets/avatars/critter_14.png',
        personality: 'Constellation Builder',
        category: 'Adventurer',
        accentColor: Color(0xFF6366F1),
      ),
      CritterAvatar(
        id: 'critter_15',
        name: 'Sol',
        assetPath: 'assets/avatars/critter_15.png',
        personality: 'Warm Growth Engine',
        category: 'Adventurer',
        accentColor: Color(0xFFEAB308),
      ),
      CritterAvatar(
        id: 'critter_16',
        name: 'Lyra',
        assetPath: 'assets/avatars/critter_16.png',
        personality: 'Creative Rhythm',
        category: 'Adventurer',
        accentColor: Color(0xFFEC4899),
      ),
      CritterAvatar(
        id: 'critter_17',
        name: 'Atlas',
        assetPath: 'assets/avatars/critter_17.png',
        personality: 'Global Pillar',
        category: 'Adventurer',
        accentColor: Color(0xFF0D9488),
      ),
      CritterAvatar(
        id: 'critter_18',
        name: 'Vesper',
        assetPath: 'assets/avatars/critter_18.png',
        personality: 'Twilight Negotiator',
        category: 'Adventurer',
        accentColor: Color(0xFF8B5CF6),
      ),
      CritterAvatar(
        id: 'critter_19',
        name: 'Zephyr',
        assetPath: 'assets/avatars/critter_19.png',
        personality: 'Agile Pioneer',
        category: 'Adventurer',
        accentColor: Color(0xFF06B6D4),
      ),
      CritterAvatar(
        id: 'critter_20',
        name: 'Onyx',
        assetPath: 'assets/avatars/critter_20.png',
        personality: 'Steadfast Operator',
        category: 'Adventurer',
        accentColor: Color(0xFF334155),
      ),
      CritterAvatar(
        id: 'critter_21',
        name: 'Zara',
        assetPath: 'assets/avatars/critter_21.png',
        personality: 'Regal Visionary',
        category: 'Lorelei',
        accentColor: Color(0xFF06B6D4),
      ),
      CritterAvatar(
        id: 'critter_22',
        name: 'Simba',
        assetPath: 'assets/avatars/critter_22.png',
        personality: 'Courageous Founder',
        category: 'Lorelei',
        accentColor: Color(0xFF8B5CF6),
      ),
      CritterAvatar(
        id: 'critter_23',
        name: 'Amara',
        assetPath: 'assets/avatars/critter_23.png',
        personality: 'Strategic Grace',
        category: 'Lorelei',
        accentColor: Color(0xFF6366F1),
      ),
      CritterAvatar(
        id: 'critter_24',
        name: 'Kofi',
        assetPath: 'assets/avatars/critter_24.png',
        personality: 'Resilient Hustler',
        category: 'Lorelei',
        accentColor: Color(0xFFEC4899),
      ),
    ];
  }

  String buildDiceBearUrl({
    required String seed,
    String style = 'bottts',
    String backgroundColor = 'b6e3f4',
    bool animated = true,
  }) {
    final cleanSeed = Uri.encodeComponent(seed.trim());
    return 'https://api.dicebear.com/9.x/$style/png?seed=$cleanSeed&size=256&backgroundColor=$backgroundColor&animated=$animated';
  }

  Future<String?> cacheOnlineAvatar(String url, String seed) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${docDir.path}/avatars');
      if (!avatarDir.existsSync()) {
        avatarDir.createSync(recursive: true);
      }

      final sanitizedSeed = seed.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final targetPath = '${avatarDir.path}/avatar_${sanitizedSeed}_${DateTime.now().millisecondsSinceEpoch}.png';

      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data != null) {
        final file = File(targetPath);
        await file.writeAsBytes(response.data!);
        return targetPath;
      }
    } catch (e) {
      debugPrint('Failed to cache online avatar: $e');
    }
    return null;
  }

  Future<List<File>> getCachedAvatars() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${docDir.path}/avatars');
      if (avatarDir.existsSync()) {
        return avatarDir.listSync().whereType<File>().toList();
      }
    } catch (e) {
      debugPrint('Error listing cached avatars: $e');
    }
    return [];
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_widget/home_widget.dart';
import '../models/contact_gain_widget_state.dart';
import '../widgets/add_widget_bottom_sheet.dart';

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService();
});

class WidgetService {
  static const _channel = MethodChannel('com.bizsquare.app/widget');
  static const String androidContactWidgetProvider = 'ContactGainWidgetProvider';
  static const String androidSpotlightWidgetProvider = 'SpotlightWidgetProvider';
  static const String iosContactWidgetKind = 'ContactGainWidget';
  static const String iosSpotlightWidgetKind = 'SpotlightWidget';

  static const String _keyContactWidgetInstalled = 'bizsquare_widget_contact_installed';
  static const String _keySpotlightWidgetInstalled = 'bizsquare_widget_spotlight_installed';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Checks whether user already installed/pinned the Contact Gain widget
  Future<bool> isContactWidgetInstalled() async {
    try {
      final val = await _storage.read(key: _keyContactWidgetInstalled);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Marks the Contact Gain widget as installed
  Future<void> markContactWidgetInstalled() async {
    try {
      await _storage.write(key: _keyContactWidgetInstalled, value: 'true');
    } catch (_) {}
  }

  /// Checks whether user already installed/pinned the Spotlight widget
  Future<bool> isSpotlightWidgetInstalled() async {
    try {
      final val = await _storage.read(key: _keySpotlightWidgetInstalled);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Marks the Spotlight widget as installed
  Future<void> markSpotlightWidgetInstalled() async {
    try {
      await _storage.write(key: _keySpotlightWidgetInstalled, value: 'true');
    } catch (_) {}
  }

  /// Checks if any widget is installed
  Future<bool> hasInstalledAnyWidget() async {
    final contact = await isContactWidgetInstalled();
    final spotlight = await isSpotlightWidgetInstalled();
    return contact || spotlight;
  }

  /// Syncs real Contact Gain Widget Data to Native OS Home Screen Widget Storage
  Future<void> syncNativeWidgetData(ContactGainWidgetData data) async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_state', data.stateType.name);
      await HomeWidget.saveWidgetData<String>('widget_title', data.title);
      await HomeWidget.saveWidgetData<String>('widget_headline', data.headline);
      await HomeWidget.saveWidgetData<String>('widget_subtitle', data.subtitle);
      await HomeWidget.saveWidgetData<int>('widget_contact_count', data.contactCount);
      await HomeWidget.saveWidgetData<String>('widget_action_label', data.actionLabel);
      await HomeWidget.saveWidgetData<String>('widget_deep_link', data.deepLink);
      await HomeWidget.saveWidgetData<bool>('widget_is_offline', data.isOffline);
      await HomeWidget.saveWidgetData<bool>('widget_is_stale', data.isStale);
      await HomeWidget.saveWidgetData<String>('widget_updated_at', data.timestamp.toIso8601String());

      await HomeWidget.updateWidget(
        androidName: androidContactWidgetProvider,
        iOSName: iosContactWidgetKind,
      );
    } on PlatformException catch (_) {
      // Native AppWidgetProvider not compiled/registered on this build target, silent fallback
    } catch (e) {
      debugPrint('[WidgetService] Contact widget sync notice: $e');
    }
  }

  /// Syncs real Spotlight Widget Data to Native OS Home Screen Widget Storage
  Future<void> syncSpotlightNativeWidgetData(dynamic data) async {
    try {
      await HomeWidget.saveWidgetData<String>('spotlight_widget_state', data.stateType.name);
      await HomeWidget.saveWidgetData<String>('spotlight_widget_headline', data.headline);
      await HomeWidget.saveWidgetData<String>('spotlight_widget_subtitle', data.subtitle);
      await HomeWidget.saveWidgetData<int>('spotlight_participant_count', data.participantCount);
      await HomeWidget.saveWidgetData<String>('spotlight_action_label', data.actionLabel);
      await HomeWidget.saveWidgetData<String>('spotlight_deep_link', data.deepLink);

      await HomeWidget.updateWidget(
        androidName: androidSpotlightWidgetProvider,
        iOSName: iosSpotlightWidgetKind,
      );
    } on PlatformException catch (_) {
      // Native AppWidgetProvider not compiled/registered on this build target, silent fallback
    } catch (e) {
      debugPrint('[WidgetService] Spotlight widget sync notice: $e');
    }
  }

  /// Checks if the device launcher supports pinning widgets programmatically
  Future<bool> isPinWidgetSupported() async {
    try {
      final isSupported = await HomeWidget.isRequestPinWidgetSupported();
      if (isSupported == true) return true;

      final supported = await _channel.invokeMethod<bool>('isPinWidgetSupported');
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Triggers native Android/iOS system prompt: "Add BizSquare Widget to Home screen?"
  Future<bool> requestPinWidget({bool isSpotlight = false}) async {
    try {
      await HomeWidget.requestPinWidget(
        androidName: isSpotlight ? androidSpotlightWidgetProvider : androidContactWidgetProvider,
      );
      if (isSpotlight) {
        await markSpotlightWidgetInstalled();
      } else {
        await markContactWidgetInstalled();
      }
      return true;
    } catch (e) {
      debugPrint('[WidgetService] requestPinWidget failed, trying channel fallback: $e');
      try {
        final success = await _channel.invokeMethod<bool>('requestPinWidget', {'isSpotlight': isSpotlight});
        if (success == true) {
          if (isSpotlight) {
            await markSpotlightWidgetInstalled();
          } else {
            await markContactWidgetInstalled();
          }
          return true;
        }
        return false;
      } catch (_) {
        return false;
      }
    }
  }

  /// Displays the interactive in-app prompt modal to add the widget
  Future<void> showAddWidgetPrompt(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddWidgetBottomSheet(),
    );
  }
}


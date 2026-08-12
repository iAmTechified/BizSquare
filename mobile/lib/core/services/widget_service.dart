import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../models/contact_gain_widget_state.dart';
import '../widgets/add_widget_bottom_sheet.dart';

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService();
});

class WidgetService {
  static const _channel = MethodChannel('com.bizsquare.app/widget');
  static const String androidWidgetProvider = 'ContactGainWidgetProvider';
  static const String iosWidgetKind = 'ContactGainWidget';

  /// Syncs real Contact Gain Widget Data to Native OS Home Screen Widget Storage (SharedPreferences / AppGroup)
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
      await HomeWidget.saveWidgetData<String>('widget_updated_at', data.timestamp.toIso8601String());

      // Trigger OS Home Screen update
      await HomeWidget.updateWidget(
        androidName: androidWidgetProvider,
        iOSName: iosWidgetKind,
      );
    } catch (e) {
      debugPrint('[WidgetService] Native widget sync error (non-fatal): $e');
    }
  }

  /// Checks if the device launcher supports pinning widgets programmatically
  Future<bool> isPinWidgetSupported() async {
    try {
      // First try native home_widget method
      final isSupported = await HomeWidget.isRequestPinWidgetSupported();
      if (isSupported == true) return true;

      // Fallback method channel
      final supported = await _channel.invokeMethod<bool>('isPinWidgetSupported');
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Triggers native Android/iOS system prompt: "Add BizSquare Widget to Home screen?"
  Future<bool> requestPinWidget() async {
    try {
      await HomeWidget.requestPinWidget(
        androidName: androidWidgetProvider,
      );
      return true;
    } catch (e) {
      debugPrint('[WidgetService] requestPinWidget failed, trying channel fallback: $e');
      try {
        final success = await _channel.invokeMethod<bool>('requestPinWidget');
        return success ?? false;
      } catch (_) {
        return false;
      }
    }
  }

  /// Displays the interactive in-app prompt modal to add the widget
  Future<void> showAddWidgetPrompt(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddWidgetBottomSheet(),
    );
  }
}

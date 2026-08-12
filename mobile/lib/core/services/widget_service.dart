import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/add_widget_bottom_sheet.dart';

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService();
});

class WidgetService {
  static const _channel = MethodChannel('com.bizsquare.app/widget');

  /// Checks if the device launcher supports pinning widgets programmatically
  Future<bool> isPinWidgetSupported() async {
    try {
      final supported = await _channel.invokeMethod<bool>('isPinWidgetSupported');
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Triggers the native Android system prompt: "Add BizSquare Widget to Home screen?"
  Future<bool> requestPinWidget() async {
    try {
      final success = await _channel.invokeMethod<bool>('requestPinWidget');
      return success ?? false;
    } catch (_) {
      return false;
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../models/user_model.dart';

class WidgetService {
  static const String appGroupId = 'group.com.cling.app';
  static const String iOSWidgetName = 'ClingWidget';
  static const String androidWidgetName = 'PartnerWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<void> syncPartnerStats(UserModel? partner) async {
    if (partner == null) return;

    await HomeWidget.saveWidgetData<String>('partner_name', partner.displayName);
    await HomeWidget.saveWidgetData<int>('battery_level', partner.battery);
    
    if (partner.currentMood != null) {
      await HomeWidget.saveWidgetData<String>('partner_mood', partner.currentMood!.emoji);
    } else {
      await HomeWidget.saveWidgetData<String>('partner_mood', '💭');
    }

    if (partner.currentSong != null) {
      await HomeWidget.saveWidgetData<String>('partner_song', '${partner.currentSong!.title} - ${partner.currentSong!.artist}');
    } else {
      await HomeWidget.saveWidgetData<String>('partner_song', '');
    }

    // Trigger widget update on both platforms
    await HomeWidget.updateWidget(
      name: androidWidgetName,
      iOSName: iOSWidgetName,
    );
  }
}

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService();
});

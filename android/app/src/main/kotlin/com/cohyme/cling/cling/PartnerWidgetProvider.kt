package com.cohyme.cling.cling

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PartnerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_partner_stats).apply {
                val name = widgetData.getString("partner_name", "Poornima 💕")
                val battery = widgetData.getInt("battery_level", 0)
                val mood = widgetData.getString("partner_mood", "💭")
                val song = widgetData.getString("partner_song", "Not playing")

                setTextViewText(R.id.tv_partner_name, name)
                setTextViewText(R.id.tv_battery, "$battery%")
                setTextViewText(R.id.tv_mood, mood)
                setTextViewText(R.id.tv_song, song)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

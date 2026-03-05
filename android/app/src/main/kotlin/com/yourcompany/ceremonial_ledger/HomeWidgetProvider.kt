package com.yourcompany.ceremonial_ledger

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class HomeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)

            val views = RemoteViews(context.packageName, R.layout.home_widget_layout)

            // 데이터 읽기
            val balance = widgetData.getString("widget_balance", "0원") ?: "0원"
            val income = widgetData.getString("widget_income", "0원") ?: "0원"
            val expense = widgetData.getString("widget_expense", "0원") ?: "0원"
            val count = widgetData.getString("widget_count", "0건") ?: "0건"
            val month = widgetData.getString("widget_month", "") ?: ""
            val upcoming = widgetData.getString("widget_upcoming", "다가오는 일정 없음") ?: "다가오는 일정 없음"

            // 뷰 업데이트
            views.setTextViewText(R.id.widget_balance, balance)
            views.setTextViewText(R.id.widget_income, income)
            views.setTextViewText(R.id.widget_expense, expense)
            views.setTextViewText(R.id.widget_count, count)
            views.setTextViewText(R.id.widget_month, month)
            views.setTextViewText(R.id.widget_upcoming, upcoming)

            // 앱 열기 인텐트
            val pendingIntent = android.app.PendingIntent.getActivity(
                context,
                0,
                context.packageManager.getLaunchIntentForPackage(context.packageName),
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_balance, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
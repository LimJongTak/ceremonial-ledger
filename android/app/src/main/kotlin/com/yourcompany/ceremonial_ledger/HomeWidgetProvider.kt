package com.yourcompany.ceremonial_ledger

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
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

            // 기본 데이터
            val balance = widgetData.getString("widget_balance", "0원") ?: "0원"
            val income = widgetData.getString("widget_income", "0원") ?: "0원"
            val expense = widgetData.getString("widget_expense", "0원") ?: "0원"
            val count = widgetData.getString("widget_count", "0건") ?: "0건"
            val month = widgetData.getString("widget_month", "") ?: ""

            // 다가오는 경조사 데이터
            val upcomingCount = widgetData.getString("widget_upcoming_count", "0")?.toIntOrNull() ?: 0
            val info1 = widgetData.getString("widget_upcoming_1_info", "") ?: ""
            val dday1 = widgetData.getString("widget_upcoming_1_dday", "") ?: ""
            val info2 = widgetData.getString("widget_upcoming_2_info", "") ?: ""
            val dday2 = widgetData.getString("widget_upcoming_2_dday", "") ?: ""

            // 기본 뷰 업데이트
            views.setTextViewText(R.id.widget_balance, balance)
            views.setTextViewText(R.id.widget_income, income)
            views.setTextViewText(R.id.widget_expense, expense)
            views.setTextViewText(R.id.widget_count, count)
            views.setTextViewText(R.id.widget_month, month)

            // 다가오는 경조사 행 표시/숨김
            if (upcomingCount == 0) {
                views.setViewVisibility(R.id.widget_upcoming_empty, View.VISIBLE)
                views.setViewVisibility(R.id.widget_upcoming_row1, View.GONE)
                views.setViewVisibility(R.id.widget_upcoming_row2, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_upcoming_empty, View.GONE)
                views.setViewVisibility(R.id.widget_upcoming_row1, View.VISIBLE)
                views.setTextViewText(R.id.widget_upcoming_1_info, info1)
                views.setTextViewText(R.id.widget_upcoming_1_dday, dday1)

                if (upcomingCount >= 2) {
                    views.setViewVisibility(R.id.widget_upcoming_row2, View.VISIBLE)
                    views.setTextViewText(R.id.widget_upcoming_2_info, info2)
                    views.setTextViewText(R.id.widget_upcoming_2_dday, dday2)
                } else {
                    views.setViewVisibility(R.id.widget_upcoming_row2, View.GONE)
                }
            }

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

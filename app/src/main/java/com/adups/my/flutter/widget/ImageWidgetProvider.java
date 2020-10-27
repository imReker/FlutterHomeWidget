package com.adups.my.flutter.widget;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.os.Bundle;

public class ImageWidgetProvider
        extends AppWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        UpdateWidgetService.updateImageWidgets(context, appWidgetIds);
    }

    @Override
    public void onDeleted(Context context, int[] appWidgetIds) {
        WidgetSettingsManager.of(context).onRemove(appWidgetIds);
    }

    @Override
    public void onDisabled(Context context) {
        WidgetSettingsManager.of(context).onDisabled();
    }

    @Override
    public void onAppWidgetOptionsChanged(Context context, AppWidgetManager appWidgetManager,
            int appWidgetId, Bundle widgetInfo) {
        UpdateWidgetService.updateImageWidgets(context, new int[]{appWidgetId});
    }
}

package com.adups.my.flutter.flutter_home_widget;

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
        WidgetManager.of(context).remove(appWidgetIds);
    }

    @Override
    public void onDisabled(Context context) {
        WidgetManager.of(context).disable();
    }

    @Override
    public void onAppWidgetOptionsChanged(Context context, AppWidgetManager appWidgetManager,
            int appWidgetId, Bundle widgetInfo) {
        UpdateWidgetService.updateImageWidgets(context, new int[]{appWidgetId});
    }
}

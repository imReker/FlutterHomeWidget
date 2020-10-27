package com.adups.my.flutter.widget;

import android.annotation.SuppressLint;
import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;

@SuppressWarnings({"WeakerAccess"})
@SuppressLint("ApplySharedPref")
public class WidgetSettingsManager {
    private static final String FLUTTER_PREFIX = "flutter.";
    private static final String PREFIX = FLUTTER_PREFIX + "widget_settings_";

    private static WidgetSettingsManager instance;

    private final SharedPreferences mPrefs;
    private final Context mContext;

    public static WidgetSettingsManager of(Context context) {
        if (instance == null) {
            instance = new WidgetSettingsManager(context);
        }
        return instance;
    }

    public void onDisabled() {
        Editor editor = mPrefs.edit();

        for (String key : mPrefs.getAll().keySet()) {
            if (key.startsWith(PREFIX)) {
                editor.remove(key);
            }
        }
        editor.commit();
        instance = null;
    }

    private WidgetSettingsManager(Context context) {
        mContext = context.getApplicationContext();
        mPrefs = mContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
        int[] appWidgetIds = AppWidgetManager.getInstance(context)
                                             .getAppWidgetIds(
                                                     new ComponentName(context,
                                                             ImageWidgetProvider.class));
        Editor editor = mPrefs.edit();
        for (int appWidgetId : appWidgetIds) {
            if (!mPrefs.contains(PREFIX + appWidgetId)) {
                editor.putBoolean(PREFIX + appWidgetId, false);
            }
        }
        editor.commit();
    }

    public void update(int[] ids) {
        UpdateWidgetService.updateImageWidgets(mContext, ids);
    }

    public void onUpdate(int id) {
    }

    public void onRemove(int id) {
        Editor editor = mPrefs.edit();
        removeWidget(editor, id);
        editor.commit();
    }

    public void onRemove(int[] ids) {
        Editor editor = mPrefs.edit();
        for (int id : ids) {
            removeWidget(editor, id);
        }
        editor.commit();
    }

    private void removeWidget(Editor editor, int id) {
        for (String key : mPrefs.getAll().keySet()) {
            if (key.startsWith(PREFIX) && key.endsWith("_" + id)) {
                editor.remove(key);
            }
        }
    }
}

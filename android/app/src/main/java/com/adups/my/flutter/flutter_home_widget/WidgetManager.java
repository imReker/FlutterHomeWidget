package com.adups.my.flutter.flutter_home_widget;

import android.annotation.SuppressLint;
import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;

import java.util.HashMap;
import java.util.Map;

@SuppressWarnings({"WeakerAccess"})
@SuppressLint("ApplySharedPref")
public class WidgetManager {
    private static final String FLUTTER_PREFIX = "flutter.";
    private static final String PREFIX = FLUTTER_PREFIX + "widget_settings_";
    public static final String DEFAULT_COLOR = "4294198070";

    private static WidgetManager instance;

    private final SharedPreferences mPrefs;
    private final Context mContext;

    public static WidgetManager of(Context context) {
        if (instance == null) {
            instance = new WidgetManager(context);
        }
        return instance;
    }

    private WidgetManager(Context context) {
        mContext = context.getApplicationContext();
        mPrefs = mContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
        int[] widgetIds = AppWidgetManager.getInstance(context)
                                             .getAppWidgetIds(
                                                     new ComponentName(context,
                                                             ImageWidgetProvider.class));
        Editor editor = mPrefs.edit();
        for (int widgetId : widgetIds) {
            if (!mPrefs.contains(PREFIX + widgetId)) {
                editor.putString(PREFIX + widgetId, DEFAULT_COLOR);
            }
        }
        editor.commit();
    }

    public Map<String, String> getConfig(int widgetId) {
        Map<String, String> config = new HashMap<>();
        config.put("id", String.valueOf(widgetId));
        config.put("color", mPrefs.getString(PREFIX + widgetId, DEFAULT_COLOR));
        return config;
    }

    public void update(int[] ids) {
        UpdateWidgetService.updateImageWidgets(mContext, ids);
    }

    public void remove(int[] ids) {
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

    public void disable() {
        Editor editor = mPrefs.edit();

        for (String key : mPrefs.getAll().keySet()) {
            if (key.startsWith(PREFIX)) {
                editor.remove(key);
            }
        }
        editor.commit();
        instance = null;
    }
}

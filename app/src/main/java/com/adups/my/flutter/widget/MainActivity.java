package com.adups.my.flutter.widget;

import android.appwidget.AppWidgetManager;
import android.content.Intent;
import android.os.Bundle;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity
        extends FlutterActivity {

    private int mAppWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        WidgetSettingsManager widgetManager = WidgetSettingsManager.of(this);

        Intent intent = getIntent();
        Bundle extras = intent.getExtras();
        if (extras != null) {
            mAppWidgetId = extras.getInt(
                    AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID);
        }

        MethodChannel methodChannel = new MethodChannel(getFlutterEngine().getDartExecutor(),
                "Widget/Native");
        methodChannel.setMethodCallHandler((call, result) -> {
            if ("saveWidget".equals(call.method)) {
                if (mAppWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    widgetManager.update(new int[]{mAppWidgetId});

                    Intent resultValue = new Intent();
                    resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, mAppWidgetId);
                    setResult(RESULT_OK, resultValue);
                    result.success(null);
                    finish();
                } else {
                    widgetManager.update(null);
                }

            }
        });

        if (mAppWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
            setResult(RESULT_CANCELED);
            intent.putExtra("route", "/widget/settings/" + mAppWidgetId);
        }
    }
}

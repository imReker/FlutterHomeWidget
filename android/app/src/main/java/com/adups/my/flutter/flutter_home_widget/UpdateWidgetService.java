package com.adups.my.flutter.flutter_home_widget;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.Message;
import android.text.format.DateFormat;
import android.util.Log;
import android.widget.RemoteViews;

import androidx.annotation.Nullable;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener;
import io.flutter.embedding.engine.systemchannels.SettingsChannel.PlatformBrightness;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.view.FlutterMain;

public class UpdateWidgetService
        extends Service {
    private static final String ACTION_UPDATE_IMAGE = "ACTION_UPDATE_IMAGE";
    private static final String ACTION_UPDATE_UI = "ACTION_UPDATE_UI";

    private static final String EXTRA_WIDGET_IDS = "EXTRA_WIDGET_IDS";
    private static final String EXTRA_START_FOREGROUND = "EXTRA_START_FOREGROUND";
    private static final String TAG = "UpdateWidgetService";

    private volatile ServiceHandler mServiceHandler;
    private FlutterEngine mFlutterEngineImage;
    private FlutterBackgroundRenderer mFlutterBackgroundRenderer;
    private Runnable mForegroundRunnable;

    public static void updateImageWidgets(Context context, int[] widgetIds) {
        Intent intent = new Intent(context, UpdateWidgetService.class);
        intent.setAction(ACTION_UPDATE_IMAGE);
        intent.putExtra(EXTRA_WIDGET_IDS, widgetIds);

        try {
            context.startService(intent);
        } catch (Exception e) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                intent.putExtra(EXTRA_START_FOREGROUND, true);
                context.startForegroundService(intent);
            }
        }
    }

    public static void updateUIWidgets(Context context, int[] widgetIds) {
        Intent intent = new Intent(context, UpdateWidgetService.class);
        intent.setAction(ACTION_UPDATE_UI);
        intent.putExtra(EXTRA_WIDGET_IDS, widgetIds);
        try {
            context.startService(intent);
        } catch (Exception e) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                intent.putExtra(EXTRA_START_FOREGROUND, true);
                context.startForegroundService(intent);
            }
        }
    }

    @Override
    public void onCreate() {
        mServiceHandler = new ServiceHandler(Looper.getMainLooper());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            mForegroundRunnable = () -> {
                NotificationChannel channel = new NotificationChannel("WidgetUpdate",
                        "WidgetUpdate", NotificationManager.IMPORTANCE_NONE);
                NotificationManager manager = (NotificationManager) getSystemService(
                        Context.NOTIFICATION_SERVICE);
                manager.createNotificationChannel(channel);

                Notification notification = new Notification.Builder(getApplicationContext(),
                        "WidgetUpdate").build();
                startForeground(5000, notification);
            };
            mServiceHandler.postDelayed(mForegroundRunnable, 1000);
        }
    }

    @Override
    public int onStartCommand(@Nullable Intent intent, int flags, int startId) {
        if (intent == null) stopSelf(startId);
        Log.d(TAG, "onStartCommand id: " + startId + " Intent: " + intent);
        if (intent.getBooleanExtra(EXTRA_START_FOREGROUND, false)
            && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            mServiceHandler.postDelayed(mForegroundRunnable, 1000);
        } else {
            mServiceHandler.removeCallbacks(mForegroundRunnable);
        }
        Message msg = mServiceHandler.obtainMessage();
        msg.arg1 = startId;
        msg.obj = intent;
        mServiceHandler.sendMessage(msg);
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        Log.d(TAG, "onDestroy");
        mServiceHandler.removeCallbacksAndMessages(null);
        stopForeground(true);
        if (mFlutterEngineImage != null) {
            FlutterRenderer flutterRenderer = mFlutterEngineImage.getRenderer();
            flutterRenderer.stopRenderingToSurface();
            flutterRenderer.setSemanticsEnabled(false);
            mFlutterEngineImage.destroy();
        }
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void createImageFlutterEngine() {
        if (mFlutterEngineImage != null) return;
        mFlutterEngineImage = new FlutterEngine(getApplicationContext());
        FlutterLoader flutterLoader = FlutterInjector.instance().flutterLoader();
//        flutterLoader.ensureInitializationComplete(this, null);
        mFlutterEngineImage.getDartExecutor()
                           .executeDartEntrypoint(
                                   new DartEntrypoint(flutterLoader.findAppBundlePath(),
                                           "imageWidgetMain"));
    }

    private FlutterEngine createUIFlutterEngine() {
        FlutterEngine mFlutterEngineUI = new FlutterEngine(getApplicationContext());
        FlutterLoader flutterLoader = FlutterInjector.instance().flutterLoader();
//        flutterLoader.ensureInitializationComplete(this, null);
        mFlutterEngineUI.getDartExecutor()
                        .executeDartEntrypoint(
                                new DartEntrypoint(flutterLoader.findAppBundlePath(),
                                        "uiWidgetMain"));
        mFlutterEngineUI.getLifecycleChannel().appIsResumed();
        return mFlutterEngineUI;
    }

    private void destroyUIFlutterEngine(FlutterEngine engine) {
        if (engine != null) {
            engine.getLifecycleChannel().appIsPaused();
            FlutterRenderer flutterRenderer = engine.getRenderer();
            flutterRenderer.stopRenderingToSurface();
            flutterRenderer.setSemanticsEnabled(false);
            engine.destroy();
        }
    }

    private void handleUpdateImage(int startId, int[] widgetIds) {
        if (widgetIds == null || widgetIds.length == 0) {
            widgetIds = AppWidgetManager.getInstance(this)
                                        .getAppWidgetIds(
                                                new ComponentName(this, ImageWidgetProvider.class));
        }
        createImageFlutterEngine();
        HashMap<Integer, Boolean> jobs = new HashMap<>(widgetIds.length);
        for (int widgetId : widgetIds) {
            jobs.put(widgetId, false);
        }
        AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(this);

        for (int widgetId : widgetIds) {
            if (widgetId <= 0) {
                if (finishJob(jobs, widgetId)) {
                    stopSelf(startId);
                    return;
                } else {
                    continue;
                }
            }
            Log.d(TAG, "handleUpdateImage start " + widgetId);
            Bundle widgetInfo = appWidgetManager.getAppWidgetOptions(widgetId);
            int width = convertDpToPx(
                    widgetInfo.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH));
            int height = convertDpToPx(
                    widgetInfo.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT));
            if (width <= 0 || height <= 0) {
                if (finishJob(jobs, widgetId)) {
                    stopSelf(startId);
                    return;
                } else {
                    continue;
                }
            }

            boolean isNightModeOn = (getResources().getConfiguration().uiMode
                                     & Configuration.UI_MODE_NIGHT_MASK)
                                    == Configuration.UI_MODE_NIGHT_YES;
            PlatformBrightness brightness = isNightModeOn
                                            ? PlatformBrightness.dark
                                            : PlatformBrightness.light;
            mFlutterEngineImage.getSettingsChannel()
                               .startMessage()
                               .setTextScaleFactor(1)
                               .setUse24HourFormat(DateFormat.is24HourFormat(this))
                               .setPlatformBrightness(brightness)
                               .send();

            Log.d(TAG, "MethodChannel start " + widgetId);
            MethodChannel channel = new MethodChannel(mFlutterEngineImage.getDartExecutor(),
                    "Widget/Dart");
            List<Object> args = new ArrayList<>();
            Map<String, String> config = WidgetManager.of(this).getConfig(widgetId);
            config.put("text", "Flutter Image Widget");

            args.add(config);
            args.add(width);
            args.add(height);
            channel.invokeMethod("drawWidget", args, new Result() {
                @Override
                public void success(@Nullable Object result) {
                    Log.d(TAG, "success " + ((byte[]) result).length);
                    Bitmap bitmap = Bitmap.createBitmap(width, height, Config.ARGB_8888);
                    ByteBuffer buffer = ByteBuffer.wrap((byte[]) result);
                    bitmap.copyPixelsFromBuffer(buffer);

                    RemoteViews views = new RemoteViews(getPackageName(),
                            R.layout.widget);
                    views.setImageViewBitmap(R.id.widget_img, bitmap);
                    views.setOnClickPendingIntent(R.id.widget_img,
                            PendingIntent.getActivity(
                                    UpdateWidgetService.this,
                                    0,
                                    new Intent(UpdateWidgetService.this, MainActivity.class),
                                    PendingIntent.FLAG_UPDATE_CURRENT));

                    appWidgetManager.updateAppWidget(widgetId, views);
                    bitmap.recycle();
                    Log.d(TAG, "handleUpdateImage done " + widgetId);

                    if (finishJob(jobs, widgetId)) {
                        stopSelf(startId);
                    }
                }

                @Override
                public void error(String errorCode, @Nullable String errorMessage,
                        @Nullable Object errorDetails) {
                }

                @Override
                public void notImplemented() {
                }
            });
        }
    }

    private void handleUpdateUI(int startId, int[] widgetIds) {
        if (widgetIds == null || widgetIds.length == 0) {
            widgetIds = AppWidgetManager.getInstance(this)
                                        .getAppWidgetIds(
                                                new ComponentName(this, UIWidgetProvider.class));
        }
        createUIFlutterEngine();
        HashMap<Integer, Boolean> jobs = new HashMap<>(widgetIds.length);
        for (int widgetId : widgetIds) {
            jobs.put(widgetId, false);
        }
        AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(this);

        for (int widgetId : widgetIds) {
            if (widgetId <= 0) {
                if (finishJob(jobs, widgetId)) {
                    stopSelf(startId);
                    return;
                } else {
                    continue;
                }
            }
            Log.d(TAG, "handleUpdateUI start " + widgetId);
            Bundle widgetInfo = appWidgetManager.getAppWidgetOptions(widgetId);
            int width = convertDpToPx(
                    widgetInfo.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH));
            int height = convertDpToPx(
                    widgetInfo.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT));
            if (width <= 0 || height <= 0) {
                if (finishJob(jobs, widgetId)) {
                    stopSelf(startId);
                    return;
                } else {
                    continue;
                }
            }

            FlutterEngine flutterEngine = createUIFlutterEngine();

            boolean isNightModeOn = (getResources().getConfiguration().uiMode
                                     & Configuration.UI_MODE_NIGHT_MASK)
                                    == Configuration.UI_MODE_NIGHT_YES;
            PlatformBrightness brightness = isNightModeOn
                                            ? PlatformBrightness.dark
                                            : PlatformBrightness.light;

            flutterEngine.getSettingsChannel()
                         .startMessage()
                         .setTextScaleFactor(1)
                         .setUse24HourFormat(DateFormat.is24HourFormat(this))
                         .setPlatformBrightness(brightness)
                         .send();
            FlutterRenderer flutterRenderer = flutterEngine.getRenderer();
            FlutterRenderer.ViewportMetrics viewportMetrics = new FlutterRenderer.ViewportMetrics();
            viewportMetrics.width = width;
            viewportMetrics.height = height;
            viewportMetrics.devicePixelRatio = getResources().getDisplayMetrics().density;
            flutterRenderer.setViewportMetrics(viewportMetrics);

            mFlutterBackgroundRenderer = new FlutterBackgroundRenderer(this, width, height);
            mFlutterBackgroundRenderer.attachToRenderer(flutterRenderer);
            flutterRenderer.addIsDisplayingFlutterUiListener(new FlutterUiDisplayListener() {
                @Override
                public void onFlutterUiDisplayed() {
                    Log.d(TAG, "onFlutterUiDisplayed " + widgetId);
                    Bitmap bitmap = mFlutterBackgroundRenderer.getBitmap();
                    mFlutterBackgroundRenderer.detachFromRenderer();
                    RemoteViews views = new RemoteViews(getPackageName(), R.layout.widget);
                    views.setImageViewBitmap(R.id.widget_img, bitmap);
                    views.setOnClickPendingIntent(R.id.widget_img,
                            PendingIntent.getActivity(
                                    UpdateWidgetService.this,
                                    0,
                                    new Intent(UpdateWidgetService.this, MainActivity.class),
                                    PendingIntent.FLAG_UPDATE_CURRENT));

                    appWidgetManager.updateAppWidget(widgetId, views);
                    Log.d(TAG, "handleUpdateUI done " + widgetId);
                    destroyUIFlutterEngine(flutterEngine);
                    if (finishJob(jobs, widgetId)) {
                        stopSelf(startId);
                    }
                }

                @Override
                public void onFlutterUiNoLongerDisplayed() {
                }
            });
        }
    }

    private boolean finishJob(HashMap<Integer, Boolean> jobs, int id) {
        jobs.put(id, true);
        return !jobs.containsValue(false);
    }

    private int convertDpToPx(int dp) {
        final float scale = getResources().getDisplayMetrics().density;
        return (int) (dp * scale + 0.5f);
    }

    protected void onHandleIntent(Intent intent, int startId) {
        if (intent != null) {
            final String action = intent.getAction();
            if (ACTION_UPDATE_IMAGE.equals(action)) {
                handleUpdateImage(startId, intent.getIntArrayExtra(EXTRA_WIDGET_IDS));
            } else if (ACTION_UPDATE_UI.equals(action)) {
                handleUpdateUI(startId, intent.getIntArrayExtra(EXTRA_WIDGET_IDS));
            }
        }
    }

    private final class ServiceHandler
            extends Handler {
        ServiceHandler(Looper looper) {
            super(looper);
        }

        @Override
        public void handleMessage(Message msg) {
            onHandleIntent((Intent) msg.obj, msg.arg1);
        }
    }
}

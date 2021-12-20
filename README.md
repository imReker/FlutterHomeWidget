# Flutter Android/iOS/macOS Home Widget Example

This project demonstrates how to create an Android/iOS Home Widget or macOS Today Widget rendered by pure Flutter.

# Previews
![Previews](https://github.com/imReker/FlutterHomeWidget/raw/master/preview_android.gif)
![Previews](https://github.com/imReker/FlutterHomeWidget/raw/master/preview_iOS.gif)
![Previews](https://github.com/imReker/FlutterHomeWidget/raw/master/preview_macOS.gif)

# Introduction
All widget examples in this project are full functional, including widget configure and update.

# Notice
1. Flutter engine on iOS takes too much memory and may only works on Simulator.
2. Flutter render engine on Android has bug on handling transparent image, details: https://github.com/flutter/flutter/issues/73036

# Render mode
This project demonstrated 2 different methods to render a widget:

**1. UI Mode**

To render Home Widget, a new instance of flutter engine will be created, and run a new Flutter App to display UI of widget from a separate [`main` Dart function](https://github.com/imReker/FlutterHomeWidget/blob/6c279d87965457d9f057e3213c181c6db2721c29/lib/main.dart#L21).

The Widget UI is rendered by the background Flutter renderer, bitmap screenshots will be taken on native side and show in the Home Widget.


PROs:

Simple, write code as normal flutter app.

CONs:

Slow, Flutter side of `runApp` is slow, and a 200ms delay should be manually set after `setState`, because you have to wait for UI render/refresh.
It can takes >6 seconds in Debug mode on an old Android phone, but fortunately, it only takes ~1 second in Release mode, so the speed is still acceptable.
It takes lot of memory on iOS because it same as run a full Flutter App (FlutterEngine + FlutterViewController).
Some Flutter API used is Internal/Undocumented and maybe changed with upgrade of Flutter.


**2. Image Mode**

In Image Mode, flutter engine is initialized with a separate [`main` Dart function](https://github.com/imReker/FlutterHomeWidget/blob/6c279d87965457d9f057e3213c181c6db2721c29/lib/main.dart#L27), no Flutter App will be initialized, instead, a `MethodChannel` will be created.

The handler of `MethodChannel` will draw a image by a dart `Canvas` and return the bytes array to native side, then convert back to Bitmap and show.


PROs:

Fast, only a few of codes are executed, and bitmap is transferred via memory.

No need to wait for render, the image is drawn realtime(also means fast).

Moreover, you can write your own Encoder of `MethodChannel` to boost the speed of data exchange.

CONs:

Difficult to write code, the whole UI of Home Widget is drawn by `Canvas`.

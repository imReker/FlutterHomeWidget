# Flutter Android/iOS/macOS Widget Example

This project demonstrates how to create an Android/iOS Home Widget or macOS Today Widget rendered by pure Flutter.

# Previews
![Previews](https://github.com/imReker/FlutterHomeWidget/raw/master/preview_android.gif)
![Previews](https://github.com/imReker/FlutterHomeWidget/raw/master/preview_iOS.gif)
![Previews](https://github.com/imReker/FlutterHomeWidget/raw/master/preview_macOS.gif)

# Introduction
All widget examples in this project are full functional, including widget configure and update.

# iOS
Flutter engine on iOS takes too much memory and may only works on Simulator.

# Render mode
This project uses 2 different of methods to render a widget.

**1. UI Mode**

In UI Mode, flutter engine is initialized with a separate `main` Dart function and run a separate App to display UI of widget.

The UI is rendered by the background renderer, a Bitmap of UI screenshot will be taken and show in the widget.


PROs:

Simple, write code as normal flutter app.

CONs:

Slow, Flutter side of `runApp` is slow, and a 200ms delay should be manually set after `setState`, because you have to wait for UI refresh.
It can takes >6 seconds in Debug mode on an old Android phone.
Fortunately, it only takes ~1 second in Release mode, so the speed is still acceptable.


**2. Image Mode**

In Image Mode, flutter engine is initialized with a separate `main` Dart function and listen a `MethodChannel`.

The handler of `MethodChannel` will draw a image by a dart `Canvas` and return the bytes array to native side.

When the widget request to update, it convert the bytes to Bitmap and show.


PROs:

Fast, only a few of codes is executed, bitmap is transferred via memory.

No need to wait for render, the image is drawn realtime.

Moreover, you can write your own Encoder of `MethodChannel` to boost the speed of the exchange of data.

CONs:

Difficult to write code, the whole content is drawn by `Canvas`.

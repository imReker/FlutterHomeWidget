# Flutter Android/iOS/macOS Widget Example

This project demonstrates how to create an Android/iOS Home Widget or macOS Today Widget rendered by pure Flutter.

# Previews
![Previews](https://github.com/imReker/FlutterHomeWidget/raw/master/preview.gif)

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

Slow, run a full flutter app can takes >6 seconds on an old Android phone.

Flutter side of `runApp` is slow, and wait for renderer takes more time.


**2. Image Mode**

In Image Mode, flutter engine is initialized with a separate `main` Dart function and listen a `MethodChannel`.

The handler of `MethodChannel` will draw a image by a dart `Canvas` and return the bytes array to native side.

When the widget request to update, it convert the bytes to Bitmap and show.


PROs:

Fast, only a few of codes is executed, bitmap is transferred via memory.

Moreover, you can write your own Encoder of `MethodChannel` to boost the speed of the exchange of data.

CONs:

Difficult to write code, the whole widget content is drawn by `Canvas`.

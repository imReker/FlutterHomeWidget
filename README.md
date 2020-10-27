# Flutter Android/iOS Widget Example

This app demonstrates how to create an Android Home Widget or iOS Today widget rendered by Flutter.

# Previews
![Previews](https://github.com/imReker/FlutterHomeWidget/raw/master/preview.gif)

# iOS
WIP, will be release ASAP.

# Android
This example demonstrates 2 different methods to display an Android Widget.
And it has full support for Android Widget including new widget configure.

1. UI Mode
In UI Mode, flutter engine is initialized with a separate `main` Dart function and run a separate App to display UI of widget.
The UI is rendered by a background renderer at the Java side, a Bitmap of UI will be taken and show in the widget.

PROs:
Simple, write code as normal flutter app.
CONs:
Slow, run a full flutter app can takes >6 seconds on an old phone.
`runApp` is slow, and wait for renderer takes more time.

2. Image Mode
In Image Mode, flutter engine is initialized with a separate `main` Dart function and listen a `MethodChannel`.
The handler of `MethodChannel` will draw a image by `Canvas` and return the bytes array to Android side.
When Android widget request to update, it calls the Dart code, get the bytes array and convert to Bitmap, and show in the widget.

PROs:
Fast, only a few of codes is executed, bitmap is transferred via memory.
Moreover, you can write your own Encoder of `MethodChannel` to boost the speed of the exchange of data.
CONs:
Difficult to write code, the whole Android widget is drawn by Canvas.

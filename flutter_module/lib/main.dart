import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _widgetChannel = const MethodChannel('Widget/Dart');

/// Main for normal Flutter App.
void main() => runApp(MyApp());

/// Main for UI widget.
void uiWidgetMain() => runApp(UIWidgetApp());

/// Main for Image widget.
void imageWidgetMain() {
  WidgetsFlutterBinding.ensureInitialized();
  _widgetChannel.setMethodCallHandler((call) async {
    if (call.method == 'drawWidget') {
      return _drawWidget(
          call.arguments[0].toString(), call.arguments[1], call.arguments[2]);
    }

    return 0;
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      onGenerateInitialRoutes: (initialRoute) =>
          [_generateRoute(RouteSettings(name: initialRoute))],
      onGenerateRoute: _generateRoute,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }

  Route _generateRoute(RouteSettings settings) {
    WidgetBuilder route;

    if (settings.name.startsWith('/widget/settings/')) {
      // Navigated from Android Launcher.
      var routes = settings.name.split('/');
      settings = RouteSettings(name: '/widget/settings');
      route = (_) => ImageWidgetSettingsPage(routes[3], true);
    } else if (settings.name == '/widget/settings') {
      // Navigated from inside of flutter.
      route = (_) => ImageWidgetSettingsPage(settings.arguments, false);
    } else if (settings.name == '/') {
      route = (_) => MyHomePage(title: 'Flutter Demo Home Page');
    }
    if (route == null) {
      route = (_) => MyHomePage(title: '404 Not Found ' + settings.name);
    }
    return MaterialPageRoute(settings: settings, builder: route);
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Builder(
          builder: (context) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(widget.title),
                    ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        prefs.reload();
                        for (var value in prefs.getKeys()) {
                          if (value.startsWith(
                              ImageWidgetSettingsPage.PREFS_WIDGET_SETTINGS)) {
                            Navigator.of(context).pushNamed('/widget/settings',
                                arguments: value.replaceFirst(
                                    ImageWidgetSettingsPage
                                        .PREFS_WIDGET_SETTINGS,
                                    ''));
                            return;
                          }
                        }
                        Scaffold.of(context).showSnackBar(
                            SnackBar(content: Text('Widget not found')));
                      },
                      child: Text('Image widget Settings'),
                    )
                  ],
                ),
              )),
    );
  }
}

class ImageWidgetSettingsPage extends StatefulWidget {
  static const PREFS_WIDGET_SETTINGS = 'widget_settings_';

  final String widgetId;
  final bool fromAndroid;

  ImageWidgetSettingsPage(this.widgetId, this.fromAndroid);

  @override
  State createState() {
    return _ImageWidgetSettingsState();
  }
}

class _ImageWidgetSettingsState extends State<ImageWidgetSettingsPage> {
  var _mode = 0;

  _ImageWidgetSettingsState() {
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _mode = prefs.getBool(ImageWidgetSettingsPage.PREFS_WIDGET_SETTINGS +
                    widget.widgetId) ??
                false
            ? 1
            : 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Widget ID: ' + widget.widgetId),
              Text('Widget preview:'),
              CustomPaint(
                size: const Size(250, 100),
                painter: _ImageWidgetPainter(_mode),
              ),
              SwitchListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('use blue color'),
                onChanged: _onModeChanged,
                value: _mode > 0,
                selected: _mode > 0,
              ),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  prefs.setBool(
                      ImageWidgetSettingsPage.PREFS_WIDGET_SETTINGS +
                          widget.widgetId,
                      _mode > 0);

                  const channel = const MethodChannel('Widget/Native');
                  channel.invokeMethod("saveWidget");
                  Navigator.of(context).pop();
                },
                child: Text('Save'),
              )
            ],
          ),
        ),
      ),
      onWillPop: () async {
        if (widget.fromAndroid) {
          SystemNavigator.pop();
          return false;
        }
        return true;
      },
    );
  }

  void _onModeChanged(value) {
    setState(() {
      _mode = value ? 1 : 0;
    });
  }
}

class _ImageWidgetPainter extends CustomPainter {
  var _mode;

  _ImageWidgetPainter(this._mode);

  @override
  void paint(Canvas canvas, Size size) {
    _drawWidgetCanvas(
        canvas, Rect.fromLTWH(0, 0, size.width, size.height), _mode);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

Future<Uint8List> _drawWidget(String widgetId, int width, int height) async {
  var prefs = await SharedPreferences.getInstance();
  var mode =
      prefs.getBool(ImageWidgetSettingsPage.PREFS_WIDGET_SETTINGS + widgetId) ??
              false
          ? 1
          : 0;
  var pictureRecorder = PictureRecorder();
  var rect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  var canvas = Canvas(pictureRecorder, rect);
  _drawWidgetCanvas(canvas, rect, mode);
  var image = await pictureRecorder.endRecording().toImage(width, height);
  var byteData = await image.toByteData();
  return byteData.buffer.asUint8List();
}

void _drawWidgetCanvas(Canvas canvas, Rect rect, int mode) {
  canvas.clipRect(rect);
  canvas.drawColor(Colors.white54, BlendMode.src);

  var local = DateTime.now().toLocal();
  TextSpan spanTime = new TextSpan(
      style: new TextStyle(
          color: mode == 0 ? Colors.red : Colors.blue,
          fontSize: rect.height / 2),
      text: '${local.hour}:${local.minute}:${local.second}');
  TextPainter tpTime = new TextPainter(
      text: spanTime,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr);
  tpTime.layout();
  tpTime.paint(canvas, new Offset(0, 0));

  TextSpan spanTail = new TextSpan(
      style: new TextStyle(
          color: mode == 0 ? Colors.red : Colors.blue,
          fontSize: rect.height / 4),
      text: 'Flutter Image Widget');
  TextPainter tpTail = new TextPainter(
      text: spanTail,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr);
  tpTail.layout();
  tpTail.paint(canvas, new Offset(0, tpTime.height));
}

class UIWidgetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        // debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.red,
        ),
        home: Container(
            constraints: BoxConstraints.expand(),
            color: Colors.white54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  child: Text('Click'),
                  onPressed: () {},
                ),
                Text('Flutter UI Widget',
                    style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.none,
                        color: Colors.red)),
              ],
            )));
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _widgetChannel = const MethodChannel('Widget/Dart');

/// Main for normal Flutter App.
void main() async {
  runApp(MyApp());
}

/// Main for UI Widget.
@pragma('vm:entry-point')
void uiWidgetMain() {
  runApp(UIWidgetApp());
}

/// Main for Image Widget.
@pragma('vm:entry-point')
void imageWidgetMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  _widgetChannel.setMethodCallHandler((call) async {
    // print('${_widgetChannel.name}: ${call.toString()}');
    if (call.method == 'drawWidget') {
      return _drawWidget(
          call.arguments[0], call.arguments[1], call.arguments[2]);
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
      // Configure page navigated from Android Launcher.
      var routes = settings.name.split('/');
      settings = RouteSettings(name: '/widget/settings');
      route = (_) => ImageWidgetSettingsPage(routes[3], true);
    } else if (settings.name == '/widget/settings') {
      // Configure page navigated from inside of flutter(Android only).
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
      body: Builder(builder: bodyBuilder),
    );
  }

  Widget bodyBuilder(context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(widget.title, style: Theme.of(context).textTheme.headline6),
            if (Platform.isAndroid)
              ElevatedButton(
                onPressed: () => SharedPreferences.getInstance().then((prefs) {
                  prefs.reload();
                  for (var value in prefs.getKeys()) {
                    if (value.startsWith(
                        ImageWidgetSettingsPage.PREFS_WIDGET_SETTINGS)) {
                      final id = value.replaceFirst(
                          ImageWidgetSettingsPage.PREFS_WIDGET_SETTINGS, '');
                      Navigator.of(context)
                          .pushNamed('/widget/settings', arguments: id);
                      return null;
                    }
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Widget not found')));
                }),
                child: Text('Image widget Settings'),
              )
            else
              Text('For iOS widget configure,\n'
                  'please long press the widget on home screen.')
          ],
        ),
      );
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
  static const COLOR_NAMES = ['Red', 'Green', 'Blue'];
  static const COLORS = [
    Color.fromARGB(255, 255, 0, 0),
    Color.fromARGB(255, 0, 255, 0),
    Color.fromARGB(255, 0, 0, 255),
  ];
  Color _color;

  _ImageWidgetSettingsState() {
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        var color = int.tryParse(prefs.getString(
                ImageWidgetSettingsPage.PREFS_WIDGET_SETTINGS +
                    widget.widgetId)) ??
            0;
        _color = Color(color == 0 ? COLORS[0].value : color);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Widget ID: ' + widget.widgetId),
              Text('Widget preview:'),
              CustomPaint(
                size: const Size(250, 100),
                painter: _ImageWidgetPainter(_color),
              ),
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: COLOR_NAMES.length,
                  itemBuilder: (BuildContext context, int index) {
                    final title = COLOR_NAMES[index];
                    final color = COLORS[index];
                    return ListTile(
                        title: Text(title),
                        selected: _color.value == color.value,
                        onTap: () => setState(() {
                              _color = color;
                            }));
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () => SharedPreferences.getInstance().then((prefs) {
                  prefs.setString(
                      ImageWidgetSettingsPage.PREFS_WIDGET_SETTINGS +
                          widget.widgetId,
                      _color.value.toString());

                  const channel = const MethodChannel('Widget/Native');
                  channel.invokeMethod("saveWidget");
                  Navigator.of(context).pop();
                }),
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
      _color = value ? Colors.blue : Colors.red;
    });
  }
}

class _ImageWidgetPainter extends CustomPainter {
  Color _color;

  _ImageWidgetPainter(this._color);

  @override
  void paint(Canvas canvas, Size size) {
    _drawWidgetCanvas(canvas, Rect.fromLTWH(0, 0, size.width, size.height),
        _color, 'Flutter Image Widget');
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

Future<Uint8List> _drawWidget(Map configs, int width, int height) async {
  if (!configs.containsKey('color')) throw ArgumentError();
  var color = Color(int.parse(configs['color']));
  var text = configs['text'];
  var pictureRecorder = PictureRecorder();
  var rect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  var canvas = Canvas(pictureRecorder, rect);
  _drawWidgetCanvas(canvas, rect, color, text);
  var image = await pictureRecorder.endRecording().toImage(width, height);
  var byteData = await image.toByteData(format: ImageByteFormat.rawRgba);
  return byteData.buffer.asUint8List();
}

void _drawWidgetCanvas(Canvas canvas, Rect rect, Color color, String text) {
  canvas.clipRect(rect);
  canvas.drawColor(Colors.white54, BlendMode.src);
  var local = DateTime.now().toLocal();
  var time = '${local.hour}:${local.minute}:${local.second}';
  var tpLayout = TextPainter(
      text: TextSpan(text: '00:00:00'), textDirection: TextDirection.ltr);
  tpLayout.layout();
  var spanTime = TextSpan(
      style: TextStyle(
          color: color,
          fontSize: min(rect.width * 0.8 / tpLayout.width * tpLayout.height,
              rect.height * 2 / 3)),
      text: time);
  var tpTime = TextPainter(text: spanTime, textDirection: TextDirection.ltr);
  tpTime.layout();
  tpTime.paint(canvas, Offset(0, 0));

  var tail = text;
  tpLayout =
      TextPainter(text: TextSpan(text: tail), textDirection: TextDirection.ltr);
  tpLayout.layout();
  var spanTail = TextSpan(
      style: TextStyle(
          color: color,
          fontSize: min(rect.width * 0.8 / tpLayout.width * tpLayout.height,
              rect.height / 3)),
      text: tail);
  var tpTail = TextPainter(text: spanTail, textDirection: TextDirection.ltr);
  tpTail.layout();
  tpTail.paint(canvas, Offset(0, rect.height * 2 / 3));
}

class UIWidgetApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => UIWidgetState();
}

class UIWidgetState extends State<UIWidgetApp> {
  String time = '';

  UIWidgetState() {
    _widgetChannel.setMethodCallHandler((call) async {
      if (call.method == 'drawWidget') {
        RenderRepaintBoundary boundary = context.findRenderObject();
        var image = await boundary.toImage(pixelRatio: call.arguments['scale']);
        var byteData = await image.toByteData(format: ImageByteFormat.rawRgba);
        print(byteData.lengthInBytes);
        return byteData.buffer.asUint8List();
      }
      return 0;
    });

    Timer.periodic(Duration(seconds: 1), (timer) {
      var local = DateTime.now().toLocal();
      setState(() {
        time = '${local.hour}:${local.minute}:${local.second}';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        child: MaterialApp(
            // debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.system,
            theme: ThemeData(
                primarySwatch: Colors.red, brightness: Brightness.light),
            darkTheme: ThemeData(
                primarySwatch: Colors.blue, brightness: Brightness.dark),
            builder: (context, child) => Container(
                constraints: BoxConstraints.expand(),
                color: Colors.white54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      time,
                      style: Theme.of(context).textTheme.subtitle1.copyWith(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    ElevatedButton(child: Text('Click'), onPressed: () {}),
                    Text('Flutter UI Widget',
                        style: Theme.of(context).textTheme.subtitle1.copyWith(
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                ))));
  }
}

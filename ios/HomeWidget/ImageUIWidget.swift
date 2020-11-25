//
//  ImageUIWidget.swift
//
//  Created by reker on 2020/11/5.
//

import WidgetKit
import SwiftUI
import Intents
#if os(iOS)
import Flutter
#else
import Cocoa
import AppKit
import FlutterMacOS
#endif

struct ImageUIWidgetProvider: IntentTimelineProvider {
    @Environment(\.sizeCategory) var sizeCategory

    func drawWidget(_ configuration: ConfigurationIntent, _ context: Context, callback: @escaping DrawCallback) {
        let scale = UIScreen.main.scale
        let width = context.displaySize.width
        let height = context.displaySize.height
        let view = ImageUIWidget.flutterView!
        view.view.bounds.size.width = width
        view.view.bounds.size.height = height
        view.viewDidLayoutSubviews()
        view.viewWillAppear(false)
        view.viewDidAppear(false)
        
        let color = configuration.color?.identifier
        let args: [String: Any?] = [
            "id": configuration.identifier,
            "scale": UIScreen.main.scale,
            "color": color ?? "4294198070",
            "text": "Flutter Image UI Widget"
        ]

        ImageUIWidget.channel?.invokeMethod("drawWidget", arguments: args) { (result) in
            guard let flutterData = result as? FlutterStandardTypedData else {
                callback(nil)
                return
            }

            let image = imageFromPixel(flutterData.data, Int(width * scale), Int(height * scale))
            callback(image)
        }
    }

    func placeholder(in context: Context) -> ImageUIWidgetEntry {
        return ImageUIWidgetEntry(Date(),
            (UIImage(named: "WidgetSnapshot")?.cgImage)!)
    }

    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (ImageUIWidgetEntry) -> ()) {
        let entry = ImageUIWidgetEntry(Date(),
                         (UIImage(named: "WidgetSnapshot")?.cgImage)!)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        drawWidget(configuration, context) { (result) in
            var entry: ImageUIWidgetEntry
            if let image = result {
                entry = ImageUIWidgetEntry(Date(), image)
            } else {
                entry = ImageUIWidgetEntry(Date(), "Loading...")
                //Something wrong, retry after 0.1 second.
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                    WidgetCenter.shared.reloadTimelines(ofKind: ImageUIWidget.kind)
                }
            }
            
            var entries: [ImageUIWidgetEntry] = []
            entries.append(entry)
            completion(Timeline(entries: entries, policy: .atEnd))
            //For debug use
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                WidgetCenter.shared.reloadTimelines(ofKind: ImageUIWidget.kind)
            }
        }
    }
}

struct ImageUIWidgetEntry: TimelineEntry {
    let date: Date

    let image: CGImage?
    let text: String

    init(_ date: Date, _ text: String) {
        self.image = nil
        self.date = date
        self.text = text
    }

    init(_ date: Date, _ image: CGImage) {
        self.image = image
        self.date = date
        self.text = ""
    }
}

struct ImageUIWidgetEntryView: View {
    var entry: ImageUIWidgetProvider.Entry
    
    #if os(iOS)
    var scale: CGFloat = UIScreen.main.scale
    #else
    var scale: CGFloat = 1
    #endif

    var body: some View {
        VStack() {
            if (entry.image != nil) {
                Image(decorative: entry.image!, scale: scale).fixedSize()
            } else {
                Text(entry.text)
            }
        }
    }
}

struct ImageUIWidget: Widget {
    static let kind: String = "ImageUIWidget"
    static var flutterEngine: FlutterEngine?
    static var flutterView: FlutterViewController?
    static var channel: FlutterMethodChannel?

    init() {
//        raise(SIGINT)
        NSLog(ImageUIWidget.kind + " init")
        DispatchQueue.main.async {
            let engine = FlutterEngine(name: ImageUIWidget.kind)
            engine.run(withEntrypoint: "imageUIWidgetMain")
            GeneratedPluginRegistrant.register(with: engine)
            let view = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
            view.loadView()
            view.overrideUserInterfaceStyle = UIUserInterfaceStyle.light
            view.viewDidLoad()
            view.view.bounds.size.width = 1
            view.view.bounds.size.height = 1
            view.viewDidLayoutSubviews()
            ImageUIWidget.flutterEngine = engine
            ImageUIWidget.flutterView = view
            ImageUIWidget.channel = FlutterMethodChannel(name: "Widget/Dart", binaryMessenger: engine.binaryMessenger)
        }
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: ImageUIWidget.kind, intent: ConfigurationIntent.self, provider: ImageUIWidgetProvider()) { entry in
            ImageUIWidgetEntryView(entry: entry)
        }
            .supportedFamilies([.systemMedium])
            .configurationDisplayName("Flutter Image UI Widget")
            .description("This is an example widget.")
    }
}

struct ImageUIWidget_Previews: PreviewProvider {
    static var previews: some View {
        ImageUIWidgetEntryView(entry: ImageUIWidgetEntry(Date(), "Preview"))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

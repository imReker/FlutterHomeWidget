//
//  ImageWidget.swift
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

struct ImageWidgetProvider: IntentTimelineProvider {
    @Environment(\.sizeCategory) var sizeCategory

    func drawWidget(_ configuration: ConfigurationIntent, _ context: Context, callback: @escaping DrawCallback) {
        #if os(iOS)
        ImageWidget.flutterEngine!.settingsChannel
            .sendMessage(["textScaleFactor": textScaleFactor(sizeCategory),
                "alwaysUse24HourFormat": isAlwaysUse24HourFormat(),
                "platformBrightness": brightnessMode(),
                "platformContrast": contrastMode()])
        #endif
        var args = [Any]()
        let color = configuration.color?.identifier
        let config: [String: String?] = [
            "id": configuration.identifier,
            "color": color ?? "4294198070",
            "text": "Flutter Image Widget"
        ]
        
        #if os(iOS)
        let scale = UIScreen.main.nativeScale
        #else
        let scale: CGFloat = 1
        #endif
        let width = Int(context.displaySize.width * scale)
        let height = Int(context.displaySize.height * scale)

        args.append(config)
        args.append(width)
        args.append(height)

        ImageWidget.channel?.invokeMethod("drawWidget", arguments: args) { (result) in
            guard let flutterData = result as? FlutterStandardTypedData else {
                callback(nil)
                return
            }

            let image = imageFromPixel(flutterData.data, width, height)
            callback(image)
        }
    }

    func placeholder(in context: Context) -> ImageWidgetEntry {
        return ImageWidgetEntry(Date(),
            (UIImage(named: "WidgetSnapshot")?.cgImage)!)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (ImageWidgetEntry) -> ()) {
        let entry = ImageWidgetEntry(Date(),
                         (UIImage(named: "WidgetSnapshot")?.cgImage)!)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        drawWidget(configuration, context) { (result) in
            guard let image = result else { return }
            var entries: [ImageWidgetEntry] = []

            let entry = ImageWidgetEntry(Date(), image)
            entries.append(entry)
            completion(Timeline(entries: entries, policy: .atEnd))
            //For debug use
//            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
//                WidgetCenter.shared.reloadTimelines(ofKind: ImageWidget.kind)
//            }
        }
    }
}

struct ImageWidgetEntry: TimelineEntry {
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

struct ImageWidgetEntryView: View {
    var entry: ImageWidgetProvider.Entry
    
    #if os(iOS)
    var scale = UIScreen.main.nativeScale
    #else
    var scale: CGFloat = 1
    #endif

    var body: some View {
        VStack() {
            if (entry.image != nil) {
                Image(decorative: entry.image!, scale: scale)
            } else {
                Text(entry.text)
            }
        }
    }
}

struct ImageWidget: Widget {
    static let kind: String = "ImageWidget"
    static var flutterEngine: FlutterEngine?
    static var channel: FlutterMethodChannel?

    init() {
        NSLog(ImageWidget.kind + " init")
        DispatchQueue.main.async {
            let engine = FlutterEngine(name: ImageWidget.kind, project: nil)
            engine.run(withEntrypoint: "imageWidgetMain")
            #if os(iOS)
            GeneratedPluginRegistrant.register(with: engine)
            #else
            RegisterGeneratedPlugins(registry: engine)
            #endif
            ImageWidget.flutterEngine = engine
            ImageWidget.channel = FlutterMethodChannel(name: "Widget/Dart", binaryMessenger: engine.binaryMessenger)
        }
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: ImageWidget.kind, intent: ConfigurationIntent.self, provider: ImageWidgetProvider()) { entry in
            ImageWidgetEntryView(entry: entry)
        }
            .supportedFamilies([.systemMedium])
            .configurationDisplayName("Flutter Image Widget")
            .description("This is an example widget.")
    }
}

struct ImageWidget_Previews: PreviewProvider {
    static var previews: some View {
        ImageWidgetEntryView(entry: ImageWidgetEntry(Date(), "Preview"))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

func isAlwaysUse24HourFormat() -> Bool {
    let dateFormat: String = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: NSLocale.current) ?? ""
    return dateFormat.range(of: "a") == nil
}

func brightnessMode() -> String {
//    colorScheme == .dark ? "dark" : "light"
    "light"
}

func contrastMode() -> String {
//    colorSchemeContrast == .increased ? "high" : "normal"
    "normal"
}

func textScaleFactor(_ sizeCategory: ContentSizeCategory) -> Float64 {
    let xs: Float64 = 14
    let s: Float64 = 15
    let m: Float64 = 16
    let l: Float64 = 17
    let xl: Float64 = 19
    let xxl: Float64 = 21
    let xxxl: Float64 = 23
    let ax1: Float64 = 28
    let ax2: Float64 = 33
    let ax3: Float64 = 40
    let ax4: Float64 = 47
    let ax5: Float64 = 53

    switch sizeCategory {
    case .extraSmall:
        return xs / l
    case .small:
        return s / l
    case .medium:
        return m / l
    case .large:
        return 1.0
    case .extraLarge:
        return xl / l
    case .extraExtraLarge:
        return xxl / l
    case .extraExtraExtraLarge:
        return xxxl / l
    case .accessibilityMedium:
        return ax1 / l
    case .accessibilityLarge:
        return ax2 / l
    case .accessibilityExtraLarge:
        return ax3 / l
    case .accessibilityExtraExtraLarge:
        return ax4 / l
    case .accessibilityExtraExtraExtraLarge:
        return ax5 / l
    default:
        return 1.0
    }
}

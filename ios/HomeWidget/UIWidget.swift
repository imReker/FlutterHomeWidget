//
//  UIWidget.swift
//
//  Created by reker on 2020/11/5.
//

import WidgetKit
import SwiftUI
import Intents
#if os(iOS)
import Flutter
#else
import FlutterMacOS
#endif

struct UIWidgetProvider: TimelineProvider {
    func drawWidget(_ id: String, _ context: Context, callback: @escaping DrawCallback) {
        let width = context.displaySize.width
        let height = context.displaySize.height
        let view = UIWidget.flutterView!
        let onDisplay = {
            guard let data = FlutterNative.takeScreenshot(UIWidget.flutterEngine!)
                else {
                    callback(nil)
                    return
            }
            #if os(iOS)
            let scale = UIScreen.main.scale
            #else
            let scale: CGFloat = 1
            #endif
            let image = imageFromPixel(data, Int(width * scale), Int(height * scale))
            callback(image)
            
            #if os(iOS)
            view.viewWillDisappear(false)
            view.viewDidDisappear(false)
            #else
            view.viewWillDisappear()
            view.viewDidDisappear()
            #endif
        }
        #if os(iOS)
        if view.isDisplayingFlutterUI {
            onDisplay()
            return
        }
        view.setFlutterViewDidRenderCallback(onDisplay)
        #endif
        view.view.bounds.size.width = width
        view.view.bounds.size.height = height
        view.viewDidLayoutSubviews()
        view.viewWillAppear(false)
        view.viewDidAppear(false)
    }

    func placeholder(in context: Context) -> UIWidgetEntry {
        return UIWidgetEntry(Date(),
            (UIImage(named: "WidgetSnapshot")?.cgImage)!)
    }

    func getSnapshot(in context: Context, completion: @escaping (UIWidgetEntry) -> ()) {
        drawWidget("ui snapshot", context) { (result) in
            guard let image = result else { return }

            let entry = UIWidgetEntry(Date(), image)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        NSLog(UIWidget.kind + " getTimeline")

        drawWidget("ui", context) { (result) in
            var entry: UIWidgetEntry
            if let image = result {
                entry = UIWidgetEntry(Date(), image)
            } else {
                entry = UIWidgetEntry(Date(), "Loading...")
                //Something wrong, retry after 0.1 second.
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                    WidgetCenter.shared.reloadTimelines(ofKind: UIWidget.kind)
                }
            }
            var entries: [UIWidgetEntry] = []
            entries.append(entry)
            completion(Timeline(entries: entries, policy: .atEnd))
            //For debug use
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                WidgetCenter.shared.reloadTimelines(ofKind: UIWidget.kind)
            }
        }
    }
}

struct UIWidgetEntry: TimelineEntry {
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

struct UIWidgetEntryView: View {
    var entry: UIWidgetProvider.Entry

    @ViewBuilder
    var body: some View {
        VStack() {
            if (entry.image != nil) {
                Image(decorative: entry.image!,
                    scale: UIScreen.main.nativeScale)
            } else {
                Text(entry.text)
            }
        }
    }
}

struct UIWidget: Widget {
    static let kind: String = "UIWidget"
    static var flutterEngine: FlutterEngine?
    static var flutterView: FlutterViewController?

    init() {
        NSLog(UIWidget.kind + " init")
        DispatchQueue.main.async {
            let engine = FlutterEngine(name: UIWidget.kind)
            engine.run(withEntrypoint: "uiWidgetMain")
            GeneratedPluginRegistrant.register(with: engine)
            let view = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
            view.loadView()
            view.overrideUserInterfaceStyle = UIUserInterfaceStyle.light
            view.viewDidLoad()
            view.view.bounds.size.width = 1
            view.view.bounds.size.height = 1
            view.viewDidLayoutSubviews()
            UIWidget.flutterEngine = engine
            UIWidget.flutterView = view
        }
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: UIWidget.kind, provider: UIWidgetProvider()) { entry in
            UIWidgetEntryView(entry: entry)
        }
            .supportedFamilies([.systemMedium])
            .configurationDisplayName("Flutter UI Widget")
            .description("This is an example widget.")
    }
}

struct UIWidget_Previews: PreviewProvider {
    static var previews: some View {
        UIWidgetEntryView(entry: UIWidgetEntry(Date(), "Preview"))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

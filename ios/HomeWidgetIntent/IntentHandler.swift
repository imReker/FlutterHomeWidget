//
//  IntentHandler.swift
//  HomeWidgetIntent
//
//  Created by reker on 2020/11/9.
//

import Intents
import Foundation

class IntentHandler: INExtension, ConfigurationIntentHandling {
    let colors = [
        WidgetColor(identifier: "4294198070", display: "Red"),
        WidgetColor(identifier: "4283215696", display: "Green"),
        WidgetColor(identifier: "4280391411", display: "Blue"),
    ]
    
    func provideColorOptionsCollection(for intent: ConfigurationIntent, with completion: @escaping (INObjectCollection<WidgetColor>?, Error?) -> Void) {
        completion(INObjectCollection(items: colors), nil)
    }

    func defaultColor(for intent: ConfigurationIntent) -> WidgetColor? {
        return colors[0]
    }

    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        return self
    }
}

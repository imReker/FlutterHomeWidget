//
//  FlutterInternal.cpp
//  HomeWidgetExtension
//
//  Created by reker on 2020/11/6.
//

#import "Widget-Bridging-Header.h"
#import "FlutterInternal.hpp"

@implementation FlutterNative

+ (NSData*) takeScreenshot: (id<FlutterViewEngineDelegate>) engine
{
    _Screenshot screenshot =
    [engine takeScreenshot:ScreenshotType::UncompressedImage
                                asBase64Encoded:NO];
    if (!screenshot.data || screenshot.data->isEmpty() || screenshot.frame_size.isEmpty()) {
        return nullptr;
    }
    
    NSData* data = [NSData dataWithBytes:const_cast<void*>(screenshot.data->data())
                                  length:screenshot.data->size()];
    return data;
}
@end

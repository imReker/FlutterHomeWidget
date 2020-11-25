//
//  FlutterInternal.h
//  HomeWidgetExtension
//
//  Created by reker on 2020/11/6.
//

#ifndef FlutterInternal_h
#define FlutterInternal_h

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "Skia/core/SkData.h"
#import "Skia/core/SkSize.h"

//namespace flutter {
//class Rasterizer final {
//public:
//    enum class ScreenshotType {
//        SkiaPicture,
//        UncompressedImage,
//        CompressedImage,
//    };
    struct _Screenshot {
        sk_sp<SkData> data;
        SkISize frame_size;
        _Screenshot();
        _Screenshot(sk_sp<SkData> p_data, SkISize p_size);
        _Screenshot(const Screenshot& other);
        ~_Screenshot() = default;
    };
//};
//}

//@protocol FlutterViewEngineDelegate <NSObject>
//- (flutter::Rasterizer::Screenshot)takeScreenshot:(flutter::Rasterizer::ScreenshotType)type asBase64Encoded:(BOOL)base64Encode;
//@end

//@interface FlutterEngine () <FlutterViewEngineDelegate>
//@end

#endif /* FlutterInternal_h */

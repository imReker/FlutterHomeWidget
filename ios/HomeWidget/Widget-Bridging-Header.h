#import "../Runner/GeneratedPluginRegistrant.h"
#import <Foundation/Foundation.h>

typedef enum  {
    SkiaPicture,
    UncompressedImage,
    CompressedImage,
} ScreenshotType;

typedef struct _Screenshot Screenshot;

typedef struct  {
    double device_pixel_ratio;
    double physical_width;
    double physical_height;
    double physical_padding_top;
    double physical_padding_right;
    double physical_padding_bottom;
    double physical_padding_left;
    double physical_view_inset_top;
    double physical_view_inset_right;
    double physical_view_inset_bottom;
    double physical_view_inset_left;
    double physical_system_gesture_inset_top;
    double physical_system_gesture_inset_right;
    double physical_system_gesture_inset_bottom;
    double physical_system_gesture_inset_left;
} ViewportMetrics;

@interface FlutterNative : NSObject
+ (NSData*) takeScreenshot: (FlutterEngine*)engine;
@end

@protocol FlutterViewEngineDelegate <NSObject>
- (Screenshot)takeScreenshot:(ScreenshotType)type asBase64Encoded:(BOOL)base64Encode;

- (void)updateViewportMetrics:(ViewportMetrics)viewportMetrics;
@end

@interface FlutterEngine () <FlutterViewEngineDelegate>
- (void)updateViewportMetrics:(ViewportMetrics)viewportMetrics;

- (Screenshot)screenshot:(ScreenshotType)type base64Encode:(bool)base64Encode;
@end

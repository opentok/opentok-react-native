//
//  OTScreenCapture.m
//  Screen-Sharing
//
//  Copyright (c) 2014 TokBox Inc. All rights reserved.
//

#include <mach/mach.h>
#include <mach/mach_time.h>
#import <ReplayKit/ReplayKit.h>
#import "OTScreenCapture.h"

@implementation OTScreenCapture {
    dispatch_queue_t _queue;
    
    CVPixelBufferRef _pixelBuffer;
    BOOL _capturing;
    OTVideoFrame* _videoFrame;
    UIView* _view;
    
    CGFloat _screenScale;
    CGContextRef _bitmapContext;
    
    CADisplayLink *_displayLink;
    dispatch_semaphore_t _capturingSemaphore;
}

@synthesize videoCaptureConsumer;
@synthesize videoContentHint;

#pragma mark - Class Lifecycle.

- (instancetype)initWithView:(UIView *)view
{
    self = [super init];
    if (self) {
        _view = view;
        _queue = dispatch_queue_create("SCREEN_CAPTURE", NULL);
        _screenScale = [[UIScreen mainScreen] scale];
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(captureView)];
        _displayLink.preferredFramesPerSecond = 30.0;
        _capturingSemaphore = dispatch_semaphore_create(1);
        [self createPixelBuffer];
        [self createCGContextFromPixelBuffer];
    }
    return self;
}

- (void)dealloc
{
    [self stopCapture];
    if(_bitmapContext)
        CGContextRelease(_bitmapContext);
    if(_pixelBuffer)
        CVPixelBufferRelease(_pixelBuffer);
}

#pragma mark - Private Methods

- (CMTime)getTimeStamp {
    static mach_timebase_info_data_t time_info;
    uint64_t time_stamp = 0;
    if (time_info.denom == 0) {
        (void) mach_timebase_info(&time_info);
    }
    time_stamp = mach_absolute_time();
    time_stamp *= time_info.numer;
    time_stamp /= time_info.denom;
    CMTime time = CMTimeMake(time_stamp, 1000);
    return time;
}

-(void)captureView
{
    if (!(_capturing && self.videoCaptureConsumer)) {
        return;
    }

    // Wait until consumeImageBuffer is done.
    if (dispatch_semaphore_wait(_capturingSemaphore, DISPATCH_TIME_NOW) != 0) {
           return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view.layer renderInContext:self->_bitmapContext];
        // Don't block the UI thread
        dispatch_async(self->_queue, ^{
            CMTime time = [self getTimeStamp];
           [self.videoCaptureConsumer consumeImageBuffer:self->_pixelBuffer
                                             orientation:OTVideoOrientationUp
                                               timestamp:time
                                                metadata:nil];
            // Signal for more frames
            dispatch_semaphore_signal(self->_capturingSemaphore);
        });
    });
}

- (void)createCGContextFromPixelBuffer {
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CVPixelBufferLockBaseAddress(_pixelBuffer, 0);

    _bitmapContext = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(_pixelBuffer),
                                          CVPixelBufferGetWidth(_pixelBuffer),
                                          CVPixelBufferGetHeight(_pixelBuffer),
                                          8, CVPixelBufferGetBytesPerRow(_pixelBuffer), rgbColorSpace,
                                          kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst
                                          );
    CGContextTranslateCTM(_bitmapContext, 0.0f, self.view.frame.size.height);
    CGContextScaleCTM(_bitmapContext, self.view.layer.contentsScale, -self.view.layer.contentsScale);
    CVPixelBufferUnlockBaseAddress(_pixelBuffer, 0);
    CFRelease(rgbColorSpace);
}

- (void)createPixelBuffer {

    CFDictionaryRef ioSurfaceProps = CFDictionaryCreate( kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks );

    NSDictionary *bufferAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                       (id)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                                       (id)kCVPixelBufferWidthKey : @(self.view.frame.size.width * _screenScale),
                                       (id)kCVPixelBufferHeightKey : @(self.view.frame.size.height * _screenScale),
                                       (id)kCVPixelBufferBytesPerRowAlignmentKey :
                                           @(self.view.frame.size.width * _screenScale * 4),
                                       (id)kCVPixelBufferIOSurfacePropertiesKey : (__bridge id)ioSurfaceProps
                                       };
     CVPixelBufferCreate(kCFAllocatorDefault,
                                             self.view.frame.size.width,
                                             self.view.frame.size.height,
                                             kCVPixelFormatType_32ARGB,
                                             (__bridge CFDictionaryRef)(bufferAttributes),
                                          &_pixelBuffer);
    CFRelease(ioSurfaceProps);
}

#pragma mark - Capture lifecycle

- (void)initCapture {
    
}

- (void)releaseCapture {
    [_displayLink invalidate];
}

- (int32_t)startCapture
{
    _capturing = YES;
   [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    return 0;
}

- (int32_t)stopCapture
{
    _capturing = NO;
    [_displayLink invalidate];
    return 0;
}

- (BOOL)isCaptureStarted
{
    return _capturing;
}

- (int32_t)captureSettings:(OTVideoFormat*)videoFormat
{
    videoFormat.pixelFormat = OTPixelFormatARGB;
    return 0;
}

@end

//
//  OTScreenCapture.m
//  Screen-Sharing
//
//  Copyright (c) 2014 TokBox Inc. All rights reserved.
//

#include <mach/mach.h>
#include <mach/mach_time.h>
#import "OTScreenCapture.h"

@implementation OTScreenCapture {
    CMTime _minFrameDuration;
    dispatch_queue_t _queue;
    dispatch_source_t _timer;
    
    CVPixelBufferRef _pixelBuffer;
    BOOL _capturing;
    OTVideoFrame* _videoFrame;
    UIView* _view;
    
}

@synthesize videoCaptureConsumer;

#pragma mark - Class Lifecycle.

- (instancetype)initWithView:(UIView *)view
{
    self = [super init];
    if (self) {
        _view = view;
        // Recommend sending 5 frames per second: Allows for higher image
        // quality per frame
        _minFrameDuration = CMTimeMake(1, 5);
        _queue = dispatch_queue_create("SCREEN_CAPTURE", NULL);
        
        OTVideoFormat *format = [[OTVideoFormat alloc] init];
        [format setPixelFormat:OTPixelFormatARGB];
        
        _videoFrame = [[OTVideoFrame alloc] initWithFormat:format];
        
    }
    return self;
}

- (void)dealloc
{
    [self stopCapture];
    CVPixelBufferRelease(_pixelBuffer);
}

#pragma mark - Private Methods

/**
 * Make sure receiving video frame container is setup for this image.
 */
- (void)checkImageSize:(CGImageRef)image {
    CGFloat width = CGImageGetWidth(image);
    CGFloat height = CGImageGetHeight(image);
    
    if (_videoFrame.format.imageHeight == height &&
        _videoFrame.format.imageWidth == width)
    {
        // don't rock the boat. if nothing has changed, don't update anything.
        return;
    }
    
    [_videoFrame.format.bytesPerRow removeAllObjects];
    [_videoFrame.format.bytesPerRow addObject:@(width * 4)];
    [_videoFrame.format setImageHeight:height];
    [_videoFrame.format setImageWidth:width];
    
    CGSize frameSize = CGSizeMake(width, height);
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @NO,
                             kCVPixelBufferCGImageCompatibilityKey,
                             @NO,
                             kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    if (NULL != _pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
    }
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameSize.width,
                                          frameSize.height,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef)(options),
                                          &_pixelBuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && _pixelBuffer != NULL);

}

#pragma mark - Capture lifecycle

/**
 * Allocate capture resources; in this case we're just setting up a timer and 
 * block to execute periodically to send video frames.
 */
- (void)initCapture {
    __unsafe_unretained OTScreenCapture* _self = self;
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0),
                              100ull * NSEC_PER_MSEC, 100ull * NSEC_PER_MSEC);
    
    dispatch_source_set_event_handler(_timer, ^{
        @autoreleasepool {
            __block UIImage* screen = [_self screenshot];
            CGImageRef paddedScreen = [self resizeAndPadImage:screen];
            [_self consumeFrame:paddedScreen];
        }
    });
}

- (void)releaseCapture {
    _timer = nil;
}

- (int32_t)startCapture
{
    _capturing = YES;

    if (_timer) {
        dispatch_resume(_timer);
    }
    
    return 0;
}

- (int32_t)stopCapture
{
    _capturing = NO;
    
    dispatch_sync(_queue, ^{
        if (self->_timer) {
            dispatch_source_cancel(self->_timer);
        }
    });

    return 0;
}

- (BOOL)isCaptureStarted
{
    return _capturing;
}

#pragma mark - Screen capture implementation

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
{
    CGFloat width = CGImageGetWidth(image);
    CGFloat height = CGImageGetHeight(image);
    CGSize frameSize = CGSizeMake(width, height);
    CVPixelBufferLockBaseAddress(_pixelBuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(_pixelBuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context =
    CGBitmapContextCreate(pxdata,
                          frameSize.width,
                          frameSize.height,
                          8,
                          CVPixelBufferGetBytesPerRow(_pixelBuffer),
                          rgbColorSpace,
                          kCGImageAlphaPremultipliedFirst |
                          kCGBitmapByteOrder32Little);
    
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(_pixelBuffer, 0);
    
    return _pixelBuffer;
}

- (int32_t)captureSettings:(OTVideoFormat*)videoFormat
{
    videoFormat.pixelFormat = OTPixelFormatARGB;
    return 0;
}

+ (void)dimensionsForInputSize:(CGSize)input
                 containerSize:(CGSize*)destContainerSize
                      drawRect:(CGRect*)destDrawRect
{
    CGFloat sourceWidth = input.width;
    CGFloat sourceHeight = input.height;
    double sourceAspectRatio = sourceWidth / sourceHeight;
    
    CGFloat destContainerWidth = sourceWidth;
    CGFloat destContainerHeight = sourceHeight;
    CGFloat destImageWidth = sourceWidth;
    CGFloat destImageHeight = sourceHeight;
    
    // if image is wider than tall and width breaks edge size limit
    if (MAX_EDGE_SIZE_LIMIT < sourceWidth && sourceAspectRatio >= 1.0) {
        destContainerWidth = MAX_EDGE_SIZE_LIMIT;
        destContainerHeight = destContainerWidth / sourceAspectRatio;
        if (0 != fmod(destContainerHeight, EDGE_DIMENSION_COMMON_FACTOR)) {
            // add padding to make height % 16 == 0
            destContainerHeight +=
            (EDGE_DIMENSION_COMMON_FACTOR - fmod(destContainerHeight,
                                                 EDGE_DIMENSION_COMMON_FACTOR));
        }
        destImageWidth = destContainerWidth;
        destImageHeight = destContainerWidth / sourceAspectRatio;
    }
    
    // if image is taller than wide and height breaks edge size limit
    if (MAX_EDGE_SIZE_LIMIT < destContainerHeight && sourceAspectRatio <= 1.0) {
        destContainerHeight = MAX_EDGE_SIZE_LIMIT;
        destContainerWidth = destContainerHeight * sourceAspectRatio;
        if (0 != fmod(destContainerWidth, EDGE_DIMENSION_COMMON_FACTOR)) {
            // add padding to make width % 16 == 0
            destContainerWidth +=
            (EDGE_DIMENSION_COMMON_FACTOR - fmod(destContainerWidth,
                                                 EDGE_DIMENSION_COMMON_FACTOR));
        }
        destImageHeight = destContainerHeight;
        destImageWidth = destContainerHeight * sourceAspectRatio;
    }
    
    // ensure the dimensions of the resulting container are safe
    if (fmod(destContainerWidth, EDGE_DIMENSION_COMMON_FACTOR) != 0) {
        double remainder = fmod(destContainerWidth,
                                EDGE_DIMENSION_COMMON_FACTOR);
        // increase the edge size only if doing so does not break the edge limit
        if (destContainerWidth + (EDGE_DIMENSION_COMMON_FACTOR - remainder) >
            MAX_EDGE_SIZE_LIMIT)
        {
            destContainerWidth -= remainder;
        } else {
            destContainerWidth += EDGE_DIMENSION_COMMON_FACTOR - remainder;
        }
    }
    // ensure the dimensions of the resulting container are safe
    if (fmod(destContainerHeight, EDGE_DIMENSION_COMMON_FACTOR) != 0) {
        double remainder = fmod(destContainerHeight,
                                EDGE_DIMENSION_COMMON_FACTOR);
        // increase the edge size only if doing so does not break the edge limit
        if (destContainerHeight + (EDGE_DIMENSION_COMMON_FACTOR - remainder) >
            MAX_EDGE_SIZE_LIMIT)
        {
            destContainerHeight -= remainder;
        } else {
            destContainerHeight += EDGE_DIMENSION_COMMON_FACTOR - remainder;
        }
    }
    
    destContainerSize->width = destContainerWidth;
    destContainerSize->height = destContainerHeight;
    
    // scale and recenter source image to fit in destination container
    if (sourceAspectRatio > 1.0) {
        destDrawRect->origin.x = 0;
        destDrawRect->origin.y =
        (destContainerHeight - destImageHeight) / 2;
        destDrawRect->size.width = destContainerWidth;
        destDrawRect->size.height =
        destContainerWidth / sourceAspectRatio;
    } else {
        destDrawRect->origin.x =
        (destContainerWidth - destImageWidth) / 2;
        destDrawRect->origin.y = 0;
        destDrawRect->size.height = destContainerHeight;
        destDrawRect->size.width =
        destContainerHeight * sourceAspectRatio;
    }

}

- (CGImageRef)resizeAndPadImage:(UIImage*)sourceUIImage {
    CGImageRef sourceCGImage = [sourceUIImage CGImage];
    CGFloat sourceWidth = CGImageGetWidth(sourceCGImage);
    CGFloat sourceHeight = CGImageGetHeight(sourceCGImage);
    CGSize sourceSize = CGSizeMake(sourceWidth, sourceHeight);
    CGSize destContainerSize = CGSizeZero;
    CGRect destRectForSourceImage = CGRectZero;
    
    [OTScreenCapture dimensionsForInputSize:sourceSize
                              containerSize:&destContainerSize
                                   drawRect:&destRectForSourceImage];
    
    UIGraphicsBeginImageContextWithOptions(destContainerSize, NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // flip source image to match destination coordinate system
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextTranslateCTM(context, 0, -destRectForSourceImage.size.height);
    CGContextDrawImage(context, destRectForSourceImage, sourceCGImage);
    
    // Clean up and get the new image.
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [newImage CGImage];
}

- (UIImage *)screenshot
{
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 0.0);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void) consumeFrame:(CGImageRef)frame {
    
    [self checkImageSize:frame];

    static mach_timebase_info_data_t time_info;
    uint64_t time_stamp = 0;
    
    if (!(_capturing && self.videoCaptureConsumer)) {
        return;
    }
    
    if (time_info.denom == 0) {
        (void) mach_timebase_info(&time_info);
    }
    
    time_stamp = mach_absolute_time();
    time_stamp *= time_info.numer;
    time_stamp /= time_info.denom;
    
    CMTime time = CMTimeMake(time_stamp, 1000);
    CVImageBufferRef ref = [self pixelBufferFromCGImage:frame];
    
    CVPixelBufferLockBaseAddress(ref, 0);

    _videoFrame.timestamp = time;
    _videoFrame.format.estimatedFramesPerSecond =
    _minFrameDuration.timescale / _minFrameDuration.value;
    _videoFrame.format.estimatedCaptureDelay = 100;
    _videoFrame.orientation = OTVideoOrientationUp;
    
    [_videoFrame clearPlanes];
    [_videoFrame.planes addPointer:CVPixelBufferGetBaseAddress(ref)];
    [self.videoCaptureConsumer consumeFrame:_videoFrame];
    
    CVPixelBufferUnlockBaseAddress(ref, 0);
}


@end

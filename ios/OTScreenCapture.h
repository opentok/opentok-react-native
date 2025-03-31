//
//  OTScreenCapture.h
//  Screen-Sharing
//
//  Copyright (c) 2014 TokBox Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenTok/OpenTok.h>

@protocol OTVideoCapture;

/**
 * Periodically sends video frames to an OpenTok Publisher by rendering the
 * CALayer for a UIView.
 */
@interface OTScreenCapture : NSObject <OTVideoCapture>

@property(readonly) UIView* view;

/**
 * Initializes a video capturer that will grab rendered stills of the view.
 */
- (instancetype)initWithView:(UIView*)view;


@end

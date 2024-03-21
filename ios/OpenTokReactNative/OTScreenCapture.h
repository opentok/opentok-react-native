//
//  OTScreenCapture.h
//  Screen-Sharing
//

#import <Foundation/Foundation.h>
#import <OpenTok/OpenTok.h>

@protocol OTVideoCapture;

/**
 * Periodically sends video frames to a Publisher by rendering the
 * CALayer for a UIView.
 */
@interface OTScreenCapture : NSObject <OTVideoCapture>

@property(readonly) UIView* view;

/**
 * Initializes a video capturer that will grab rendered stills of the view.
 */
- (instancetype)initWithView:(UIView*)view;


@end

#import "FabricComponentRegistrar.h"
#import <React/RCTComponentViewFactory.h>
#import <React/RCTLog.h>
#import <OpentokReactNative/OTRNPublisherComponentView.h>
#import <OpentokReactNative/OTRNSubscriberComponentView.h>

@implementation FabricComponentRegistrar

+ (void)registerCustomComponents {
    RCTComponentViewFactory *factory = [RCTComponentViewFactory currentComponentViewFactory];
    [factory registerComponentViewClass:[OTRNPublisherComponentView class]];
    [factory registerComponentViewClass:[OTRNSubscriberComponentView class]];
}

@end

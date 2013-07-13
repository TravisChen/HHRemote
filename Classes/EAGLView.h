#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import "Setup.h"

@interface EAGLView : UIView {
@public
    bool showStatusBanner;
	bool imageChanged[BlockRows];
    CGImageRef images[BlockRows];
    unsigned char imageData[BlockRows][BlockWidth * BlockHeight * 3];
@private
	NSTimer *animationTimer;
	NSTimeInterval animationInterval;
}

- (id)initWithFrame:(CGRect)frame;
- (void)initImageAtIndex:(int)index data:(unsigned char *)d length:(int)len;
- (void)redrawScreen;

@end

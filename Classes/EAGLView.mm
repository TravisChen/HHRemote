#import "iPhoneRemoteInput.h"
#import "iPhoneRemoteInputImpl.h"
#import "EAGLView.h"

static inline CGFloat RoundToIntPrecision(CGFloat flt)
{
    int i = (int)flt;
    return (CGFloat)i;
}


@implementation EAGLView

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
        for (int i = 0; i < BlockRows; i++)
        {
            imageChanged[i] = false;
            images[i] = nil;
        }

        showStatusBanner = true;
		animationInterval = 1.0 / 60.0;
		[self setMultipleTouchEnabled:YES];
	}

	return self;
}

- (void)initImageAtIndex:(int)index data:(unsigned char *)d length:(int)len
{
    if (index < BlockRows)
    {
        if (images[index] != nil)
        {
            CGImageRef i = images[index];
            CGImageRelease(i);
            images[index] = nil;
        }

        memcpy(imageData[index], d, len);

        // Use CGDataProviderCreateDirect ?
        CGDataProviderRef jpegData = CGDataProviderCreateWithData(
            NULL, imageData[index], len, NULL);

        CGImageRef img = CGImageCreateWithJPEGDataProvider(
            jpegData, NULL, false, kCGRenderingIntentDefault);

        CGDataProviderRelease(jpegData);

        images[index] = img;
        imageChanged[index] = true;
    }

    showStatusBanner = false;
}

- (void)redrawScreen
{
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef myContext = UIGraphicsGetCurrentContext();

    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    CGFloat aspectW = screenBounds.size.width / (CGFloat)BlockWidth;
	CGFloat aspectH = screenBounds.size.height / ((CGFloat)BlockHeight * (CGFloat)BlockRows);
    CGFloat blockWidth = ((CGFloat)BlockWidth * aspectW);
    CGFloat blockHeight = (RoundToIntPrecision((CGFloat)BlockHeight * aspectH));

    if (showStatusBanner == false)
    {
        for (int i = 0; i < BlockRows; i++)
        {
            CGImageRef img = images[i];

            if (img != nil)
            {
                CGContextSaveGState(myContext);
                CGContextTranslateCTM(myContext, 0.0f, (blockHeight *
                    (CGFloat)i) + blockHeight);
                CGContextScaleCTM(myContext, 1.0, -1.0);

                CGRect r = CGRectMake(0.0f, 0.0f,
                    blockWidth,
                    blockHeight);
                CGContextDrawImage(myContext, r, img);

                CGContextRestoreGState(myContext);

                imageChanged[i] = false;
            }
        }
    }
    else
    {
        static const CGFloat whiteColor[] = {
            1.0f, 1.0f, 1.0f, 1.0f
        };

        static const CGFloat blackColor[] = {
            0.0f, 0.0f, 0.0f, 1.0f
        };

        static const char text1[] = "Waiting for game view";
        static const char text2[] = "Press 'Play'";

        CGContextSetFillColor(myContext, whiteColor);
        CGContextFillRect(myContext, rect);
        CGContextSelectFont(myContext, "Arial", 26.0f, kCGEncodingMacRoman);

        CGContextSetFillColor(myContext, blackColor);

        CGContextSaveGState(myContext);
        CGContextTranslateCTM(myContext, 10.0f, 100.0f);
        CGContextScaleCTM(myContext, 1.0, -1.0);
        CGContextShowTextAtPoint(myContext, 0.0f, 0.0f,
            text1, sizeof(text1) - 1);
        CGContextTranslateCTM(myContext, 0.0f, -40.0f);
        CGContextShowTextAtPoint(myContext, 0.0f, 0.0f,
            text2, sizeof(text2) - 1);
        CGContextRestoreGState(myContext);
    }
}

- (void)dealloc
{
	[super dealloc];
}


@end

#import "EAGLView.h"
#import "Setup.h"
#include "iPhoneRemoteMessage.h"
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>

enum
{
    kReceiveBufferSize = 0xffff
};


@interface UnityRemoteView : EAGLView <UIAccelerometerDelegate> {
@public
	NSTimer* m_UpdateTimer;
	struct sockaddr_in m_Sin;
    int m_fd;
    unsigned char m_block[kReceiveBufferSize];
    double m_LastScreenshotTime;
    int m_LastSentMessageID;
    int m_LastReceivedMessageID;
    bool m_ShowImages;
}

- (id)initWithFrame:(CGRect)frame editorAddress:(struct sockaddr_in *) addr;
- (void)dealloc;
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesCanceled:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration;
- (void)shutdown;
- (void)sendMessage:(RemoteMessage *)data length:(int)len;
- (void)setShowImages:(BOOL)toggle;
@end
